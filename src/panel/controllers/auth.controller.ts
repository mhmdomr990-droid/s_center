import type { Request, Response } from 'express';

import { loginForPanel } from '../../modules/auth/service';
import { UserRole } from '../../entities/enums';

import { env } from '../../config/env';
import { clearPanelAuthCookies, resolvePanelUserFromToken } from '../middlewares/panelAuth';

function cookieSecureFlag() {
  return env.NODE_ENV === 'production';
}

export async function getLogin(req: Request, res: Response) {
  const token = req.cookies?.panel_token as string | undefined;
  if (token) {
    const user = await resolvePanelUserFromToken(token);
    if (user) {
      return res.redirect('/panel');
    }

    clearPanelAuthCookies(res);
  }

  const csrfToken = res.locals.csrfToken || req.cookies?.panel_csrf_token || '';
  res.render('auth/login', { title: 'تسجيل الدخول', csrfToken });
}

export async function postLogin(req: Request, res: Response, next: (error?: unknown) => void) {
  try {
    const { username, password } = req.body as { username: string; password: string };
    const result = await loginForPanel({ username, password });
    const token = result.token;
    const user = result.user;
    res.cookie('panel_token', token, {
      httpOnly: true,
      sameSite: 'strict',
      secure: cookieSecureFlag(),
      path: '/',
      maxAge: 1000 * 60 * 60 * 24 * 7,
    });

    const redirectTo = user.role === UserRole.ADMIN ? '/panel/admin/overview' : '/panel/teacher/courses';
    return res.redirect(redirectTo);
  } catch (error) {
    return next(error);
  }
}

export async function postLogout(req: Request, res: Response) {
  clearPanelAuthCookies(res);
  res.clearCookie('panel_csrf_token', { path: '/panel', httpOnly: true, sameSite: 'strict', secure: cookieSecureFlag(), expires: new Date(0), maxAge: 0 });
  res.clearCookie('panel_csrf_token', { path: '/', httpOnly: true, sameSite: 'strict', secure: cookieSecureFlag(), expires: new Date(0), maxAge: 0 });
  res.clearCookie('panel_flash', { path: '/panel', httpOnly: true, sameSite: 'strict', secure: cookieSecureFlag(), expires: new Date(0), maxAge: 0 });
  res.clearCookie('panel_flash', { path: '/', httpOnly: true, sameSite: 'strict', secure: cookieSecureFlag(), expires: new Date(0), maxAge: 0 });
  return res.redirect('/panel/login');
}

export async function getPanelHome(req: Request, res: Response) {
  if (!req.user) {
    return res.redirect('/panel/login');
  }

  if (req.user.role === UserRole.ADMIN) {
    return res.redirect('/panel/admin/overview');
  }

  if (req.user.role === UserRole.TEACHER) {
    return res.redirect('/panel/teacher/courses');
  }

  return res.redirect('/panel/login');
}
