import 'dotenv/config';

import { z } from 'zod';

function parseTrustProxy(rawValue: string | undefined, nodeEnv: 'development' | 'test' | 'production'): boolean | number | string {
  if (rawValue === undefined || rawValue.trim() === '') {
    return nodeEnv === 'production' ? 1 : false;
  }

  const normalized = rawValue.trim().toLowerCase();
  if (normalized === 'true') {
    return true;
  }

  if (normalized === 'false') {
    return false;
  }

  if (/^\d+$/.test(normalized)) {
    return Number.parseInt(normalized, 10);
  }

  return rawValue.trim();
}

const envSchema = z.object({
  NODE_ENV: z.enum(['development', 'test', 'production']).default('development'),
  PORT: z.coerce.number().int().positive().default(3000),
  TRUST_PROXY: z.string().optional(),
  DB_HOST: z.string().min(1),
  DB_PORT: z.coerce.number().int().positive().default(3306),
  DB_USER: z.string().min(1),
  DB_PASSWORD: z.string().default(''),
  DB_NAME: z.string().min(1),
  DB_NAME_TEST: z.string().min(1).optional(),
  DB_SYNC: z
    .string()
    .default('false')
    .transform((value) => value === 'true'),
  JWT_SECRET: z.string().min(1),
  JWT_EXPIRES_IN: z.string().min(1),
  STAFF_JWT_EXPIRES_IN: z.string().optional(),
  CORS_ORIGINS: z.string().min(1),
  VIDEO_STORAGE_PATH: z.string().min(1).optional(),
  VIDEO_MAX_SIZE_MB: z.coerce.number().int().positive().default(2048),
  VIDEO_SIGNING_SECRET: z.string().min(1).optional(),
  DOWNLOAD_URL_EXPIRY_MINUTES: z.coerce.number().int().positive().default(120),
  DOWNLOAD_TTL_DAYS: z.coerce.number().int().positive().default(100),
  ADMIN_USERNAME: z.string().default('asmaa'),
  ADMIN_PASSWORD: z.string().default('asmaa2026'),
  RATE_LIMIT_GENERAL_WINDOW_MINUTES: z.coerce.number().int().positive().default(15),
  RATE_LIMIT_GENERAL_MAX: z.coerce.number().int().positive().default(600),
  RATE_LIMIT_GENERAL_STAFF_MAX: z.coerce.number().int().positive().default(3000),
  RATE_LIMIT_LOGIN_WINDOW_MINUTES: z.coerce.number().int().positive().default(15),
  RATE_LIMIT_LOGIN_MAX: z.coerce.number().int().positive().default(10),
  RATE_LIMIT_SENSITIVE_WINDOW_MINUTES: z.coerce.number().int().positive().default(15),
  RATE_LIMIT_SENSITIVE_MAX: z.coerce.number().int().positive().default(60),
  RATE_LIMIT_UPLOAD_WINDOW_MINUTES: z.coerce.number().int().positive().default(60),
  RATE_LIMIT_UPLOAD_MAX: z.coerce.number().int().positive().default(60),
  DEBUG_PANEL: z
    .string()
    .optional()
    .transform((value) => value === 'true'),
});

const parsed = envSchema.safeParse(process.env);

if (!parsed.success) {
  const message = parsed.error.issues.map((issue) => issue.message).join(', ');
  throw new Error(message || 'Invalid environment configuration');
}

const corsOrigins = parsed.data.CORS_ORIGINS.split(',').map((value) => value.trim()).filter(Boolean);

if (corsOrigins.length === 0) {
  throw new Error('CORS_ORIGINS must contain at least one origin');
}

export const env = {
  ...parsed.data,
  DB_NAME: parsed.data.NODE_ENV === 'test' && parsed.data.DB_NAME_TEST ? parsed.data.DB_NAME_TEST : parsed.data.DB_NAME,
  TRUST_PROXY: parseTrustProxy(parsed.data.TRUST_PROXY, parsed.data.NODE_ENV),
  STAFF_JWT_EXPIRES_IN: parsed.data.STAFF_JWT_EXPIRES_IN || parsed.data.JWT_EXPIRES_IN,
  VIDEO_STORAGE_PATH: parsed.data.VIDEO_STORAGE_PATH || 'storage/videos',
  VIDEO_SIGNING_SECRET: parsed.data.VIDEO_SIGNING_SECRET || parsed.data.JWT_SECRET,
  CORS_ORIGINS: corsOrigins,
};
