import type { NextFunction, Request, Response } from 'express';
import { QueryFailedError } from 'typeorm';
import { ZodError } from 'zod';

import { AppError } from '../utils/AppError';
import { setFlash } from '../panel/middlewares/flash';

function isPanelRequest(req: Request) {
  return req.originalUrl.startsWith('/panel');
}

function formatPanelErrorMessage(message: string) {
  const normalized = message.trim();
  if (!normalized) {
    return 'بيانات غير صحيحة';
  }

  if (normalized.includes('at least 3 character')) {
    return 'اسم المستخدم يجب أن يكون 3 أحرف على الأقل';
  }

  if (normalized.includes('at least 2 character')) {
    return 'هذا الحقل يجب أن يحتوي على حرفين على الأقل';
  }

  if (normalized.includes('at least 8')) {
    return 'كلمة المرور يجب أن تكون 8 أحرف على الأقل';
  }

  if (normalized.includes('String must contain')) {
    return 'طول الحقل غير مناسب';
  }

  if (normalized.includes('Expected number')) {
    return 'يجب إدخال رقم صحيح';
  }

  if (normalized.includes('Invalid input')) {
    return 'القيمة المدخلة غير صحيحة';
  }

  if (normalized.includes('Unrecognized key')) {
    return 'تم إرسال حقول غير مسموحة';
  }

  return normalized;
}

function redirectBackToReferer(req: Request, res: Response) {
  const referer = req.get('referer') || req.headers.referer;
  if (referer) {
    return res.redirect(referer);
  }

  return res.redirect('/panel/admin/users');
}

export function errorMiddleware(error: unknown, _req: Request, res: Response, _next: NextFunction) {
  const req = _req;

  // Log all errors for debugging
  console.error('[ERROR_MIDDLEWARE]', {
    error: error instanceof Error ? error.message : String(error),
    path: req.path,
    method: req.method,
    url: req.originalUrl,
    stack: error instanceof Error ? error.stack : undefined,
  });

  if (error instanceof AppError) {
    if (isPanelRequest(req)) {
      const message = formatPanelErrorMessage(error.message);
      setFlash(res, 'error', message);
      if (req.method !== 'GET') {
        return redirectBackToReferer(req, res);
      }
      return renderPanelErrorPage(res, error.statusCode >= 400 && error.statusCode < 600 ? error.statusCode : 500, message);
    }
    return res.status(error.statusCode).json({ success: false, message: error.message, code: error.code });
  }

  if (error instanceof Error && (error.name === 'MulterError' || (error as { code?: string }).code?.startsWith('LIMIT_'))) {
    const message = formatPanelErrorMessage(error.message || 'Invalid upload');
    if (isPanelRequest(req)) {
      setFlash(res, 'error', message);
      if (req.method !== 'GET') {
        return redirectBackToReferer(req, res);
      }
      return renderPanelErrorPage(res, 400, message);
    }
    return res.status(400).json({ success: false, message });
  }

  // Validation errors
  if (error instanceof ZodError) {
    const message = error.issues.map((issue) => formatPanelErrorMessage(issue.message)).join(' • ');
    if (isPanelRequest(req)) {
      setFlash(res, 'error', message);
      if (req.method !== 'GET') {
        return redirectBackToReferer(req, res);
      }
      return renderPanelErrorPage(res, 400, message);
    }
    return res.status(400).json({ success: false, message: error.issues.map((issue) => issue.message).join(', ') });
  }

  // Database errors
  if (error instanceof QueryFailedError) {
    const driverError = error.driverError as { errno?: number; code?: string; sqlMessage?: string } | undefined;
    if (driverError?.errno === 1062 || driverError?.code === 'ER_DUP_ENTRY') {
      if (isPanelRequest(req)) {
        const message = 'السجل موجود مسبقًا';
        setFlash(res, 'error', message);
        if (req.method !== 'GET') {
          return redirectBackToReferer(req, res);
        }
        return renderPanelErrorPage(res, 409, message);
      }
      return res.status(409).json({ success: false, message: 'Resource already exists' });
    }
    if (isPanelRequest(req)) {
      const message = 'حدث خطأ في قاعدة البيانات';
      setFlash(res, 'error', message);
      if (req.method !== 'GET') {
        return redirectBackToReferer(req, res);
      }
      return renderPanelErrorPage(res, 500, message);
    }
    return res.status(500).json({ success: false, message: 'Database operation failed' });
  }

  // Unexpected errors
  if (isPanelRequest(req)) {
    const message = 'حدث خطأ غير متوقع';
    setFlash(res, 'error', message);
    if (req.method !== 'GET') {
      return redirectBackToReferer(req, res);
    }
    return renderPanelErrorPage(res, 500, message);
  }

  return res.status(500).json({ success: false, message: 'Internal server error' });
}

// Simple error page that doesn't depend on complex layouts
function renderPanelErrorPage(res: Response, statusCode: number, message = 'حدث خطأ') {
  res.status(statusCode);

  res.render('error', { title: 'حدث خطأ', message }, (err, html) => {
    if (err) {
      console.error('[ERROR_RENDER_FALLBACK]', err.message);
      return res.send(`
        <!DOCTYPE html>
        <html lang="ar" dir="rtl">
        <head>
          <meta charset="UTF-8">
          <meta name="viewport" content="width=device-width, initial-scale=1.0">
          <title>خطأ</title>
          <style>
            body { font-family: Arial, sans-serif; background: #f5f5f5; padding: 20px; }
            .error-box { background: white; border: 1px solid #ddd; border-radius: 4px; padding: 40px; max-width: 500px; margin: 50px auto; text-align: center; }
            h1 { color: #d9534f; margin: 0 0 10px 0; }
            p { color: #666; margin: 0 0 20px 0; }
            a { color: #0275d8; text-decoration: none; }
            a:hover { text-decoration: underline; }
          </style>
        </head>
        <body>
          <div class="error-box">
            <h1>حدث خطأ</h1>
            <p>${message}</p>
            <a href="/panel/login">العودة إلى تسجيل الدخول</a>
          </div>
        </body>
        </html>
      `);
    }

    return res.send(html);
  });
}
