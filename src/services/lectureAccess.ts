import type { EntityManager } from 'typeorm';

import { Lecture } from '../entities/Lecture';
import { LectureGrant } from '../entities/LectureGrant';
import { Purchase } from '../entities/Purchase';

export async function findStudentAccessibleLectureIds(
  manager: EntityManager,
  input: { userId: number; courseId: number; lectureIds: number[] },
) {
  if (!input.lectureIds.length) {
    return new Set<number>();
  }

  const rows = await manager
    .getRepository(Lecture)
    .createQueryBuilder('lecture')
    .leftJoin(
      Purchase,
      'purchase',
      'purchase.user_id = :userId AND purchase.course_id = lecture.course_id',
      { userId: input.userId },
    )
    .leftJoin(
      LectureGrant,
      'lecture_grant',
      'lecture_grant.user_id = :userId AND lecture_grant.lecture_id = lecture.id AND lecture_grant.revoked = false',
      { userId: input.userId },
    )
    .select('lecture.id', 'lecture_id')
    .where('lecture.course_id = :courseId', { courseId: input.courseId })
    .andWhere('lecture.id IN (:...lectureIds)', { lectureIds: input.lectureIds })
    .andWhere('(purchase.id IS NOT NULL OR lecture_grant.id IS NOT NULL)')
    .getRawMany<{ lecture_id: number | string }>();

  return new Set(rows.map((row) => Number(row.lecture_id)));
}

export async function hasStudentLectureAccess(
  manager: EntityManager,
  input: { userId: number; courseId: number; lectureId: number },
) {
  const accessibleIds = await findStudentAccessibleLectureIds(manager, {
    userId: input.userId,
    courseId: input.courseId,
    lectureIds: [input.lectureId],
  });

  return accessibleIds.has(input.lectureId);
}

export async function hasStudentCourseAccess(
  manager: EntityManager,
  input: { userId: number; courseId: number },
) {
  return manager.getRepository(Purchase).exist({
    where: { user: { id: input.userId }, course: { id: input.courseId } },
  });
}
