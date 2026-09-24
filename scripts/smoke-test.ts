const BASE_URL = 'http://localhost:3000';

interface ApiEnvelope<T> {
  success: boolean;
  data: T;
}

interface AssertionResult {
  name: string;
  passed: boolean;
  detail: string;
}

interface RequestOptions {
  method?: 'GET' | 'POST' | 'PATCH';
  token?: string;
  body?: Record<string, unknown>;
  expectedStatuses?: number[];
}

function toCents(value: string | number): bigint {
  const raw = String(value).trim();
  const negative = raw.startsWith('-');
  const unsigned = negative ? raw.slice(1) : raw;
  const [wholePart, fractionPart = ''] = unsigned.split('.');
  const whole = BigInt(wholePart || '0');
  const fraction = BigInt((fractionPart + '00').slice(0, 2));
  const cents = whole * 100n + fraction;
  return negative ? -cents : cents;
}

function fromCents(cents: bigint): string {
  const negative = cents < 0n;
  const absolute = negative ? -cents : cents;
  const whole = absolute / 100n;
  const fraction = (absolute % 100n).toString().padStart(2, '0');
  return `${negative ? '-' : ''}${whole.toString()}.${fraction}`;
}

async function request<T>(path: string, options: RequestOptions = {}): Promise<{ status: number; data: T }> {
  const response = await fetch(`${BASE_URL}${path}`, {
    method: options.method ?? 'GET',
    headers: {
      'Content-Type': 'application/json',
      ...(options.token ? { Authorization: `Bearer ${options.token}` } : {}),
    },
    body: options.body ? JSON.stringify(options.body) : undefined,
  });

  const text = await response.text();
  const expected = options.expectedStatuses ?? [200];

  if (!expected.includes(response.status)) {
    throw new Error(`Unexpected status for ${options.method ?? 'GET'} ${path}: ${response.status} ${text}`);
  }

  let parsed: unknown = {};
  if (text) {
    try {
      parsed = JSON.parse(text);
    } catch {
      parsed = { raw: text };
    }
  }

  return {
    status: response.status,
    data: parsed as T,
  };
}

function assert(results: AssertionResult[], name: string, condition: boolean, detail: string) {
  results.push({ name, passed: condition, detail });
  const status = condition ? 'PASS' : 'FAIL';
  console.log(`[${status}] ${name} :: ${detail}`);
}

function findTeacherRow(rows: any[], teacherId: number) {
  return rows.find((row) => Number(row.teacher_id) === teacherId);
}

async function runRegressionScenario() {
  const results: AssertionResult[] = [];
  const suffix = Date.now();
  const currentMonth = new Date().toISOString().slice(0, 7);

  console.log('Running teacher reassignment earnings regression scenario...');

  const adminLogin = await request<ApiEnvelope<{ token: string }>>('/api/auth/login', {
    method: 'POST',
    body: { username: 'admin', password: 'admin1234' },
    expectedStatuses: [200],
  });
  const adminToken = adminLogin.data.data.token;

  const specializationRes = await request<ApiEnvelope<{ id: number }>>('/api/admin/specializations', {
    method: 'POST',
    token: adminToken,
    body: { name: `Regression Spec ${suffix}`, is_published: true, sort_order: 0 },
    expectedStatuses: [201],
  });
  const specializationId = Number(specializationRes.data.data.id);

  const teacherARes = await request<ApiEnvelope<{ id: number; username: string }>>('/api/admin/teachers', {
    method: 'POST',
    token: adminToken,
    body: { username: `teacher_a_${suffix}`, full_name: `Teacher A ${suffix}`, password: 'teacher1234' },
    expectedStatuses: [201],
  });
  const teacherAId = Number(teacherARes.data.data.id);

  const teacherBRes = await request<ApiEnvelope<{ id: number; username: string }>>('/api/admin/teachers', {
    method: 'POST',
    token: adminToken,
    body: { username: `teacher_b_${suffix}`, full_name: `Teacher B ${suffix}`, password: 'teacher1234' },
    expectedStatuses: [201],
  });
  const teacherBId = Number(teacherBRes.data.data.id);

  const courseRes = await request<ApiEnvelope<{ id: number }>>('/api/admin/courses', {
    method: 'POST',
    token: adminToken,
    body: {
      specialization_id: specializationId,
      year: 1,
      name: `Regression Course ${suffix}`,
      description: 'Teacher reassignment regression check',
      price: '100.00',
      is_published: true,
      sort_order: 0,
      teacher_id: teacherAId,
      teacher_percent: '30.00',
    },
    expectedStatuses: [201],
  });
  const courseId = Number(courseRes.data.data.id);

  const studentARegister = await request<ApiEnvelope<{ token: string; user: { id: number } }>>('/api/auth/register', {
    method: 'POST',
    body: {
      username: `student_a_${suffix}`,
      full_name: `Student A ${suffix}`,
      password: 'student1234',
      device_id: `device-a-${suffix}`,
    },
    expectedStatuses: [201],
  });
  const studentAToken = studentARegister.data.data.token;
  const studentAId = Number(studentARegister.data.data.user.id);

  const studentBRegister = await request<ApiEnvelope<{ token: string; user: { id: number } }>>('/api/auth/register', {
    method: 'POST',
    body: {
      username: `student_b_${suffix}`,
      full_name: `Student B ${suffix}`,
      password: 'student1234',
      device_id: `device-b-${suffix}`,
    },
    expectedStatuses: [201],
  });
  const studentBToken = studentBRegister.data.data.token;
  const studentBId = Number(studentBRegister.data.data.user.id);

  await request<ApiEnvelope<{ message: string }>>(`/api/admin/users/${studentAId}/adjust-balance`, {
    method: 'POST',
    token: adminToken,
    body: { amount: '500.00', description: 'Regression test funding A' },
    expectedStatuses: [200],
  });

  await request<ApiEnvelope<{ message: string }>>(`/api/admin/users/${studentBId}/adjust-balance`, {
    method: 'POST',
    token: adminToken,
    body: { amount: '500.00', description: 'Regression test funding B' },
    expectedStatuses: [200],
  });

  await request<ApiEnvelope<{ purchase: { id: number } }>>(`/api/courses/${courseId}/purchase`, {
    method: 'POST',
    token: studentAToken,
    body: {},
    expectedStatuses: [200],
  });

  const studentAPurchases = await request<ApiEnvelope<any[]>>(`/api/admin/users/${studentAId}/purchases`, {
    token: adminToken,
    expectedStatuses: [200],
  });
  const studentAPurchaseSnapshot = studentAPurchases.data.data.find((item) => Number(item.course_id) === courseId);

  assert(
    results,
    'Step 2 snapshot teacher on first purchase',
    Number(studentAPurchaseSnapshot?.teacher_id) === teacherAId,
    `expected teacher_id=${teacherAId}, actual=${studentAPurchaseSnapshot?.teacher_id}`,
  );

  assert(
    results,
    'Step 2 snapshot teacher_share on first purchase',
    String(studentAPurchaseSnapshot?.teacher_share) === '30.00',
    `expected 30.00, actual=${studentAPurchaseSnapshot?.teacher_share}`,
  );

  const teachersAfterFirstPurchase = await request<ApiEnvelope<any[]>>('/api/admin/teachers', {
    token: adminToken,
    expectedStatuses: [200],
  });
  const teacherAAfterFirst = findTeacherRow(teachersAfterFirstPurchase.data.data, teacherAId);
  const teacherBAfterFirst = findTeacherRow(teachersAfterFirstPurchase.data.data, teacherBId);

  assert(
    results,
    'Step 3 admin teachers: A earned after first purchase',
    String(teacherAAfterFirst?.earned) === '30.00',
    `expected 30.00, actual=${teacherAAfterFirst?.earned}`,
  );

  assert(
    results,
    'Step 3 admin teachers: B earned after first purchase',
    String(teacherBAfterFirst?.earned) === '0.00',
    `expected 0.00, actual=${teacherBAfterFirst?.earned}`,
  );

  const courseBeforeReassign = await request<ApiEnvelope<any>>(`/api/admin/courses/${courseId}`, {
    token: adminToken,
    expectedStatuses: [200],
  });

  assert(
    results,
    'Step 4 transparency: old teacher per-course purchases visible',
    Number(courseBeforeReassign.data.data.teacher_reassignment_notice?.course_purchases_count) === 1,
    `expected 1, actual=${courseBeforeReassign.data.data.teacher_reassignment_notice?.course_purchases_count}`,
  );

  assert(
    results,
    'Step 4 transparency: old teacher per-course earned visible',
    String(courseBeforeReassign.data.data.teacher_reassignment_notice?.course_earned) === '30.00',
    `expected 30.00, actual=${courseBeforeReassign.data.data.teacher_reassignment_notice?.course_earned}`,
  );

  await request<ApiEnvelope<any>>(`/api/admin/courses/${courseId}`, {
    method: 'PATCH',
    token: adminToken,
    body: { teacher_id: teacherBId },
    expectedStatuses: [200],
  });

  const teachersAfterReassign = await request<ApiEnvelope<any[]>>('/api/admin/teachers', {
    token: adminToken,
    expectedStatuses: [200],
  });
  const teacherAAfterReassign = findTeacherRow(teachersAfterReassign.data.data, teacherAId);
  const teacherBAfterReassign = findTeacherRow(teachersAfterReassign.data.data, teacherBId);

  assert(
    results,
    'Step 5 admin teachers: A earned unchanged after reassignment',
    String(teacherAAfterReassign?.earned) === '30.00',
    `expected 30.00, actual=${teacherAAfterReassign?.earned}`,
  );

  assert(
    results,
    'Step 5 admin teachers: B still zero after reassignment',
    String(teacherBAfterReassign?.earned) === '0.00',
    `expected 0.00, actual=${teacherBAfterReassign?.earned}`,
  );

  await request<ApiEnvelope<{ purchase: { id: number } }>>(`/api/courses/${courseId}/purchase`, {
    method: 'POST',
    token: studentBToken,
    body: {},
    expectedStatuses: [200],
  });

  const studentBPurchases = await request<ApiEnvelope<any[]>>(`/api/admin/users/${studentBId}/purchases`, {
    token: adminToken,
    expectedStatuses: [200],
  });
  const studentBPurchaseSnapshot = studentBPurchases.data.data.find((item) => Number(item.course_id) === courseId);

  assert(
    results,
    'Step 6 snapshot teacher on second purchase',
    Number(studentBPurchaseSnapshot?.teacher_id) === teacherBId,
    `expected teacher_id=${teacherBId}, actual=${studentBPurchaseSnapshot?.teacher_id}`,
  );

  assert(
    results,
    'Step 6 snapshot teacher_share on second purchase',
    String(studentBPurchaseSnapshot?.teacher_share) === '30.00',
    `expected 30.00, actual=${studentBPurchaseSnapshot?.teacher_share}`,
  );

  const teachersAfterSecondPurchase = await request<ApiEnvelope<any[]>>('/api/admin/teachers', {
    token: adminToken,
    expectedStatuses: [200],
  });
  const teacherAAfterSecond = findTeacherRow(teachersAfterSecondPurchase.data.data, teacherAId);
  const teacherBAfterSecond = findTeacherRow(teachersAfterSecondPurchase.data.data, teacherBId);

  assert(
    results,
    'Step 7 admin teachers: A earned remains first sale only',
    String(teacherAAfterSecond?.earned) === '30.00',
    `expected 30.00, actual=${teacherAAfterSecond?.earned}`,
  );

  assert(
    results,
    'Step 7 admin teachers: B earned equals second sale only',
    String(teacherBAfterSecond?.earned) === '30.00',
    `expected 30.00, actual=${teacherBAfterSecond?.earned}`,
  );

  const teacherStatsRows = await request<ApiEnvelope<any[]>>('/api/admin/stats/teachers', {
    token: adminToken,
    expectedStatuses: [200],
  });
  const teacherAStats = findTeacherRow(teacherStatsRows.data.data, teacherAId);
  const teacherBStats = findTeacherRow(teacherStatsRows.data.data, teacherBId);

  assert(
    results,
    'Admin stats teachers: A earned reflects historical snapshot',
    String(teacherAStats?.earned) === '30.00',
    `expected 30.00, actual=${teacherAStats?.earned}`,
  );

  assert(
    results,
    'Admin stats teachers: B earned reflects historical snapshot',
    String(teacherBStats?.earned) === '30.00',
    `expected 30.00, actual=${teacherBStats?.earned}`,
  );

  const teacherDetailA = await request<ApiEnvelope<any>>(`/api/admin/teachers/${teacherAId}`, {
    token: adminToken,
    expectedStatuses: [200],
  });
  const teacherDetailB = await request<ApiEnvelope<any>>(`/api/admin/teachers/${teacherBId}`, {
    token: adminToken,
    expectedStatuses: [200],
  });

  assert(
    results,
    'Admin teacher detail: A totals.earned uses historical purchase snapshot',
    String(teacherDetailA.data.data.totals?.earned) === '30.00',
    `expected 30.00, actual=${teacherDetailA.data.data.totals?.earned}`,
  );

  assert(
    results,
    'Admin teacher detail: B totals.earned uses historical purchase snapshot',
    String(teacherDetailB.data.data.totals?.earned) === '30.00',
    `expected 30.00, actual=${teacherDetailB.data.data.totals?.earned}`,
  );

  const teacherALogin = await request<ApiEnvelope<{ token: string }>>('/api/auth/login', {
    method: 'POST',
    body: { username: `teacher_a_${suffix}`, password: 'teacher1234' },
    expectedStatuses: [200],
  });
  const teacherBLogin = await request<ApiEnvelope<{ token: string }>>('/api/auth/login', {
    method: 'POST',
    body: { username: `teacher_b_${suffix}`, password: 'teacher1234' },
    expectedStatuses: [200],
  });

  const teacherADashboard = await request<ApiEnvelope<any>>('/api/teacher/dashboard?days=30', {
    token: teacherALogin.data.data.token,
    expectedStatuses: [200],
  });
  const teacherBDashboard = await request<ApiEnvelope<any>>('/api/teacher/dashboard?days=30', {
    token: teacherBLogin.data.data.token,
    expectedStatuses: [200],
  });

  assert(
    results,
    'Teacher dashboard: A total_earned remains first purchase only',
    String(teacherADashboard.data.data.total_earned) === '30.00',
    `expected 30.00, actual=${teacherADashboard.data.data.total_earned}`,
  );

  assert(
    results,
    'Teacher dashboard: B total_earned includes only second purchase',
    String(teacherBDashboard.data.data.total_earned) === '30.00',
    `expected 30.00, actual=${teacherBDashboard.data.data.total_earned}`,
  );

  const teacherAEarnings = await request<ApiEnvelope<any>>(`/api/teacher/earnings?month=${currentMonth}`, {
    token: teacherALogin.data.data.token,
    expectedStatuses: [200],
  });
  const teacherBEarnings = await request<ApiEnvelope<any>>(`/api/teacher/earnings?month=${currentMonth}`, {
    token: teacherBLogin.data.data.token,
    expectedStatuses: [200],
  });

  const teacherAMonthlyEarned = teacherAEarnings.data.data.courses.reduce(
    (sum: bigint, row: any) => sum + toCents(String(row.earned ?? '0.00')),
    0n,
  );
  const teacherBMonthlyEarned = teacherBEarnings.data.data.courses.reduce(
    (sum: bigint, row: any) => sum + toCents(String(row.earned ?? '0.00')),
    0n,
  );

  assert(
    results,
    'Teacher earnings: A monthly earned uses historical snapshot',
    fromCents(teacherAMonthlyEarned) === '30.00',
    `expected 30.00, actual=${fromCents(teacherAMonthlyEarned)}`,
  );

  assert(
    results,
    'Teacher earnings: B monthly earned uses historical snapshot',
    fromCents(teacherBMonthlyEarned) === '30.00',
    `expected 30.00, actual=${fromCents(teacherBMonthlyEarned)}`,
  );

  const payoutAllowed = await request<ApiEnvelope<any>>(`/api/admin/teachers/${teacherAId}/payouts`, {
    method: 'POST',
    token: adminToken,
    body: { amount: '29.00', note: 'Regression allowed payout' },
    expectedStatuses: [201],
  });

  assert(
    results,
    'Step 8 payout <= remaining succeeds',
    payoutAllowed.status === 201,
    `expected status 201, actual=${payoutAllowed.status}`,
  );

  const payoutRejected = await request<{ message?: string }>(`/api/admin/teachers/${teacherAId}/payouts`, {
    method: 'POST',
    token: adminToken,
    body: { amount: '2.00', note: 'Regression reject payout' },
    expectedStatuses: [400],
  });

  assert(
    results,
    'Step 8 payout > remaining rejected',
    payoutRejected.status === 400,
    `expected status 400, actual=${payoutRejected.status}`,
  );

  const passed = results.filter((item) => item.passed).length;
  const failed = results.length - passed;

  console.log('');
  console.log('Regression Summary');
  console.log('------------------');
  console.log(`Total Assertions: ${results.length}`);
  console.log(`Passed: ${passed}`);
  console.log(`Failed: ${failed}`);

  if (failed > 0) {
    process.exitCode = 1;
  }
}

runRegressionScenario().catch((error) => {
  console.error(`Regression scenario crashed: ${error instanceof Error ? error.message : String(error)}`);
  process.exitCode = 1;
});
