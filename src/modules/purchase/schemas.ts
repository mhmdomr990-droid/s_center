import { z } from 'zod';

import { idParamSchema } from '../../utils/requestSchemas';

export const purchaseCourseParamSchema = idParamSchema;

export const courseSwapRequestSchema = z
  .object({
    old_purchase_id: z.coerce.number().int().positive(),
    new_course_id: z.coerce.number().int().positive(),
    reason: z.string().trim().max(500).optional().nullable(),
  })
  .strict();

export const courseSwapDecisionSchema = z
  .object({
    admin_note: z.string().trim().max(500).optional().nullable(),
    reason: z.string().trim().max(500).optional().nullable(),
  })
  .strict();
