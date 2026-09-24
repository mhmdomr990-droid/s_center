import { AppDataSource } from '../../config/data-source';
import { Course } from '../../entities/Course';
import { Lecture } from '../../entities/Lecture';
import { Purchase } from '../../entities/Purchase';
import { Specialization } from '../../entities/Specialization';
import { LectureType, UserRole } from '../../entities/enums';
import { User } from '../../entities/User';
import { AppError } from '../../utils/AppError';

function isPurchasedCourse(purchasedCourseIds: Set<number>, courseId: number) {
  return purchasedCourseIds.has(courseId);
}

export async function listSpecializations() {
  const specializations = await AppDataSource.getRepository(Specialization).find({
    where: { isPublished: true },
    order: { sortOrder: 'ASC', id: 'ASC' },
  });

  return specializations.map((specialization) => ({
    id: specialization.id,
    name: specialization.name,
    is_published: specialization.isPublished,
    sort_order: specialization.sortOrder,
  }));
}

export async function listCourses(userId: number, filters: { specializationId?: number; year?: number }) {
  const courseRepository = AppDataSource.getRepository(Course);
  const purchaseRepository = AppDataSource.getRepository(Purchase);

  const purchasedCourses = await purchaseRepository.find({
    where: { user: { id: userId } },
    relations: { course: true },
  });
  const purchasedCourseIds = new Set(purchasedCourses.map((purchase) => purchase.course.id));

  const courses = await courseRepository.find({
    relations: { specialization: true, teacher: true },
    where: {
      isPublished: true,
      specialization: { isPublished: true, ...(filters.specializationId ? { id: filters.specializationId } : {}) },
      ...(filters.year ? { year: filters.year } : {}),
    },
    order: { sortOrder: 'ASC', id: 'ASC' },
  });

  return courses.map((course) => ({
    id: course.id,
    specialization_id: course.specialization.id,
    year: course.year,
    name: course.name,
    description: course.description,
    price: course.price,
    is_published: course.isPublished,
    sort_order: course.sortOrder,
    teacher_full_name: course.teacher ? course.teacher.fullName : null,
    purchased: isPurchasedCourse(purchasedCourseIds, course.id),
  }));
}

export async function listLectures(user: User, courseId: number) {
  const course = await AppDataSource.getRepository(Course).findOne({
    where: { id: courseId, isPublished: true, specialization: { isPublished: true } },
    relations: { specialization: true },
  });

  if (!course) {
    throw new AppError(404, 'Course not found');
  }

  const purchaseRepository = AppDataSource.getRepository(Purchase);
  const purchased = user.role === UserRole.ADMIN
    ? true
    : !!(await purchaseRepository.findOne({ where: { user: { id: user.id }, course: { id: course.id } } }));

  const lectures = await AppDataSource.getRepository(Lecture).find({
    where: { course: { id: course.id }, isPublished: true },
    order: { sortOrder: 'ASC', id: 'ASC' },
  });

  if (purchased) {
    return lectures.map((lecture) => ({
      id: lecture.id,
      title: lecture.title,
      type: lecture.type,
      url: lecture.type === LectureType.VIDEO ? null : lecture.url,
      content: lecture.content,
      is_published: lecture.isPublished,
      sort_order: lecture.sortOrder,
    }));
  }

  return lectures.map((lecture) => ({
    id: lecture.id,
    title: lecture.title,
    type: lecture.type,
    url: null,
    content: null,
    is_published: lecture.isPublished,
    sort_order: lecture.sortOrder,
    locked: true,
  }));
}
