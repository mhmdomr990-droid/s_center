import type { Request, Response } from 'express';

import { AppDataSource } from '../../config/data-source';
import { Lecture } from '../../entities/Lecture';
import { User } from '../../entities/User';
import { AppError } from '../../utils/AppError';
import { createSignedMediaToken, type StoredVideoFile } from '../../services/media';
import {
  approveTopupRequest,
  archiveCourse,
  archiveLecture,
  archiveSpecialization,
  deleteLecturePermanently,
  bySpecializationStats,
  createCourse,
  createLecture,
  createNotifications,
  createSpecialization,
  createTeacher,
  createStudent,
  createAdmin,
  adjustBalance,
  listCourses,
  listLectures,
  listSpecializations,
  listTeacherPayouts,
  listTeachers,
  listTopupRequests,
  listUsers,
  listFreeGrantsByAdmin,
  listPurchaseHistory,
  overviewStats,
  payoutTeacher,
  rejectTopupRequest,
  resetPassword,
  resetUserDevice,
  salesStats,
  teachersStats,
  topCoursesStats,
  updateCourse,
  updateLecture,
  updateSpecialization,
  setUserActive,
  grantCourseToUser,
  revokeCourseGrant,
} from '../../modules/admin/service';
import {
  approveCourseSwapRequest,
  listPendingCourseSwapRequests,
  rejectCourseSwapRequest,
} from '../../modules/purchase/service';
import { TopupStatus, UserRole } from '../../entities/enums';
import { setFlash } from '../middlewares/flash';

function paginate<T>(items: T[], page = 1, perPage = 20) {
  const total = items.length;
  const pageCount = Math.max(1, Math.ceil(total / perPage));
  const currentPage = Math.min(Math.max(page, 1), pageCount);
  const start = (currentPage - 1) * perPage;
  return {
    items: items.slice(start, start + perPage),
    total,
    page: currentPage,
    pageCount,
    perPage,
  };
}

async function loadAdminCommon() {
  const stats = await overviewStats();
  const pendingCourseSwapRequests = await listPendingCourseSwapRequests();
  return { pendingTopupsCount: stats.pending_topups_count, pendingCourseSwapCount: pendingCourseSwapRequests.length };
}

export async function overviewPage(req: Request, res: Response) {
  const days = [7, 30, 90].includes(Number(req.query.days)) ? Number(req.query.days) : 30;
  const stats = await overviewStats();
  const sales = await salesStats(days);
  const topCourses = await topCoursesStats(10);
  const bySpec = await bySpecializationStats();
  const common = await loadAdminCommon();

  return res.render('admin/overview', {
    title: 'نظرة عامة',
    currentUser: req.user,
    flash: res.locals.flash,
    csrfToken: res.locals.csrfToken,
    days,
    statCards: [
      { label: 'الطلاب', value: stats.students_count },
      { label: 'المدرسون', value: stats.teachers_count },
      { label: 'الكورسات', value: stats.courses_count },
      { label: 'المشتريات', value: stats.purchases_count },
      { label: 'إجمالي المبيعات', value: stats.total_sales_amount },
      { label: 'إجمالي الشحن', value: stats.total_topups_amount },
      { label: 'طلبات قيد الانتظار', value: stats.pending_topups_count },
      { label: 'رصيد الطلاب', value: stats.total_students_balance },
    ],
    salesChart: {
      data: {
        labels: sales.map((row) => row.date),
        datasets: [{ label: 'المبيعات', data: sales.map((row) => Number(row.amount)), borderColor: '#184e77', backgroundColor: 'rgba(24, 78, 119, 0.2)', fill: true }],
      },
      options: { responsive: true, maintainAspectRatio: false },
    },
    topCoursesChart: {
      data: {
        labels: topCourses.map((row) => row.name),
        datasets: [{ label: 'عدد المشتريات', data: topCourses.map((row) => row.purchases_count), backgroundColor: '#184e77' }],
      },
      options: { responsive: true, maintainAspectRatio: false },
    },
    specializationSales: bySpec,
    ...common,
  });
}

export async function specializationsPage(req: Request, res: Response) {
  const specializations = await listSpecializations();
  const common = await loadAdminCommon();
  return res.render('admin/specializations', {
    title: 'التخصصات',
    currentUser: req.user,
    flash: res.locals.flash,
    csrfToken: res.locals.csrfToken,
    specializations,
    ...common,
  });
}

export async function createSpecializationAction(req: Request, res: Response) {
  await createSpecialization(req.body);
  setFlash(res, 'success', 'تم حفظ التخصص بنجاح');
  return res.redirect('/panel/admin/specializations');
}

export async function updateSpecializationAction(req: Request, res: Response) {
  await updateSpecialization(Number(req.params.id), req.body);
  setFlash(res, 'success', 'تم تحديث التخصص بنجاح');
  return res.redirect('/panel/admin/specializations');
}

export async function toggleSpecializationAction(req: Request, res: Response) {
  const nextValue = req.body.next_is_published === 'true';
  await updateSpecialization(Number(req.params.id), { is_published: nextValue });
  setFlash(res, 'success', nextValue ? 'تم نشر التخصص' : 'تم إخفاء التخصص');
  return res.redirect('/panel/admin/specializations');
}

export async function deleteSpecializationAction(req: Request, res: Response) {
  await archiveSpecialization(Number(req.params.id));
  setFlash(res, 'success', 'تم حذف التخصص (أصبح مخفيًا)');
  return res.redirect('/panel/admin/specializations');
}

export async function coursesPage(req: Request, res: Response) {
  const [coursesAll, specializations, teachers, common] = await Promise.all([
    listCourses(),
    listSpecializations(),
    listTeachers(),
    loadAdminCommon(),
  ]);

  const specializationId = req.query.specializationId ? Number(req.query.specializationId) : undefined;
  const year = req.query.year ? Number(req.query.year) : undefined;
  const filtered = coursesAll.filter((course) => {
    if (specializationId && course.specialization_id !== specializationId) return false;
    if (year && course.year !== year) return false;
    return true;
  });

  const paged = paginate(filtered, Number(req.query.page) || 1, 20);
  return res.render('admin/courses', {
    title: 'الكورسات',
    currentUser: req.user,
    flash: res.locals.flash,
    csrfToken: res.locals.csrfToken,
    courses: paged.items,
    specializations,
    teachers,
    filters: { specializationId, year },
    page: paged.page,
    pageCount: paged.pageCount,
    baseUrl: '/panel/admin/courses',
    queryString: [specializationId ? `specializationId=${specializationId}` : '', year ? `year=${year}` : ''].filter(Boolean).join('&'),
    ...common,
  });
}

export async function createCourseAction(req: Request, res: Response) {
  await createCourse(req.body);
  setFlash(res, 'success', 'تم حفظ الكورس بنجاح');
  return res.redirect('/panel/admin/courses');
}

export async function updateCourseAction(req: Request, res: Response) {
  await updateCourse(Number(req.params.id), req.body, req.user!.id);
  setFlash(res, 'success', 'تم تحديث الكورس بنجاح');
  return res.redirect('/panel/admin/courses');
}

export async function toggleCourseAction(req: Request, res: Response) {
  const nextValue = req.body.next_is_published === 'true';
  await updateCourse(Number(req.params.id), { is_published: nextValue });
  setFlash(res, 'success', nextValue ? 'تم نشر الكورس' : 'تم إخفاء الكورس');
  return res.redirect('/panel/admin/courses');
}

export async function deleteCourseAction(req: Request, res: Response) {
  await archiveCourse(Number(req.params.id));
  setFlash(res, 'success', 'تم حذف الكورس (أصبح مخفيًا)');
  return res.redirect('/panel/admin/courses');
}

export async function lecturesPage(req: Request, res: Response) {
  const [courses, lecturesAll, common] = await Promise.all([listCourses(), listLectures(), loadAdminCommon()]);
  const selectedCourseId = req.query.courseId ? Number(req.query.courseId) : undefined;
  const lectures = selectedCourseId ? lecturesAll.filter((item) => item.course_id === selectedCourseId) : [];
  return res.render('admin/lectures', {
    title: 'المحاضرات',
    currentUser: req.user,
    flash: res.locals.flash,
    csrfToken: res.locals.csrfToken,
    courses,
    lectures,
    selectedCourseId,
    ...common,
  });
}

export async function createLectureAction(req: Request, res: Response) {
  await createLecture(req.user!.id, req.body, req.file as StoredVideoFile | undefined);
  setFlash(res, 'success', 'تم حفظ المحاضرة بنجاح');
  return res.redirect('/panel/admin/lectures');
}

export async function updateLectureAction(req: Request, res: Response) {
  await updateLecture(Number(req.params.id), req.body, req.file as StoredVideoFile | undefined);
  setFlash(res, 'success', 'تم تحديث المحاضرة بنجاح');
  return res.redirect('/panel/admin/lectures');
}

export async function hideLectureAction(req: Request, res: Response) {
  await archiveLecture(Number(req.params.id));
  setFlash(res, 'success', 'تم إخفاء المحاضرة');
  return res.redirect('/panel/admin/lectures');
}

export async function deleteLectureAction(req: Request, res: Response) {
  await deleteLecturePermanently(Number(req.params.id));
  setFlash(res, 'success', 'تم حذف المحاضرة نهائيًا');
  return res.redirect('/panel/admin/lectures');
}

export async function watchLecturePage(req: Request, res: Response) {
  const lectureId = Number(req.params.id);
  const lecture = await AppDataSource.getRepository(Lecture).findOne({
    where: { id: lectureId },
    relations: { course: { specialization: true, teacher: true } },
  });

  if (!lecture) {
    throw new AppError(404, 'Lecture not found');
  }

  const token = createSignedMediaToken({
    lectureId: lecture.id,
    userId: req.user!.id,
    purpose: 'stream',
    role: req.user!.role,
    expiresInMinutes: 10,
  });

  const common = await loadAdminCommon();

  return res.render('admin/lecture-watch', {
    title: 'مشاهدة المحاضرة',
    currentUser: req.user,
    flash: res.locals.flash,
    csrfToken: res.locals.csrfToken,
    lecture: {
      ...lecture,
      course_id: lecture.course.id,
      course_name: lecture.course.name,
      type: lecture.type,
      is_published: lecture.isPublished,
      sort_order: lecture.sortOrder,
    },
    streamUrl: `/media/play/${token}`,
    ...common,
  });
}

export async function topupsPage(req: Request, res: Response) {
  const status = (req.query.status as TopupStatus) || TopupStatus.PENDING;
  const requests = await listTopupRequests(status);
  const common = await loadAdminCommon();
  return res.render('admin/topups', {
    title: 'طلبات الشحن',
    currentUser: req.user,
    flash: res.locals.flash,
    csrfToken: res.locals.csrfToken,
    requests,
    status,
    ...common,
  });
}

export async function approveTopupAction(req: Request, res: Response) {
  await approveTopupRequest(Number(req.params.id), req.user!.id);
  setFlash(res, 'success', 'تمت الموافقة على الطلب');
  return res.redirect('/panel/admin/topups?status=PENDING');
}

export async function rejectTopupAction(req: Request, res: Response) {
  await rejectTopupRequest(Number(req.params.id), req.user!.id, req.body.reason);
  setFlash(res, 'success', 'تم رفض الطلب');
  return res.redirect('/panel/admin/topups?status=PENDING');
}

export async function courseSwapRequestsPage(req: Request, res: Response) {
  const requests = await listPendingCourseSwapRequests();
  const common = await loadAdminCommon();

  return res.render('admin/course-swaps', {
    title: 'طلبات تبديل المواد',
    currentUser: req.user,
    flash: res.locals.flash,
    csrfToken: res.locals.csrfToken,
    requests,
    ...common,
  });
}

export async function approveCourseSwapRequestAction(req: Request, res: Response) {
  await approveCourseSwapRequest(req.user!.id, Number(req.params.id), req.body.admin_note ?? null);
  setFlash(res, 'success', 'تمت الموافقة على طلب تبديل المادة');
  return res.redirect('/panel/admin/course-swap-requests');
}

export async function rejectCourseSwapRequestAction(req: Request, res: Response) {
  await rejectCourseSwapRequest(req.user!.id, Number(req.params.id), req.body.reason ?? null);
  setFlash(res, 'success', 'تم رفض طلب تبديل المادة');
  return res.redirect('/panel/admin/course-swap-requests');
}

export async function purchasesPage(req: Request, res: Response) {
  const search = typeof req.query.search === 'string' ? req.query.search : '';
  const courseName = typeof req.query.courseName === 'string' ? req.query.courseName : '';
  const studentName = typeof req.query.studentName === 'string' ? req.query.studentName : '';

  const purchases = await listPurchaseHistory({ search, courseName, studentName });
  const common = await loadAdminCommon();

  return res.render('admin/purchases', {
    title: 'عمليات الشراء',
    currentUser: req.user,
    flash: res.locals.flash,
    csrfToken: res.locals.csrfToken,
    purchases,
    search,
    courseName,
    studentName,
    ...common,
  });
}

export async function usersPage(req: Request, res: Response) {
  const search = typeof req.query.search === 'string' ? req.query.search : '';
  const [users, courses, specializations, freeGrants] = await Promise.all([
    listUsers(search || undefined),
    listCourses(),
    listSpecializations(),
    listFreeGrantsByAdmin(req.user!.id),
  ]);
  const paged = paginate(users, Number(req.query.page) || 1, 20);
  const common = await loadAdminCommon();
  return res.render('admin/users', {
    title: 'المستخدمون',
    currentUser: req.user,
    flash: res.locals.flash,
    csrfToken: res.locals.csrfToken,
    users: paged.items,
    courses,
    specializations,
    freeGrants,
    search,
    page: paged.page,
    pageCount: paged.pageCount,
    baseUrl: '/panel/admin/users',
    queryString: search ? `search=${encodeURIComponent(search)}` : '',
    ...common,
  });
}

export async function grantUserCourseAction(req: Request, res: Response) {
  const userId = Number(req.params.id);
  const courseId = Number(req.body.course_id);
  await grantCourseToUser({ adminId: req.user!.id, userId, courseId });
  setFlash(res, 'success', 'تم منح الطالب صلاحية الوصول المجاني لهذا الكورس');
  return res.redirect('/panel/admin/users');
}

export async function revokeUserCourseGrantAction(req: Request, res: Response) {
  const userId = Number(req.params.id);
  const courseId = Number(req.body.course_id);
  await revokeCourseGrant({ adminId: req.user!.id, userId, courseId });
  setFlash(res, 'success', 'تم إلغاء المنحة المجانية لهذا الكورس');
  return res.redirect('/panel/admin/users');
}

export async function toggleUserActiveAction(req: Request, res: Response) {
  const targetUserId = Number(req.params.id);
  const targetUser = await AppDataSource.getRepository(User).findOne({ where: { id: targetUserId } });

  if (!targetUser) {
    setFlash(res, 'error', 'المستخدم غير موجود');
    return res.redirect('/panel/admin/users');
  }

  if (targetUser.id === req.user!.id) {
    setFlash(res, 'error', 'لا يمكنك إيقاف حسابك الشخصي');
    return res.redirect('/panel/admin/users');
  }

  if (targetUser.role === UserRole.ADMIN) {
    setFlash(res, 'error', 'لا يمكن إيقاف حساب مدير');
    return res.redirect('/panel/admin/users');
  }

  const nextIsActive = req.body.is_active === true || req.body.is_active === 'true' || req.body.is_active === 1 || req.body.is_active === '1';
  await setUserActive(targetUserId, nextIsActive);
  setFlash(res, 'success', 'تم تحديث حالة المستخدم');
  return res.redirect('/panel/admin/users');
}

export async function resetUserDeviceAction(req: Request, res: Response) {
  await resetUserDevice(Number(req.params.id));
  setFlash(res, 'success', 'تمت إعادة ضبط الجهاز');
  return res.redirect('/panel/admin/users');
}

export async function resetUserPasswordAction(req: Request, res: Response) {
  await resetPassword(Number(req.params.id), req.body.new_password);
  setFlash(res, 'success', 'تمت إعادة تعيين كلمة المرور');
  return res.redirect('/panel/admin/users');
}

export async function adjustUserBalanceAction(req: Request, res: Response) {
  await adjustBalance(Number(req.params.id), req.body.amount, req.body.description);
  setFlash(res, 'success', 'تم تعديل الرصيد');
  return res.redirect('/panel/admin/users');
}

export async function teachersPage(req: Request, res: Response) {
  const teachers = await listTeachers();
  const common = await loadAdminCommon();
  return res.render('admin/teachers', {
    title: 'المدرسون',
    currentUser: req.user,
    flash: res.locals.flash,
    csrfToken: res.locals.csrfToken,
    teachers,
    ...common,
  });
}

export async function createTeacherAction(req: Request, res: Response) {
  await createTeacher(req.body);
  setFlash(res, 'success', 'تم إنشاء المدرس');
  return res.redirect('/panel/admin/teachers');
}

export async function createStudentAction(req: Request, res: Response) {
  await createStudent(req.body);
  setFlash(res, 'success', 'تم إنشاء الطالب');
  return res.redirect('/panel/admin/users');
}

export async function createAdminAction(req: Request, res: Response) {
  await createAdmin(req.body);
  setFlash(res, 'success', 'تم إنشاء المدير الجديد');
  return res.redirect('/panel/admin/users');
}

export async function teacherPayoutAction(req: Request, res: Response) {
  await payoutTeacher(Number(req.params.id), req.user!.id, req.body.amount, req.body.note || null);
  setFlash(res, 'success', 'تم تسجيل الدفعة');
  return res.redirect(`/panel/admin/teachers/${req.params.id}/payouts`);
}

export async function teacherPayoutsPage(req: Request, res: Response) {
  const teacherId = Number(req.params.id);
  const teachers = await listTeachers();
  const teacher = teachers.find((item) => item.teacher_id === teacherId);
  if (!teacher) {
    throw new AppError(404, 'Teacher not found');
  }

  const payouts = await listTeacherPayouts(teacherId);
  const summary = await teachersStats();
  const selected = summary.find((item) => item.teacher_id === teacherId) || {
    teacher_id: teacherId,
    earned: '0.00',
    paid: '0.00',
    remaining: '0.00',
    purchases_count: 0,
  };

  return res.render('admin/teacher-payouts', {
    title: 'سجل الدفعات',
    currentUser: req.user,
    flash: res.locals.flash,
    csrfToken: res.locals.csrfToken,
    teacher,
    payouts,
    summary: selected,
    pendingTopupsCount: (await overviewStats()).pending_topups_count,
  });
}

export async function notificationsPage(req: Request, res: Response) {
  const common = await loadAdminCommon();
  return res.render('admin/notifications', {
    title: 'الإشعارات',
    currentUser: req.user,
    flash: res.locals.flash,
    csrfToken: res.locals.csrfToken,
    ...common,
  });
}

export async function sendNotificationAction(req: Request, res: Response) {
  const username = typeof req.body.username === 'string' ? req.body.username.trim() : '';
  const sendAll = ['true', '1', 'on', 'yes'].includes(String(req.body.all ?? '').toLowerCase());
  let payload: { all?: boolean; user_id?: number; title: string; body: string };

  if (sendAll) {
    payload = { all: true, title: req.body.title, body: req.body.body };
  } else if (username) {
    const user = await AppDataSource.getRepository(User).findOne({ where: { username } });
    if (!user) {
      throw new AppError(404, 'User not found');
    }
    payload = { user_id: user.id, title: req.body.title, body: req.body.body };
  } else {
    throw new AppError(400, 'يجب تحديد المستخدم أو اختيار الإرسال للجميع');
  }

  const result = await createNotifications(payload);
  setFlash(res, 'success', `تم إرسال الإشعار إلى ${result.count} مستخدم`);
  return res.redirect('/panel/admin/notifications');
}

export async function statsRedirect(_req: Request, res: Response) {
  return res.redirect('/panel/admin/overview');
}
