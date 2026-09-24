import { AppDataSource } from '../../config/data-source';
import { Course } from '../../entities/Course';
import { Lecture } from '../../entities/Lecture';
import { Purchase } from '../../entities/Purchase';
import { TeacherPayout } from '../../entities/TeacherPayout';
import { LectureType, LectureUploadStatus } from '../../entities/enums';
import { User } from '../../entities/User';
import { AppError } from '../../utils/AppError';
import { centsToMoney, toCents } from '../../utils/money';
import { deleteStoredVideoFile, detectVideoDurationSeconds, type StoredVideoFile } from '../../services/media';

function toNumber(value: unknown): number {
  if (typeof value === 'number') {
    return value;
  }
  if (typeof value === 'string') {
    return Number(value);
  }
  return 0;
}

function toMoney(value: unknown): string {
  if (value === null || value === undefined || value === '') {
    return '0.00';
  }
  return String(value);
}

async function assertOwnedCourse(courseId: number, teacherId: number) {
  const course = await AppDataSource.getRepository(Course).findOne({
    where: { id: courseId, teacher: { id: teacherId } },
    relations: { teacher: true, specialization: true },
  });

  if (!course) {
    throw new AppError(403, 'Access denied');
  }

  return course;
}

async function assertOwnedLecture(lectureId: number, teacherId: number) {
  const lecture = await AppDataSource.getRepository(Lecture).findOne({
    where: { id: lectureId },
    relations: { course: { teacher: true, specialization: true }, createdBy: true },
  });

  if (!lecture || lecture.course.teacher?.id !== teacherId) {
    throw new AppError(403, 'Access denied');
  }

  return lecture;
}

function mapCourseRow(row: Record<string, unknown>) {
  return {
    course_id: toNumber(row.course_id),
    name: String(row.name ?? ''),
    year: toNumber(row.year),
    description: row.description === null ? null : row.description ?? null,
    price: toMoney(row.price),
    is_published: Boolean(row.is_published),
    sort_order: toNumber(row.sort_order),
    purchases_count: toNumber(row.purchases_count),
    earned: toMoney(row.earned),
  };
}

function mapLecture(lecture: Lecture) {
  return {
    id: lecture.id,
    course_id: lecture.course.id,
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

function mapPayout(payout: TeacherPayout) {
  return {
    id: payout.id,
    amount: payout.amount,
    note: payout.note,
    created_by: payout.createdBy.id,
    created_at: payout.createdAt,
  };
}

export async function listMyCourses(teacherId: number) {
  const rows = await AppDataSource.getRepository(Course)
    .createQueryBuilder('course')
    // Course ownership is live (course.teacher_id), but earnings must use purchase.teacher_id snapshots.
    .leftJoin('course.purchases', 'purchase', 'purchase.teacher_id = :teacherId', { teacherId })
    .select('course.id', 'course_id')
    .addSelect('course.name', 'name')
    .addSelect('course.year', 'year')
    .addSelect('course.description', 'description')
    .addSelect('course.price', 'price')
    .addSelect('course.isPublished', 'is_published')
    .addSelect('course.sortOrder', 'sort_order')
    .addSelect('COUNT(purchase.id)', 'purchases_count')
    .addSelect('COALESCE(SUM(purchase.teacher_share), 0)', 'earned')
    .where('course.teacher_id = :teacherId', { teacherId })
    .groupBy('course.id')
    .orderBy('course.sortOrder', 'ASC')
    .addOrderBy('course.id', 'ASC')
    .getRawMany();

  return rows.map(mapCourseRow);
}

export async function getTeacherCourseById(teacherId: number, courseId: number) {
  const course = await assertOwnedCourse(courseId, teacherId);
  const stats = await listMyCourses(teacherId);
  const summary = stats.find((item) => item.course_id === courseId);

  return {
    course_id: course.id,
    name: course.name,
    year: course.year,
    description: course.description,
    price: course.price,
    teacher_percent: course.teacherPercent,
    is_published: course.isPublished,
    sort_order: course.sortOrder,
    purchases_count: summary?.purchases_count ?? 0,
    earned: summary?.earned ?? '0.00',
  };
}

export async function updateTeacherCourseDescription(teacherId: number, courseId: number, input: { description?: string | null }) {
  const course = await assertOwnedCourse(courseId, teacherId);
  if (input.description !== undefined) {
    course.description = input.description;
  }

  const saved = await AppDataSource.getRepository(Course).save(course);
  return getTeacherCourseById(teacherId, saved.id);
}

export async function listCourseLectures(teacherId: number, courseId: number) {
  await assertOwnedCourse(courseId, teacherId);

  const lectures = await AppDataSource.getRepository(Lecture).find({
    where: { course: { id: courseId } },
    relations: { course: true, createdBy: true },
    order: { sortOrder: 'ASC', id: 'ASC' },
  });

  return lectures.map(mapLecture);
}

export async function createLectureForTeacher(
  teacherId: number,
  courseId: number,
  input: { title: string; type: LectureType; url?: string | null; content?: string | null; sort_order?: number },
  file?: StoredVideoFile | null,
) {
  const course = await assertOwnedCourse(courseId, teacherId);
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
      createdBy: { id: teacherId } as User,
      title: input.title,
      type: input.type,
      url: isVideo ? null : normalizedUrl ?? null,
      storageFilename: isVideo ? videoMetadata?.storageFilename ?? null : null,
      fileSize: isVideo ? videoMetadata?.fileSize ?? null : null,
      durationSeconds: isVideo ? videoMetadata?.durationSeconds ?? null : null,
      uploadStatus: LectureUploadStatus.READY,
      content: isVideo ? null : normalizedContent ?? null,
      isPublished: true,
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

export async function updateTeacherLecture(
  teacherId: number,
  lectureId: number,
  input: Partial<{ title: string; type: LectureType; url: string | null; content: string | null; sort_order: number }>,
  file?: StoredVideoFile | null,
) {
  const repository = AppDataSource.getRepository(Lecture);
  const lecture = await assertOwnedLecture(lectureId, teacherId);
  const nextType = input.type ?? lecture.type;
  const oldVideoFilename = lecture.storageFilename;
  const replacingVideo = nextType === LectureType.VIDEO && !!file;
  const removingVideo = lecture.type === LectureType.VIDEO && nextType !== LectureType.VIDEO;

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

  if (input.title !== undefined) lecture.title = input.title;
  if (input.type !== undefined) lecture.type = nextType;
  if (nextType === LectureType.VIDEO) {
    lecture.url = null;
    lecture.content = null;
  } else {
    if (input.url !== undefined) lecture.url = normalizedUrl ?? null;
    if (input.content !== undefined) lecture.content = normalizedContent ?? null;
  }
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

  let uploadedFilename: string | null = file?.filename ?? null;

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

export async function archiveTeacherLecture(teacherId: number, lectureId: number) {
  const repository = AppDataSource.getRepository(Lecture);
  const lecture = await assertOwnedLecture(lectureId, teacherId);
  lecture.isPublished = false;
  return mapLecture(await repository.save(lecture));
}

export async function setTeacherLecturePublished(teacherId: number, lectureId: number, isPublished: boolean) {
  const repository = AppDataSource.getRepository(Lecture);
  const lecture = await assertOwnedLecture(lectureId, teacherId);
  lecture.isPublished = isPublished;
  return mapLecture(await repository.save(lecture));
}

export async function reorderTeacherCourseLectures(teacherId: number, courseId: number, lectureIds: number[]) {
  return AppDataSource.transaction(async (manager) => {
    await assertOwnedCourse(courseId, teacherId);
    const repository = manager.getRepository(Lecture);
    const lectures = await repository.find({
      where: { course: { id: courseId } },
      relations: { course: { teacher: true }, createdBy: true },
      order: { sortOrder: 'ASC', id: 'ASC' },
      lock: { mode: 'pessimistic_write' },
    });

    if (lectures.some((lecture) => lecture.course.teacher?.id !== teacherId) || lectures.length !== lectureIds.length) {
      throw new AppError(400, 'lecture_ids must include all course lectures exactly once');
    }

    const existingIds = lectures.map((lecture) => lecture.id).sort((left, right) => left - right);
    const requestedIds = [...lectureIds].sort((left, right) => left - right);
    if (existingIds.some((id, index) => id !== requestedIds[index])) {
      throw new AppError(400, 'lecture_ids must include all course lectures exactly once');
    }

    const map = new Map(lectures.map((lecture) => [lecture.id, lecture]));
    for (let index = 0; index < lectureIds.length; index += 1) {
      const lecture = map.get(lectureIds[index]);
      if (!lecture) {
        throw new AppError(400, 'lecture_ids must include all course lectures exactly once');
      }
      lecture.sortOrder = index;
      await repository.save(lecture);
    }

    return listCourseLectures(teacherId, courseId);
  });
}

export async function previewTeacherCourseLectures(teacherId: number, courseId: number) {
  await assertOwnedCourse(courseId, teacherId);
  const lectures = await AppDataSource.getRepository(Lecture).find({
    where: { course: { id: courseId }, isPublished: true },
    relations: { course: true, createdBy: true },
    order: { sortOrder: 'ASC', id: 'ASC' },
  });

  return lectures.map(mapLecture);
}

export async function getTeacherDashboard(teacherId: number, days: number) {
  const stats = await getTeacherStats(teacherId);
  const endDate = new Date();
  const startDate = new Date(endDate);
  startDate.setUTCDate(startDate.getUTCDate() - (days - 1));

  const rows = await AppDataSource.getRepository(Course)
    .createQueryBuilder('course')
    .innerJoin('course.purchases', 'purchase')
    .select("DATE_FORMAT(CONVERT_TZ(purchase.created_at, '+00:00', '+03:00'), '%Y-%m-%d')", 'date')
    .addSelect('COUNT(purchase.id)', 'purchases_count')
    .addSelect('COALESCE(SUM(purchase.teacher_share), 0)', 'earned')
    // Earnings attribution is historical and must come from purchase.teacher_id snapshots.
    .where('purchase.teacher_id = :teacherId', { teacherId })
    .andWhere('purchase.created_at >= :from', { from: startDate.toISOString() })
    .andWhere('purchase.created_at <= :to', { to: endDate.toISOString() })
    .groupBy('date')
    .orderBy('date', 'ASC')
    .getRawMany<{ date: string; purchases_count: string; earned: string }>();

  const map = new Map(rows.map((row) => [row.date, row]));
  const series: Array<{ date: string; purchases_count: number; earned: string }> = [];
  const current = new Date(Date.UTC(startDate.getUTCFullYear(), startDate.getUTCMonth(), startDate.getUTCDate()));
  const finalDate = new Date(Date.UTC(endDate.getUTCFullYear(), endDate.getUTCMonth(), endDate.getUTCDate()));
  while (current <= finalDate) {
    const date = current.toISOString().slice(0, 10);
    const row = map.get(date);
    series.push({
      date,
      purchases_count: Number(row?.purchases_count ?? 0),
      earned: String(row?.earned ?? '0.00'),
    });
    current.setUTCDate(current.getUTCDate() + 1);
  }

  return {
    ...stats,
    daily_sales: series,
    per_course: stats.courses,
  };
}

export async function getTeacherMonthlyEarnings(teacherId: number, month?: string) {
  const target = month ?? new Date().toISOString().slice(0, 7);
  const [year, monthNumber] = target.split('-').map(Number);
  const from = new Date(Date.UTC(year, monthNumber - 1, 1));
  const to = new Date(Date.UTC(year, monthNumber, 0, 23, 59, 59, 999));

  const perCourse = await AppDataSource.getRepository(Purchase)
    .createQueryBuilder('purchase')
    .innerJoin('purchase.course', 'course')
    .select('course.id', 'course_id')
    .addSelect('course.name', 'name')
    .addSelect('COUNT(purchase.id)', 'purchases_count')
    .addSelect('COALESCE(SUM(purchase.teacher_share), 0)', 'earned')
    // Earnings attribution is historical and must come from purchase.teacher_id snapshots.
    .where('purchase.teacher_id = :teacherId', { teacherId })
    .andWhere('purchase.created_at >= :from AND purchase.created_at <= :to', {
      from: from.toISOString(),
      to: to.toISOString(),
    })
    .groupBy('course.id')
    .orderBy('MAX(course.sort_order)', 'ASC')
    .addOrderBy('course.id', 'ASC')
    .getRawMany<{ course_id: string; name: string; purchases_count: string; earned: string }>();

  const payouts = await AppDataSource.getRepository(TeacherPayout).find({
    where: { teacher: { id: teacherId } },
    relations: { createdBy: true },
    order: { createdAt: 'DESC', id: 'DESC' },
  });

  const monthlyPayouts = payouts.filter((item) => item.createdAt >= from && item.createdAt <= to).map(mapPayout);

  return {
    month: target,
    courses: perCourse.map((row) => ({
      course_id: Number(row.course_id),
      name: row.name,
      purchases_count: Number(row.purchases_count ?? 0),
      earned: String(row.earned ?? '0.00'),
    })),
    payouts: monthlyPayouts,
  };
}

export async function getTeacherStats(teacherId: number) {
  const [courses, payoutRow] = await Promise.all([
    AppDataSource.getRepository(Purchase)
      .createQueryBuilder('purchase')
      .innerJoin('purchase.course', 'course')
      .select('course.id', 'course_id')
      .addSelect('course.name', 'name')
      .addSelect('COUNT(purchase.id)', 'purchases_count')
      .addSelect('COALESCE(SUM(purchase.teacher_share), 0)', 'earned')
      // Earnings attribution is historical and must come from purchase.teacher_id snapshots.
      .where('purchase.teacher_id = :teacherId', { teacherId })
      .groupBy('course.id')
      .orderBy('MAX(course.sort_order)', 'ASC')
      .addOrderBy('course.id', 'ASC')
      .getRawMany(),
    AppDataSource.getRepository(TeacherPayout)
      .createQueryBuilder('payout')
      .select('COALESCE(SUM(payout.amount), 0)', 'total_paid')
      .where('payout.teacher_id = :teacherId', { teacherId })
      .getRawOne(),
  ]);

  let totalPurchases = 0;
  let totalEarnedCents = 0n;

  const mappedCourses = courses.map((row) => {
    const purchasesCount = toNumber(row.purchases_count);
    const earned = toMoney(row.earned);
    totalPurchases += purchasesCount;
    totalEarnedCents += toCents(earned);
    return {
      course_id: toNumber(row.course_id),
      name: String(row.name ?? ''),
      purchases_count: purchasesCount,
      earned,
    };
  });

  const totalPaid = toMoney(payoutRow?.total_paid);
  const remaining = centsToMoney(totalEarnedCents - toCents(totalPaid));

  return {
    total_purchases: totalPurchases,
    total_earned: centsToMoney(totalEarnedCents),
    total_paid: totalPaid,
    remaining,
    courses: mappedCourses,
  };
}

export async function listTeacherPayouts(teacherId: number) {
  const payouts = await AppDataSource.getRepository(TeacherPayout).find({
    where: { teacher: { id: teacherId } },
    relations: { createdBy: true },
    order: { createdAt: 'DESC', id: 'DESC' },
  });

  return payouts.map(mapPayout);
}
