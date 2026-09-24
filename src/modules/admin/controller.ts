import type { Request, Response } from 'express';

import { asyncHandler } from '../../utils/asyncHandler';
import { TopupStatus, UserRole } from '../../entities/enums';
import {
  getCourseById,
  getLectureById,
  getSpecializationById,
  getTeacherById,
  getUserById,
  getTopupRequestById,
  listCourseLecturesForAdmin,
  approveTopupRequest,
  archiveCourse,
  archiveLecture,
  archiveSpecialization,
  bySpecializationStats,
  createCourse,
  createLecture,
  createNotifications,
  createSpecialization,
  createTeacher,
  adjustBalance,
  listTeacherPayouts,
  listTeachers,
  listCoursesFiltered,
  listLecturesFiltered,
  listSpecializationsFiltered,
  listTopupRequests,
  listUserPurchases,
  listUserTransactions,
  listUsersFiltered,
  overviewStats,
  reorderCourseLectures,
  rejectTopupRequest,
  resetUserDevice,
  resetPassword,
  setCoursePublished,
  setLecturePublished,
  setSpecializationPublished,
  setUserActive,
  payoutTeacher,
  salesStats,
  teacherPayoutHistory,
  teachersStats,
  topCoursesStats,
  updateCourse,
  updateLecture,
  updateSpecialization,
} from './service';
import { paginateItems } from '../../utils/pagination';
import { executeIdempotent } from '../../services/idempotency';

export const getAdminSpecializations = asyncHandler(async (req: Request, res: Response) => {
  const data = await listSpecializationsFiltered(req.query.search as string | undefined);
  const paged = paginateItems(data, { page: Number(req.query.page ?? 1), limit: Number(req.query.limit ?? 20) });
  res.status(200).json({ success: true, data: paged.data, meta: paged.meta });
});

export const getAdminSpecializationById = asyncHandler(async (req: Request, res: Response) => {
  const data = await getSpecializationById(Number(req.params.id));
  res.status(200).json({ success: true, data });
});

export const postAdminSpecialization = asyncHandler(async (req: Request, res: Response) => {
  const data = await createSpecialization(req.body);
  res.status(201).json({ success: true, data });
});

export const patchAdminSpecialization = asyncHandler(async (req: Request, res: Response) => {
  const data = await updateSpecialization(Number(req.params.id), req.body);
  res.status(200).json({ success: true, data });
});

export const patchAdminSpecializationPublished = asyncHandler(async (req: Request, res: Response) => {
  const data = await setSpecializationPublished(Number(req.params.id), req.body.is_published);
  res.status(200).json({ success: true, data });
});

export const deleteAdminSpecialization = asyncHandler(async (req: Request, res: Response) => {
  const data = await archiveSpecialization(Number(req.params.id));
  res.status(200).json({ success: true, data });
});

export const getAdminCourses = asyncHandler(async (req: Request, res: Response) => {
  const data = await listCoursesFiltered({
    specializationId: req.query.specializationId ? Number(req.query.specializationId) : undefined,
    year: req.query.year ? Number(req.query.year) : undefined,
    teacherId: req.query.teacherId ? Number(req.query.teacherId) : undefined,
    is_published: req.query.is_published !== undefined ? String(req.query.is_published) === 'true' : undefined,
    search: req.query.search as string | undefined,
  });
  const paged = paginateItems(data, { page: Number(req.query.page ?? 1), limit: Number(req.query.limit ?? 20) });
  res.status(200).json({ success: true, data: paged.data, meta: paged.meta });
});

export const getAdminCourseById = asyncHandler(async (req: Request, res: Response) => {
  const data = await getCourseById(Number(req.params.id));
  res.status(200).json({ success: true, data });
});

export const postAdminCourse = asyncHandler(async (req: Request, res: Response) => {
  const data = await createCourse(req.body);
  res.status(201).json({ success: true, data });
});

export const patchAdminCourse = asyncHandler(async (req: Request, res: Response) => {
  const data = await updateCourse(Number(req.params.id), req.body, req.user!.id);
  res.status(200).json({ success: true, data });
});

export const patchAdminCoursePublished = asyncHandler(async (req: Request, res: Response) => {
  const data = await setCoursePublished(Number(req.params.id), req.body.is_published);
  res.status(200).json({ success: true, data });
});

export const deleteAdminCourse = asyncHandler(async (req: Request, res: Response) => {
  const data = await archiveCourse(Number(req.params.id));
  res.status(200).json({ success: true, data });
});

export const getAdminLectures = asyncHandler(async (req: Request, res: Response) => {
  const data = await listLecturesFiltered(req.query.course_id ? Number(req.query.course_id) : undefined);
  const paged = paginateItems(data, { page: Number(req.query.page ?? 1), limit: Number(req.query.limit ?? 20) });
  res.status(200).json({ success: true, data: paged.data, meta: paged.meta });
});

export const getAdminCourseLectures = asyncHandler(async (req: Request, res: Response) => {
  const data = await listCourseLecturesForAdmin(Number(req.params.id));
  res.status(200).json({ success: true, data });
});

export const getAdminLectureById = asyncHandler(async (req: Request, res: Response) => {
  const data = await getLectureById(Number(req.params.id));
  res.status(200).json({ success: true, data });
});

export const postAdminLecture = asyncHandler(async (req: Request, res: Response) => {
  const data = await createLecture(req.user!.id, req.body, req.file ?? null);
  res.status(201).json({ success: true, data });
});

export const patchAdminLecture = asyncHandler(async (req: Request, res: Response) => {
  const data = await updateLecture(Number(req.params.id), req.body, req.file ?? null);
  res.status(200).json({ success: true, data });
});

export const patchAdminLecturePublished = asyncHandler(async (req: Request, res: Response) => {
  const data = await setLecturePublished(Number(req.params.id), req.body.is_published);
  res.status(200).json({ success: true, data });
});

export const putAdminLectureOrder = asyncHandler(async (req: Request, res: Response) => {
  const data = await reorderCourseLectures(Number(req.params.id), req.body.lecture_ids);
  res.status(200).json({ success: true, data });
});

export const deleteAdminLecture = asyncHandler(async (req: Request, res: Response) => {
  const data = await archiveLecture(Number(req.params.id));
  res.status(200).json({ success: true, data });
});

export const getAdminTopupRequests = asyncHandler(async (req: Request, res: Response) => {
  const data = await listTopupRequests(req.query.status as TopupStatus);
  const paged = paginateItems(data, { page: Number(req.query.page ?? 1), limit: Number(req.query.limit ?? 20) });
  res.status(200).json({ success: true, data: paged.data, meta: paged.meta });
});

export const getAdminTopupRequestById = asyncHandler(async (req: Request, res: Response) => {
  const data = await getTopupRequestById(Number(req.params.id));
  res.status(200).json({ success: true, data });
});

export const approveAdminTopupRequest = asyncHandler(async (req: Request, res: Response) => {
  const data = await approveTopupRequest(Number(req.params.id), req.user!.id);
  res.status(200).json({ success: true, data });
});

export const rejectAdminTopupRequest = asyncHandler(async (req: Request, res: Response) => {
  const data = await rejectTopupRequest(Number(req.params.id), req.user!.id, req.body.reason);
  res.status(200).json({ success: true, data });
});

export const getAdminUsers = asyncHandler(async (req: Request, res: Response) => {
  const data = await listUsersFiltered({
    search: req.query.search as string | undefined,
    role: req.query.role as UserRole | undefined,
    is_active: req.query.is_active !== undefined ? String(req.query.is_active) === 'true' : undefined,
    is_test: req.query.is_test !== undefined ? String(req.query.is_test) === 'true' : undefined,
  });
  const paged = paginateItems(data, { page: Number(req.query.page ?? 1), limit: Number(req.query.limit ?? 20) });
  res.status(200).json({ success: true, data: paged.data, meta: paged.meta });
});

export const getAdminUserById = asyncHandler(async (req: Request, res: Response) => {
  const data = await getUserById(Number(req.params.id));
  res.status(200).json({ success: true, data });
});

export const getAdminUserTransactions = asyncHandler(async (req: Request, res: Response) => {
  const data = await listUserTransactions(Number(req.params.id));
  const paged = paginateItems(data, { page: Number(req.query.page ?? 1), limit: Number(req.query.limit ?? 20) });
  res.status(200).json({ success: true, data: paged.data, meta: paged.meta });
});

export const getAdminUserPurchases = asyncHandler(async (req: Request, res: Response) => {
  const data = await listUserPurchases(Number(req.params.id));
  const paged = paginateItems(data, { page: Number(req.query.page ?? 1), limit: Number(req.query.limit ?? 20) });
  res.status(200).json({ success: true, data: paged.data, meta: paged.meta });
});

export const patchAdminUserActive = asyncHandler(async (req: Request, res: Response) => {
  const data = await setUserActive(Number(req.params.id), req.body.is_active);
  res.status(200).json({ success: true, data });
});

export const resetAdminUserDevice = asyncHandler(async (req: Request, res: Response) => {
  const data = await resetUserDevice(Number(req.params.id));
  res.status(200).json({ success: true, data });
});

export const adjustAdminUserBalance = asyncHandler(async (req: Request, res: Response) => {
  const result = await executeIdempotent({
    actorId: req.user!.id,
    route: '/api/admin/users/:id/adjust-balance',
    key: req.get('Idempotency-Key') ?? undefined,
    action: async () => {
      const data = await adjustBalance(Number(req.params.id), req.body.amount, req.body.description);
      return { status: 200, body: { success: true, data } };
    },
  });
  res.status(result.status).json(result.body);
});

export const sendAdminNotification = asyncHandler(async (req: Request, res: Response) => {
  const data = await createNotifications(req.body);
  res.status(201).json({ success: true, data });
});

export const postAdminTeacher = asyncHandler(async (req: Request, res: Response) => {
  const data = await createTeacher(req.body);
  res.status(201).json({ success: true, data });
});

export const getAdminTeachers = asyncHandler(async (_req: Request, res: Response) => {
  const data = await listTeachers();
  res.status(200).json({ success: true, data });
});

export const getAdminTeacherById = asyncHandler(async (req: Request, res: Response) => {
  const data = await getTeacherById(Number(req.params.id));
  res.status(200).json({ success: true, data });
});

export const getAdminBadges = asyncHandler(async (_req: Request, res: Response) => {
  const overview = await overviewStats();
  const pending = await listTopupRequests(TopupStatus.PENDING);
  const pendingTopupsAmount = pending.reduce((sum, item) => {
    const [whole, fraction = '00'] = String(item.amount).split('.');
    return sum + BigInt(whole) * 100n + BigInt((fraction + '00').slice(0, 2));
  }, 0n);
  const totalWhole = pendingTopupsAmount / 100n;
  const totalFraction = (pendingTopupsAmount % 100n).toString().padStart(2, '0');
  res.status(200).json({
    success: true,
    data: {
      pending_topups: overview.pending_topups_count,
      pending_topups_amount: `${totalWhole.toString()}.${totalFraction}`,
    },
  });
});

export const postAdminTeacherPayout = asyncHandler(async (req: Request, res: Response) => {
  const result = await executeIdempotent({
    actorId: req.user!.id,
    route: '/api/admin/teachers/:id/payouts',
    key: req.get('Idempotency-Key') ?? undefined,
    action: async () => {
      const data = await payoutTeacher(Number(req.params.id), req.user!.id, req.body.amount, req.body.note);
      return { status: 201, body: { success: true, data } };
    },
  });
  res.status(result.status).json(result.body);
});

export const getAdminTeacherPayouts = asyncHandler(async (req: Request, res: Response) => {
  const data = await teacherPayoutHistory(Number(req.params.id));
  res.status(200).json({ success: true, data });
});

export const postAdminResetPassword = asyncHandler(async (req: Request, res: Response) => {
  const data = await resetPassword(Number(req.params.id), req.body.new_password);
  res.status(200).json({ success: true, data });
});

export const getAdminStatsOverview = asyncHandler(async (req: Request, res: Response) => {
  const data = await overviewStats(req.query.from as string | undefined, req.query.to as string | undefined);
  res.status(200).json({ success: true, data });
});

export const getAdminStatsSales = asyncHandler(async (req: Request, res: Response) => {
  const data = await salesStats(Number(req.query.days), req.query.from as string | undefined, req.query.to as string | undefined);
  res.status(200).json({ success: true, data });
});

export const getAdminStatsTopCourses = asyncHandler(async (req: Request, res: Response) => {
  const data = await topCoursesStats(Number(req.query.limit), req.query.from as string | undefined, req.query.to as string | undefined);
  res.status(200).json({ success: true, data });
});

export const getAdminStatsBySpecialization = asyncHandler(async (req: Request, res: Response) => {
  const data = await bySpecializationStats(req.query.from as string | undefined, req.query.to as string | undefined);
  res.status(200).json({ success: true, data });
});

export const getAdminStatsTeachers = asyncHandler(async (req: Request, res: Response) => {
  const data = await teachersStats(req.query.from as string | undefined, req.query.to as string | undefined);
  res.status(200).json({ success: true, data });
});
