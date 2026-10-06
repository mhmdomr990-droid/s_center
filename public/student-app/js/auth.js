import { apiGet } from './api.js';

const TOKEN_KEY = 'access_token';
const DEVICE_KEY = 'device_id';

function setCookie(name, value, maxAgeDays = 365) {
  const secure = location.protocol === 'https:' ? '; Secure' : '';
  document.cookie = `${name}=${encodeURIComponent(value)}; path=/; max-age=${maxAgeDays * 86400}; SameSite=Lax${secure}`;
}

function getCookie(name) {
  const value = `; ${document.cookie}`;
  const parts = value.split(`; ${name}=`);
  if (parts.length === 2) {
    return decodeURIComponent(parts.pop()?.split(';').shift() || '');
  }
  return '';
}

function readStorage(key) {
  try {
    if (localStorage.getItem(key) !== null) {
      return localStorage.getItem(key);
    }
  } catch (_error) {
    // Ignore and fall back below.
  }

  try {
    if (sessionStorage.getItem(key) !== null) {
      return sessionStorage.getItem(key);
    }
  } catch (_error) {
    // Ignore and fall back below.
  }

  return getCookie(key) || null;
}

function writeStorage(key, value) {
  try {
    localStorage.setItem(key, value);
    return;
  } catch (_error) {
    // Ignore and fall back below.
  }

  try {
    sessionStorage.setItem(key, value);
    return;
  } catch (_error) {
    // Ignore and fall back below.
  }

  setCookie(key, value, 365);
}

function removeStorage(key) {
  try {
    localStorage.removeItem(key);
  } catch (_error) {
    // Ignore and fall back below.
  }

  try {
    sessionStorage.removeItem(key);
  } catch (_error) {
    // Ignore and fall back below.
  }

  setCookie(key, '', 0);
}

export function ensureDeviceId() {
  let deviceId = readStorage(DEVICE_KEY);
  if (!deviceId) {
    deviceId = (typeof crypto !== 'undefined' && crypto.randomUUID) ? crypto.randomUUID() : `device-${Date.now()}-${Math.random().toString(16).slice(2)}`;
    writeStorage(DEVICE_KEY, deviceId);
  }
  return deviceId;
}

export function getDeviceId() {
  return readStorage(DEVICE_KEY);
}

export function setAccessToken(token) {
  writeStorage(TOKEN_KEY, token);
}

export function getAccessToken() {
  return readStorage(TOKEN_KEY);
}

export function clearAuthStorage() {
  const deviceId = readStorage(DEVICE_KEY);
  removeStorage(TOKEN_KEY);
  if (deviceId) {
    writeStorage(DEVICE_KEY, deviceId);
  } else {
    removeStorage(DEVICE_KEY);
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
