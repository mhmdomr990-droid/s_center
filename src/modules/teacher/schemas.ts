import { z } from 'zod';

import { LectureType } from '../../entities/enums';
import { idParamSchema } from '../../utils/requestSchemas';

export const teacherCourseIdParamSchema = idParamSchema;
export const teacherLectureIdParamSchema = idParamSchema;

export const teacherLectureCreateSchema = z
  .object({
    title: z.string().trim().min(1).max(150),
    type: z.nativeEnum(LectureType),
    url: z.string().trim().max(5000).optional().nullable(),
    content: z.string().trim().max(50000).optional().nullable(),
    sort_order: z.coerce.number().int().min(0).optional(),
  })
  .strict();

export const teacherLectureUpdateSchema = teacherLectureCreateSchema.partial().strict();

export const teacherCourseUpdateSchema = z
  .object({
    description: z.string().trim().max(5000).nullable().optional(),
  })
  .strict();

export const teacherLecturePublishSchema = z
  .object({
    is_published: z.boolean(),
  })
  .strict();

export const teacherLectureOrderSchema = z
  .object({
    lecture_ids: z.array(z.coerce.number().int().positive()).min(1),
  })
  .strict();

export const teacherStatsQuerySchema = z
  .object({
    from: z.string().datetime().optional(),
    to: z.string().datetime().optional(),
  })
  .strict();

export const teacherDashboardQuerySchema = z
  .object({
    days: z.coerce.number().int().refine((value) => [7, 30, 90].includes(value), 'days must be 7, 30, or 90').default(30),
  })
  .strict();

export const teacherPurchasesQuerySchema = z
  .object({
    course_id: z.coerce.number().int().positive().optional(),
    search: z.string().trim().max(100).optional(),
    page: z.coerce.number().int().positive().optional(),
    limit: z.coerce.number().int().positive().optional(),
  })
  .strict();

export const teacherEarningsQuerySchema = z
  .object({
    month: z.string().regex(/^\d{4}-\d{2}$/).optional(),
  })
  .strict();
