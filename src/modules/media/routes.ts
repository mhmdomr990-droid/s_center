import { Router } from 'express';

import { authMiddleware } from '../../middlewares/auth';
import { lectureDownloadUrlRateLimit, lectureStreamUrlRateLimit } from '../../middlewares/rateLimit';
import { validate } from '../../middlewares/validate';
import { idParamSchema } from '../../utils/requestSchemas';
import { postLectureDownloadUrl, postLectureStreamUrl } from './controller';

export const lectureMediaRoutes = Router();

lectureMediaRoutes.post('/lectures/:id/stream-url', authMiddleware, lectureStreamUrlRateLimit, validate({ params: idParamSchema }), postLectureStreamUrl);
lectureMediaRoutes.post('/lectures/:id/download-url', authMiddleware, lectureDownloadUrlRateLimit, validate({ params: idParamSchema }), postLectureDownloadUrl);
