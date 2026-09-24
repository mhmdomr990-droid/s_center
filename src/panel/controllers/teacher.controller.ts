import type { Request, Response } from 'express';

import { AppError } from '../../utils/AppError';
import type { StoredVideoFile } from '../../services/media';
import { archiveTeacherLecture, createLectureForTeacher, getTeacherStats, listCourseLectures, listMyCourses, listTeacherPayouts, updateTeacherLecture } from '../../modules/teacher/service';
import { setFlash } from '../middlewares/flash';

async function loadTeacherCommon(teacherId: number) {
  const stats = await getTeacherStats(teacherId);
  return {
    pendingTopupsCount: 0,
    stats,
  };
}

export async function coursesPage(req: Request, res: Response) {
  const courses = await listMyCourses(req.user!.id);
  const common = await loadTeacherCommon(req.user!.id);
  return res.render('teacher/courses', {
    title: 'كورساتي',
    currentUser: req.user,
    flash: res.locals.flash,
    csrfToken: res.locals.csrfToken,
    courses,
    ...common,
  });
}

export async function lecturesPage(req: Request, res: Response) {
  const courses = await listMyCourses(req.user!.id);
  const selectedCourseId = req.query.courseId ? Number(req.query.courseId) : undefined;
  const lectures = selectedCourseId ? await listCourseLectures(req.user!.id, selectedCourseId) : [];
  return res.render('teacher/lectures', {
    title: 'محاضراتي',
    currentUser: req.user,
    flash: res.locals.flash,
    csrfToken: res.locals.csrfToken,
    courses,
    selectedCourseId,
    lectures,
  });
}

export async function createLectureAction(req: Request, res: Response) {
  await createLectureForTeacher(req.user!.id, Number(req.params.id), req.body, req.file as StoredVideoFile | undefined);
  setFlash(res, 'success', 'تم حفظ المحاضرة');
  return res.redirect(`/panel/teacher/lectures?courseId=${req.params.id}`);
}

export async function updateLectureAction(req: Request, res: Response) {
  await updateTeacherLecture(req.user!.id, Number(req.params.id), req.body, req.file as StoredVideoFile | undefined);
  setFlash(res, 'success', 'تم تحديث المحاضرة');
  const courseId = Number(req.body.course_id);
  if (Number.isFinite(courseId) && courseId > 0) {
    return res.redirect(`/panel/teacher/lectures?courseId=${courseId}`);
  }
  return res.redirect('/panel/teacher/lectures');
}

export async function hideLectureAction(req: Request, res: Response) {
  await archiveTeacherLecture(req.user!.id, Number(req.params.id));
  setFlash(res, 'success', 'تم إخفاء المحاضرة');
  const courseId = Number(req.query.courseId ?? req.body.course_id);
  if (Number.isFinite(courseId) && courseId > 0) {
    return res.redirect(`/panel/teacher/lectures?courseId=${courseId}`);
  }
  return res.redirect('/panel/teacher/lectures');
}

export async function earningsPage(req: Request, res: Response) {
  const stats = await getTeacherStats(req.user!.id);
  const payouts = await listTeacherPayouts(req.user!.id);
  return res.render('teacher/earnings', {
    title: 'الأرباح',
    currentUser: req.user,
    flash: res.locals.flash,
    csrfToken: res.locals.csrfToken,
    stats,
    payouts,
  });
}

export async function rootTeacherRedirect(req: Request, res: Response) {
  if (!req.user || req.user.role !== 'TEACHER') {
    throw new AppError(403, 'Access denied');
  }
  return res.redirect('/panel/teacher/courses');
}
