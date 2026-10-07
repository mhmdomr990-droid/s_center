import 'reflect-metadata';

import { DataSource } from 'typeorm';
import fs from 'fs';
import { env } from './env';
import { Course } from '../entities/Course';
import { Lecture } from '../entities/Lecture';
import { Notification } from '../entities/Notification';
import { Purchase } from '../entities/Purchase';
import { TeacherPayout } from '../entities/TeacherPayout';
import { Specialization } from '../entities/Specialization';
import { TopupRequest } from '../entities/TopupRequest';
import { Transaction } from '../entities/Transaction';
import { User } from '../entities/User';
import { IdempotencyKey } from '../entities/IdempotencyKey';
import { AuditLog } from '../entities/AuditLog';
import { CourseSwapRequest } from '../entities/CourseSwapRequest';
import path from 'path/win32';
const isProduction = process.env.NODE_ENV === 'production';
export const AppDataSource = new DataSource({
  type: 'mysql',
  host: env.DB_HOST,
  port: env.DB_PORT,
  username: env.DB_USER,
  password: env.DB_PASSWORD,
  database: env.DB_NAME,
  entities: [User, Specialization, Course, Lecture, Purchase, TeacherPayout, Transaction, TopupRequest, Notification, IdempotencyKey, AuditLog, CourseSwapRequest],
  synchronize: env.DB_SYNC,
  logging: false,
  charset: 'utf8mb4_unicode_ci',
ssl: false,
});
