import { z } from 'zod';

import { LectureType, TopupStatus } from '../../entities/enums';
import { positiveMoneySchema, signedMoneySchema } from '../../utils/money';
import { idParamSchema } from '../../utils/requestSchemas';

const usernameSchema = z
  .string()
  .trim()
  .toLowerCase()
  .min(3)
  .max(30)
  .regex(/^[a-z0-9_]+$/, 'Username may contain only lowercase letters, numbers, and underscores');

const passwordSchema = z.string().min(8).max(128);

const nameSchema = z.string().trim().min(1).max(120);
const descriptionSchema = z.string().trim().max(5000).optional().nullable();
const contentSchema = z.string().trim().max(50000).optional().nullable();
const urlSchema = z
  .string()
  .trim()
  .max(5000)
  .optional()
  .nullable()
  .refine(
    (value) => !value || /^https?:\/\/.+/.test(value),
    'URL must start with http:// or https://',
  );
const percentageSchema = z
  .union([z.string(), z.number()])
  .transform((value) => String(value).trim())
  .refine((value) => /^\d+(?:\.\d{1,2})?$/.test(value), 'Invalid percentage')
  .refine((value) => Number(value) >= 0 && Number(value) <= 100, 'Percentage must be between 0 and 100');

const optionalTeacherIdSchema = z.preprocess(
  (value) => {
    if (value === '' || value === undefined) {
      return null;
    }

    return value;
  },
  z.coerce.number().int().positive().nullable(),
);

export const adminIdParamSchema = idParamSchema;

export const paginationPageSchema = z
  .object({
    page: z.coerce.number().int().min(1).default(1),
    limit: z.coerce.number().int().min(1).max(100).default(20),
  })
  .strict();

export const publishedBodySchema = z
  .object({
    is_published: z.boolean(),
  })
  .strict();

export const lectureOrderSchema = z
  .object({
    lecture_ids: z.array(z.coerce.number().int().positive()).min(1),
  })
  .strict();

export const specializationCreateSchema = z
  .object({
    name: nameSchema,
    is_published: z.boolean().optional(),
    sort_order: z.coerce.number().int().min(0).optional(),
  })
  .strict();

export const specializationUpdateSchema = specializationCreateSchema.partial().strict();

export const courseCreateSchema = z
  .object({
    specialization_id: z.coerce.number().int().positive(),
    year: z.coerce.number().int().min(1).max(5),
    name: nameSchema,
    description: descriptionSchema,
    price: positiveMoneySchema,
    is_published: z.boolean().optional(),
    sort_order: z.coerce.number().int().min(0).optional(),
    teacher_id: optionalTeacherIdSchema.optional(),
    teacher_percent: percentageSchema.optional(),
  })
  .strict();

export const courseUpdateSchema = courseCreateSchema.partial().strict();

export const lectureCreateSchema = z
  .object({
    course_id: z.coerce.number().int().positive(),
    title: nameSchema,
    type: z.nativeEnum(LectureType),
    url: urlSchema,
    content: contentSchema,
    is_published: z.boolean().optional(),
    sort_order: z.coerce.number().int().min(0).optional(),
  })
  .strict();

export const lectureUpdateSchema = lectureCreateSchema.partial().strict();

export const topupRequestsQuerySchema = z
  .object({
    status: z.nativeEnum(TopupStatus).optional().default(TopupStatus.PENDING),
    page: z.coerce.number().int().min(1).default(1),
    limit: z.coerce.number().int().min(1).max(100).default(20),
  })
  .strict();

export const rejectTopupSchema = z
  .object({
    reason: z.string().trim().min(1).max(1000),
  })
  .strict();

export const activeUserSchema = z
  .object({
    is_active: z.preprocess((value) => {
      if (typeof value === 'string') {
        const normalized = value.trim().toLowerCase();
        if (normalized === 'true' || normalized === '1') {
          return true;
        }
        if (normalized === 'false' || normalized === '0') {
          return false;
        }
      }
      return value;
    }, z.boolean()),
  })
  .strict();

export const adjustBalanceSchema = z
  .object({
    amount: signedMoneySchema,
    description: z.string().trim().min(1).max(1000),
  })
  .strict();

export const adminUsersQuerySchema = z
  .object({
    search: z.string().trim().max(100).optional(),
    role: z.enum(['STUDENT', 'TEACHER', 'ADMIN']).optional(),
    is_active: z.coerce.boolean().optional(),
    is_test: z.coerce.boolean().optional(),
    page: z.coerce.number().int().min(1).default(1),
    limit: z.coerce.number().int().min(1).max(100).default(20),
  })
  .strict();

export const adminCoursesQuerySchema = z
  .object({
    specializationId: z.coerce.number().int().positive().optional(),
    year: z.coerce.number().int().min(1).max(5).optional(),
    teacherId: z.coerce.number().int().positive().optional(),
    is_published: z.coerce.boolean().optional(),
    search: z.string().trim().max(150).optional(),
    page: z.coerce.number().int().min(1).default(1),
    limit: z.coerce.number().int().min(1).max(100).default(20),
  })
  .strict();

export const adminSpecializationsQuerySchema = z
  .object({
    search: z.string().trim().max(120).optional(),
    page: z.coerce.number().int().min(1).default(1),
    limit: z.coerce.number().int().min(1).max(100).default(20),
  })
  .strict();

export const adminLecturesQuerySchema = z
  .object({
    course_id: z.coerce.number().int().positive().optional(),
    page: z.coerce.number().int().min(1).default(1),
    limit: z.coerce.number().int().min(1).max(100).default(20),
  })
  .strict();

export const adminNotificationSchema = z.union([
  z
    .object({
      all: z.literal(true),
      title: z.string().trim().min(1).max(180),
      body: z.string().trim().min(1).max(5000),
    })
    .strict(),
  z
    .object({
      user_id: z.coerce.number().int().positive(),
      title: z.string().trim().min(1).max(180),
      body: z.string().trim().min(1).max(5000),
    })
    .strict(),
]);

export const teacherCreateSchema = z
  .object({
    username: usernameSchema,
    full_name: z.string().trim().min(2).max(120),
    password: passwordSchema,
  })
  .strict();

export const studentCreateSchema = z
  .object({
    username: usernameSchema,
    full_name: z.string().trim().min(2).max(120),
    password: passwordSchema,
    device_id: z.string().trim().max(255).optional().nullable(),
  })
  .strict();

export const adminCreateSchema = z
  .object({
    username: usernameSchema,
    full_name: z.string().trim().min(2).max(120),
    password: passwordSchema,
  })
  .strict();

export const teacherPayoutSchema = z
  .object({
    amount: positiveMoneySchema,
    note: z.string().trim().max(1000).optional().nullable(),
  })
  .strict();

export const resetPasswordSchema = z
  .object({
    new_password: passwordSchema,
  })
  .strict();

export const adminStatsRangeSchema = z
  .object({
    from: z.string().datetime().optional(),
    to: z.string().datetime().optional(),
  })
  .strict();

export const adminSalesStatsSchema = z
  .object({
    days: z.coerce.number().int().min(1).max(365).default(30),
    from: z.string().datetime().optional(),
    to: z.string().datetime().optional(),
  })
  .strict();

export const adminTopCoursesStatsSchema = z
  .object({
    limit: z.coerce.number().int().min(1).max(100).default(10),
    from: z.string().datetime().optional(),
    to: z.string().datetime().optional(),
  })
  .strict();

export const adminTeachersStatsSchema = z
  .object({
    from: z.string().datetime().optional(),
    to: z.string().datetime().optional(),
  })
  .strict();
