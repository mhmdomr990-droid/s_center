import { z } from 'zod';

const usernameSchema = z
  .string()
  .trim()
  .toLowerCase()
  .min(3, 'اسم المستخدم يجب أن يكون 3 أحرف على الأقل')
  .max(30, 'اسم المستخدم لا يمكن أن يتجاوز 30 حرفًا')
  .regex(/^[a-z0-9_]+$/, 'اسم المستخدم يسمح فقط بحروف صغيرة، أرقام، وشرطة سفلية');

const passwordSchema = z.string().min(8, 'كلمة المرور يجب أن تكون 8 أحرف على الأقل').max(128, 'كلمة المرور لا يمكن أن تتجاوز 128 حرفًا');
const deviceIdSchema = z.string().trim().min(1, 'معرّف الجهاز لا يمكن أن يكون فارغًا').max(255, 'معرّف الجهاز لا يمكن أن يتجاوز 255 حرفًا');

const phoneSchema = z
  .string()
  .trim()
  .transform((value) => (value === '' ? null : value))
  .nullable()
  .refine((value) => !value || /^\+?[0-9\s\-()]{7,30}$/.test(value), 'Phone number is invalid');

export const registerSchema = z
  .object({
    username: usernameSchema,
    full_name: z.string().trim().min(2).max(120),
    password: passwordSchema,
    phone: phoneSchema.optional(),
    specialization_id: z.coerce.number().int().positive().nullable().optional(),
    device_id: deviceIdSchema,
  })
  .strict();

export const loginSchema = z
  .object({
    username: usernameSchema,
    password: passwordSchema,
    device_id: deviceIdSchema.optional(),
  })
  .strict();

export const changePasswordSchema = z
  .object({
    old_password: passwordSchema,
    new_password: passwordSchema,
  })
  .strict();

export const updateProfileSchema = z
  .object({
    full_name: z.string().trim().min(2, 'الاسم الكامل يجب أن يكون 2 أحرف على الأقل').max(120, 'الاسم الكامل لا يمكن أن يتجاوز 120 حرفًا').optional(),
    phone: phoneSchema.optional(),
    specialization_id: z.coerce.number().int().positive().nullable().optional(),
  })
  .strict();
