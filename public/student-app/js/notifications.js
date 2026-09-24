import { apiGet, apiPatch } from './api.js';
import { requireAuth } from './auth.js';
import { formatDate } from './format.js';
import { initNav, setUnreadBadge } from './nav.js';
import { renderBreadcrumb, setViewState, showToast } from './ui.js';

const LIMIT = 20;

document.addEventListener('DOMContentLoaded', async () => {
  initNav('notifications');
  await requireAuth();

  const state = document.getElementById('notificationsState');
  const list = document.getElementById('notificationsList');
  const more = document.getElementById('notificationsMore');
  const readAll = document.getElementById('readAllButton');
  const breadcrumb = document.getElementById('studentBreadcrumb');

  if (!state || !list || !more || !readAll) {
    return;
  }

  renderBreadcrumb(breadcrumb, [
    { label: 'الرئيسية', href: '/student/index.html' },
    { label: 'الإشعارات' },
  ]);

  let offset = 0;
  let unreadCount = 0;

  function renderItem(item) {
    return `
      <article class="student-card student-compact student-notification ${item.is_read ? '' : 'unread'}" data-id="${item.id}" data-read="${item.is_read ? '1' : '0'}">
        <div class="student-card-row">
          <strong>${item.title}</strong>
          ${item.is_read ? '' : '<span class="student-badge warning">جديد</span>'}
        </div>
        <p>${item.body}</p>
        <p class="student-muted">${formatDate(item.created_at)}</p>
      </article>
    `;
  }

  async function markAsRead(card) {
    if (!card || card.dataset.read === '1') {
      return;
    }

    const notificationId = card.dataset.id;
    await apiPatch(`/notifications/${notificationId}/read`);

    card.dataset.read = '1';
    card.classList.remove('unread');
    const badge = card.querySelector('.student-badge');
    if (badge) {
      badge.remove();
    }

    unreadCount = Math.max(0, unreadCount - 1);
    setUnreadBadge(unreadCount);
    showToast('تم تعليم الإشعار كمقروء.', 'success');
  }

  async function loadNotifications(append) {
    const data = await apiGet('/notifications', {
      query: { limit: LIMIT, offset },
    });

    const items = data.items || [];
    unreadCount = Number(data.unread_count || 0);
    setUnreadBadge(unreadCount);

    if (!append) {
      list.innerHTML = '';
    }

    if (!items.length && !append) {
      list.innerHTML = window.Polish?.emptyState
        ? window.Polish.emptyState({
          title: 'صندوق الإشعارات فارغ',
          message: 'عند وجود تحديثات جديدة ستظهر لك هنا مباشرة.',
        })
        : '<div class="student-empty-inline">لا توجد إشعارات.</div>';
    } else {
      list.insertAdjacentHTML('beforeend', items.map(renderItem).join(''));
    }

    offset += items.length;
    more.hidden = offset >= (data.total || 0);
  }

  list.addEventListener('click', (event) => {
    const card = event.target.closest('.student-notification');
    if (!card) {
      return;
    }

    void markAsRead(card);
  });

  more.addEventListener('click', () => {
    void loadNotifications(true);
  });

  readAll.addEventListener('click', () => {
    void (async () => {
      await apiPatch('/notifications/read-all');
      unreadCount = 0;
      setUnreadBadge(0);
      list.querySelectorAll('.student-notification').forEach((card) => {
        card.dataset.read = '1';
        card.classList.remove('unread');
      });
      list.querySelectorAll('.student-notification .student-badge').forEach((badge) => badge.remove());
      showToast('تم تعليم كل الإشعارات كمقروءة.', 'success');
    })();
  });

  try {
    setViewState(state, {
      type: 'loading',
      title: 'جار تحميل الإشعارات',
      message: 'لحظات...',
      variant: 'table',
    });

    await loadNotifications(false);
    window.Polish?.initPullToRefresh({
      container: document.querySelector('.student-main'),
      onRefresh: async () => {
        offset = 0;
        await loadNotifications(false);
      },
    });
    setViewState(state, null);
  } catch (error) {
    setViewState(state, {
      type: 'error',
      title: 'تعذر تحميل الإشعارات',
      message: error?.message || 'حاول لاحقًا.',
      actionHref: '/student/notifications.html',
      actionLabel: 'إعادة المحاولة',
    });
  }
});
