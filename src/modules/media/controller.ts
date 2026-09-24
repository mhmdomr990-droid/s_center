import type { Request, Response } from 'express';

import { env } from '../../config/env';
import { AppDataSource } from '../../config/data-source';
import { Lecture } from '../../entities/Lecture';
import { Purchase } from '../../entities/Purchase';
import { User } from '../../entities/User';
import { LectureType, UserRole } from '../../entities/enums';
import { asyncHandler } from '../../utils/asyncHandler';
import { AppError } from '../../utils/AppError';
import { logAuditEvent } from '../../services/auditLog';
import path from 'path';
import {
  createSignedMediaToken,
  getVideoContentType,
  loadLectureMediaContext,
  streamStoredVideoResponse,
  verifySignedMediaToken,
} from '../../services/media';

async function findLectureOrThrow(lectureId: number) {
  const lecture = await AppDataSource.getRepository(Lecture).findOne({
    where: { id: lectureId },
    relations: { course: { specialization: true, teacher: true } },
  });

  if (!lecture) {
    throw new AppError(404, 'Lecture not found');
  }

  return lecture;
}

async function assertCanIssueStreamToken(user: User, lecture: Lecture) {
  if (lecture.type !== LectureType.VIDEO || lecture.uploadStatus !== 'READY' || !lecture.storageFilename) {
    throw new AppError(400, 'Video not available');
  }

  if (user.role === UserRole.STUDENT) {
    if (!lecture.isPublished || !lecture.course.isPublished || !lecture.course.specialization.isPublished) {
      throw new AppError(403, 'Access denied');
    }

    const purchased = await AppDataSource.getRepository(Purchase).findOne({
      where: { user: { id: user.id }, course: { id: lecture.course.id } },
    });

    if (!purchased) {
      throw new AppError(403, 'Access denied');
    }
    return;
  }

  if (user.role === UserRole.TEACHER) {
    if (lecture.course.teacher?.id !== user.id) {
      throw new AppError(403, 'Access denied');
    }
    return;
  }

  if (user.role !== UserRole.ADMIN) {
    throw new AppError(403, 'Access denied');
  }
}

export const postLectureStreamUrl = asyncHandler(async (req: Request, res: Response) => {
  const lecture = await findLectureOrThrow(Number(req.params.id));
  await assertCanIssueStreamToken(req.user!, lecture);

  const token = createSignedMediaToken({
    lectureId: lecture.id,
    userId: req.user!.id,
    purpose: 'stream',
    role: req.user!.role,
    expiresInMinutes: 10,
  });

  res.status(200).json({ success: true, data: { url: `/media/play/${token}` } });
});

export const postLectureDownloadUrl = asyncHandler(async (req: Request, res: Response) => {
  if (req.user!.role !== UserRole.STUDENT) {
    throw new AppError(403, 'Access denied');
  }

  const lecture = await findLectureOrThrow(Number(req.params.id));
  await assertCanIssueStreamToken(req.user!, lecture);

  const token = createSignedMediaToken({
    lectureId: lecture.id,
    userId: req.user!.id,
    purpose: 'download',
    role: req.user!.role,
    expiresInMinutes: env.DOWNLOAD_URL_EXPIRY_MINUTES,
  });

  const expiresAt = new Date((Math.floor(Date.now() / 1000) + (env.DOWNLOAD_URL_EXPIRY_MINUTES * 60)) * 1000).toISOString();

  await logAuditEvent({
    action: 'LECTURE_DOWNLOAD_URL_ISSUED',
    actorId: req.user!.id,
    entityType: 'Lecture',
    entityId: lecture.id,
    metadata: {
      user_id: req.user!.id,
      lecture_id: lecture.id,
      issued_at: new Date().toISOString(),
    },
  });

  res.status(200).json({
    success: true,
    data: {
      url: `/media/download/${token}`,
      expires_at: expiresAt,
      lecture_id: lecture.id,
      course_id: lecture.course.id,
      download_ttl_days: env.DOWNLOAD_TTL_DAYS,
    },
  });
});

async function serveMediaToken(req: Request, res: Response, purpose: 'stream' | 'download', token: string) {
  const payload = verifySignedMediaToken(token);
  if (!payload || payload.purpose !== purpose) {
    return res.status(403).end();
  }

  try {
    const { lecture, filePath } = await loadLectureMediaContext(payload);
    const fileExtension = path.extname(lecture.storageFilename || '') || '.mp4';

    await streamStoredVideoResponse(res, filePath, {
      contentType: getVideoContentType(lecture.storageFilename!),
      attachmentFilename: purpose === 'download' ? `lecture-${lecture.id}${fileExtension || '.mp4'}` : undefined,
      rangeHeader: req.headers.range,
    });
  } catch (error) {
    if (error instanceof AppError && error.statusCode === 404) {
      return res.status(404).end();
    }
    return res.status(403).end();
  }
}

export const getMediaPlay = asyncHandler(async (req: Request, res: Response) => {
  await serveMediaToken(req, res, 'stream', String(req.params.token || ''));
});

export const getMediaDownload = asyncHandler(async (req: Request, res: Response) => {
  await serveMediaToken(req, res, 'download', String(req.params.token || ''));
});
