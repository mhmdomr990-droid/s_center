import { ApiError, apiGet, apiPost } from './api.js';
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

function populateSpecializationOptions() {
  const select = document.querySelector('select[name="specialization_id"]');
  if (!select) {
    return;
  }

  select.innerHTML = '<option value="">اختر الاختصاص</option>';

  apiGet('/specializations', { requiresAuth: false, skip401Redirect: true })
    .then((specializations) => {
      if (!Array.isArray(specializations) || !specializations.length) {
        select.innerHTML = '<option value="">لا توجد اختصاصات منشورة</option>';
        return;
      }

      select.innerHTML = '<option value="">اختر الاختصاص</option>';
      specializations.forEach((item) => {
        const option = document.createElement('option');
        option.value = String(item.id);
        option.textContent = item.name;
        select.appendChild(option);
      });
    })
    .catch(() => {
      select.innerHTML = '<option value="">تعذر تحميل الاختصاصات</option>';
    });
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

  populateSpecializationOptions();
  void redirectIfAuthenticated().catch(() => {});

  form.addEventListener('submit', (event) => {
    event.preventDefault();
    setError('');

    void withSubmitLock(submit, async () => {
      const formData = new FormData(form);
      const username = String(formData.get('username') || '').trim().toLowerCase();
      const fullName = String(formData.get('full_name') || '').trim();
      const specializationId = Number(formData.get('specialization_id') || 0) || null;
      const phone = String(formData.get('phone') || '').trim();
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

      if (!specializationId) {
        setError('يرجى اختيار الاختصاص الخاص بك.');
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
          specialization_id: specializationId,
          phone: phone || null,
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
