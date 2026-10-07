import { Router } from 'express';

import { authMiddleware } from '../../middlewares/auth';
import { authRateLimit } from '../../middlewares/rateLimit';
import { validate } from '../../middlewares/validate';
import { changePasswordSchema, loginSchema, registerSchema, updateProfileSchema } from './schemas';
import { login, logoutAll, me, register, updatePassword, updateProfile } from './controller';

export const authRoutes = Router();

authRoutes.post('/register', authRateLimit, validate({ body: registerSchema }), register);
authRoutes.post('/login', authRateLimit, validate({ body: loginSchema }), login);
authRoutes.get('/me', authMiddleware, me);
authRoutes.patch('/profile', authMiddleware, validate({ body: updateProfileSchema }), updateProfile);
authRoutes.post('/change-password', authMiddleware, validate({ body: changePasswordSchema }), updatePassword);
authRoutes.post('/logout-all', authMiddleware, logoutAll);
