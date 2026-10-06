import type { NextFunction, Request, Response } from 'express';
import jwt from 'jsonwebtoken';

import { AppDataSource } from '../../config/data-source';
import { env } from '../../config/env';
import { User } from '../../entities/User';
import { UserRole } from '../../entities/enums';
import { debugPanel } from '../debug';

interface PanelTokenPayload {
  userId: number;
  role: UserRole;
  deviceId: string | null;
}

function redirectToLogin(res: Response) {
  return res.redirect('/');
}

export function clearPanelAuthCookies(res: Response) {
  const expired = { path: '/panel', httpOnly: true, sameSite: 'strict' as const, secure: env.NODE_ENV === 'production', expires: new Date(0), maxAge: 0 };
  const rootExpired = { path: '/', httpOnly: true, sameSite: 'strict' as const, secure: env.NODE_ENV === 'production', expires: new Date(0), maxAge: 0 };

  res.clearCookie('panel_token', expired);
  res.clearCookie('panel_token', rootExpired);
}

export async function resolvePanelUserFromToken(token: string | undefined) {
  if (!token) {
    return null;
  }

  let payload: PanelTokenPayload;
  try {
    payload = jwt.verify(token, env.JWT_SECRET) as PanelTokenPayload;
  } catch (error) {
    debugPanel('panelAuth invalid token', { error: error instanceof Error ? error.message : String(error) });
    return null;
  }

  const user = await AppDataSource.getRepository(User).findOne({ where: { id: payload.userId } });
  if (!user || !user.isActive) {
    debugPanel('panelAuth missing or inactive user', { userId: payload.userId });
    return null;
  }

  if (user.role !== payload.role) {
    debugPanel('panelAuth role mismatch', { tokenRole: payload.role, dbRole: user.role, userId: payload.userId });
    return null;
  }

  if (user.role !== UserRole.ADMIN && user.role !== UserRole.TEACHER) {
    debugPanel('panelAuth blocked non-panel role', { role: user.role, userId: user.id });
    return null;
  }

  return user;
}

export async function panelAuth(req: Request, res: Response, next: NextFunction) {
  const token = req.cookies?.panel_token as string | undefined;
  if (!token) {
    debugPanel('panelAuth missing token', { path: req.originalUrl });
    return redirectToLogin(res);
  }

  const user = await resolvePanelUserFromToken(token);
  if (!user) {
    clearPanelAuthCookies(res);
    return redirectToLogin(res);
  }

  req.user = user;
  res.locals.currentUser = user;
  debugPanel('panelAuth success', { path: req.originalUrl, role: user.role, username: user.username, baseUrl: req.baseUrl, reqPath: req.path });
  next();
}
