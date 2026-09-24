import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import cookieParser from 'cookie-parser';
import fs from 'fs';
import path from 'path';

import { env } from './config/env';
import { adminRoutes } from './modules/admin/routes';
import { authRoutes } from './modules/auth/routes';
import { catalogRoutes } from './modules/catalog/routes';
import { notificationsRoutes } from './modules/notifications/routes';
import { lectureMediaRoutes } from './modules/media/routes';
import { purchaseRoutes } from './modules/purchase/routes';
import { walletRoutes } from './modules/wallet/routes';
import { teacherRoutes } from './modules/teacher/routes';
import { getMediaDownload, getMediaPlay } from './modules/media/controller';
import { panelAuthRoutes } from './panel/routes/auth.routes';
import { panelAdminRoutes } from './panel/routes/admin.routes';
import { panelTeacherRoutes } from './panel/routes/teacher.routes';
import { errorMiddleware } from './middlewares/error';
import { generalRateLimit } from './middlewares/rateLimit';
import { csrfOrigin } from './panel/middlewares/csrfOrigin';

export const app = express();

function resolveViewsPath() {
  const distViews = path.resolve(process.cwd(), 'dist', 'panel', 'views');
  const srcViews = path.resolve(process.cwd(), 'src', 'panel', 'views');
  return fs.existsSync(distViews) ? distViews : srcViews;
}

function formatMoney(value: unknown) {
  const number = typeof value === 'bigint' ? Number(value) : Number(value ?? 0);
  return new Intl.NumberFormat('ar-SY', { minimumFractionDigits: 2, maximumFractionDigits: 2 }).format(Number.isFinite(number) ? number : 0);
}

function formatDate(value: unknown) {
  const date = value instanceof Date ? value : new Date(value as string | number);
  if (Number.isNaN(date.getTime())) {
    return '-';
  }
  return new Intl.DateTimeFormat('ar', { dateStyle: 'medium', timeStyle: 'short' }).format(date);
}

app.set('view engine', 'ejs');
app.set('views', resolveViewsPath());
app.locals.money = formatMoney;
app.locals.date = formatDate;

app.disable('x-powered-by');
// app.use(
//   helmet({
//     contentSecurityPolicy: {
//       useDefaults: true,
//       directives: {
//         defaultSrc: ["'self'"],
//         scriptSrc: ["'self'"],
//         styleSrc: ["'self'"],
//         imgSrc: ["'self'", 'data:'],
//         fontSrc: ["'self'"],
//         connectSrc: ["'self'"],
//         objectSrc: ["'none'"],
//         baseUri: ["'self'"],
//         frameAncestors: ["'self'"],
//       },
//     },
//   }),
// );
app.use(
  cors({
    origin: env.CORS_ORIGINS,
    credentials: true,
  }),
);
app.use(cookieParser());
app.use(express.json({ limit: '1mb' }));
app.use(express.urlencoded({ extended: false }));
app.use(['/student', '/panel'], (_req, res, next) => {
  res.setHeader('Cache-Control', 'no-store, no-cache, must-revalidate, private');
  res.setHeader('Pragma', 'no-cache');
  res.setHeader('Expires', '0');
  next();
});
app.use('/student', express.static(path.resolve(process.cwd(), 'public', 'student-app')));
app.use(express.static(path.resolve(process.cwd(), 'public')));
app.use('/api', generalRateLimit);

app.get('/', (_req, res) => {
  res.sendFile(path.resolve(process.cwd(), 'public', 'landing', 'index.html'));
});

app.use('/api/auth', authRoutes);
app.use('/api', catalogRoutes);
app.use('/api', lectureMediaRoutes);
app.use('/api/wallet', walletRoutes);
app.use('/api', purchaseRoutes);
app.use('/api/notifications', notificationsRoutes);
app.use('/api/admin', adminRoutes);
app.use('/api/teacher', teacherRoutes);

app.get('/media/play/:token', getMediaPlay);
app.get('/media/download/:token', getMediaDownload);

app.use('/panel', csrfOrigin, panelAuthRoutes);
app.use('/panel/admin', csrfOrigin, panelAdminRoutes);
app.use('/panel/teacher', csrfOrigin, panelTeacherRoutes);

app.use(errorMiddleware);
