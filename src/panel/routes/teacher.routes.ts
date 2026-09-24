import { Router } from 'express';

import { UserRole } from '../../entities/enums';
import { requireRole } from '../../middlewares/role';
import { validate } from '../../middlewares/validate';
import { lectureVideoUpload } from '../../middlewares/videoUpload';
import { asyncHandler } from '../../utils/asyncHandler';
import { panelFlash } from '../middlewares/flash';
import { panelAuth } from '../middlewares/panelAuth';
import { teacherCourseIdParamSchema, teacherLectureCreateSchema, teacherLectureIdParamSchema, teacherLectureUpdateSchema } from '../schemas/teacher.schema';
import { coursesPage, createLectureAction, earningsPage, hideLectureAction, lecturesPage, rootTeacherRedirect, updateLectureAction } from '../controllers/teacher.controller';

export const panelTeacherRoutes = Router();

panelTeacherRoutes.use(panelFlash, panelAuth, requireRole(UserRole.TEACHER));

panelTeacherRoutes.get('/', rootTeacherRedirect);
panelTeacherRoutes.get('/courses', asyncHandler(coursesPage));
panelTeacherRoutes.get('/lectures', asyncHandler(lecturesPage));
panelTeacherRoutes.get('/earnings', asyncHandler(earningsPage));
panelTeacherRoutes.post('/courses/:id/lectures', lectureVideoUpload.single('video'), validate({ params: teacherCourseIdParamSchema, body: teacherLectureCreateSchema }), asyncHandler(createLectureAction));
panelTeacherRoutes.post('/lectures/:id', lectureVideoUpload.single('video'), validate({ params: teacherLectureIdParamSchema, body: teacherLectureUpdateSchema }), asyncHandler(updateLectureAction));
panelTeacherRoutes.post('/lectures/:id/hide', validate({ params: teacherLectureIdParamSchema }), asyncHandler(hideLectureAction));
