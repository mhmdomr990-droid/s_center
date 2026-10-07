import { QueryFailedError } from 'typeorm';

import { AppDataSource } from '../../config/data-source';
import { Course } from '../../entities/Course';
import { CourseSwapRequest } from '../../entities/CourseSwapRequest';
import { Purchase } from '../../entities/Purchase';
import { Transaction } from '../../entities/Transaction';
import { CourseSwapStatus, PurchaseSource, TransactionType, UserRole } from '../../entities/enums';
import { User } from '../../entities/User';
import { AppError } from '../../utils/AppError';
import { calculateMoneyShare, centsToMoney, toCents } from '../../utils/money';
import { logAuditEvent } from '../../services/auditLog';
import { notify } from '../notifications/service';

export const COURSE_SWAP_WINDOW_HOURS = 72;

export function resolveSwapReplacementPurchaseFields(input: {
  oldSource: PurchaseSource | string | null;
  replacementPrice: string | number;
  replacementTeacherShare?: string | number;
}) {
  const source = input.oldSource === PurchaseSource.GRANTED ? PurchaseSource.GRANTED : PurchaseSource.PURCHASED;

  if (source === PurchaseSource.GRANTED) {
    return {
      source,
      pricePaid: '0.00',
      teacherShare: '0.00',
    };
  }

  return {
    source,
    pricePaid: String(input.replacementPrice ?? '0.00'),
    teacherShare: String(input.replacementTeacherShare ?? '0.00'),
  };
}

export function evaluateCourseSwapRequest(input: {
  purchaseCreatedAt: Date | string;
  currentCourseId: number;
  replacementCourseId: number;
  allowedWindowHours?: number;
}) {
  if (!input.currentCourseId || !input.replacementCourseId || input.currentCourseId === input.replacementCourseId) {
    return { allowed: false, reason: 'لا يمكن تبديل المادة بنفس المادة الحالية.', hours_remaining: 0 };
  }

  const purchaseCreatedAt = new Date(input.purchaseCreatedAt);
  const allowedWindowHours = input.allowedWindowHours ?? COURSE_SWAP_WINDOW_HOURS;
  const allowedWindowMs = allowedWindowHours * 60 * 60 * 1000;
  const elapsedMs = Date.now() - purchaseCreatedAt.getTime();

  if (Number.isNaN(purchaseCreatedAt.getTime())) {
    return { allowed: false, reason: 'تاريخ شراء المادة غير صالح.', hours_remaining: 0 };
  }

  if (elapsedMs > allowedWindowMs) {
    return {
      allowed: false,
      reason: `انتهت نافذة تبديل المادة. يسمح فقط خلال ${allowedWindowHours} ساعة من الشراء.`,
      hours_remaining: 0,
    };
  }

  return {
    allowed: true,
    reason: null,
    hours_remaining: Math.max(0, Math.ceil((allowedWindowMs - elapsedMs) / (60 * 60 * 1000))),
  };
}

function toPurchasedCourseResponse(purchase: Purchase) {
  return {
    purchase_id: purchase.id,
    id: purchase.course.id,
    specialization_id: purchase.course.specialization.id,
    teacher_full_name: purchase.course.teacher ? purchase.course.teacher.fullName : null,
    year: purchase.course.year,
    name: purchase.course.name,
    description: purchase.course.description,
    price: purchase.course.price,
    price_paid: purchase.pricePaid,
    teacher_share: purchase.teacherShare,
    source: purchase.source,
    is_granted: purchase.source === 'GRANTED',
    purchased_at: purchase.createdAt,
  };
}

function toPaymentResponse(transaction: Transaction) {
  return {
    id: transaction.id,
    amount: transaction.amount,
    balance_after: transaction.balanceAfter,
    description: transaction.description,
    reference_type: transaction.referenceType,
    reference_id: transaction.referenceId,
    created_at: transaction.createdAt,
  };
}

export async function purchaseCourse(userId: number, courseId: number) {
  try {
    const result = await AppDataSource.transaction(async (manager) => {
      const courseRepository = manager.getRepository(Course);
      const userRepository = manager.getRepository(User);
      const purchaseRepository = manager.getRepository(Purchase);
      const transactionRepository = manager.getRepository(Transaction);

      const course = await courseRepository.findOne({
        where: { id: courseId, isPublished: true, specialization: { isPublished: true } },
        relations: { specialization: true, teacher: true },
      });

      if (!course) {
        throw new AppError(404, 'Course not found');
      }

      const user = await userRepository.findOne({
        where: { id: userId },
        lock: { mode: 'pessimistic_write' },
      });

      if (!user) {
        throw new AppError(404, 'User not found');
      }

      const existingPurchase = await purchaseRepository.findOne({
        where: { user: { id: user.id }, course: { id: course.id } },
      });

      if (existingPurchase) {
        throw new AppError(409, 'You already purchased this course');
      }

      if (toCents(user.balance) < toCents(course.price)) {
        throw new AppError(400, 'Insufficient balance');
      }

      const purchase = purchaseRepository.create({
        user: { id: user.id } as User,
        course: { id: course.id } as Course,
        pricePaid: course.price,
        teacher: course.teacher ? ({ id: course.teacher.id } as User) : null,
        teacherShare: course.teacher ? calculateMoneyShare(course.price, course.teacherPercent) : '0.00',
      });
      const savedPurchase = await purchaseRepository.save(purchase);

      const balanceAfter = centsToMoney(toCents(user.balance) - toCents(course.price));
      user.balance = balanceAfter;
      await userRepository.save(user);

      const transaction = transactionRepository.create({
        user: { id: user.id } as User,
        type: TransactionType.PURCHASE,
        amount: course.price,
        balanceAfter,
        description: `Purchased course: ${course.name}`,
        referenceType: 'PURCHASE',
        referenceId: savedPurchase.id,
      });
      await transactionRepository.save(transaction);

      await notify(user.id, 'Purchase successful', `You purchased ${course.name}`, manager);

      return {
        message: 'Course purchased successfully',
        purchase: {
          id: savedPurchase.id,
          course_id: course.id,
          price_paid: savedPurchase.pricePaid,
        },
        balance: balanceAfter,
      };
    });

    return result;
  } catch (error) {
    if (error instanceof QueryFailedError) {
      const driverError = error.driverError as { errno?: number; code?: string } | undefined;
      if (driverError?.errno === 1062 || driverError?.code === 'ER_DUP_ENTRY') {
        throw new AppError(409, 'You already purchased this course');
      }
    }
    throw error;
  }
}

export async function listMyCourses(userId: number) {
  const purchases = await AppDataSource.getRepository(Purchase).find({
    where: { user: { id: userId } },
    relations: { course: { specialization: true, teacher: true } },
    order: { createdAt: 'DESC', id: 'DESC' },
  });

  return purchases.map(toPurchasedCourseResponse);
}

export async function listMyPayments(userId: number) {
  const transactions = await AppDataSource.getRepository(Transaction).find({
    where: { user: { id: userId }, type: TransactionType.PURCHASE },
    order: { createdAt: 'DESC', id: 'DESC' },
  });

  return transactions.map(toPaymentResponse);
}

export async function requestCourseSwap(userId: number, oldPurchaseId: number, newCourseId: number, reason: string | null) {
  const requestRepository = AppDataSource.getRepository(CourseSwapRequest);
  const purchaseRepository = AppDataSource.getRepository(Purchase);
  const courseRepository = AppDataSource.getRepository(Course);

  const oldPurchase = await purchaseRepository.findOne({
    where: { id: oldPurchaseId, user: { id: userId } },
    relations: { user: true, course: { teacher: true }, teacher: true },
  });

  if (!oldPurchase) {
    throw new AppError(404, 'Purchase not found for this student');
  }

  const replacement = await courseRepository.findOne({
    where: { id: newCourseId, isPublished: true, specialization: { isPublished: true } },
    relations: { teacher: true, specialization: true },
  });

  if (!replacement) {
    throw new AppError(404, 'Replacement course not found');
  }

  const eligibility = evaluateCourseSwapRequest({
    purchaseCreatedAt: oldPurchase.createdAt,
    currentCourseId: oldPurchase.course.id,
    replacementCourseId: replacement.id,
  });

  if (!eligibility.allowed) {
    throw new AppError(400, eligibility.reason || 'لا يمكن طلب تبديل المادة في هذه المرحلة');
  }

  if (oldPurchase.course.id === replacement.id) {
    throw new AppError(400, 'لا يمكن تبديل المادة بنفس المادة الحالية');
  }

  const existingRequest = await requestRepository.findOne({
    where: {
      student: { id: userId },
      oldPurchase: { id: oldPurchaseId },
      status: CourseSwapStatus.PENDING,
    },
  });

  if (existingRequest) {
    throw new AppError(409, 'يوجد طلب تبديل قيد الانتظار لهذه المادة');
  }

  const newTeacherShare = replacement.teacher ? calculateMoneyShare(replacement.price, replacement.teacherPercent) : '0.00';
  const request = requestRepository.create({
    student: { id: userId } as User,
    oldPurchase: { id: oldPurchaseId } as Purchase,
    oldCourse: { id: oldPurchase.course.id } as Course,
    newCourse: { id: replacement.id } as Course,
    oldTeacher: oldPurchase.teacher ? ({ id: oldPurchase.teacher.id } as User) : null,
    newTeacher: replacement.teacher ? ({ id: replacement.teacher.id } as User) : null,
    oldTeacherShare: oldPurchase.teacherShare,
    newTeacherShare,
    status: CourseSwapStatus.PENDING,
    reason: reason && reason.trim() ? reason.trim() : null,
  });

  const saved = await requestRepository.save(request);

  const adminUsers = await AppDataSource.getRepository(User).find({ where: { role: UserRole.ADMIN } });
  await Promise.all(adminUsers.map((admin) => notify(admin.id, 'طلب تبديل مادة جديد', `طلب طالب بتبديل المادة ${oldPurchase.course.name} إلى ${replacement.name}.`)));
  await logAuditEvent({
    action: 'COURSE_SWAP_REQUESTED',
    actorId: userId,
    entityType: 'CourseSwapRequest',
    entityId: saved.id,
    metadata: {
      studentId: userId,
      oldPurchaseId,
      oldCourseId: oldPurchase.course.id,
      newCourseId: replacement.id,
      oldTeacherId: oldPurchase.teacher?.id ?? null,
      newTeacherId: replacement.teacher?.id ?? null,
      oldTeacherShare: oldPurchase.teacherShare,
      newTeacherShare,
    },
  });

  return {
    id: saved.id,
    status: saved.status,
    old_course_id: oldPurchase.course.id,
    new_course_id: replacement.id,
    old_teacher_share: saved.oldTeacherShare,
    new_teacher_share: saved.newTeacherShare,
    reason: saved.reason,
    requested_at: saved.createdAt,
    window_hours_remaining: eligibility.hours_remaining,
  };
}

export async function listCourseSwapRequestsForStudent(userId: number) {
  const requests = await AppDataSource.getRepository(CourseSwapRequest).find({
    where: { student: { id: userId } },
    relations: { oldCourse: true, newCourse: { teacher: true }, oldTeacher: true, newTeacher: true },
    order: { createdAt: 'DESC', id: 'DESC' },
  });

  return requests.map((request) => ({
    id: request.id,
    status: request.status,
    old_course_id: request.oldCourse.id,
    old_course_name: request.oldCourse.name,
    new_course_id: request.newCourse.id,
    new_course_name: request.newCourse.name,
    old_teacher_share: request.oldTeacherShare,
    new_teacher_share: request.newTeacherShare,
    reason: request.reason,
    admin_note: request.adminNote,
    requested_at: request.createdAt,
    approved_at: request.approvedAt,
    rejected_at: request.rejectedAt,
  }));
}

export async function listPendingCourseSwapRequests() {
  const requests = await AppDataSource.getRepository(CourseSwapRequest).find({
    where: { status: CourseSwapStatus.PENDING },
    relations: {
      student: true,
      oldCourse: true,
      newCourse: { teacher: true },
      oldTeacher: true,
      newTeacher: true,
      oldPurchase: { course: true },
    },
    order: { createdAt: 'DESC', id: 'DESC' },
  });

  return requests.map((request) => ({
    id: request.id,
    student_id: request.student.id,
    student_name: request.student.fullName,
    username: request.student.username,
    old_course_id: request.oldCourse.id,
    old_course_name: request.oldCourse.name,
    new_course_id: request.newCourse.id,
    new_course_name: request.newCourse.name,
    old_teacher_share: request.oldTeacherShare,
    new_teacher_share: request.newTeacherShare,
    reason: request.reason,
    status: request.status,
    requested_at: request.createdAt,
    created_at: request.createdAt,
  }));
}

export async function approveCourseSwapRequest(adminId: number, requestId: number, adminNote: string | null) {
  const requestRepository = AppDataSource.getRepository(CourseSwapRequest);
  const purchaseRepository = AppDataSource.getRepository(Purchase);

  const request = await requestRepository.findOne({
    where: { id: requestId },
    relations: {
      student: true,
      oldPurchase: { teacher: true, course: true },
      oldCourse: true,
      newCourse: { teacher: true },
      oldTeacher: true,
      newTeacher: true,
    },
  });

  if (!request) {
    throw new AppError(404, 'Course swap request not found');
  }

  if (request.status !== CourseSwapStatus.PENDING) {
    throw new AppError(409, 'This course swap request is no longer pending');
  }

  const eligibility = evaluateCourseSwapRequest({
    purchaseCreatedAt: request.oldPurchase?.createdAt ?? new Date(),
    currentCourseId: request.oldCourse.id,
    replacementCourseId: request.newCourse.id,
  });

  if (!eligibility.allowed) {
    throw new AppError(400, eligibility.reason || 'The swap window has expired');
  }

  const oldPurchase = request.oldPurchase;
  if (!oldPurchase) {
    throw new AppError(404, 'Original purchase record not found');
  }

  const existingReplacement = await purchaseRepository.findOne({
    where: { user: { id: request.student.id }, course: { id: request.newCourse.id } },
  });

  if (existingReplacement && existingReplacement.id !== oldPurchase.id) {
    throw new AppError(409, 'Student already owns the replacement course');
  }

  const replacementFields = resolveSwapReplacementPurchaseFields({
    oldSource: oldPurchase.source,
    replacementPrice: request.newCourse.price,
    replacementTeacherShare: request.newTeacherShare,
  });

  const replacementPurchase = purchaseRepository.create({
    user: { id: request.student.id } as User,
    course: { id: request.newCourse.id } as Course,
    teacher: request.newTeacher ? ({ id: request.newTeacher.id } as User) : request.newCourse.teacher ? ({ id: request.newCourse.teacher.id } as User) : null,
    source: replacementFields.source,
    grantedBy: oldPurchase.grantedBy ?? null,
    pricePaid: replacementFields.pricePaid,
    teacherShare: replacementFields.teacherShare,
  });

  await purchaseRepository.remove(oldPurchase);
  await purchaseRepository.save(replacementPurchase);

  request.status = CourseSwapStatus.APPROVED;
  request.adminNote = adminNote && adminNote.trim() ? adminNote.trim() : null;
  request.approvedBy = { id: adminId } as User;
  request.approvedAt = new Date();
  await requestRepository.save(request);

  await logAuditEvent({
    action: 'COURSE_SWAP_APPROVED',
    actorId: adminId,
    entityType: 'CourseSwapRequest',
    entityId: request.id,
    metadata: {
      studentId: request.student.id,
      oldPurchaseId: oldPurchase.id,
      oldCourseId: request.oldCourse.id,
      newCourseId: request.newCourse.id,
      oldTeacherId: request.oldTeacher?.id ?? oldPurchase.teacher?.id ?? null,
      newTeacherId: request.newTeacher?.id ?? request.newCourse.teacher?.id ?? null,
      oldTeacherShare: request.oldTeacherShare,
      newTeacherShare: request.newTeacherShare,
    },
  });

  await notify(request.student.id, 'تمت الموافقة على تبديل المادة', `تم نقل اشتراكك من ${request.oldCourse.name} إلى ${request.newCourse.name}.`);
  if (request.oldTeacher && request.newTeacher && request.oldTeacher.id !== request.newTeacher.id) {
    await notify(request.oldTeacher.id, 'إعادة توزيع الحصة الدراسية', `تمت إعادة تخصيص قرار المادة ${request.oldCourse.name} إلى مادة أخرى، وتم نقل الحصة إلى مدرس جديد.`);
    await notify(request.newTeacher.id, 'إضافة مادة جديدة في توزيعك', `تمت إضافة مادة ${request.newCourse.name} إلى حسابك بناءً على طلب تبديل المادة.`);
  }

  return {
    id: request.id,
    status: request.status,
    approved_by: adminId,
    approved_at: request.approvedAt,
    old_course_id: request.oldCourse.id,
    new_course_id: request.newCourse.id,
  };
}

export async function rejectCourseSwapRequest(adminId: number, requestId: number, reason: string | null) {
  const requestRepository = AppDataSource.getRepository(CourseSwapRequest);
  const request = await requestRepository.findOne({
    where: { id: requestId },
    relations: { student: true, oldCourse: true, newCourse: true },
  });

  if (!request) {
    throw new AppError(404, 'Course swap request not found');
  }

  if (request.status !== CourseSwapStatus.PENDING) {
    throw new AppError(409, 'This course swap request is no longer pending');
  }

  request.status = CourseSwapStatus.REJECTED;
  request.rejectedBy = { id: adminId } as User;
  request.rejectedAt = new Date();
  request.adminNote = reason && reason.trim() ? reason.trim() : 'لم يتم الموافقة على طلب التبديل.';
  await requestRepository.save(request);

  await logAuditEvent({
    action: 'COURSE_SWAP_REJECTED',
    actorId: adminId,
    entityType: 'CourseSwapRequest',
    entityId: request.id,
    metadata: { studentId: request.student.id, oldCourseId: request.oldCourse.id, newCourseId: request.newCourse.id, reason: request.adminNote },
  });

  await notify(request.student.id, 'تم رفض طلب تبديل المادة', `تم رفض طلب تبديل المادة ${request.oldCourse.name} إلى ${request.newCourse.name}.`);

  return {
    id: request.id,
    status: request.status,
    rejected_by: adminId,
    rejected_at: request.rejectedAt,
    reason: request.adminNote,
  };
}
