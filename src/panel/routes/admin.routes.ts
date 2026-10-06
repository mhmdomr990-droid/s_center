import { Router } from 'express';
import { z } from 'zod';

import { UserRole } from '../../entities/enums';
import { requireRole } from '../../middlewares/role';
import { validate } from '../../middlewares/validate';
import { lectureVideoUpload } from '../../middlewares/videoUpload';
import { asyncHandler } from '../../utils/asyncHandler';
import {
	adminIdParamSchema,
	adjustBalanceSchema,
	activeUserSchema,
	adminCreateSchema,
	adminNotificationSchema,
	adminSalesStatsSchema,
	studentCreateSchema,
	adminStatsRangeSchema,
	adminTeachersStatsSchema,
	adminTopCoursesStatsSchema,
	courseCreateSchema,
	courseUpdateSchema,
	lectureCreateSchema,
	lectureUpdateSchema,
	rejectTopupSchema,
	resetPasswordSchema,
	specializationCreateSchema,
	specializationUpdateSchema,
	teacherCreateSchema,
	teacherPayoutSchema,
	topupRequestsQuerySchema,
	adminUsersQuerySchema,
} from '../../modules/admin/schemas';
import { panelFlash } from '../middlewares/flash';
import { panelAuth } from '../middlewares/panelAuth';
import {
	approveTopupAction,
	adjustUserBalanceAction,
	coursesPage,
	createAdminAction,
	createCourseAction,
	createLectureAction,
	createSpecializationAction,
	createStudentAction,
	createTeacherAction,
	grantUserCourseAction,
	lecturesPage,
	watchLecturePage,
	notificationsPage,
	overviewPage,
	rejectTopupAction,
	revokeUserCourseGrantAction,
	resetUserDeviceAction,
	resetUserPasswordAction,
	sendNotificationAction,
	specializationsPage,
	statsRedirect,
	teacherPayoutAction,
	teacherPayoutsPage,
	teachersPage,
	topupsPage,
	deleteCourseAction,
	deleteLectureAction,
	deleteSpecializationAction,
	toggleCourseAction,
	toggleSpecializationAction,
	toggleUserActiveAction,
	updateCourseAction,
	updateLectureAction,
	updateSpecializationAction,
	usersPage,
	hideLectureAction,
} from '../controllers/admin.controller';

export const panelAdminRoutes = Router();

const togglePublishSchema = z
	.object({
		next_is_published: z.string().min(1),
	})
	.strict();

const grantCourseSchema = z
	.object({
		course_id: z.coerce.number().int().positive(),
	})
	.strict();

const panelNotificationSchema = z
	.object({
		all: z.string().optional(),
		username: z.string().trim().optional(),
		title: z.string().trim().min(1).max(180),
		body: z.string().trim().min(1).max(5000),
	})
	.strict();

panelAdminRoutes.use(panelFlash, panelAuth, requireRole(UserRole.ADMIN));

panelAdminRoutes.get('/', (_req, res) => res.redirect('/panel/admin/overview'));
panelAdminRoutes.get('/overview', asyncHandler(overviewPage));
panelAdminRoutes.get('/stats', statsRedirect);

panelAdminRoutes.get('/specializations', asyncHandler(specializationsPage));
panelAdminRoutes.post('/specializations', validate({ body: specializationCreateSchema }), asyncHandler(createSpecializationAction));
panelAdminRoutes.post('/specializations/:id', validate({ params: adminIdParamSchema, body: specializationUpdateSchema }), asyncHandler(updateSpecializationAction));
panelAdminRoutes.post('/specializations/:id/toggle', validate({ params: adminIdParamSchema, body: togglePublishSchema }), asyncHandler(toggleSpecializationAction));
panelAdminRoutes.post('/specializations/:id/delete', validate({ params: adminIdParamSchema }), asyncHandler(deleteSpecializationAction));

panelAdminRoutes.get('/courses', asyncHandler(coursesPage));
panelAdminRoutes.post('/courses', validate({ body: courseCreateSchema }), asyncHandler(createCourseAction));
panelAdminRoutes.post('/courses/:id', validate({ params: adminIdParamSchema, body: courseUpdateSchema }), asyncHandler(updateCourseAction));
panelAdminRoutes.post('/courses/:id/toggle', validate({ params: adminIdParamSchema, body: togglePublishSchema }), asyncHandler(toggleCourseAction));
panelAdminRoutes.post('/courses/:id/delete', validate({ params: adminIdParamSchema }), asyncHandler(deleteCourseAction));

panelAdminRoutes.get('/lectures', asyncHandler(lecturesPage));
panelAdminRoutes.get('/lectures/:id/watch', validate({ params: adminIdParamSchema }), asyncHandler(watchLecturePage));
panelAdminRoutes.post('/lectures', lectureVideoUpload.single('video'), validate({ body: lectureCreateSchema }), asyncHandler(createLectureAction));
panelAdminRoutes.post('/lectures/:id', lectureVideoUpload.single('video'), validate({ params: adminIdParamSchema, body: lectureUpdateSchema }), asyncHandler(updateLectureAction));
panelAdminRoutes.post('/lectures/:id/hide', validate({ params: adminIdParamSchema }), asyncHandler(hideLectureAction));
panelAdminRoutes.post('/lectures/:id/delete', validate({ params: adminIdParamSchema }), asyncHandler(deleteLectureAction));

panelAdminRoutes.get('/topups', validate({ query: topupRequestsQuerySchema }), asyncHandler(topupsPage));
panelAdminRoutes.post('/topups/:id/approve', validate({ params: adminIdParamSchema }), asyncHandler(approveTopupAction));
panelAdminRoutes.post('/topups/:id/reject', validate({ params: adminIdParamSchema, body: rejectTopupSchema }), asyncHandler(rejectTopupAction));

panelAdminRoutes.get('/users', validate({ query: adminUsersQuerySchema }), asyncHandler(usersPage));
panelAdminRoutes.post('/users/:id/grant-course', validate({ params: adminIdParamSchema, body: grantCourseSchema }), asyncHandler(grantUserCourseAction));
panelAdminRoutes.post('/users/:id/revoke-course-grant', validate({ params: adminIdParamSchema, body: grantCourseSchema }), asyncHandler(revokeUserCourseGrantAction));
panelAdminRoutes.post('/users/:id/active', validate({ params: adminIdParamSchema, body: activeUserSchema }), asyncHandler(toggleUserActiveAction));
panelAdminRoutes.post('/users/:id/reset-device', validate({ params: adminIdParamSchema }), asyncHandler(resetUserDeviceAction));
panelAdminRoutes.post('/users/:id/reset-password', validate({ params: adminIdParamSchema, body: resetPasswordSchema }), asyncHandler(resetUserPasswordAction));
panelAdminRoutes.post('/users/:id/adjust-balance', validate({ params: adminIdParamSchema, body: adjustBalanceSchema }), asyncHandler(adjustUserBalanceAction));

panelAdminRoutes.post('/students', validate({ body: studentCreateSchema }), asyncHandler(createStudentAction));
panelAdminRoutes.post('/admins', validate({ body: adminCreateSchema }), asyncHandler(createAdminAction));
panelAdminRoutes.get('/teachers', asyncHandler(teachersPage));
panelAdminRoutes.post('/teachers', validate({ body: teacherCreateSchema }), asyncHandler(createTeacherAction));
panelAdminRoutes.post('/teachers/:id/payouts', validate({ params: adminIdParamSchema, body: teacherPayoutSchema }), asyncHandler(teacherPayoutAction));
panelAdminRoutes.get('/teachers/:id/payouts', validate({ params: adminIdParamSchema }), asyncHandler(teacherPayoutsPage));

panelAdminRoutes.get('/notifications', asyncHandler(notificationsPage));
panelAdminRoutes.post('/notifications', validate({ body: panelNotificationSchema }), asyncHandler(sendNotificationAction));
