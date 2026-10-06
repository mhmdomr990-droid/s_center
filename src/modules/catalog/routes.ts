import { Router } from 'express';

import { authMiddleware } from '../../middlewares/auth';
import { validate } from '../../middlewares/validate';
import { coursesQuerySchema, courseIdParamSchema } from './schemas';
import { getCourses, getLectures, getSpecializations } from './controller';

export const catalogRoutes = Router();

catalogRoutes.get('/specializations', getSpecializations);
catalogRoutes.get('/courses', authMiddleware, validate({ query: coursesQuerySchema }), getCourses);
catalogRoutes.get('/courses/:id/lectures', authMiddleware, validate({ params: courseIdParamSchema }), getLectures);
