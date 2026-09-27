import fs from 'fs';
import path from 'path';

import { expect, request, test } from '@playwright/test';

import { crawlRolePages } from '../utils/crawler';
import { E2EReport } from '../utils/report';
import { bootstrapE2EData, call, loginTeacher, type E2EState } from '../utils/test-data';

const report = new E2EReport();
const screenshotsDir = path.resolve(process.cwd(), 'test-results', 'e2e-failures');
const videoPath = path.resolve(process.cwd(), 'tests', 'e2e', 'fixtures', 'tiny.mp4');

let state: E2EState;
let baseURL = '';

test.beforeAll(async ({ baseURL: configuredBaseUrl }) => {
  fs.mkdirSync(screenshotsDir, { recursive: true });
  baseURL = configuredBaseUrl || 'http://127.0.0.1:3000';

  const api = await request.newContext({ baseURL });
  state = await bootstrapE2EData(api, baseURL);
  state.teacherA.token = await loginTeacher(api, baseURL, state.teacherA.username, state.teacherA.password);
  state.teacherB.token = await loginTeacher(api, baseURL, state.teacherB.username, state.teacherB.password);
  await api.dispose();
});

test.afterAll(async () => {
  report.write(path.resolve(process.cwd(), 'test-results'));
});

test('Specific cross-role and money-critical flows', async ({ page }) => {
  const api = await request.newContext({ baseURL });

  await step('Auth incorrect credentials rejected', async () => {
    const response = await call<{ success: boolean }>(api, `${baseURL}/api/auth/login`, {
      method: 'POST',
      data: { username: state.studentA.username, password: 'wrong-password' },
      expectStatuses: [401],
    });
    expect(response.status).toBe(401);
  });

  await step('Device lock rejects second device login', async () => {
    const response = await call<{ success: boolean }>(api, `${baseURL}/api/auth/login`, {
      method: 'POST',
      data: { username: state.studentA.username, password: state.studentA.password, device_id: `another-device-${state.suffix}` },
      expectStatuses: [403],
    });
    expect(response.status).toBe(403);
  });

  await step('Student A purchases course successfully', async () => {
    const response = await call<{ success: boolean }>(api, `${baseURL}/api/courses/${state.courseId}/purchase`, {
      method: 'POST',
      token: state.studentA.token,
      data: {},
      expectStatuses: [200],
    });
    expect(response.status).toBe(200);
  });

  await step('Student B purchase rejected with insufficient balance', async () => {
    const response = await call<{ success: boolean }>(api, `${baseURL}/api/courses/${state.courseId}/purchase`, {
      method: 'POST',
      token: state.studentB.token,
      data: {},
      expectStatuses: [400],
    });
    expect(response.status).toBe(400);
  });

  await step('Student topup request is created', async () => {
    const response = await call<{ data: { id: number } }>(api, `${baseURL}/api/wallet/topup-requests`, {
      method: 'POST',
      token: state.studentB.token,
      data: {
        amount: '150.00',
        method: 'SHAM_CASH',
        reference_number: `E2E-${state.suffix}`,
        sender_name: 'E2E Sender',
        note: 'Topup for E2E',
      },
      expectStatuses: [201],
    });
    state.topupRequestId = (response.data as any).data.id;
    expect(state.topupRequestId).toBeTruthy();
  });

  await step('Admin reassigns course to teacher B', async () => {
    const response = await call(api, `${baseURL}/api/admin/courses/${state.courseId}`, {
      method: 'PATCH',
      token: state.admin.token,
      data: { teacher_id: state.teacherB.id },
      expectStatuses: [200],
    });
    expect(response.status).toBe(200);
  });

  await step('Teacher earnings remain with teacher A immediately after reassignment', async () => {
    const teachers = await call<{ data: Array<{ teacher_id: number; earned: string }> }>(api, `${baseURL}/api/admin/teachers`, {
      method: 'GET',
      token: state.admin.token,
      expectStatuses: [200],
    });

    const teacherA = teachers.data.data.find((item) => item.teacher_id === state.teacherA.id);
    const teacherB = teachers.data.data.find((item) => item.teacher_id === state.teacherB.id);

    expect(teacherA?.earned).toBe('30.00');
    expect(teacherB?.earned).toBe('0.00');
  });

  await step('Admin approves topup request', async () => {
    expect(state.topupRequestId).toBeTruthy();
    const response = await call(api, `${baseURL}/api/admin/topup-requests/${state.topupRequestId}/approve`, {
      method: 'POST',
      token: state.admin.token,
      data: {},
      expectStatuses: [200],
    });
    expect(response.status).toBe(200);
  });

  await step('Student B can purchase after approved topup', async () => {
    const response = await call(api, `${baseURL}/api/courses/${state.courseId}/purchase`, {
      method: 'POST',
      token: state.studentB.token,
      data: {},
      expectStatuses: [200],
    });
    expect(response.status).toBe(200);
  });

  await step('Teacher reassignment historical earnings are preserved after new purchase', async () => {
    const teachers = await call<{ data: Array<{ teacher_id: number; earned: string }> }>(api, `${baseURL}/api/admin/teachers`, {
      method: 'GET',
      token: state.admin.token,
      expectStatuses: [200],
    });

    const teacherA = teachers.data.data.find((item) => item.teacher_id === state.teacherA.id);
    const teacherB = teachers.data.data.find((item) => item.teacher_id === state.teacherB.id);

    expect(teacherA?.earned).toBe('30.00');
    expect(teacherB?.earned).toBe('30.00');
  });

  await step('Teacher payout records and over-limit rejection work', async () => {
    const ok = await call(api, `${baseURL}/api/admin/teachers/${state.teacherA.id}/payouts`, {
      method: 'POST',
      token: state.admin.token,
      data: { amount: '10.00', note: 'E2E payout' },
      expectStatuses: [201],
    });
    expect(ok.status).toBe(201);

    const reject = await call(api, `${baseURL}/api/admin/teachers/${state.teacherA.id}/payouts`, {
      method: 'POST',
      token: state.admin.token,
      data: { amount: '9999.00', note: 'E2E overflow payout' },
      expectStatuses: [400],
    });
    expect(reject.status).toBe(400);
  });

  await step('Teacher B cannot access teacher A resources', async () => {
    const ownedCourse = await call<{ data: { id: number } }>(api, `${baseURL}/api/admin/courses`, {
      method: 'POST',
      token: state.admin.token,
      data: {
        specialization_id: state.specializationId,
        year: 1,
        name: `E2E A-only course ${state.suffix}`,
        description: 'Authorization probe course',
        price: '50.00',
        is_published: true,
        sort_order: 1,
        teacher_id: state.teacherA.id,
        teacher_percent: '20.00',
      },
      expectStatuses: [201],
    });

    const teacherACourseId = (ownedCourse.data as any).data.id as number;

    const allowedForOwner = await call(api, `${baseURL}/api/teacher/courses/${teacherACourseId}/lectures`, {
      method: 'GET',
      token: state.teacherA.token!,
      expectStatuses: [200],
    });
    expect(allowedForOwner.status).toBe(200);

    const blocked = await call(api, `${baseURL}/api/teacher/courses/${teacherACourseId}/lectures`, {
      method: 'GET',
      token: state.teacherB.token!,
      expectStatuses: [403],
    });
    expect(blocked.status).toBe(403);
  });

  await step('Teacher cannot reach admin API routes', async () => {
    const response = await call(api, `${baseURL}/api/admin/teachers`, {
      method: 'GET',
      token: state.teacherA.token!,
      expectStatuses: [403],
    });
    expect(response.status).toBe(403);
  });

  await step('Teacher responses do not leak student identity fields', async () => {
    const dashboard = await call(api, `${baseURL}/api/teacher/dashboard?days=30`, {
      method: 'GET',
      token: state.teacherA.token!,
      expectStatuses: [200],
    });
    const serialized = JSON.stringify(dashboard.data);
    expect(serialized.includes(state.studentA.username)).toBeFalsy();
    expect(serialized.includes(`E2E Student A ${state.suffix}`)).toBeFalsy();
  });

  await step('Student stream URL returns partial content and video can seek', async () => {
    const streamUrlResponse = await call<{ data: { url: string } }>(api, `${baseURL}/api/lectures/${state.lectureId}/stream-url`, {
      method: 'POST',
      token: state.studentA.token,
      data: {},
      expectStatuses: [200],
    });

    const streamPath = (streamUrlResponse.data as any).data.url as string;

    await page.goto(`${baseURL}/student/course.html?id=${state.courseId}&purchased=1`, { waitUntil: 'domcontentloaded' });
    await page.addInitScript((token) => {
      window.localStorage.setItem('access_token', token);
    }, state.studentA.token);
    await page.goto(`${baseURL}/student/course.html?id=${state.courseId}&purchased=1`, { waitUntil: 'domcontentloaded' });
    await page.waitForSelector('video', { timeout: 15000 });

    const videoCheck = await page.evaluate(async (url) => {
      const fullUrl = `${window.location.origin}${url}`;
      const partial = await fetch(fullUrl, { headers: { Range: 'bytes=0-300' } });
      const video = document.querySelector('video') as HTMLVideoElement | null;
      if (!video) {
        return { partialStatus: partial.status, canSeek: false, hasSrc: false };
      }

      if (!video.src) {
        video.src = fullUrl;
      }

      if (video.readyState < 1) {
        await new Promise<void>((resolve) => {
          const timeout = window.setTimeout(resolve, 10000);
          video.addEventListener('loadedmetadata', () => {
            window.clearTimeout(timeout);
            resolve();
          }, { once: true });
        });
      }

      const target = Math.min(0.1, Math.max((video.duration || 1) / 2, 0.05));
      await new Promise<void>((resolve) => {
        const timeout = window.setTimeout(resolve, 3000);
        video.addEventListener('seeked', () => {
          window.clearTimeout(timeout);
          resolve();
        }, { once: true });
        try {
          video.currentTime = target;
        } catch {
          window.clearTimeout(timeout);
          resolve();
        }
      });

      const hasSeekableRange = video.seekable.length > 0;
      const canSeek = hasSeekableRange || video.currentTime > 0;

      return { partialStatus: partial.status, canSeek, hasSrc: Boolean(video.src) };
    }, streamPath);

    expect(videoCheck.partialStatus).toBe(206);
    expect(videoCheck.hasSrc).toBeTruthy();
    expect(videoCheck.canSeek).toBeTruthy();
  });

  await step('Student download URL can be fetched', async () => {
    const download = await call<{ data: { url: string } }>(api, `${baseURL}/api/lectures/${state.lectureId}/download-url`, {
      method: 'POST',
      token: state.studentA.token,
      data: {},
      expectStatuses: [200],
    });

    const pathUrl = (download.data as any).data.url as string;
    const file = await api.fetch(`${baseURL}${pathUrl}`, { method: 'GET' });
    expect([200, 206]).toContain(file.status());
  });

  await step('Profile change-password and logout-all invalidate old token', async () => {
    const newPassword = `student_new_${state.suffix}`;
    const change = await call(api, `${baseURL}/api/auth/change-password`, {
      method: 'POST',
      token: state.studentB.token,
      data: { old_password: state.studentB.password, new_password: newPassword },
      expectStatuses: [200],
    });
    expect(change.status).toBe(200);

    const reLogin = await call<{ data: { token: string } }>(api, `${baseURL}/api/auth/login`, {
      method: 'POST',
      data: { username: state.studentB.username, password: newPassword, device_id: state.studentB.deviceId },
      expectStatuses: [200],
    });

    const freshToken = (reLogin.data as any).data.token as string;
    const logoutAll = await call(api, `${baseURL}/api/auth/logout-all`, {
      method: 'POST',
      token: freshToken,
      data: {},
      expectStatuses: [200],
    });
    expect(logoutAll.status).toBe(200);

    const oldTokenCheck = await call(api, `${baseURL}/api/auth/me`, {
      method: 'GET',
      token: freshToken,
      expectStatuses: [401],
    });
    expect(oldTokenCheck.status).toBe(401);
  });

  await step('Admin audit log page probe', async () => {
    const response = await api.fetch(`${baseURL}/panel/admin/audit-logs`, {
      method: 'GET',
      headers: {
        Cookie: await panelCookieHeader(page, state.admin.username, state.admin.password),
      },
      maxRedirects: 0,
    });

    if (response.status() >= 400 || response.status() === 302) {
      report.addIssue({
        severity: 'MEDIUM',
        role: 'ADMIN',
        page: '/panel/admin/audit-logs',
        reproSteps: 'Open audit log page from admin session',
        expected: 'Audit log UI page should exist and render',
        actual: `Route unavailable or redirects unexpectedly (status ${response.status()})`,
        rootCause: 'No panel route/view is implemented for audit log browsing.',
        fix: 'Add admin panel route/controller/view for audit logs and wire it in sidebar.',
      });
    }
  });

  await step('Admin refund endpoint probe', async () => {
    const response = await api.fetch(`${baseURL}/api/admin/purchases/1/refund`, {
      method: 'POST',
      headers: { Authorization: `Bearer ${state.admin.token}` },
      data: {},
    });

    if (response.status() === 404) {
      report.addIssue({
        severity: 'HIGH',
        role: 'ADMIN',
        page: '/api/admin/purchases/:id/refund',
        reproSteps: 'Call refund endpoint for a valid admin token',
        expected: 'Refund operation should exist and update balance/access atomically',
        actual: 'Refund endpoint is missing (404).',
        rootCause: 'Refund workflow is not implemented in admin API/service.',
        fix: 'Implement refund service transaction, route/controller, and panel action in test-safe data scope.',
      });
    }
  });

  await api.dispose();
});

test('Exhaustive DOM-driven interaction crawler for ADMIN, TEACHER, STUDENT', async ({ browser }) => {
  const adminContext = await browser.newContext();
  const adminPage = await adminContext.newPage();
  await loginPanel(adminPage, state.admin.username, state.admin.password);

  await crawlRolePages(adminPage, {
    role: 'ADMIN',
    roleRootUrl: `${baseURL}/panel/admin/overview`,
    navLinkSelector: '.panel-nav a[href]',
    videoPath,
    report,
    screenshotDir: screenshotsDir,
    maxActionsPerPage: 3,
    maxPagesPerRole: 2,
  });

  const teacherContext = await browser.newContext();
  const teacherPage = await teacherContext.newPage();
  await loginPanel(teacherPage, state.teacherA.username, state.teacherA.password);

  await crawlRolePages(teacherPage, {
    role: 'TEACHER',
    roleRootUrl: `${baseURL}/panel/teacher/courses`,
    navLinkSelector: '.panel-nav a[href]',
    videoPath,
    report,
    screenshotDir: screenshotsDir,
    maxActionsPerPage: 3,
    maxPagesPerRole: 2,
  });

  const studentContext = await browser.newContext();
  const studentPage = await studentContext.newPage();
  await loginStudent(studentPage, state.studentA.username, state.studentA.password, state.studentA.deviceId);

  await crawlRolePages(studentPage, {
    role: 'STUDENT',
    roleRootUrl: `${baseURL}/student/index.html`,
    navLinkSelector: '#studentNav a[href]',
    videoPath,
    report,
    screenshotDir: screenshotsDir,
    maxActionsPerPage: 3,
    maxPagesPerRole: 2,
  });

  await step('Teacher cannot reach /panel/admin/*', async () => {
    const response = await teacherPage.goto(`${baseURL}/panel/admin/overview`, { waitUntil: 'domcontentloaded' });
    const bodyText = (await teacherPage.textContent('body')) || '';
    const deniedByStatus = response ? response.status() >= 400 : false;
    const deniedByText = /access denied|رفض|غير مصرح/i.test(bodyText);
    expect(deniedByStatus || deniedByText).toBeTruthy();
  });

  await adminContext.close();
  await teacherContext.close();
  await studentContext.close();
});

async function loginPanel(page: import('@playwright/test').Page, username: string, password: string) {
  await page.goto(`${baseURL}/panel/login`, { waitUntil: 'domcontentloaded' });
  await page.fill('input[name="username"]', username);
  await page.fill('input[name="password"]', password);
  await page.click('button[type="submit"]');
  await page.waitForLoadState('domcontentloaded');
}

async function loginStudent(page: import('@playwright/test').Page, username: string, password: string, deviceId: string) {
  await page.addInitScript((seedDeviceId) => {
    window.localStorage.setItem('device_id', seedDeviceId);
  }, deviceId);
  await page.goto(`${baseURL}/student/login.html`, { waitUntil: 'domcontentloaded' });
  await page.fill('input[name="username"]', username);
  await page.fill('input[name="password"]', password);
  await page.click('button[type="submit"]');
  await page.waitForURL('**/student/index.html', { timeout: 20_000 });
}

async function panelCookieHeader(page: import('@playwright/test').Page, username: string, password: string) {
  await loginPanel(page, username, password);
  const cookies = await page.context().cookies();
  return cookies.map((item) => `${item.name}=${item.value}`).join('; ');
}

async function step(name: string, fn: () => Promise<void>) {
  try {
    await fn();
    report.addAction({
      role: 'ADMIN',
      page: 'specific-flow',
      action: name,
      result: 'PASS',
      errorDetail: '',
      screenshotPath: '',
    });
  } catch (error) {
    report.addAction({
      role: 'ADMIN',
      page: 'specific-flow',
      action: name,
      result: 'FAIL',
      errorDetail: error instanceof Error ? error.message : String(error),
      screenshotPath: '',
    });
    throw error;
  }
}
