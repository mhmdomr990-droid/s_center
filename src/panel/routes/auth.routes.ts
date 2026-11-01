import { Router } from 'express';

import { panelLoginRateLimit } from '../../middlewares/rateLimit';
import { asyncHandler } from '../../utils/asyncHandler';
import { panelFlash } from '../middlewares/flash';
import { panelAuth } from '../middlewares/panelAuth';
import { getLogin, getPanelHome, postLogin, postLogout } from '../controllers/auth.controller';

export const panelAuthRoutes = Router();

panelAuthRoutes.get('/', panelFlash, panelAuth, asyncHandler(getPanelHome));
panelAuthRoutes.get('/login', panelFlash, asyncHandler(getLogin));
panelAuthRoutes.post('/login', panelLoginRateLimit, panelFlash, asyncHandler(postLogin));
panelAuthRoutes.post('/logout', panelFlash, asyncHandler(postLogout));
