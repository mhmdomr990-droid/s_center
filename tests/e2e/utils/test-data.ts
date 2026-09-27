import fs from 'fs';
import path from 'path';

import type { APIRequestContext } from '@playwright/test';

interface ApiEnvelope<T> {
  success: boolean;
  data: T;
}

export interface E2EState {
  suffix: string;
  admin: {
    username: string;
    password: string;
    token: string;
  };
  teacherA: { id: number; username: string; password: string; token?: string };
  teacherB: { id: number; username: string; password: string; token?: string };
  studentA: { id: number; username: string; password: string; token: string; deviceId: string };
  studentB: { id: number; username: string; password: string; token: string; deviceId: string };
  specializationId: number;
  courseId: number;
  lectureId: number;
  topupRequestId?: number;
}

export async function bootstrapE2EData(api: APIRequestContext, baseURL: string) {
  const suffix = Date.now().toString();
  const adminUsername = process.env.ADMIN_USERNAME || 'admin';
  const adminPassword = process.env.ADMIN_PASSWORD || 'admin1234';

  const adminLogin = await call<ApiEnvelope<{ token: string }>>(api, `${baseURL}/api/auth/login`, {
    method: 'POST',
    data: { username: adminUsername, password: adminPassword },
    expectStatuses: [200],
  });

  const adminToken = adminLogin.data.data.token;

  const teacherAUsername = `e2e_teacher_a_${suffix}`;
  const teacherBUsername = `e2e_teacher_b_${suffix}`;
  const teacherPassword = 'teacher1234';

  const teacherA = await call<ApiEnvelope<{ id: number }>>(api, `${baseURL}/api/admin/teachers`, {
    method: 'POST',
    token: adminToken,
    data: { username: teacherAUsername, full_name: `E2E Teacher A ${suffix}`, password: teacherPassword },
    expectStatuses: [201],
  });

  const teacherB = await call<ApiEnvelope<{ id: number }>>(api, `${baseURL}/api/admin/teachers`, {
    method: 'POST',
    token: adminToken,
    data: { username: teacherBUsername, full_name: `E2E Teacher B ${suffix}`, password: teacherPassword },
    expectStatuses: [201],
  });

  const studentAUsername = `e2e_student_a_${suffix}`;
  const studentBUsername = `e2e_student_b_${suffix}`;
  const studentPassword = 'student1234';
  const studentADevice = `e2e-device-a-${suffix}`;
  const studentBDevice = `e2e-device-b-${suffix}`;

  const studentA = await call<ApiEnvelope<{ token: string; user: { id: number } }>>(api, `${baseURL}/api/auth/register`, {
    method: 'POST',
    data: { username: studentAUsername, full_name: `E2E Student A ${suffix}`, password: studentPassword, device_id: studentADevice },
    expectStatuses: [201],
  });

  const studentB = await call<ApiEnvelope<{ token: string; user: { id: number } }>>(api, `${baseURL}/api/auth/register`, {
    method: 'POST',
    data: { username: studentBUsername, full_name: `E2E Student B ${suffix}`, password: studentPassword, device_id: studentBDevice },
    expectStatuses: [201],
  });

  const specialization = await call<ApiEnvelope<{ id: number }>>(api, `${baseURL}/api/admin/specializations`, {
    method: 'POST',
    token: adminToken,
    data: { name: `E2E Spec ${suffix}`, is_published: true, sort_order: 0 },
    expectStatuses: [201],
  });

  const course = await call<ApiEnvelope<{ id: number }>>(api, `${baseURL}/api/admin/courses`, {
    method: 'POST',
    token: adminToken,
    data: {
      specialization_id: specialization.data.data.id,
      year: 1,
      name: `E2E Course ${suffix}`,
      description: `E2E course ${suffix}`,
      price: '100.00',
      is_published: true,
      sort_order: 0,
      teacher_id: teacherA.data.data.id,
      teacher_percent: '30.00',
    },
    expectStatuses: [201],
  });

  const videoPath = path.resolve(process.cwd(), 'tests', 'e2e', 'fixtures', 'tiny.mp4');
  const lecture = await call<ApiEnvelope<{ id: number }>>(api, `${baseURL}/api/admin/lectures`, {
    method: 'POST',
    token: adminToken,
    multipart: {
      course_id: String(course.data.data.id),
      title: `E2E Lecture ${suffix}`,
      type: 'VIDEO',
      sort_order: '0',
      video: {
        name: path.basename(videoPath),
        mimeType: 'video/mp4',
        buffer: fs.readFileSync(videoPath),
      },
    },
    expectStatuses: [201],
  });

  await call(api, `${baseURL}/api/admin/users/${studentA.data.data.user.id}/adjust-balance`, {
    method: 'POST',
    token: adminToken,
    data: { amount: '500.00', description: 'E2E funding student A' },
    expectStatuses: [200],
  });

  await call(api, `${baseURL}/api/admin/users/${studentB.data.data.user.id}/adjust-balance`, {
    method: 'POST',
    token: adminToken,
    data: { amount: '80.00', description: 'E2E funding student B (insufficient purchase)' },
    expectStatuses: [200],
  });

  return {
    suffix,
    admin: { username: adminUsername, password: adminPassword, token: adminToken },
    teacherA: { id: teacherA.data.data.id, username: teacherAUsername, password: teacherPassword },
    teacherB: { id: teacherB.data.data.id, username: teacherBUsername, password: teacherPassword },
    studentA: { id: studentA.data.data.user.id, username: studentAUsername, password: studentPassword, token: studentA.data.data.token, deviceId: studentADevice },
    studentB: { id: studentB.data.data.user.id, username: studentBUsername, password: studentPassword, token: studentB.data.data.token, deviceId: studentBDevice },
    specializationId: specialization.data.data.id,
    courseId: course.data.data.id,
    lectureId: lecture.data.data.id,
  } as E2EState;
}

export async function loginTeacher(api: APIRequestContext, baseURL: string, username: string, password: string) {
  const response = await call<ApiEnvelope<{ token: string }>>(api, `${baseURL}/api/auth/login`, {
    method: 'POST',
    data: { username, password },
    expectStatuses: [200],
  });

  return response.data.data.token;
}

export async function call<T>(
  api: APIRequestContext,
  url: string,
  options: {
    method: 'GET' | 'POST' | 'PATCH' | 'DELETE' | 'PUT';
    token?: string;
    data?: unknown;
    multipart?: Record<string, unknown>;
    expectStatuses: number[];
  },
) {
  const response = await api.fetch(url, {
    method: options.method,
    headers: {
      ...(options.token ? { Authorization: `Bearer ${options.token}` } : {}),
    },
    data: options.data,
    multipart: options.multipart,
  });

  const text = await response.text();
  if (!options.expectStatuses.includes(response.status())) {
    throw new Error(`Unexpected status for ${options.method} ${url}: ${response.status()} ${text}`);
  }

  return {
    status: response.status(),
    data: text ? (JSON.parse(text) as T) : ({} as T),
  };
}
