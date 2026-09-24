import { apiGet, apiPost } from './api.js';
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

  try {
    setViewState(state, {
      type: 'loading',
      title: 'جار تحميل الملف الشخصي',
      message: 'لحظات...',
    });

    const me = await apiGet('/auth/me');
    setText('profileUsername', me.username);
    setText('profileFullName', me.full_name);
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
