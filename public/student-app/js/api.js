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

function getToken() {
  return localStorage.getItem('access_token');
}

function clearToken() {
  localStorage.removeItem('access_token');
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

  let response;
  try {
    response = await fetch(`/api${path}${toQuery(query)}`, {
      method,
      headers: requestHeaders,
      body: body !== undefined ? JSON.stringify(body) : undefined,
      signal: controller?.signal,
    });
  } catch (error) {
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
