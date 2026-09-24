import { ApiError, apiPost } from './api.js';
import { ensureDeviceId, redirectIfAuthenticated, setAccessToken } from './auth.js';
import { withSubmitLock } from './ui.js';

const USERNAME_REGEX = /^[a-z0-9_]{3,30}$/;

function setError(message) {
  const box = document.getElementById('authError');
  if (!box) {
    return;
  }
  box.textContent = message || '';
  box.hidden = !message;
}

document.addEventListener('DOMContentLoaded', async () => {
  try {
    ensureDeviceId();
  } catch (_error) {
    setError('تعذر تهيئة جهازك الحالي. أعد تحميل الصفحة أو امسح بيانات الموقع.');
    return;
  }

  const form = document.getElementById('registerForm');
  const submit = document.getElementById('registerSubmit');

  if (!form || !submit) {
    return;
  }

  void redirectIfAuthenticated().catch(() => {});

  form.addEventListener('submit', (event) => {
    event.preventDefault();
    setError('');

    void withSubmitLock(submit, async () => {
      const formData = new FormData(form);
      const username = String(formData.get('username') || '').trim().toLowerCase();
      const fullName = String(formData.get('full_name') || '').trim();
      const password = String(formData.get('password') || '');
      const confirmPassword = String(formData.get('confirm_password') || '');

      if (!USERNAME_REGEX.test(username)) {
        setError('اسم المستخدم يجب أن يكون بين 3 و30 حرفًا ويحتوي على أحرف إنجليزية صغيرة أو أرقام أو _.');
        return;
      }

      if (fullName.length < 2) {
        setError('الاسم الكامل قصير جدًا.');
        return;
      }

      if (password.length < 8) {
        setError('كلمة المرور يجب أن تكون 8 أحرف على الأقل.');
        return;
      }

      if (password !== confirmPassword) {
        setError('تأكيد كلمة المرور غير مطابق.');
        return;
      }

      try {
        const result = await apiPost('/auth/register', {
          username,
          full_name: fullName,
          password,
          device_id: ensureDeviceId(),
        }, {
          requiresAuth: false,
          skip401Redirect: true,
        });

        setAccessToken(result.token);
        window.location.href = '/student/index.html';
      } catch (error) {
        if (error instanceof ApiError) {
          setError(error.message || 'تعذر إنشاء الحساب.');
          return;
        }

        setError('حدث خطأ غير متوقع. حاول لاحقًا.');
      }
    });
  });
});
