import bcrypt from 'bcrypt';
import { Brackets, Like } from 'typeorm';

import { AppDataSource } from '../../config/data-source';
import { Course } from '../../entities/Course';
import { Lecture } from '../../entities/Lecture';
import { Notification } from '../../entities/Notification';
import { Purchase } from '../../entities/Purchase';
import { TeacherPayout } from '../../entities/TeacherPayout';
import { Specialization } from '../../entities/Specialization';
import { TopupRequest } from '../../entities/TopupRequest';
import { LectureType, LectureUploadStatus, TopupStatus, TransactionType } from '../../entities/enums';
import { Transaction } from '../../entities/Transaction';
import { User } from '../../entities/User';
import { UserRole } from '../../entities/enums';
import { AppError } from '../../utils/AppError';
import { calculateMoneyShare, centsToMoney, toCents } from '../../utils/money';
import { notify } from '../notifications/service';
import { deleteStoredVideoFile, detectVideoDurationSeconds, type StoredVideoFile } from '../../services/media';
import { logAuditEvent } from '../../services/auditLog';

function mapSpecialization(specialization: Specialization) {
  return {
    id: specialization.id,
    name: specialization.name,
    is_published: specialization.isPublished,
    sort_order: specialization.sortOrder,
    created_at: specialization.createdAt,
    updated_at: specialization.updatedAt,
  };
}

function mapCourse(course: Course) {
  return {
    id: course.id,
    specialization_id: course.specialization.id,
    specialization_name: course.specialization.name,
    teacher_id: course.teacher ? course.teacher.id : null,
    teacher_full_name: course.teacher ? course.teacher.fullName : null,
    teacher_percent: course.teacherPercent,
    year: course.year,
    name: course.name,
    description: course.description,
    price: course.price,
    is_published: course.isPublished,
    sort_order: course.sortOrder,
    created_at: course.createdAt,
    updated_at: course.updatedAt,
  };
}

function mapLecture(lecture: Lecture) {
  return {
    id: lecture.id,
    course_id: lecture.course.id,
    course_name: lecture.course.name,
    course_teacher_id: lecture.course.teacher ? lecture.course.teacher.id : null,
    title: lecture.title,
    type: lecture.type,
    url: lecture.type === LectureType.VIDEO ? null : lecture.url,
    content: lecture.content,
    is_published: lecture.isPublished,
    sort_order: lecture.sortOrder,
    created_by: lecture.createdBy ? lecture.createdBy.id : null,
    created_at: lecture.createdAt,
    updated_at: lecture.updatedAt,
  };
}

function normalizeOptionalText(value: unknown) {
  if (value === undefined || value === null) {
    return undefined;
  }

  const text = String(value).trim();
  return text.length ? text : null;
}

async function readUploadedVideoMetadata(file: StoredVideoFile) {
  return {
    storageFilename: file.filename,
    fileSize: String(file.size),
    durationSeconds: detectVideoDurationSeconds(file.path),
    uploadStatus: LectureUploadStatus.READY,
  };
}

function mapUser(user: User) {
  return {
    id: user.id,
    username: user.username,
    full_name: user.fullName,
    role: user.role,
    is_active: user.isActive,
    balance: user.balance,
    created_at: user.createdAt,
    updated_at: user.updatedAt,
  };
}

function mapTopupRequest(request: TopupRequest) {
  return {
    id: request.id,
    user_id: request.user.id,
    username: request.user.username,
    full_name: request.user.fullName,
    amount: request.amount,
    method: request.method,
    reference_number: request.referenceNumber,
    sender_name: request.senderName,
    note: request.note,
    status: request.status,
    reject_reason: request.rejectReason,
    reviewed_by: request.reviewedBy ? request.reviewedBy.id : null,
    reviewed_at: request.reviewedAt,
    created_at: request.createdAt,
  };
}

function mapTeacherAggregate(row: Record<string, unknown>) {
  const earned = String(row.total_earned ?? '0.00');
  const paid = String(row.total_paid ?? '0.00');
  const remaining = centsToMoney(toCents(earned) - toCents(paid));

  return {
    teacher_id: Number(row.teacher_id),
    username: String(row.username ?? ''),
    full_name: String(row.full_name ?? ''),
    purchases_count: Number(row.purchases_count ?? 0),
    earned,
    paid,
    remaining,
  };
}

function addDateFilter(qb: { andWhere: (sql: string, params?: Record<string, unknown>) => unknown }, alias: string, from?: string, to?: string) {
  if (from) {
    qb.andWhere(`${alias}.created_at >= :from`, { from });
  }
  if (to) {
    qb.andWhere(`${alias}.created_at <= :to`, { to });
  }
}

async function getTeacherHistoricalCourseSnapshot(courseId: number, teacherId: number | null) {
  if (!teacherId) {
    return {
      purchasesCount: 0,
      earned: '0.00',
    };
  }

  const row = await AppDataSource.getRepository(Purchase)
    .createQueryBuilder('purchase')
    .select('COUNT(purchase.id)', 'purchases_count')
    .addSelect('COALESCE(SUM(purchase.teacher_share), 0)', 'earned')
    .where('purchase.course_id = :courseId', { courseId })
    // Earnings attribution is historical and must come from purchase.teacher_id snapshots.
    .andWhere('purchase.teacher_id = :teacherId', { teacherId })
    .getRawOne<{ purchases_count: string; earned: string }>();

  return {
    purchasesCount: Number(row?.purchases_count ?? 0),
    earned: String(row?.earned ?? '0.00'),
  };
}

async function getTeacherTotals(teacherId: number) {
  const [earnedRow, paidRow] = await Promise.all([
    AppDataSource.getRepository(Purchase)
      .createQueryBuilder('purchase')
      .select('COALESCE(SUM(purchase.teacher_share), 0)', 'total_earned')
      // Earnings attribution is historical and must come from purchase.teacher_id snapshots.
      .where('purchase.teacher_id = :teacherId', { teacherId })
      .getRawOne<{ total_earned: string }>(),
    AppDataSource.getRepository(TeacherPayout)
      .createQueryBuilder('payout')
      .select('COALESCE(SUM(payout.amount), 0)', 'total_paid')
      .where('payout.teacher_id = :teacherId', { teacherId })
      .getRawOne<{ total_paid: string }>(),
  ]);

  const totalEarned = String(earnedRow?.total_earned ?? '0.00');
  const totalPaid = String(paidRow?.total_paid ?? '0.00');
  const remaining = centsToMoney(toCents(totalEarned) - toCents(totalPaid));

  return {
    totalEarned,
    totalPaid,
    remaining,
  };
}

async function requireTeacherUser(id: number) {
  const user = await AppDataSource.getRepository(User).findOne({ where: { id, role: UserRole.TEACHER } });
  if (!user) {
    throw new AppError(400, 'teacher_id must reference a TEACHER user');
  }
  return user;
}

async function requireNonAdminUser(id: number) {
  const user = await AppDataSource.getRepository(User).findOne({ where: { id } });
  if (!user) {
    throw new AppError(404, 'User not found');
  }
  if (user.role === UserRole.ADMIN) {
    throw new AppError(400, 'Admin users cannot be modified');
  }
  return user;
}

async function findSpecializationOrFail(id: number) {
  const specialization = await AppDataSource.getRepository(Specialization).findOne({ where: { id } });
  if (!specialization) {
    throw new AppError(404, 'Specialization not found');
  }
  return specialization;
}

async function findCourseOrFail(id: number) {
  const course = await AppDataSource.getRepository(Course).findOne({ where: { id }, relations: { specialization: true, teacher: true } });
  if (!course) {
    throw new AppError(404, 'Course not found');
  }
  return course;
}

async function findLectureOrFail(id: number) {
  const lecture = await AppDataSource.getRepository(Lecture).findOne({ where: { id }, relations: { course: { specialization: true, teacher: true }, createdBy: true } });
  if (!lecture) {
    throw new AppError(404, 'Lecture not found');
  }
  return lecture;
}

async function findTopupRequestOrFail(id: number) {
  const request = await AppDataSource.getRepository(TopupRequest).findOne({
    where: { id },
    relations: { user: true, reviewedBy: true },
  });
  if (!request) {
    throw new AppError(404, 'Top-up request not found');
  }
  return request;
}

export async function listSpecializations() {
  const specializations = await AppDataSource.getRepository(Specialization).find({ order: { sortOrder: 'ASC', id: 'ASC' } });
  return specializations.map(mapSpecialization);
}

export async function getSpecializationById(id: number) {
  return mapSpecialization(await findSpecializationOrFail(id));
}

export async function listSpecializationsFiltered(search?: string) {
  const items = await listSpecializations();
  if (!search) {
    return items;
  }

  const normalized = search.trim().toLowerCase();
  return items.filter((item) => item.name.toLowerCase().includes(normalized));
}

export async function createSpecialization(input: { name: string; is_published?: boolean; sort_order?: number }) {
  const specialization = AppDataSource.getRepository(Specialization).create({
    name: input.name,
    isPublished: input.is_published ?? true,
    sortOrder: input.sort_order ?? 0,
  });
  return mapSpecialization(await AppDataSource.getRepository(Specialization).save(specialization));
}

export async function updateSpecialization(id: number, input: Partial<{ name: string; is_published: boolean; sort_order: number }>) {
  const repository = AppDataSource.getRepository(Specialization);
  const specialization = await repository.findOne({ where: { id } });
  if (!specialization) {
    throw new AppError(404, 'Specialization not found');
  }

  if (input.name !== undefined) specialization.name = input.name;
  if (input.is_published !== undefined) specialization.isPublished = input.is_published;
  if (input.sort_order !== undefined) specialization.sortOrder = input.sort_order;

  return mapSpecialization(await repository.save(specialization));
}

export async function archiveSpecialization(id: number) {
  const repository = AppDataSource.getRepository(Specialization);
  const specialization = await repository.findOne({ where: { id } });
  if (!specialization) {
    throw new AppError(404, 'Specialization not found');
  }
  specialization.isPublished = false;
  return mapSpecialization(await repository.save(specialization));
}

export async function setSpecializationPublished(id: number, isPublished: boolean) {
  return updateSpecialization(id, { is_published: isPublished });
}

export async function listCourses() {
  return listCoursesFiltered({});
}

export async function listCoursesFiltered(filters: {
  specializationId?: number;
  year?: number;
  teacherId?: number;
  is_published?: boolean;
  search?: string;
}) {
  const query = AppDataSource.getRepository(Course)
    .createQueryBuilder('course')
    .innerJoin('course.specialization', 'specialization')
    .leftJoin('course.teacher', 'teacher')
    .leftJoin('course.purchases', 'purchase')
    .select('course.id', 'id')
    .addSelect('specialization.id', 'specialization_id')
    .addSelect('specialization.name', 'specialization_name')
    .addSelect('teacher.id', 'teacher_id')
    .addSelect('teacher.full_name', 'teacher_full_name')
    .addSelect('course.teacher_percent', 'teacher_percent')
    .addSelect('course.year', 'year')
    .addSelect('course.name', 'name')
    .addSelect('course.description', 'description')
    .addSelect('course.price', 'price')
    .addSelect('course.is_published', 'is_published')
    .addSelect('course.sort_order', 'sort_order')
    .addSelect('course.created_at', 'created_at')
    .addSelect('course.updated_at', 'updated_at')
    .addSelect('COUNT(purchase.id)', 'purchases_count')
    .addSelect('COALESCE(SUM(CASE WHEN purchase.teacher_id = teacher.id THEN 1 ELSE 0 END), 0)', 'current_teacher_historical_purchases_count')
    .addSelect('COALESCE(SUM(CASE WHEN purchase.teacher_id = teacher.id THEN purchase.teacher_share ELSE 0 END), 0)', 'current_teacher_historical_earned')
    .groupBy('course.id')
    .addGroupBy('specialization.id')
    .addGroupBy('specialization.name')
    .addGroupBy('teacher.id')
    .addGroupBy('teacher.full_name')
    .orderBy('course.sort_order', 'ASC')
    .addOrderBy('course.id', 'ASC');

  if (filters.specializationId) {
    query.andWhere('specialization.id = :specializationId', { specializationId: filters.specializationId });
  }
  if (filters.year) {
    query.andWhere('course.year = :year', { year: filters.year });
  }
  if (filters.teacherId) {
    query.andWhere('teacher.id = :teacherId', { teacherId: filters.teacherId });
  }
  if (filters.is_published !== undefined) {
    query.andWhere('course.is_published = :isPublished', { isPublished: filters.is_published });
  }
  if (filters.search) {
    query.andWhere('(course.name LIKE :search OR course.description LIKE :search)', { search: `%${filters.search}%` });
  }

  const rows = await query.getRawMany<Record<string, unknown>>();
  return rows.map((row) => ({
    id: Number(row.id),
    specialization_id: Number(row.specialization_id),
    specialization_name: String(row.specialization_name ?? ''),
    teacher_id: row.teacher_id === null ? null : Number(row.teacher_id),
    teacher_full_name: row.teacher_full_name === null ? null : String(row.teacher_full_name),
    teacher_percent: String(row.teacher_percent ?? '0.00'),
    year: Number(row.year),
    name: String(row.name ?? ''),
    description: row.description === null ? null : String(row.description ?? ''),
    price: String(row.price ?? '0.00'),
    is_published: Boolean(row.is_published),
    sort_order: Number(row.sort_order ?? 0),
    purchases_count: Number(row.purchases_count ?? 0),
    current_teacher_historical_purchases_count: Number(row.current_teacher_historical_purchases_count ?? 0),
    current_teacher_historical_earned: String(row.current_teacher_historical_earned ?? '0.00'),
    created_at: row.created_at,
    updated_at: row.updated_at,
  }));
}

export async function getCourseById(id: number) {
  const course = await findCourseOrFail(id);
  const oldTeacherId = course.teacher ? course.teacher.id : null;
  const [snapshot, totals] = await Promise.all([
    getTeacherHistoricalCourseSnapshot(course.id, oldTeacherId),
    oldTeacherId ? getTeacherTotals(oldTeacherId) : Promise.resolve(null),
  ]);

  return {
    ...mapCourse(course),
    teacher_reassignment_notice: {
      old_teacher_id: oldTeacherId,
      old_teacher_full_name: course.teacher ? course.teacher.fullName : null,
      course_purchases_count: snapshot.purchasesCount,
      course_earned: snapshot.earned,
      teacher_total_paid: totals?.totalPaid ?? '0.00',
      teacher_total_remaining: totals?.remaining ?? '0.00',
    },
  };
}

export async function createCourse(input: { specialization_id: number; year: number; name: string; description?: string | null; price: string; is_published?: boolean; sort_order?: number; teacher_id?: number | null; teacher_percent?: string }) {
  const specialization = await findSpecializationOrFail(input.specialization_id);
  const teacher = input.teacher_id ? await requireTeacherUser(input.teacher_id) : null;
  const course = AppDataSource.getRepository(Course).create({
    specialization,
    teacher,
    year: input.year,
    name: input.name,
    description: input.description ?? null,
    price: input.price,
    isPublished: input.is_published ?? true,
    sortOrder: input.sort_order ?? 0,
    teacherPercent: input.teacher_percent ?? '0.00',
  });
  return mapCourse(await AppDataSource.getRepository(Course).save(course));
}

export async function updateCourse(
  id: number,
  input: Partial<{ specialization_id: number; teacher_id: number | null; year: number; name: string; description: string | null; price: string; teacher_percent: string; is_published: boolean; sort_order: number }>,
  actorId?: number | null,
) {
  const repository = AppDataSource.getRepository(Course);
  const course = await repository.findOne({ where: { id }, relations: { specialization: true, teacher: true } });
  if (!course) {
    throw new AppError(404, 'Course not found');
  }

  const oldTeacherId = course.teacher ? course.teacher.id : null;

  if (input.specialization_id !== undefined) {
    course.specialization = await findSpecializationOrFail(input.specialization_id);
  }
  if (input.teacher_id !== undefined) {
    course.teacher = input.teacher_id === null ? null : await requireTeacherUser(input.teacher_id);
  }
  if (input.year !== undefined) course.year = input.year;
  if (input.name !== undefined) course.name = input.name;
  if (input.description !== undefined) course.description = input.description;
  if (input.price !== undefined) course.price = input.price;
  if (input.teacher_percent !== undefined) course.teacherPercent = input.teacher_percent;
  if (input.is_published !== undefined) course.isPublished = input.is_published;
  if (input.sort_order !== undefined) course.sortOrder = input.sort_order;

  const saved = await repository.save(course);
  const newTeacherId = saved.teacher ? saved.teacher.id : null;

  if (input.teacher_id !== undefined && oldTeacherId !== newTeacherId) {
    const oldTeacherSnapshot = await getTeacherHistoricalCourseSnapshot(saved.id, oldTeacherId);
    await logAuditEvent({
      action: 'COURSE_TEACHER_REASSIGNED',
      actorId: actorId ?? null,
      entityType: 'COURSE',
      entityId: saved.id,
      metadata: {
        old_teacher_id: oldTeacherId,
        new_teacher_id: newTeacherId,
        old_teacher_historical_purchases_count: oldTeacherSnapshot.purchasesCount,
        old_teacher_historical_earned: oldTeacherSnapshot.earned,
      },
    });
  }

  return mapCourse(saved);
}

export async function archiveCourse(id: number) {
  const repository = AppDataSource.getRepository(Course);
  const course = await repository.findOne({ where: { id }, relations: { specialization: true, teacher: true } });
  if (!course) {
    throw new AppError(404, 'Course not found');
  }
  course.isPublished = false;
  return mapCourse(await repository.save(course));
}

export async function setCoursePublished(id: number, isPublished: boolean) {
  return updateCourse(id, { is_published: isPublished });
}

export async function listLectures() {
  return listLecturesFiltered();
}

export async function listLecturesFiltered(courseId?: number) {
  const lectures = await AppDataSource.getRepository(Lecture).find({
    where: courseId ? { course: { id: courseId } } : undefined,
    relations: { course: { specialization: true, teacher: true }, createdBy: true },
    order: { sortOrder: 'ASC', id: 'ASC' },
  });
  return lectures.map(mapLecture);
}

export async function listCourseLecturesForAdmin(courseId: number) {
  await findCourseOrFail(courseId);
  return listLecturesFiltered(courseId);
}

export async function getLectureById(id: number) {
  return mapLecture(await findLectureOrFail(id));
}

export async function createLecture(adminId: number, input: { course_id: number; title: string; type: string; url?: string | null; content?: string | null; is_published?: boolean; sort_order?: number }, file?: StoredVideoFile | null) {
  const course = await findCourseOrFail(input.course_id);
  const repository = AppDataSource.getRepository(Lecture);
  const isVideo = input.type === LectureType.VIDEO;
  const normalizedUrl = normalizeOptionalText(input.url);
  const normalizedContent = normalizeOptionalText(input.content);

  if (isVideo) {
    if (normalizedUrl) {
      throw new AppError(400, 'Video lectures must not include an external URL');
    }
    if (!file) {
      throw new AppError(400, 'Video file is required');
    }
  } else if (file) {
    throw new AppError(400, 'Video uploads are only allowed for VIDEO lectures');
  }

  let uploadedFilename: string | null = file?.filename ?? null;

  try {
    const videoMetadata = file ? await readUploadedVideoMetadata(file) : null;
    const lecture = repository.create({
      course,
      createdBy: { id: adminId } as User,
      title: input.title,
      type: input.type as Lecture['type'],
      url: isVideo ? null : normalizedUrl ?? null,
      storageFilename: isVideo ? videoMetadata?.storageFilename ?? null : null,
      fileSize: isVideo ? videoMetadata?.fileSize ?? null : null,
      durationSeconds: isVideo ? videoMetadata?.durationSeconds ?? null : null,
      uploadStatus: isVideo ? LectureUploadStatus.READY : LectureUploadStatus.READY,
      content: isVideo ? null : normalizedContent ?? null,
      isPublished: input.is_published ?? true,
      sortOrder: input.sort_order ?? 0,
    });

    const saved = await repository.save(lecture);
    uploadedFilename = null;
    return mapLecture(saved);
  } catch (error) {
    if (uploadedFilename) {
      await deleteStoredVideoFile(uploadedFilename);
    }
    throw error;
  }
}

export async function updateLecture(id: number, input: Partial<{ course_id: number; title: string; type: string; url: string | null; content: string | null; is_published: boolean; sort_order: number }>, file?: StoredVideoFile | null) {
  const repository = AppDataSource.getRepository(Lecture);
  const lecture = await repository.findOne({ where: { id }, relations: { course: { specialization: true, teacher: true }, createdBy: true } });
  if (!lecture) {
    throw new AppError(404, 'Lecture not found');
  }

  const nextType = input.type ? (input.type as LectureType) : lecture.type;
  const replacingVideo = nextType === LectureType.VIDEO && !!file;
  const removingVideo = lecture.type === LectureType.VIDEO && nextType !== LectureType.VIDEO;
  const oldVideoFilename = lecture.storageFilename;

  if (file && nextType !== LectureType.VIDEO) {
    throw new AppError(400, 'Video uploads are only allowed for VIDEO lectures');
  }

  const normalizedUrl = input.url === undefined ? undefined : normalizeOptionalText(input.url);
  const normalizedContent = input.content === undefined ? undefined : normalizeOptionalText(input.content);

  if (nextType === LectureType.VIDEO) {
    if (normalizedUrl) {
      throw new AppError(400, 'Video lectures must not include an external URL');
    }
    if (!file && !lecture.storageFilename) {
      throw new AppError(400, 'Video file is required');
    }
  }

  let uploadedFilename: string | null = file?.filename ?? null;

  if (input.course_id !== undefined) lecture.course = await findCourseOrFail(input.course_id);
  if (input.title !== undefined) lecture.title = input.title;
  if (input.type !== undefined) lecture.type = nextType;
  if (nextType === LectureType.VIDEO) {
    lecture.url = null;
    lecture.content = null;
  } else {
    if (input.url !== undefined) lecture.url = normalizedUrl ?? null;
    if (input.content !== undefined) lecture.content = normalizedContent ?? null;
  }
  if (input.is_published !== undefined) lecture.isPublished = input.is_published;
  if (input.sort_order !== undefined) lecture.sortOrder = input.sort_order;

  if (nextType === LectureType.VIDEO) {
    if (file) {
      const videoMetadata = await readUploadedVideoMetadata(file);
      lecture.storageFilename = videoMetadata.storageFilename;
      lecture.fileSize = videoMetadata.fileSize;
      lecture.durationSeconds = videoMetadata.durationSeconds;
      lecture.uploadStatus = LectureUploadStatus.READY;
    } else {
      lecture.uploadStatus = LectureUploadStatus.READY;
    }
  } else {
    lecture.storageFilename = null;
    lecture.fileSize = null;
    lecture.durationSeconds = null;
    lecture.uploadStatus = LectureUploadStatus.READY;
  }

  try {
    const saved = await repository.save(lecture);
    uploadedFilename = null;
    if ((replacingVideo || removingVideo) && oldVideoFilename && oldVideoFilename !== saved.storageFilename) {
      await deleteStoredVideoFile(oldVideoFilename);
    }
    return mapLecture(saved);
  } catch (error) {
    if (uploadedFilename) {
      await deleteStoredVideoFile(uploadedFilename);
    }
    throw error;
  }
}

export async function archiveLecture(id: number) {
  const repository = AppDataSource.getRepository(Lecture);
  const lecture = await repository.findOne({ where: { id }, relations: { course: { specialization: true, teacher: true }, createdBy: true } });
  if (!lecture) {
    throw new AppError(404, 'Lecture not found');
  }
  lecture.isPublished = false;
  return mapLecture(await repository.save(lecture));
}

export async function setLecturePublished(id: number, isPublished: boolean) {
  return updateLecture(id, { is_published: isPublished });
}

export async function reorderCourseLectures(courseId: number, lectureIds: number[]) {
  return AppDataSource.transaction(async (manager) => {
    await findCourseOrFail(courseId);
    const repository = manager.getRepository(Lecture);
    const lectures = await repository.find({
      where: { course: { id: courseId } },
      relations: { course: true, createdBy: true },
      order: { sortOrder: 'ASC', id: 'ASC' },
      lock: { mode: 'pessimistic_write' },
    });

    if (lectures.length !== lectureIds.length) {
      throw new AppError(400, 'lecture_ids must include all course lectures exactly once');
    }

    const existingIds = lectures.map((lecture) => lecture.id).sort((left, right) => left - right);
    const requestedIds = [...lectureIds].sort((left, right) => left - right);

    if (existingIds.some((id, index) => id !== requestedIds[index])) {
      throw new AppError(400, 'lecture_ids must include all course lectures exactly once');
    }

    const lectureMap = new Map(lectures.map((lecture) => [lecture.id, lecture]));
    for (let index = 0; index < lectureIds.length; index += 1) {
      const lecture = lectureMap.get(lectureIds[index]);
      if (!lecture) {
        throw new AppError(400, 'lecture_ids must include all course lectures exactly once');
      }
      lecture.sortOrder = index;
      await repository.save(lecture);
    }

    return listCourseLecturesForAdmin(courseId);
  });
}

export async function listTopupRequests(status: TopupStatus) {
  const requests = await AppDataSource.getRepository(TopupRequest).find({
    where: { status },
    relations: { user: true, reviewedBy: true },
    order: { createdAt: 'DESC', id: 'DESC' },
  });
  return requests.map(mapTopupRequest);
}

export async function approveTopupRequest(topupRequestId: number, reviewerId: number) {
  return AppDataSource.transaction(async (manager) => {
    const requestRepository = manager.getRepository(TopupRequest);
    const userRepository = manager.getRepository(User);
    const transactionRepository = manager.getRepository(Transaction);

    const request = await requestRepository.findOne({
      where: { id: topupRequestId },
      relations: { user: true, reviewedBy: true },
      lock: { mode: 'pessimistic_write' },
    });

    if (!request) {
      throw new AppError(404, 'Top-up request not found');
    }

    if (request.status !== TopupStatus.PENDING) {
      throw new AppError(400, 'Top-up request is not pending');
    }

    const user = await userRepository.findOne({
      where: { id: request.user.id },
      lock: { mode: 'pessimistic_write' },
    });

    if (!user) {
      throw new AppError(404, 'User not found');
    }

    const newBalance = centsToMoney(toCents(user.balance) + toCents(request.amount));
    user.balance = newBalance;
    await userRepository.save(user);

    const transaction = transactionRepository.create({
      user: { id: user.id } as User,
      type: TransactionType.TOPUP,
      amount: request.amount,
      balanceAfter: newBalance,
      description: `Top-up request approved: ${request.referenceNumber}`,
      referenceType: 'TOPUP_REQUEST',
      referenceId: request.id,
    });
    await transactionRepository.save(transaction);

    request.status = TopupStatus.APPROVED;
    request.reviewedBy = { id: reviewerId } as User;
    request.reviewedAt = new Date();
    request.rejectReason = null;
    await requestRepository.save(request);

    await notify(user.id, 'Top-up approved', `Your balance was topped up by ${request.amount}`, manager);

    return {
      message: 'Top-up request approved',
      request_id: request.id,
    };
  });
}

export async function rejectTopupRequest(topupRequestId: number, reviewerId: number, reason: string) {
  return AppDataSource.transaction(async (manager) => {
    const requestRepository = manager.getRepository(TopupRequest);
    const request = await requestRepository.findOne({
      where: { id: topupRequestId },
      relations: { user: true, reviewedBy: true },
      lock: { mode: 'pessimistic_write' },
    });

    if (!request) {
      throw new AppError(404, 'Top-up request not found');
    }

    if (request.status !== TopupStatus.PENDING) {
      throw new AppError(400, 'Top-up request is not pending');
    }

    request.status = TopupStatus.REJECTED;
    request.reviewedBy = { id: reviewerId } as User;
    request.reviewedAt = new Date();
    request.rejectReason = reason;
    await requestRepository.save(request);

    await notify(request.user.id, 'Top-up rejected', `Your top-up request was rejected: ${reason}`, manager);

    return {
      message: 'Top-up request rejected',
      request_id: request.id,
    };
  });
}

export async function listUsers(search?: string) {
  return listUsersFiltered({ search });
}

export async function listUsersFiltered(filters: {
  search?: string;
  role?: UserRole;
  is_active?: boolean;
  is_test?: boolean;
}) {
  const repository = AppDataSource.getRepository(User);
  const query = repository.createQueryBuilder('user').orderBy('user.created_at', 'DESC').addOrderBy('user.id', 'DESC');

  if (filters.search) {
    query.andWhere(new Brackets((qb) => {
      qb.where('user.username LIKE :search', { search: `%${filters.search}%` })
        .orWhere('user.full_name LIKE :search', { search: `%${filters.search}%` });
    }));
  }
  if (filters.role) {
    query.andWhere('user.role = :role', { role: filters.role });
  }
  if (filters.is_active !== undefined) {
    query.andWhere('user.is_active = :isActive', { isActive: filters.is_active });
  }
  if (filters.is_test !== undefined) {
    query.andWhere('user.is_test = :isTest', { isTest: filters.is_test });
  }

  const users = await query.getMany();

  return users.map(mapUser);
}

export async function getUserById(userId: number) {
  const user = await AppDataSource.getRepository(User).findOne({ where: { id: userId } });
  if (!user) {
    throw new AppError(404, 'User not found');
  }

  const [purchasesCount, topups] = await Promise.all([
    AppDataSource.getRepository(Purchase).count({ where: { user: { id: userId } } }),
    AppDataSource.getRepository(TopupRequest).find({
      where: { user: { id: userId } },
      order: { createdAt: 'DESC', id: 'DESC' },
      take: 5,
      relations: { user: true, reviewedBy: true },
    }),
  ]);

  return {
    ...mapUser(user),
    purchases_count: purchasesCount,
    last_topups: topups.map(mapTopupRequest),
  };
}

export async function listUserTransactions(userId: number) {
  const user = await AppDataSource.getRepository(User).findOne({ where: { id: userId } });
  if (!user) {
    throw new AppError(404, 'User not found');
  }

  const transactions = await AppDataSource.getRepository(Transaction).find({
    where: { user: { id: userId } },
    order: { createdAt: 'DESC', id: 'DESC' },
  });

  return transactions.map((transaction) => ({
    id: transaction.id,
    type: transaction.type,
    amount: transaction.amount,
    balance_after: transaction.balanceAfter,
    description: transaction.description,
    reference_type: transaction.referenceType,
    reference_id: transaction.referenceId,
    created_at: transaction.createdAt,
  }));
}

export async function listUserPurchases(userId: number) {
  const user = await AppDataSource.getRepository(User).findOne({ where: { id: userId } });
  if (!user) {
    throw new AppError(404, 'User not found');
  }

  const purchases = await AppDataSource.getRepository(Purchase).find({
    where: { user: { id: userId } },
    relations: { course: { specialization: true, teacher: true }, teacher: true },
    order: { createdAt: 'DESC', id: 'DESC' },
  });

  return purchases.map((purchase) => ({
    id: purchase.id,
    course_id: purchase.course.id,
    course_name: purchase.course.name,
    specialization_name: purchase.course.specialization.name,
    teacher_id: purchase.teacher?.id ?? null,
    price_paid: purchase.pricePaid,
    teacher_share: purchase.teacherShare,
    created_at: purchase.createdAt,
  }));
}

export async function setUserActive(userId: number, isActive: boolean) {
  const repository = AppDataSource.getRepository(User);
  const user = await requireNonAdminUser(userId);
  user.isActive = isActive;
  return mapUser(await repository.save(user));
}

export async function resetUserDevice(userId: number) {
  const repository = AppDataSource.getRepository(User);
  const user = await requireNonAdminUser(userId);
  user.deviceId = null;
  return mapUser(await repository.save(user));
}

export async function adjustBalance(userId: number, amount: string, description: string) {
  return AppDataSource.transaction(async (manager) => {
    const userRepository = manager.getRepository(User);
    const transactionRepository = manager.getRepository(Transaction);

    const user = await userRepository.findOne({
      where: { id: userId },
      lock: { mode: 'pessimistic_write' },
    });

    if (!user) {
      throw new AppError(404, 'User not found');
    }

    const newBalanceCents = toCents(user.balance) + toCents(amount);
    if (newBalanceCents < 0n) {
      throw new AppError(400, 'Balance cannot go below zero');
    }

    const newBalance = centsToMoney(newBalanceCents);
    user.balance = newBalance;
    await userRepository.save(user);

    await transactionRepository.save(
      transactionRepository.create({
        user: { id: user.id } as User,
        type: TransactionType.TOPUP,
        amount,
        balanceAfter: newBalance,
        description,
        referenceType: 'ADMIN_ADJUSTMENT',
        referenceId: null,
      }),
    );

    return {
      message: 'Balance updated successfully',
      balance: newBalance,
    };
  });
}

export async function createNotifications(input: { all?: boolean; user_id?: number; title: string; body: string }) {
  return AppDataSource.transaction(async (manager) => {
    const userRepository = manager.getRepository(User);
    const notificationRepository = manager.getRepository(Notification);

    const targetUsers = input.all
      ? await userRepository.find({ select: { id: true } })
      : input.user_id
        ? await userRepository.find({ where: { id: input.user_id }, select: { id: true } })
        : [];

    if (targetUsers.length === 0) {
      if (input.all) {
        throw new AppError(400, 'No users available to receive notification');
      }
      throw new AppError(404, 'User not found');
    }

    const notifications = targetUsers.map((user) =>
      notificationRepository.create({
        user: { id: user.id } as User,
        title: input.title,
        body: input.body,
        isRead: false,
      }),
    );

    await notificationRepository.save(notifications);

    return {
      message: 'Notification sent successfully',
      count: notifications.length,
    };
  });
}

export async function getTopupRequestById(id: number) {
  const request = await findTopupRequestOrFail(id);
  return mapTopupRequest(request);
}

export async function createTeacher(input: { username: string; full_name: string; password: string }) {
  const userRepository = AppDataSource.getRepository(User);
  const existing = await userRepository.findOne({ where: { username: input.username } });

  if (existing) {
    throw new AppError(409, 'Username already exists');
  }

  const passwordHash = await bcrypt.hash(input.password, 12);
  const teacher = userRepository.create({
    username: input.username,
    fullName: input.full_name,
    passwordHash,
    role: UserRole.TEACHER,
    isActive: true,
    balance: '0.00',
    deviceId: null,
  });

  const saved = await userRepository.save(teacher);
  return mapUser(saved);
}

function buildTeacherAggregateQuery(from?: string, to?: string) {
  const purchaseAgg = AppDataSource.createQueryBuilder()
    .from(Purchase, 'purchase')
    // Earnings attribution is historical and must come from purchase.teacher_id snapshots.
    .select('purchase.teacher_id', 'teacher_id')
    .addSelect('COUNT(purchase.id)', 'purchases_count')
    .addSelect('COALESCE(SUM(purchase.teacher_share), 0)', 'total_earned')
    .where('purchase.teacher_id IS NOT NULL');

  const payoutAgg = AppDataSource.createQueryBuilder()
    .from(TeacherPayout, 'payout')
    .select('payout.teacher_id', 'teacher_id')
    .addSelect('COALESCE(SUM(payout.amount), 0)', 'total_paid');

  addDateFilter(purchaseAgg, 'purchase', from, to);
  addDateFilter(payoutAgg, 'payout', from, to);

  purchaseAgg.groupBy('purchase.teacher_id');
  payoutAgg.groupBy('payout.teacher_id');

  return { purchaseAgg, payoutAgg };
}

async function loadTeacherRows(from?: string, to?: string) {
  const { purchaseAgg, payoutAgg } = buildTeacherAggregateQuery(from, to);

  return AppDataSource.getRepository(User)
    .createQueryBuilder('teacher')
    .select('teacher.id', 'teacher_id')
    .addSelect('teacher.username', 'username')
    .addSelect('teacher.full_name', 'full_name')
    .addSelect('COALESCE(purchases.purchases_count, 0)', 'purchases_count')
    .addSelect('COALESCE(purchases.total_earned, 0)', 'total_earned')
    .addSelect('COALESCE(payouts.total_paid, 0)', 'total_paid')
    .leftJoin(`(${purchaseAgg.getQuery()})`, 'purchases', 'purchases.teacher_id = teacher.id')
    .leftJoin(`(${payoutAgg.getQuery()})`, 'payouts', 'payouts.teacher_id = teacher.id')
    .setParameters({ ...purchaseAgg.getParameters(), ...payoutAgg.getParameters() })
    .where('teacher.role = :role', { role: UserRole.TEACHER })
    .orderBy('teacher.id', 'ASC')
    .getRawMany();
}

export async function listTeachers() {
  return (await loadTeacherRows()).map(mapTeacherAggregate);
}

export async function getTeacherById(teacherId: number) {
  const teacher = await AppDataSource.getRepository(User).findOne({ where: { id: teacherId, role: UserRole.TEACHER } });
  if (!teacher) {
    throw new AppError(404, 'Teacher not found');
  }

  const [totals, courses, payouts] = await Promise.all([
    teachersStats(),
    listCoursesFiltered({ teacherId }),
    listTeacherPayouts(teacherId),
  ]);

  const total = totals.find((item) => item.teacher_id === teacherId) ?? {
    teacher_id: teacherId,
    username: teacher.username,
    full_name: teacher.fullName,
    purchases_count: 0,
    earned: '0.00',
    paid: '0.00',
    remaining: '0.00',
  };

  return {
    ...mapUser(teacher),
    totals: total,
    courses,
    payouts,
  };
}

export async function payoutTeacher(teacherId: number, createdById: number, amount: string, note?: string | null) {
  return AppDataSource.transaction(async (manager) => {
    const userRepository = manager.getRepository(User);
    const payoutRepository = manager.getRepository(TeacherPayout);

    const teacher = await userRepository.findOne({
      where: { id: teacherId, role: UserRole.TEACHER },
      lock: { mode: 'pessimistic_write' },
    });

    if (!teacher) {
      throw new AppError(404, 'Teacher not found');
    }

    const earnedRow = await manager
      .getRepository(Purchase)
      .createQueryBuilder('purchase')
      .select('COALESCE(SUM(purchase.teacher_share), 0)', 'total_earned')
      // Earnings attribution is historical and must come from purchase.teacher_id snapshots.
      .where('purchase.teacher_id = :teacherId', { teacherId })
      .getRawOne<{ total_earned: string }>();

    const paidRow = await manager
      .getRepository(TeacherPayout)
      .createQueryBuilder('payout')
      .select('COALESCE(SUM(payout.amount), 0)', 'total_paid')
      .where('payout.teacher_id = :teacherId', { teacherId })
      .getRawOne<{ total_paid: string }>();

    const totalEarned = String(earnedRow?.total_earned ?? '0.00');
    const totalPaid = String(paidRow?.total_paid ?? '0.00');
    const remaining = toCents(totalEarned) - toCents(totalPaid);

    if (toCents(amount) > remaining) {
      throw new AppError(400, 'Payout amount exceeds remaining balance');
    }

    const payout = payoutRepository.create({
      teacher: { id: teacher.id } as User,
      amount,
      note: note ?? null,
      createdBy: { id: createdById } as User,
    });

    const saved = await payoutRepository.save(payout);
    return {
      id: saved.id,
      teacher_id: teacher.id,
      amount: saved.amount,
      note: saved.note,
      created_by: saved.createdBy.id,
      created_at: saved.createdAt,
    };
  });
}

export async function listTeacherPayouts(teacherId: number) {
  const payouts = await AppDataSource.getRepository(TeacherPayout).find({
    where: { teacher: { id: teacherId } },
    relations: { createdBy: true },
    order: { createdAt: 'DESC', id: 'DESC' },
  });

  return payouts.map((payout) => ({
    id: payout.id,
    teacher_id: teacherId,
    amount: payout.amount,
    note: payout.note,
    created_by: payout.createdBy.id,
    created_at: payout.createdAt,
  }));
}

export async function resetPassword(userId: number, newPassword: string) {
  const user = await requireNonAdminUser(userId);
  const passwordHash = await bcrypt.hash(newPassword, 12);
  user.passwordHash = passwordHash;
  await AppDataSource.getRepository(User).save(user);
  return { message: 'Password reset successfully' };
}

export async function overviewStats(from?: string, to?: string) {
  const userRepo = AppDataSource.getRepository(User);
  const courseRepo = AppDataSource.getRepository(Course);
  const purchaseRepo = AppDataSource.getRepository(Purchase);
  const topupRepo = AppDataSource.getRepository(TopupRequest);

  const studentsCountQuery = userRepo.createQueryBuilder('user').select('COUNT(user.id)', 'count').where('user.role = :role', { role: UserRole.STUDENT });
  const teachersCountQuery = userRepo.createQueryBuilder('user').select('COUNT(user.id)', 'count').where('user.role = :role', { role: UserRole.TEACHER });
  const coursesCountQuery = courseRepo.createQueryBuilder('course').select('COUNT(course.id)', 'count');
  const purchasesCountQuery = purchaseRepo.createQueryBuilder('purchase').select('COUNT(purchase.id)', 'count');
  const totalSalesQuery = purchaseRepo.createQueryBuilder('purchase').select('COALESCE(SUM(purchase.pricePaid), 0)', 'amount');
  const totalTopupsQuery = topupRepo.createQueryBuilder('request').select('COALESCE(SUM(request.amount), 0)', 'amount').where('request.status = :status', { status: TopupStatus.APPROVED });
  const pendingTopupsQuery = topupRepo.createQueryBuilder('request').select('COUNT(request.id)', 'count').where('request.status = :status', { status: TopupStatus.PENDING });
  const totalBalanceQuery = userRepo.createQueryBuilder('user').select('COALESCE(SUM(user.balance), 0)', 'amount').where('user.role = :role', { role: UserRole.STUDENT });

  addDateFilter(studentsCountQuery, 'user', from, to);
  addDateFilter(teachersCountQuery, 'user', from, to);
  addDateFilter(coursesCountQuery, 'course', from, to);
  addDateFilter(purchasesCountQuery, 'purchase', from, to);
  addDateFilter(totalSalesQuery, 'purchase', from, to);
  if (from) {
    pendingTopupsQuery.andWhere('request.created_at >= :from', { from });
  }
  if (to) {
    pendingTopupsQuery.andWhere('request.created_at <= :to', { to });
  }
  if (from) {
    totalTopupsQuery.andWhere('request.reviewed_at >= :from', { from });
  }
  if (to) {
    totalTopupsQuery.andWhere('request.reviewed_at <= :to', { to });
  }
  addDateFilter(totalBalanceQuery, 'user', from, to);

  const [studentsCount, teachersCount, coursesCount, purchasesCount, salesRow, topupRow, pendingRow, balanceRow] = await Promise.all([
    studentsCountQuery.getRawOne<{ count: string }>(),
    teachersCountQuery.getRawOne<{ count: string }>(),
    coursesCountQuery.getRawOne<{ count: string }>(),
    purchasesCountQuery.getRawOne<{ count: string }>(),
    totalSalesQuery.getRawOne<{ amount: string }>(),
    totalTopupsQuery.getRawOne<{ amount: string }>(),
    pendingTopupsQuery.getRawOne<{ count: string }>(),
    totalBalanceQuery.getRawOne<{ amount: string }>(),
  ]);

  return {
    students_count: Number(studentsCount?.count ?? 0),
    teachers_count: Number(teachersCount?.count ?? 0),
    courses_count: Number(coursesCount?.count ?? 0),
    purchases_count: Number(purchasesCount?.count ?? 0),
    total_sales_amount: String(salesRow?.amount ?? '0.00'),
    total_topups_amount: String(topupRow?.amount ?? '0.00'),
    pending_topups_count: Number(pendingRow?.count ?? 0),
    total_students_balance: String(balanceRow?.amount ?? '0.00'),
  };
}

function buildDateSeries(start: Date, end: Date) {
  const series: string[] = [];
  const current = new Date(Date.UTC(start.getUTCFullYear(), start.getUTCMonth(), start.getUTCDate()));
  const finalDate = new Date(Date.UTC(end.getUTCFullYear(), end.getUTCMonth(), end.getUTCDate()));

  while (current <= finalDate) {
    series.push(current.toISOString().slice(0, 10));
    current.setUTCDate(current.getUTCDate() + 1);
  }

  return series;
}

export async function salesStats(days: number, from?: string, to?: string) {
  const endDate = to ? new Date(to) : new Date();
  const startDate = from ? new Date(from) : new Date(endDate);
  if (!from) {
    startDate.setUTCDate(startDate.getUTCDate() - (days - 1));
  }

  const rows = await AppDataSource.getRepository(Purchase)
    .createQueryBuilder('purchase')
    .select("DATE_FORMAT(purchase.created_at, '%Y-%m-%d')", 'date')
    .addSelect('COUNT(purchase.id)', 'purchases_count')
    .addSelect('COALESCE(SUM(purchase.pricePaid), 0)', 'amount')
    .where('purchase.created_at >= :from', { from: startDate.toISOString() })
    .andWhere('purchase.created_at <= :to', { to: endDate.toISOString() })
    .groupBy('date')
    .orderBy('date', 'ASC')
    .getRawMany<{ date: string; purchases_count: string; amount: string }>();

  const rowMap = new Map(rows.map((row) => [row.date, row]));
  return buildDateSeries(startDate, endDate).map((date) => {
    const row = rowMap.get(date);
    return {
      date,
      purchases_count: Number(row?.purchases_count ?? 0),
      amount: String(row?.amount ?? '0.00'),
    };
  });
}

export async function topCoursesStats(limit: number, from?: string, to?: string) {
  const query = AppDataSource.getRepository(Purchase)
    .createQueryBuilder('purchase')
    .innerJoin('purchase.course', 'course')
    .leftJoin('course.teacher', 'teacher')
    .select('course.id', 'course_id')
    .addSelect('course.name', 'name')
    .addSelect('teacher.full_name', 'teacher_name')
    .addSelect('COUNT(purchase.id)', 'purchases_count')
    .addSelect('COALESCE(SUM(purchase.pricePaid), 0)', 'revenue')
    .groupBy('course.id')
    .orderBy('purchases_count', 'DESC')
    .addOrderBy('course.id', 'ASC')
    .limit(limit);

  addDateFilter(query, 'purchase', from, to);

  const rows = await query.getRawMany<{ course_id: string; name: string; teacher_name: string | null; purchases_count: string; revenue: string }>();

  return rows.map((row) => ({
    course_id: Number(row.course_id),
    name: row.name,
    teacher_name: row.teacher_name,
    purchases_count: Number(row.purchases_count),
    revenue: String(row.revenue ?? '0.00'),
  }));
}

export async function bySpecializationStats(from?: string, to?: string) {
  const query = AppDataSource.getRepository(Purchase)
    .createQueryBuilder('purchase')
    .innerJoin('purchase.course', 'course')
    .innerJoin('course.specialization', 'specialization')
    .select('specialization.id', 'specialization_id')
    .addSelect('specialization.name', 'name')
    .addSelect('COUNT(purchase.id)', 'purchases_count')
    .addSelect('COALESCE(SUM(purchase.pricePaid), 0)', 'revenue')
    .groupBy('specialization.id')
    .orderBy('purchases_count', 'DESC')
    .addOrderBy('specialization.id', 'ASC');

  addDateFilter(query, 'purchase', from, to);

  const rows = await query.getRawMany<{ specialization_id: string; name: string; purchases_count: string; revenue: string }>();

  return rows.map((row) => ({
    specialization_id: Number(row.specialization_id),
    name: row.name,
    purchases_count: Number(row.purchases_count),
    revenue: String(row.revenue ?? '0.00'),
  }));
}

export async function teachersStats(from?: string, to?: string) {
  return (await loadTeacherRows(from, to)).map(mapTeacherAggregate);
}

export async function teacherPayoutHistory(teacherId: number) {
  return listTeacherPayouts(teacherId);
}
