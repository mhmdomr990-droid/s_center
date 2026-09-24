import crypto from 'crypto';
import { spawnSync } from 'child_process';
import fs from 'fs';
import path from 'path';

import type { Response } from 'express';

import { env } from '../config/env';
import { AppDataSource } from '../config/data-source';
import { Lecture } from '../entities/Lecture';
import { Purchase } from '../entities/Purchase';
import { User } from '../entities/User';
import { LectureType, LectureUploadStatus, UserRole } from '../entities/enums';
import { AppError } from '../utils/AppError';

export type MediaPurpose = 'stream' | 'download';

export interface MediaTokenPayload {
  lecture_id: number;
  user_id: number;
  purpose: MediaPurpose;
  exp: number;
  nonce: string;
  role: UserRole;
}

export interface StoredVideoFile {
  fieldname: string;
  originalname: string;
  encoding: string;
  mimetype: string;
  size: number;
  destination: string;
  filename: string;
  path: string;
}

const ALLOWED_VIDEO_MIME_TYPES: Record<string, string[]> = {
  '.mp4': ['video/mp4', 'application/mp4'],
  '.webm': ['video/webm'],
  '.mov': ['video/quicktime'],
  '.mkv': ['video/x-matroska', 'video/x-mkv'],
};

function base64Url(input: string | Buffer) {
  return Buffer.from(input).toString('base64url');
}

function fromBase64Url(input: string) {
  return Buffer.from(input, 'base64url');
}

export function resolveVideoStoragePath() {
  const configured = env.VIDEO_STORAGE_PATH;
  return path.isAbsolute(configured) ? configured : path.resolve(process.cwd(), configured);
}

export function resolveVideoFilePath(filename: string) {
  if (!filename || path.basename(filename) !== filename) {
    throw new AppError(400, 'Invalid video file reference');
  }

  return path.join(resolveVideoStoragePath(), filename);
}

export async function ensureVideoStorageDirectory() {
  await fs.promises.mkdir(resolveVideoStoragePath(), { recursive: true });
}

export function getAllowedVideoExtension(file: Pick<StoredVideoFile, 'originalname' | 'mimetype'>) {
  const extension = path.extname(file.originalname || '').toLowerCase();
  const allowedMimeTypes = ALLOWED_VIDEO_MIME_TYPES[extension];

  if (!allowedMimeTypes) {
    return null;
  }

  if (!allowedMimeTypes.includes(String(file.mimetype || '').toLowerCase())) {
    return null;
  }

  return extension;
}

export function assertValidVideoUpload(file: Pick<StoredVideoFile, 'originalname' | 'mimetype'>) {
  const extension = getAllowedVideoExtension(file);
  if (!extension) {
    throw new AppError(400, 'Only mp4, webm, mov, and mkv video files are allowed');
  }

  return extension;
}

export function buildStoredVideoFilename(file: Pick<StoredVideoFile, 'originalname' | 'mimetype'>) {
  const extension = assertValidVideoUpload(file);
  return `${crypto.randomUUID()}${extension}`;
}

export function buildStoredVideoFilePath(filename: string) {
  return resolveVideoFilePath(filename);
}

export async function deleteStoredVideoFile(filename?: string | null) {
  if (!filename) {
    return;
  }

  const fullPath = resolveVideoFilePath(filename);
  try {
    await fs.promises.unlink(fullPath);
  } catch (error) {
    if ((error as NodeJS.ErrnoException).code !== 'ENOENT') {
      throw error;
    }
  }
}

export function detectVideoDurationSeconds(filePath: string) {
  const result = spawnSync('ffprobe', [
    '-v',
    'error',
    '-show_entries',
    'format=duration',
    '-of',
    'default=noprint_wrappers=1:nokey=1',
    filePath,
  ], { encoding: 'utf8' });

  if (result.error || result.status !== 0) {
    return null;
  }

  const duration = Number(String(result.stdout || '').trim());
  if (!Number.isFinite(duration) || duration <= 0) {
    return null;
  }

  return Math.round(duration);
}

export function getVideoContentType(filename: string) {
  const extension = path.extname(filename).toLowerCase();
  switch (extension) {
    case '.mp4':
      return 'video/mp4';
    case '.webm':
      return 'video/webm';
    case '.mov':
      return 'video/quicktime';
    case '.mkv':
      return 'video/x-matroska';
    default:
      return 'application/octet-stream';
  }
}

export function createSignedMediaToken(input: { lectureId: number; userId: number; purpose: MediaPurpose; role: UserRole; expiresInMinutes: number }) {
  const payload: MediaTokenPayload = {
    lecture_id: input.lectureId,
    user_id: input.userId,
    purpose: input.purpose,
    exp: Math.floor(Date.now() / 1000) + (input.expiresInMinutes * 60),
    nonce: crypto.randomUUID(),
    role: input.role,
  };

  const encodedPayload = base64Url(JSON.stringify(payload));
  const signature = crypto.createHmac('sha256', env.VIDEO_SIGNING_SECRET).update(encodedPayload).digest('base64url');
  return `${encodedPayload}.${signature}`;
}

export function verifySignedMediaToken(token: string) {
  const [encodedPayload, encodedSignature, extra] = String(token || '').split('.');
  if (!encodedPayload || !encodedSignature || extra) {
    return null;
  }

  let payloadBuffer: Buffer;
  try {
    payloadBuffer = fromBase64Url(encodedPayload);
  } catch {
    return null;
  }

  let payload: MediaTokenPayload;
  try {
    payload = JSON.parse(payloadBuffer.toString('utf8')) as MediaTokenPayload;
  } catch {
    return null;
  }

  if (!payload || typeof payload !== 'object') {
    return null;
  }

  const expectedSignature = crypto.createHmac('sha256', env.VIDEO_SIGNING_SECRET).update(encodedPayload).digest();
  let providedSignature: Buffer;
  try {
    providedSignature = fromBase64Url(encodedSignature);
  } catch {
    return null;
  }

  if (expectedSignature.length !== providedSignature.length || !crypto.timingSafeEqual(expectedSignature, providedSignature)) {
    return null;
  }

  if (typeof payload.lecture_id !== 'number' || typeof payload.user_id !== 'number' || typeof payload.exp !== 'number' || typeof payload.nonce !== 'string' || typeof payload.purpose !== 'string' || !Object.values(UserRole).includes(payload.role)) {
    return null;
  }

  return payload;
}

export async function loadLectureMediaContext(payload: MediaTokenPayload) {
  if (payload.exp < Math.floor(Date.now() / 1000)) {
    throw new AppError(403, 'Access denied');
  }

  const userRepository = AppDataSource.getRepository(User);
  const lectureRepository = AppDataSource.getRepository(Lecture);

  const user = await userRepository.findOne({ where: { id: payload.user_id } });
  if (!user || !user.isActive || user.role !== payload.role) {
    throw new AppError(403, 'Access denied');
  }

  const lecture = await lectureRepository.findOne({
    where: { id: payload.lecture_id },
    relations: { course: { specialization: true, teacher: true } },
  });

  if (!lecture || lecture.type !== LectureType.VIDEO || lecture.uploadStatus !== LectureUploadStatus.READY || !lecture.storageFilename) {
    throw new AppError(404, 'Media not found');
  }

  const isStudent = user.role === UserRole.STUDENT;
  const isTeacher = user.role === UserRole.TEACHER;
  const isAdmin = user.role === UserRole.ADMIN;

  if (isStudent) {
    if (!lecture.isPublished || !lecture.course.isPublished || !lecture.course.specialization.isPublished) {
      throw new AppError(403, 'Access denied');
    }

    const purchased = await AppDataSource.getRepository(Purchase).findOne({
      where: { user: { id: user.id }, course: { id: lecture.course.id } },
    });

    if (!purchased) {
      throw new AppError(403, 'Access denied');
    }
  } else if (isTeacher) {
    if (lecture.course.teacher?.id !== user.id) {
      throw new AppError(403, 'Access denied');
    }
  } else if (!isAdmin) {
    throw new AppError(403, 'Access denied');
  }

  const filePath = resolveVideoFilePath(lecture.storageFilename);
  try {
    await fs.promises.access(filePath, fs.constants.R_OK);
  } catch {
    throw new AppError(404, 'Media not found');
  }

  return { user, lecture, filePath };
}

function parseRangeHeader(rangeHeader: string | undefined, totalSize: number) {
  if (!rangeHeader) {
    return null;
  }

  const match = /^bytes=(\d*)-(\d*)$/i.exec(rangeHeader.trim());
  if (!match) {
    return null;
  }

  const startText = match[1];
  const endText = match[2];

  if (!startText && !endText) {
    return null;
  }

  let start: number;
  let end: number;

  if (!startText) {
    const suffixLength = Number(endText);
    if (!Number.isFinite(suffixLength) || suffixLength <= 0) {
      return null;
    }
    start = Math.max(totalSize - suffixLength, 0);
    end = totalSize - 1;
  } else {
    start = Number(startText);
    end = endText ? Number(endText) : totalSize - 1;
    if (!Number.isFinite(start) || start < 0 || !Number.isFinite(end) || end < start) {
      return null;
    }
    end = Math.min(end, totalSize - 1);
  }

  if (start >= totalSize) {
    return null;
  }

  return { start, end };
}

export async function streamStoredVideoResponse(
  res: Response,
  filePath: string,
  options: { contentType: string; attachmentFilename?: string; rangeHeader?: string | undefined },
) {
  const stat = await fs.promises.stat(filePath);
  const totalSize = stat.size;
  const range = parseRangeHeader(options.rangeHeader, totalSize);

  if (options.rangeHeader && !range) {
    res.status(416);
    res.setHeader('Content-Range', `bytes */${totalSize}`);
    res.setHeader('Accept-Ranges', 'bytes');
    res.end();
    return;
  }

  const start = range ? range.start : 0;
  const end = range ? range.end : totalSize - 1;
  const chunkSize = end - start + 1;

  res.status(range ? 206 : 200);
  res.setHeader('Content-Type', options.contentType);
  res.setHeader('Accept-Ranges', 'bytes');
  res.setHeader('Content-Length', String(chunkSize));
  if (range) {
    res.setHeader('Content-Range', `bytes ${start}-${end}/${totalSize}`);
  }
  if (options.attachmentFilename) {
    res.setHeader('Content-Disposition', `attachment; filename="${options.attachmentFilename}"`);
  }

  await new Promise<void>((resolve, reject) => {
    const stream = fs.createReadStream(filePath, { start, end });
    const cleanup = () => {
      stream.destroy();
      resolve();
    };

    res.once('close', cleanup);
    stream.once('error', reject);
    stream.once('end', () => {
      res.removeListener('close', cleanup);
      resolve();
    });
    stream.pipe(res);
  });
}
