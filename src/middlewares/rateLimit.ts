import type { NextFunction, Request, Response } from 'express';
import jwt from 'jsonwebtoken';
import { ipKeyGenerator, rateLimit } from 'express-rate-limit';

import { env } from '../config/env';
import { UserRole } from '../entities/enums';

interface TokenPayload {
  userId?: number;
  role?: UserRole;
}

function getIpKey(req: Request) {
  return `ip:${ipKeyGenerator(req.ip || '')}`;
}

function getUserKey(req: Request) {
  const userId = req.user?.id;
  if (userId !== undefined && userId !== null) {
    return `user:${userId}`;
  }

  return getIpKey(req);
}

function getTokenPayload(req: Request): TokenPayload | null {
  const header = req.headers.authorization;
  if (!header?.startsWith('Bearer ')) {
    return null;
  }

  const token = header.slice('Bearer '.length).trim();
  if (!token) {
    return null;
  }

  try {
    return jwt.verify(token, env.JWT_SECRET) as TokenPayload;
  } catch {
    return null;
  }
}

function getGeneralKey(req: Request) {
  const payload = getTokenPayload(req);
  if (payload?.userId) {
    return `user:${payload.userId}`;
  }

  return getIpKey(req);
}

function getLoginUsernameKey(req: Request) {
  const usernameInput = req.body && typeof req.body === 'object' ? (req.body as { username?: unknown }).username : undefined;
  const normalizedUsername = typeof usernameInput === 'string' ? usernameInput.trim().toLowerCase() : 'unknown';
  return `${getIpKey(req)}:username:${normalizedUsername || 'unknown'}`;
}

function getRetryAfterSeconds(req: Request, windowMs: number) {
  const resetTime = (req as Request & { rateLimit?: { resetTime?: Date } }).rateLimit?.resetTime;
  if (resetTime instanceof Date) {
    return Math.max(1, Math.ceil((resetTime.getTime() - Date.now()) / 1000));
  }

  return Math.max(1, Math.ceil(windowMs / 1000));
}

function logLimitHit(req: Request, limiterName: string) {
  const userId = req.user?.id ?? 'anonymous';
  const safeIp = req.ip || 'unknown';
  console.warn(`[rate-limit] name=${limiterName} ip=${safeIp} user=${userId} route=${req.method} ${req.originalUrl}`);
}

function createLimitHandler(limiterName: string, windowMs: number) {
  return (req: Request, res: Response, _next: NextFunction) => {
    const retryAfterSeconds = getRetryAfterSeconds(req, windowMs);
    const retryAfterMinutes = Math.max(1, Math.ceil(retryAfterSeconds / 60));

    logLimitHit(req, limiterName);
    res.setHeader('Retry-After', String(retryAfterSeconds));

    res.status(429).json({
      success: false,
      message: `محاولات كثيرة، حاول بعد ${retryAfterMinutes} دقيقة`,
      retry_after_seconds: retryAfterSeconds,
    });
  };
}

const generalWindowMs = env.RATE_LIMIT_GENERAL_WINDOW_MINUTES * 60 * 1000;
const loginWindowMs = env.RATE_LIMIT_LOGIN_WINDOW_MINUTES * 60 * 1000;
const sensitiveWindowMs = env.RATE_LIMIT_SENSITIVE_WINDOW_MINUTES * 60 * 1000;
const uploadWindowMs = env.RATE_LIMIT_UPLOAD_WINDOW_MINUTES * 60 * 1000;

export const generalRateLimit = rateLimit({
  windowMs: generalWindowMs,
  limit: (req) => {
    const payload = getTokenPayload(req);
    if (payload?.role === UserRole.ADMIN || payload?.role === UserRole.TEACHER) {
      return env.RATE_LIMIT_GENERAL_STAFF_MAX;
    }

    return env.RATE_LIMIT_GENERAL_MAX;
  },
  keyGenerator: getGeneralKey,
  standardHeaders: true,
  legacyHeaders: false,
  skip: (req) => {
    const apiPath = req.path;
    const isHealth = apiPath === '/health';
    const isMedia = apiPath.startsWith('/media/');
    const isUploadRoute =
      (req.method === 'POST' &&
        (apiPath === '/admin/lectures' || /^\/teacher\/courses\/[^/]+\/lectures$/.test(apiPath))) ||
      ((req.method === 'PATCH' || req.method === 'PUT') && (apiPath.startsWith('/admin/lectures/') || apiPath.startsWith('/teacher/lectures/')));

    return isHealth || isMedia || isUploadRoute;
  },
  handler: createLimitHandler('general-api', generalWindowMs),
});

export const loginRegisterRateLimit = rateLimit({
  windowMs: loginWindowMs,
  limit: env.RATE_LIMIT_LOGIN_MAX,
  keyGenerator: getLoginUsernameKey,
  skipSuccessfulRequests: true,
  standardHeaders: true,
  legacyHeaders: false,
  handler: createLimitHandler('login-register', loginWindowMs),
});

export const panelLoginRateLimit = rateLimit({
  windowMs: loginWindowMs,
  limit: env.RATE_LIMIT_LOGIN_MAX,
  keyGenerator: getLoginUsernameKey,
  skipSuccessfulRequests: true,
  standardHeaders: true,
  legacyHeaders: false,
  handler: createLimitHandler('panel-login', loginWindowMs),
});

export const sensitiveActionRateLimit = rateLimit({
  windowMs: sensitiveWindowMs,
  limit: env.RATE_LIMIT_SENSITIVE_MAX,
  keyGenerator: getUserKey,
  standardHeaders: true,
  legacyHeaders: false,
  handler: createLimitHandler('sensitive-action', sensitiveWindowMs),
});

export const uploadRateLimit = rateLimit({
  windowMs: uploadWindowMs,
  limit: env.RATE_LIMIT_UPLOAD_MAX,
  keyGenerator: getUserKey,
  standardHeaders: true,
  legacyHeaders: false,
  handler: createLimitHandler('lecture-upload', uploadWindowMs),
});
