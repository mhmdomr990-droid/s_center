import { ApiError, apiGet, apiPost } from './api.js';
import { requireAuth } from './auth.js';
import { formatDate, formatMoney } from './format.js';
import { initNav } from './nav.js';
import { renderBreadcrumb, setViewState, showToast, withSubmitLock } from './ui.js';

const PAGE_LIMIT = 20;

function topupStatusBadge(status) {
  if (status === 'APPROVED') {
    return '<span class="student-badge success">مقبول</span>';
  }
  if (status === 'REJECTED') {
    return '<span class="student-badge danger">مرفوض</span>';
  }
  return '<span class="student-badge warning">قيد المراجعة</span>';
}

function txTypeLabel(type) {
  if (type === 'TOPUP') {
    return 'شحن';
  }
  if (type === 'PURCHASE') {
    return 'شراء';
  }
  return type;
}

document.addEventListener('DOMContentLoaded', async () => {
  initNav('wallet');
  await requireAuth();

  const state = document.getElementById('walletState');
  const balance = document.getElementById('walletBalance');
  const topupForm = document.getElementById('topupForm');
  const topupSubmit = document.getElementById('topupSubmit');
  const topupMessage = document.getElementById('topupMessage');
  const topupList = document.getElementById('topupList');
  const topupMore = document.getElementById('topupMore');
  const txList = document.getElementById('txList');
  const txMore = document.getElementById('txMore');
  const breadcrumb = document.getElementById('studentBreadcrumb');

  if (!state || !balance || !topupForm || !topupSubmit || !topupMessage || !topupList || !topupMore || !txList || !txMore) {
    return;
  }

  renderBreadcrumb(breadcrumb, [
    { label: 'الرئيسية', href: '/student/index.html' },
    { label: 'المحفظة' },
  ]);

  let topupOffset = 0;
  let txOffset = 0;

  async function loadWallet() {
    const data = await apiGet('/wallet');
    if (window.Polish?.animateCount) {
      window.Polish.animateCount(balance, Number(data.balance || 0), { duration: 720, decimals: 2, suffix: ' ل.س' });
    } else {
      balance.textContent = `${formatMoney(data.balance)} ل.س`;
    }
  }

  async function loadTopups(append) {
    const data = await apiGet('/wallet/topup-requests', {
      query: { limit: PAGE_LIMIT, offset: topupOffset },
    });

    const items = data.items || [];
    if (!append) {
      topupList.innerHTML = '';
    }

    if (!items.length && !append) {
      topupList.innerHTML = window.Polish?.emptyState
        ? window.Polish.emptyState({
          title: 'لا توجد طلبات شحن بعد',
          message: 'أرسل أول طلب شحن وسيظهر سجل المتابعة هنا.',
        })
        : '<div class="student-empty-inline">لا توجد طلبات شحن بعد.</div>';
    } else {
      topupList.insertAdjacentHTML(
        'beforeend',
        items
          .map((item) => `
            <article class="student-card student-compact">
              <div class="student-card-row">
                <strong>${formatMoney(item.amount)} ل.س</strong>
                ${topupStatusBadge(item.status)}
              </div>
              <p class="student-muted">${item.method} - <span dir="ltr">${item.reference_number}</span> <button type="button" class="polish-copy-btn" data-copy-text="${item.reference_number}" data-copy-success="تم نسخ الرقم المرجعي">نسخ</button></p>
              <p class="student-muted">المرسل: ${item.sender_name}</p>
              <p class="student-muted">${formatDate(item.created_at)}</p>
              ${item.reject_reason ? `<p class="student-danger-text">سبب الرفض: ${item.reject_reason}</p>` : ''}
            </article>
          `)
          .join(''),
      );
      window.Polish?.bindCopyButtons(topupList);
    }

    topupOffset += items.length;
    topupMore.hidden = topupOffset >= (data.total || 0);
  }

  async function loadTransactions(append) {
    const data = await apiGet('/wallet/transactions', {
      query: { limit: PAGE_LIMIT, offset: txOffset },
    });

    const items = data.items || [];
    if (!append) {
      txList.innerHTML = '';
    }

    if (!items.length && !append) {
      txList.innerHTML = window.Polish?.emptyState
        ? window.Polish.emptyState({
          title: 'لا يوجد سجل مالي بعد',
          message: 'ستظهر عمليات الشحن والشراء هنا فور تنفيذها.',
        })
        : '<div class="student-empty-inline">لا توجد حركات مالية بعد.</div>';
    } else {
      txList.insertAdjacentHTML(
        'beforeend',
        items
          .map((item) => `
            <article class="student-card student-compact">
              <div class="student-card-row">
                <strong>${txTypeLabel(item.type)}</strong>
                <strong>${formatMoney(item.amount)} ل.س</strong>
              </div>
              <p class="student-muted">الرصيد بعد العملية: ${formatMoney(item.balance_after)} ل.س</p>
              <p class="student-muted">${item.description || '-'}</p>
              <p class="student-muted">${formatDate(item.created_at)}</p>
            </article>
          `)
          .join(''),
      );
    }

    txOffset += items.length;
    txMore.hidden = txOffset >= (data.total || 0);
  }

  topupForm.addEventListener('submit', (event) => {
    event.preventDefault();
    topupMessage.textContent = '';
    topupMessage.className = 'student-inline-message';

    void withSubmitLock(topupSubmit, async () => {
      const formData = new FormData(topupForm);
      const payload = {
        amount: String(formData.get('amount') || '').trim(),
        method: String(formData.get('method') || '').trim(),
        reference_number: String(formData.get('reference_number') || '').trim(),
        sender_name: String(formData.get('sender_name') || '').trim(),
        note: String(formData.get('note') || '').trim() || null,
      };

      try {
        const created = await apiPost('/wallet/topup-requests', payload, { idempotent: true });
        topupMessage.textContent = `تم إرسال الطلب بنجاح. الحالة الحالية: ${created.status}.`;
        topupMessage.className = 'student-inline-message success';
        showToast('تم إرسال طلب الشحن بنجاح.', 'success');
        topupForm.reset();
        topupOffset = 0;
        await loadTopups(false);
      } catch (error) {
        if (error instanceof ApiError) {
          topupMessage.textContent = error.message;
        } else {
          topupMessage.textContent = 'تعذر إرسال الطلب.';
        }
        topupMessage.className = 'student-inline-message error';
        showToast(topupMessage.textContent || 'تعذر إرسال طلب الشحن.', 'error');
      }
    });
  });

  topupMore.addEventListener('click', () => {
    void loadTopups(true);
  });

  txMore.addEventListener('click', () => {
    void loadTransactions(true);
  });

  try {
    setViewState(state, {
      type: 'loading',
      title: 'جار تحميل المحفظة',
      message: 'لحظات...',
      variant: 'detail',
    });

    await loadWallet();
    await loadTopups(false);
    await loadTransactions(false);
    window.Polish?.initPullToRefresh({
      container: document.querySelector('.student-main'),
      onRefresh: async () => {
        topupOffset = 0;
        txOffset = 0;
        await loadWallet();
        await loadTopups(false);
        await loadTransactions(false);
      },
    });
    setViewState(state, null);
  } catch (error) {
    setViewState(state, {
      type: 'error',
      title: 'تعذر تحميل صفحة المحفظة',
      message: error?.message || 'حاول لاحقًا.',
      actionHref: '/student/wallet.html',
      actionLabel: 'إعادة المحاولة',
    });
  }
});
