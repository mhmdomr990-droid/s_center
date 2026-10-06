import { apiGet } from './api.js';

const TOKEN_KEY = 'access_token';
const DEVICE_KEY = 'device_id';

export function ensureDeviceId() {
  let deviceId = localStorage.getItem(DEVICE_KEY);
  if (!deviceId) {
    deviceId = crypto.randomUUID();
    localStorage.setItem(DEVICE_KEY, deviceId);
  }
  return deviceId;
}

export function getDeviceId() {
  return localStorage.getItem(DEVICE_KEY);
}

export function setAccessToken(token) {
  // LocalStorage is acceptable for this test client; production should use a more XSS-resistant approach.
  localStorage.setItem(TOKEN_KEY, token);
}

export function getAccessToken() {
  return localStorage.getItem(TOKEN_KEY);
}

export function clearAuthStorage() {
  const deviceId = localStorage.getItem(DEVICE_KEY);
  localStorage.clear();
  if (deviceId) {
    localStorage.setItem(DEVICE_KEY, deviceId);
  }
}

export async function requireAuth() {
  const token = getAccessToken();
  if (!token) {
    window.location.href = '/student/login.html';
    throw new Error('Missing token');
  }

  try {
    const me = await apiGet('/auth/me', { skip401Redirect: true });
    return me;
  } catch (_error) {
    clearAuthStorage();
    window.location.href = '/student/login.html';
    throw new Error('Auth check failed');
  }
}

export async function redirectIfAuthenticated() {
  const token = getAccessToken();
  if (!token) {
    return;
  }

  try {
    const me = await apiGet('/auth/me', { skip401Redirect: true });
    if (me.role === 'STUDENT') {
      window.location.href = '/student/index.html';
      return;
    }

    if (me.role === 'TEACHER') {
      document.cookie = `panel_token=${encodeURIComponent(token)}; path=/panel; max-age=604800; SameSite=Lax${location.protocol === 'https:' ? '; Secure' : ''}`;
      window.location.href = '/panel/teacher/courses';
      return;
    }

    if (me.role === 'ADMIN') {
      document.cookie = `panel_token=${encodeURIComponent(token)}; path=/panel; max-age=604800; SameSite=Lax${location.protocol === 'https:' ? '; Secure' : ''}`;
      window.location.href = '/panel/admin/overview';
      return;
    }
  } catch (_error) {
    clearAuthStorage();
  }
}
