import type { Request, Response } from 'express';

import { asyncHandler } from '../../utils/asyncHandler';
import {
  getTeacherCourseById,
  getTeacherDashboard,
  getTeacherMonthlyEarnings,
  archiveTeacherLecture,
  createLectureForTeacher,
  getTeacherStats,
  listCourseLectures,
  listMyCourses,
  listTeacherPayouts,
  previewTeacherCourseLectures,
  reorderTeacherCourseLectures,
  setTeacherLecturePublished,
  updateTeacherCourseDescription,
  updateTeacherLecture,
} from './service';
import { paginateItems } from '../../utils/pagination';

export const getTeacherCourses = asyncHandler(async (req: Request, res: Response) => {
  const data = await listMyCourses(req.user!.id);
  const paged = paginateItems(data, { page: Number(req.query.page ?? 1), limit: Number(req.query.limit ?? 20) });
  res.status(200).json({ success: true, data: paged.data, meta: paged.meta });
});

export const getTeacherCourseByIdController = asyncHandler(async (req: Request, res: Response) => {
  const data = await getTeacherCourseById(req.user!.id, Number(req.params.id));
  res.status(200).json({ success: true, data });
});

export const patchTeacherCourse = asyncHandler(async (req: Request, res: Response) => {
  const data = await updateTeacherCourseDescription(req.user!.id, Number(req.params.id), req.body);
  res.status(200).json({ success: true, data });
});

export const getTeacherCourseLectures = asyncHandler(async (req: Request, res: Response) => {
  const data = await listCourseLectures(req.user!.id, Number(req.params.id));
  res.status(200).json({ success: true, data });
});

export const getTeacherCoursePreview = asyncHandler(async (req: Request, res: Response) => {
  const data = await previewTeacherCourseLectures(req.user!.id, Number(req.params.id));
  res.status(200).json({ success: true, data });
});

export const postTeacherLecture = asyncHandler(async (req: Request, res: Response) => {
  const data = await createLectureForTeacher(req.user!.id, Number(req.params.id), req.body, req.file ?? null);
  res.status(201).json({ success: true, data });
});

export const patchTeacherLecture = asyncHandler(async (req: Request, res: Response) => {
  const data = await updateTeacherLecture(req.user!.id, Number(req.params.id), req.body, req.file ?? null);
  res.status(200).json({ success: true, data });
});

export const patchTeacherLecturePublished = asyncHandler(async (req: Request, res: Response) => {
  const data = await setTeacherLecturePublished(req.user!.id, Number(req.params.id), req.body.is_published);
  res.status(200).json({ success: true, data });
});

export const putTeacherLectureOrder = asyncHandler(async (req: Request, res: Response) => {
  const data = await reorderTeacherCourseLectures(req.user!.id, Number(req.params.id), req.body.lecture_ids);
  res.status(200).json({ success: true, data });
});

export const deleteTeacherLecture = asyncHandler(async (req: Request, res: Response) => {
  const data = await archiveTeacherLecture(req.user!.id, Number(req.params.id));
  res.status(200).json({ success: true, data });
});

export const getTeacherStatsController = asyncHandler(async (req: Request, res: Response) => {
  const data = await getTeacherStats(req.user!.id);
  res.status(200).json({ success: true, data });
});

export const getTeacherDashboardController = asyncHandler(async (req: Request, res: Response) => {
  const data = await getTeacherDashboard(req.user!.id, Number(req.query.days ?? 30));
  res.status(200).json({ success: true, data });
});

export const getTeacherPayouts = asyncHandler(async (req: Request, res: Response) => {
  const data = await listTeacherPayouts(req.user!.id);
  const paged = paginateItems(data, { page: Number(req.query.page ?? 1), limit: Number(req.query.limit ?? 20) });
  res.status(200).json({ success: true, data: paged.data, meta: paged.meta });
});

export const getTeacherEarnings = asyncHandler(async (req: Request, res: Response) => {
  const data = await getTeacherMonthlyEarnings(req.user!.id, req.query.month as string | undefined);
  res.status(200).json({ success: true, data });
});
