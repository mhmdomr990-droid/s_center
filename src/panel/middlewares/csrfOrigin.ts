import type { NextFunction, Request, Response } from 'express';
import { timingSafeEqual } from 'crypto';
import { AppError } from '../../utils/AppError';
import { debugPanel } from '../debug';

function getHost(value: string | undefined) {
  if (!value) {
    return null;
  }

  try {
    return new URL(value).host;
  } catch {
    return null;
  }
}

export function csrfOrigin(req: Request, _res: Response, next: NextFunction) {
  if (req.method === 'GET' || req.method === 'HEAD' || req.method === 'OPTIONS') {
    return next();
  }
  
  const requestHost = req.get('host');
  const originHost = getHost(req.get('origin') ?? undefined) ?? getHost(req.get('referer') ?? undefined);
  debugPanel('csrf check', { method: req.method, path: req.originalUrl, requestHost, originHost });

  // For development: be more lenient with origin check
  if (process.env.NODE_ENV === 'development') {
    if (!originHost) {
      debugPanel('csrf skipped origin check in development', { path: req.originalUrl });
    } else if (requestHost !== originHost) {
      return next(new AppError(403, 'تعذر التحقق من مصدر الطلب'));
    }
  } else {
    if (!requestHost || !originHost || requestHost !== originHost) {
      return next(new AppError(403, 'تعذر التحقق من مصدر الطلب'));
    }
  }

  const tokenFromCookie = req.cookies?.panel_csrf_token;
  const tokenFromBody = typeof req.body?.csrf_token === 'string' ? req.body.csrf_token : undefined;
  const tokenFromQuery = typeof req.query?.csrf_token === 'string' ? req.query.csrf_token : undefined;
  const tokenFromHeader = typeof req.get('x-csrf-token') === 'string' ? req.get('x-csrf-token') || undefined : undefined;
  const tokenFromRequest = tokenFromBody || tokenFromQuery || tokenFromHeader;

  if (!tokenFromCookie || !tokenFromRequest) {
    return next(new AppError(403, 'انتهت صلاحية النموذج أو تم التلاعب به'));
  }

  try {
    if (!timingSafeEqual(Buffer.from(tokenFromCookie), Buffer.from(tokenFromRequest))) {
      return next(new AppError(403, 'انتهت صلاحية النموذج أو تم التلاعب به'));
    }
  } catch (error) {
    debugPanel('csrf compare error', { path: req.originalUrl, error: error instanceof Error ? error.message : String(error) });
    return next(new AppError(403, 'انتهت صلاحية النموذج أو تم التلاعب به'));
  }

  next();
}
