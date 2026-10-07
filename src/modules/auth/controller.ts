import type { Request, Response } from 'express';

import { asyncHandler } from '../../utils/asyncHandler';
import { changePassword, getCurrentUser, loginUser, logoutAllSessions, registerStudent, updateMyProfile } from './service';

export const register = asyncHandler(async (req: Request, res: Response) => {
  const result = await registerStudent(req.body);
  res.status(201).json({ success: true, data: result });
});

export const login = asyncHandler(async (req: Request, res: Response) => {
  const result = await loginUser(req.body);
  res.status(200).json({ success: true, data: result });
});

export const me = asyncHandler(async (req: Request, res: Response) => {
  const result = await getCurrentUser(req.user!.id);
  res.status(200).json({ success: true, data: result });
});

export const updatePassword = asyncHandler(async (req: Request, res: Response) => {
  const result = await changePassword(req.user!.id, req.body);
  res.status(200).json({ success: true, data: result });
});

export const updateProfile = asyncHandler(async (req: Request, res: Response) => {
  const result = await updateMyProfile(req.user!.id, req.body);
  res.status(200).json({ success: true, data: result });
});

export const logoutAll = asyncHandler(async (req: Request, res: Response) => {
  const result = await logoutAllSessions(req.user!.id);
  res.status(200).json({ success: true, data: result });
});
