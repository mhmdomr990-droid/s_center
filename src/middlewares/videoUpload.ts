import multer from 'multer';

import { env } from '../config/env';
import { assertValidVideoUpload, buildStoredVideoFilename, ensureVideoStorageDirectory, resolveVideoStoragePath } from '../services/media';

const fileSizeLimit = env.VIDEO_MAX_SIZE_MB * 1024 * 1024;

const storage = multer.diskStorage({
  destination: async (_req: any, _file: any, callback: any) => {
    try {
      await ensureVideoStorageDirectory();
      callback(null, resolveVideoStoragePath());
    } catch (error) {
      callback(error as Error, '');
    }
  },
  filename: (_req: any, file: any, callback: any) => {
    try {
      callback(null, buildStoredVideoFilename(file));
    } catch (error) {
      callback(error as Error, '');
    }
  },
});

export const lectureVideoUpload = multer({
  storage,
  limits: {
    fileSize: fileSizeLimit,
  },
  fileFilter: (_req: any, file: any, callback: any) => {
    try {
      assertValidVideoUpload(file);
      callback(null, true);
    } catch (error) {
      callback(error as Error, false);
    }
  },
});
