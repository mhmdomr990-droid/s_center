import { apiGet } from './api.js';

const NAV_ITEMS = [
  { key: 'home', href: '/student/index.html', label: 'الرئيسية', icon: '⌂' },
  { key: 'wallet', href: '/student/wallet.html', label: 'المحفظة', icon: '$' },
  { key: 'courses', href: '/student/courses.html', label: 'دوراتي', icon: '▶' },
  { key: 'notifications', href: '/student/notifications.html', label: 'الإشعارات', icon: '◉', hasUnread: true },
  { key: 'profile', href: '/student/profile.html', label: 'حسابي', icon: '⚙' },
];

function renderItem(item, activeKey) {
  const activeClass = item.key === activeKey ? 'is-active' : '';
  const unreadMarkup = item.hasUnread ? '<span class="student-nav-badge" data-unread-badge hidden>0</span>' : '';

  return `
    <a class="student-nav-link ${activeClass}" href="${item.href}" aria-label="${item.label}">
      <span class="student-nav-icon">${item.icon}</span>
      <span class="student-nav-label">${item.label}</span>
      ${unreadMarkup}
    </a>
  `;
}

export function setUnreadBadge(count) {
  const safeCount = Number(count || 0);
  localStorage.setItem('student_unread_count', String(safeCount));

  const badges = document.querySelectorAll('[data-unread-badge]');
  badges.forEach((badge) => {
    if (safeCount > 0) {
      badge.textContent = safeCount > 99 ? '99+' : String(safeCount);
      badge.hidden = false;
    } else {
      badge.textContent = '0';
      badge.hidden = true;
    }
  });
}

function hydrateUnreadBadgeFromStorage() {
  const stored = Number(localStorage.getItem('student_unread_count') || 0);
  setUnreadBadge(stored);
}

export async function refreshUnreadBadge() {
  try {
    const data = await apiGet('/notifications', { query: { limit: 1, offset: 0 }, skip401Redirect: true });
    setUnreadBadge(data?.unread_count || 0);
  } catch (_error) {
    // Keep UI usable even if notifications endpoint fails.
  }
}

export function initNav(activeKey) {
  const nav = document.getElementById('studentNav');
  if (!nav) {
    return;
  }

  nav.innerHTML = `
    <div class="student-nav-inner">
      <div class="student-nav-brand">
        <strong>مركز العلوم</strong>
        <small>تطبيق الطالب</small>
      </div>
      <button type="button" class="polish-theme-toggle student-theme-toggle" data-theme-toggle aria-label="تبديل النمط">
        <span class="moon">◐</span>
        <span class="sun">☀</span>
      </button>
      <div class="student-nav-links">
        ${NAV_ITEMS.map((item) => renderItem(item, activeKey)).join('')}
      </div>
    </div>
  `;

  hydrateUnreadBadgeFromStorage();
  window.Polish?.initThemeToggle(nav);
  void refreshUnreadBadge();
}
