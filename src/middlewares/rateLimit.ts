import { ipKeyGenerator, rateLimit } from 'express-rate-limit';

function getUserOrIpKey(req: unknown) {
  const userId = (req as { user?: { id?: number } }).user?.id;
  if (userId !== undefined && userId !== null) {
    return `user:${userId}`;
  }

  return `ip:${ipKeyGenerator((req as { ip?: string }).ip || '')}`;
}

export const generalRateLimit = rateLimit({
  windowMs: 15 * 60 * 1000,
  limit: 300,
  standardHeaders: true,
  legacyHeaders: false,
});

export const authRateLimit = rateLimit({
  windowMs: 15 * 60 * 1000,
  limit: 50,
  standardHeaders: true,
  legacyHeaders: false,
});

export const lectureStreamUrlRateLimit = rateLimit({
  windowMs: 60 * 60 * 1000,
  limit: 20,
  standardHeaders: true,
  legacyHeaders: false,
  keyGenerator: getUserOrIpKey,
});

export const lectureDownloadUrlRateLimit = rateLimit({
  windowMs: 60 * 60 * 1000,
  limit: 5,
  standardHeaders: true,
  legacyHeaders: false,
  keyGenerator: getUserOrIpKey,
});
