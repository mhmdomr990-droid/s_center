import { Router } from 'express';

import { authMiddleware } from '../../middlewares/auth';
import { requireRole } from '../../middlewares/role';
import { validate } from '../../middlewares/validate';
import { lectureVideoUpload } from '../../middlewares/videoUpload';
import { UserRole } from '../../entities/enums';
import {
  teacherCourseUpdateSchema,
  teacherDashboardQuerySchema,
  teacherEarningsQuerySchema,
  teacherCourseIdParamSchema,
  teacherLectureCreateSchema,
  teacherLectureIdParamSchema,
  teacherLectureOrderSchema,
  teacherLecturePublishSchema,
  teacherLectureUpdateSchema,
  teacherStatsQuerySchema,
} from './schemas';
import {
  deleteTeacherLecture,
  getTeacherCourseByIdController,
  getTeacherCourseLectures,
  getTeacherCoursePreview,
  getTeacherCourses,
  getTeacherDashboardController,
  getTeacherEarnings,
  getTeacherPayouts,
  getTeacherStatsController,
  patchTeacherLecture,
  patchTeacherLecturePublished,
  patchTeacherCourse,
  postTeacherLecture,
  putTeacherLectureOrder,
} from './controller';

export const teacherRoutes = Router();

teacherRoutes.use(authMiddleware, requireRole(UserRole.TEACHER));

teacherRoutes.get('/courses', getTeacherCourses);
teacherRoutes.get('/dashboard', validate({ query: teacherDashboardQuerySchema }), getTeacherDashboardController);
teacherRoutes.get('/courses/:id', validate({ params: teacherCourseIdParamSchema }), getTeacherCourseByIdController);
teacherRoutes.patch('/courses/:id', validate({ params: teacherCourseIdParamSchema, body: teacherCourseUpdateSchema }), patchTeacherCourse);
teacherRoutes.get('/courses/:id/lectures', validate({ params: teacherCourseIdParamSchema }), getTeacherCourseLectures);
teacherRoutes.get('/courses/:id/preview', validate({ params: teacherCourseIdParamSchema }), getTeacherCoursePreview);
teacherRoutes.put('/courses/:id/lectures/order', validate({ params: teacherCourseIdParamSchema, body: teacherLectureOrderSchema }), putTeacherLectureOrder);
teacherRoutes.post('/courses/:id/lectures', lectureVideoUpload.single('video'), validate({ params: teacherCourseIdParamSchema, body: teacherLectureCreateSchema }), postTeacherLecture);
teacherRoutes.patch('/lectures/:id', lectureVideoUpload.single('video'), validate({ params: teacherLectureIdParamSchema, body: teacherLectureUpdateSchema }), patchTeacherLecture);
teacherRoutes.patch('/lectures/:id/published', validate({ params: teacherLectureIdParamSchema, body: teacherLecturePublishSchema }), patchTeacherLecturePublished);
teacherRoutes.delete('/lectures/:id', validate({ params: teacherLectureIdParamSchema }), deleteTeacherLecture);
teacherRoutes.get('/stats', validate({ query: teacherStatsQuerySchema }), getTeacherStatsController);
teacherRoutes.get('/earnings', validate({ query: teacherEarningsQuerySchema }), getTeacherEarnings);
teacherRoutes.get('/payouts', getTeacherPayouts);
