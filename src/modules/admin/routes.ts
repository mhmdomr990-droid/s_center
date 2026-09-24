import { Router } from 'express';

import { authMiddleware } from '../../middlewares/auth';
import { requireRole } from '../../middlewares/role';
import { validate } from '../../middlewares/validate';
import { lectureVideoUpload } from '../../middlewares/videoUpload';
import { UserRole } from '../../entities/enums';
import {
  adjustBalanceSchema,
  adminCoursesQuerySchema,
  adminIdParamSchema,
  adminLecturesQuerySchema,
  adminSalesStatsSchema,
  adminSpecializationsQuerySchema,
  adminStatsRangeSchema,
  adminTeachersStatsSchema,
  adminTopCoursesStatsSchema,
  adminNotificationSchema,
  adminUsersQuerySchema,
  activeUserSchema,
  courseCreateSchema,
  courseUpdateSchema,
  lectureOrderSchema,
  lectureCreateSchema,
  lectureUpdateSchema,
  publishedBodySchema,
  rejectTopupSchema,
  resetPasswordSchema,
  specializationCreateSchema,
  specializationUpdateSchema,
  teacherCreateSchema,
  teacherPayoutSchema,
  topupRequestsQuerySchema,
} from './schemas';
import {
  getAdminBadges,
  getAdminCourseById,
  getAdminCourseLectures,
  approveAdminTopupRequest,
  adjustAdminUserBalance,
  deleteAdminCourse,
  deleteAdminLecture,
  deleteAdminSpecialization,
  getAdminLectureById,
  getAdminStatsBySpecialization,
  getAdminStatsOverview,
  getAdminStatsSales,
  getAdminStatsTeachers,
  getAdminStatsTopCourses,
  getAdminSpecializationById,
  getAdminTeacherById,
  getAdminTeacherPayouts,
  getAdminCourses,
  getAdminLectures,
  getAdminSpecializations,
  getAdminTopupRequestById,
  getAdminTopupRequests,
  getAdminUserById,
  getAdminUserPurchases,
  getAdminUserTransactions,
  getAdminTeachers,
  getAdminUsers,
  patchAdminCourse,
  patchAdminCoursePublished,
  patchAdminLecture,
  patchAdminLecturePublished,
  patchAdminSpecialization,
  patchAdminSpecializationPublished,
  patchAdminUserActive,
  postAdminResetPassword,
  postAdminCourse,
  postAdminLecture,
  postAdminSpecialization,
  postAdminTeacher,
  postAdminTeacherPayout,
  putAdminLectureOrder,
  rejectAdminTopupRequest,
  resetAdminUserDevice,
  sendAdminNotification,
} from './controller';

export const adminRoutes = Router();

adminRoutes.use(authMiddleware, requireRole(UserRole.ADMIN));

adminRoutes.get('/badges', getAdminBadges);

adminRoutes.get('/specializations', validate({ query: adminSpecializationsQuerySchema }), getAdminSpecializations);
adminRoutes.post('/specializations', validate({ body: specializationCreateSchema }), postAdminSpecialization);
adminRoutes.get('/specializations/:id', validate({ params: adminIdParamSchema }), getAdminSpecializationById);
adminRoutes.patch('/specializations/:id', validate({ params: adminIdParamSchema, body: specializationUpdateSchema }), patchAdminSpecialization);
adminRoutes.patch('/specializations/:id/published', validate({ params: adminIdParamSchema, body: publishedBodySchema }), patchAdminSpecializationPublished);
adminRoutes.delete('/specializations/:id', validate({ params: adminIdParamSchema }), deleteAdminSpecialization);

adminRoutes.get('/courses', validate({ query: adminCoursesQuerySchema }), getAdminCourses);
adminRoutes.post('/courses', validate({ body: courseCreateSchema }), postAdminCourse);
adminRoutes.get('/courses/:id', validate({ params: adminIdParamSchema }), getAdminCourseById);
adminRoutes.get('/courses/:id/lectures', validate({ params: adminIdParamSchema }), getAdminCourseLectures);
adminRoutes.patch('/courses/:id', validate({ params: adminIdParamSchema, body: courseUpdateSchema }), patchAdminCourse);
adminRoutes.patch('/courses/:id/published', validate({ params: adminIdParamSchema, body: publishedBodySchema }), patchAdminCoursePublished);
adminRoutes.put('/courses/:id/lectures/order', validate({ params: adminIdParamSchema, body: lectureOrderSchema }), putAdminLectureOrder);
adminRoutes.delete('/courses/:id', validate({ params: adminIdParamSchema }), deleteAdminCourse);

adminRoutes.get('/lectures', validate({ query: adminLecturesQuerySchema }), getAdminLectures);
adminRoutes.post('/lectures', lectureVideoUpload.single('video'), validate({ body: lectureCreateSchema }), postAdminLecture);
adminRoutes.get('/lectures/:id', validate({ params: adminIdParamSchema }), getAdminLectureById);
adminRoutes.patch('/lectures/:id', lectureVideoUpload.single('video'), validate({ params: adminIdParamSchema, body: lectureUpdateSchema }), patchAdminLecture);
adminRoutes.patch('/lectures/:id/published', validate({ params: adminIdParamSchema, body: publishedBodySchema }), patchAdminLecturePublished);
adminRoutes.delete('/lectures/:id', validate({ params: adminIdParamSchema }), deleteAdminLecture);

adminRoutes.get('/topup-requests', validate({ query: topupRequestsQuerySchema }), getAdminTopupRequests);
adminRoutes.get('/topup-requests/:id', validate({ params: adminIdParamSchema }), getAdminTopupRequestById);
adminRoutes.post('/topup-requests/:id/approve', validate({ params: adminIdParamSchema }), approveAdminTopupRequest);
adminRoutes.post('/topup-requests/:id/reject', validate({ params: adminIdParamSchema, body: rejectTopupSchema }), rejectAdminTopupRequest);

adminRoutes.get('/users', validate({ query: adminUsersQuerySchema }), getAdminUsers);
adminRoutes.get('/users/:id', validate({ params: adminIdParamSchema }), getAdminUserById);
adminRoutes.get('/users/:id/transactions', validate({ params: adminIdParamSchema }), getAdminUserTransactions);
adminRoutes.get('/users/:id/purchases', validate({ params: adminIdParamSchema }), getAdminUserPurchases);
adminRoutes.patch('/users/:id/active', validate({ params: adminIdParamSchema, body: activeUserSchema }), patchAdminUserActive);
adminRoutes.post('/users/:id/reset-device', validate({ params: adminIdParamSchema }), resetAdminUserDevice);
adminRoutes.post('/users/:id/adjust-balance', validate({ params: adminIdParamSchema, body: adjustBalanceSchema }), adjustAdminUserBalance);
adminRoutes.post('/users/:id/reset-password', validate({ params: adminIdParamSchema, body: resetPasswordSchema }), postAdminResetPassword);

adminRoutes.post('/notifications', validate({ body: adminNotificationSchema }), sendAdminNotification);

adminRoutes.post('/teachers', validate({ body: teacherCreateSchema }), postAdminTeacher);
adminRoutes.get('/teachers', getAdminTeachers);
adminRoutes.get('/teachers/:id', validate({ params: adminIdParamSchema }), getAdminTeacherById);
adminRoutes.post('/teachers/:id/payouts', validate({ params: adminIdParamSchema, body: teacherPayoutSchema }), postAdminTeacherPayout);
adminRoutes.get('/teachers/:id/payouts', validate({ params: adminIdParamSchema }), getAdminTeacherPayouts);

adminRoutes.get('/stats/overview', validate({ query: adminStatsRangeSchema }), getAdminStatsOverview);
adminRoutes.get('/stats/sales', validate({ query: adminSalesStatsSchema }), getAdminStatsSales);
adminRoutes.get('/stats/top-courses', validate({ query: adminTopCoursesStatsSchema }), getAdminStatsTopCourses);
adminRoutes.get('/stats/by-specialization', validate({ query: adminStatsRangeSchema }), getAdminStatsBySpecialization);
adminRoutes.get('/stats/teachers', validate({ query: adminTeachersStatsSchema }), getAdminStatsTeachers);
