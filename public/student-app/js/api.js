const LOGIN_URL = '/student/login.html';

export class ApiError extends Error {
  constructor(message, status, code, payload) {
    super(message);
    this.name = 'ApiError';
    this.status = status;
    this.code = code;
    this.payload = payload;
  }
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

  document.cookie = `${key}=${encodeURIComponent(value)}; path=/; max-age=${365 * 86400}; SameSite=Lax${location.protocol === 'https:' ? '; Secure' : ''}`;
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

  document.cookie = `${key}=; path=/; max-age=0; SameSite=Lax${location.protocol === 'https:' ? '; Secure' : ''}`;
}

function getToken() {
  return readStorage('access_token');
}

function clearToken() {
  removeStorage('access_token');
}

function toQuery(params = {}) {
  const query = new URLSearchParams();
  Object.entries(params).forEach(([key, value]) => {
    if (value === null || value === undefined || value === '') {
      return;
    }
    query.set(key, String(value));
  });
  const queryString = query.toString();
  return queryString ? `?${queryString}` : '';
}

function maybeRedirectToLogin() {
  if (window.location.pathname !== LOGIN_URL) {
    window.location.href = LOGIN_URL;
  }
}

function toArabicError(message) {
  const text = String(message || '').trim();
  if (!text) {
    return 'تعذر إكمال الطلب. حاول مرة أخرى.';
  }

  if (/insufficient balance/i.test(text)) {
    return 'رصيد المحفظة غير كافٍ لإتمام العملية.';
  }

  if (/request failed/i.test(text)) {
    return 'تعذر تنفيذ الطلب. حاول مرة أخرى بعد قليل.';
  }

  return text;
}

export async function apiRequest(path, options = {}) {
  const {
    method = 'GET',
    body,
    headers = {},
    query,
    requiresAuth = true,
    idempotent = false,
    skip401Redirect = false,
    timeoutMs = 20000,
  } = options;

  const requestHeaders = {
    Accept: 'application/json',
    ...headers,
  };

  if (body !== undefined) {
    requestHeaders['Content-Type'] = 'application/json';
  }

  if (requiresAuth) {
    const token = getToken();
    console.log('[API_DEBUG] token before request', !!token, path, method);
    if (token) {
      requestHeaders.Authorization = `Bearer ${token}`;
    }
  }

  if (idempotent) {
    requestHeaders['Idempotency-Key'] = crypto.randomUUID();
  }

  const controller = typeof AbortController === 'function' ? new AbortController() : null;
  const timeoutId = controller && timeoutMs > 0
    ? window.setTimeout(() => controller.abort(), timeoutMs)
    : null;

  console.log('[API_DEBUG] sending fetch', path, method, requestHeaders.Authorization ? 'with-token' : 'no-token', body);

  let response;
  try {
    response = await fetch(`/api${path}${toQuery(query)}`, {
      method,
      headers: requestHeaders,
      body: body !== undefined ? JSON.stringify(body) : undefined,
      signal: controller?.signal,
    });
    console.log('[API_DEBUG] fetch resolved', path, method, response.status, response.statusText);
  } catch (error) {
    console.log('[API_DEBUG] fetch threw', path, method, error);
    if (error instanceof DOMException && error.name === 'AbortError') {
      throw new ApiError('انتهت مهلة الاتصال بالخادم. حاول مرة أخرى.', 408);
    }
    throw error;
  } finally {
    if (timeoutId) {
      window.clearTimeout(timeoutId);
    }
  }

  let payload = null;
  const text = await response.text();
  console.log('[API_DEBUG] raw response for', path, text?.slice(0, 500));
  if (text) {
    try {
      payload = JSON.parse(text);
    } catch (_error) {
      payload = null;
    }
  }

  if (!response.ok || payload?.success === false) {
    const message = toArabicError(payload?.message || response.statusText || 'Request failed');
    const error = new ApiError(message, response.status, payload?.code, payload);

    if (error.status === 401) {
      clearToken();
      if (!skip401Redirect) {
        maybeRedirectToLogin();
      }
    }

    console.log('[API_DEBUG] API error thrown', error);
    throw error;
  }

  return payload?.data;
}

export function apiGet(path, options = {}) {
  return apiRequest(path, { ...options, method: 'GET' });
}

export function apiPost(path, body, options = {}) {
  return apiRequest(path, { ...options, method: 'POST', body });
}

export function apiPatch(path, body, options = {}) {
  return apiRequest(path, { ...options, method: 'PATCH', body });
}
