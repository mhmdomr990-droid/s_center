import { apiGet, apiPatch, apiPost } from './api.js';
import { clearAuthStorage, requireAuth } from './auth.js';
import { formatMoney } from './format.js';
import { initNav } from './nav.js';
import { renderBreadcrumb, setText, setViewState, showToast, withSubmitLock } from './ui.js';

function logout() {
  clearAuthStorage();
  window.location.replace('/');
}

document.addEventListener('DOMContentLoaded', async () => {
  initNav('profile');
  await requireAuth();

  const state = document.getElementById('profileState');
  const form = document.getElementById('passwordForm');
  const submit = document.getElementById('passwordSubmit');
  const msg = document.getElementById('passwordMessage');
  const profileForm = document.getElementById('profileForm');
  const profileSubmit = document.getElementById('profileSubmit');
  const profileMsg = document.getElementById('profileMessage');
  const profileSpecializationRow = document.getElementById('profileSpecializationRow');
  const logoutButton = document.getElementById('logoutButton');
  const logoutAllButton = document.getElementById('logoutAllButton');

  if (!state || !form || !submit || !msg || !logoutButton || !logoutAllButton) {
    return;
  }

  logoutButton.addEventListener('click', logout);

  logoutAllButton.addEventListener('click', () => {
    void withSubmitLock(logoutAllButton, async () => {
      try {
        await apiPost('/auth/logout-all', {});
      } finally {
        logout();
      }
    });
  });

  form.addEventListener('submit', (event) => {
    event.preventDefault();
    msg.textContent = '';
    msg.className = 'student-inline-message';

    void withSubmitLock(submit, async () => {
      const data = new FormData(form);
      const oldPassword = String(data.get('old_password') || '');
      const newPassword = String(data.get('new_password') || '');
      const confirmPassword = String(data.get('confirm_password') || '');

      if (newPassword.length < 8) {
        msg.textContent = 'كلمة المرور الجديدة يجب أن تكون 8 أحرف على الأقل.';
        msg.className = 'student-inline-message error';
        return;
      }

      if (newPassword !== confirmPassword) {
        msg.textContent = 'تأكيد كلمة المرور غير مطابق.';
        msg.className = 'student-inline-message error';
        return;
      }

      await apiPost('/auth/change-password', {
        old_password: oldPassword,
        new_password: newPassword,
      });

      form.reset();
      msg.textContent = 'تم تغيير كلمة المرور بنجاح.';
      msg.className = 'student-inline-message success';
      showToast('تم تحديث كلمة المرور بنجاح.', 'success');
    });
  });

  if (profileForm && profileSubmit && profileMsg) {
    profileForm.addEventListener('submit', (event) => {
      event.preventDefault();
      profileMsg.textContent = '';
      profileMsg.className = 'student-inline-message';

      console.log('[PROFILE_DEBUG] submit clicked');

      void withSubmitLock(profileSubmit, async () => {
        try {
          const data = new FormData(profileForm);
          const payload = {
            full_name: String(data.get('full_name') || '').trim(),
            phone: String(data.get('phone') || '').trim() || null,
          };

          console.log('[PROFILE_DEBUG] payload before patch', payload);

          if (profileSpecializationRow && !profileSpecializationRow.hidden) {
            const specializationValue = String(data.get('specialization_id') || '');
            payload.specialization_id = specializationValue ? Number(specializationValue) : null;
          }

          if (!payload.full_name || payload.full_name.length < 2) {
            profileMsg.textContent = 'الاسم الكامل مطلوب.';
            profileMsg.className = 'student-inline-message error';
            console.log('[PROFILE_DEBUG] validation failed: empty full_name');
            return;
          }

          console.log('[PROFILE_DEBUG] sending PATCH /auth/profile');
          const result = await apiPatch('/auth/profile', payload);
          console.log('[PROFILE_DEBUG] PATCH resolved', result);
          setText('profileFullName', result.full_name || 'غير محدد');
          setText('profilePhone', result.phone || 'غير محدد');
          profileMsg.textContent = 'تم حفظ التعديلات بنجاح.';
          profileMsg.className = 'student-inline-message success';
          showToast('تم تحديث الملف الشخصي بنجاح.', 'success');
        } catch (error) {
          console.log('[PROFILE_DEBUG] PATCH failed', error);
          const message = error?.message || 'تعذر حفظ التعديلات. حاول مرة أخرى.';
          profileMsg.textContent = message;
          profileMsg.className = 'student-inline-message error';
          showToast('تعذر حفظ التعديلات.', 'error');
        }
      });
    });
  }

  try {
    setViewState(state, {
      type: 'loading',
      title: 'جار تحميل الملف الشخصي',
      message: 'لحظات...',
    });

    const me = await apiGet('/auth/me');
    setText('profileUsername', me.username);
    setText('profileFullName', me.full_name);
    setText('profilePhone', me.phone || 'غير محدد');

    if (profileForm) {
      const fullNameInput = profileForm.querySelector('input[name="full_name"]');
      const phoneInput = profileForm.querySelector('input[name="phone"]');
      if (fullNameInput) {
        fullNameInput.value = me.full_name || '';
      }
      if (phoneInput) {
        phoneInput.value = me.phone || '';
      }
    }

    if (profileSpecializationRow && me.role === 'STUDENT') {
      profileSpecializationRow.hidden = false;
      const specializationSelect = profileForm?.querySelector('select[name="specialization_id"]');
      const specializations = await apiGet('/specializations', { requiresAuth: false, skip401Redirect: true });
      if (specializationSelect) {
        specializationSelect.innerHTML = '<option value="">اختر الاختصاص</option>';
        specializations.forEach((item) => {
          const option = document.createElement('option');
          option.value = String(item.id);
          option.textContent = item.name;
          if (Number(item.id) === Number(me.specialization_id)) {
            option.selected = true;
          }
          specializationSelect.appendChild(option);
        });
        specializationSelect.value = me.specialization_id ? String(me.specialization_id) : '';
      }
    }

    const balanceElement = document.getElementById('profileBalance');
    if (window.Polish?.animateCount && balanceElement) {
      window.Polish.animateCount(balanceElement, Number(me.balance || 0), { duration: 700, decimals: 2, suffix: ' ل.س' });
    } else {
      setText('profileBalance', `${formatMoney(me.balance || 0)} ل.س`);
    }

    setViewState(state, null);
  } catch (error) {
    setViewState(state, {
      type: 'error',
      title: 'تعذر تحميل بيانات الحساب',
      message: error?.message || 'حاول لاحقًا.',
      actionHref: '/student/profile.html',
      actionLabel: 'إعادة المحاولة',
    });
  }
  const breadcrumb = document.getElementById('studentBreadcrumb');
  renderBreadcrumb(breadcrumb, [
    { label: 'الرئيسية', href: '/student/index.html' },
    { label: 'حسابي' },
  ]);
});
