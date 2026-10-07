import { apiGet, apiPost } from './api.js';
import { requireAuth } from './auth.js';
import { formatDate, formatMoney } from './format.js';
import { initNav } from './nav.js';
import { renderBreadcrumb, setViewState, showToast } from './ui.js';

const PAYMENTS_STEP = 10;

document.addEventListener('DOMContentLoaded', async () => {
  initNav('courses');
  await requireAuth();

  const state = document.getElementById('coursesState');
  const coursesList = document.getElementById('myCoursesList');
  const paymentsList = document.getElementById('paymentsList');
  const paymentsMore = document.getElementById('paymentsMore');
  const tabCourses = document.getElementById('tabCourses');
  const tabPayments = document.getElementById('tabPayments');
  const coursesSection = document.getElementById('coursesSection');
  const paymentsSection = document.getElementById('paymentsSection');
  const breadcrumb = document.getElementById('studentBreadcrumb');

  if (!state || !coursesList || !paymentsList || !paymentsMore || !tabCourses || !tabPayments || !coursesSection || !paymentsSection) {
    return;
  }

  let payments = [];
  let paymentsVisible = 0;

  async function openSwapModal(course) {
    try {
      const alternatives = await apiGet('/courses', {
        query: { specializationId: course.specialization_id },
      });

      const validAlternatives = (Array.isArray(alternatives) ? alternatives : []).filter((item) => {
        const isCurrentCourse = Number(item.id) === Number(course.id);
        const isAlreadyOwned = Boolean(item.purchased || item.is_granted || item.source === 'GRANTED');
        return !isCurrentCourse && !isAlreadyOwned;
      });

      if (!validAlternatives.length) {
        showToast('لا توجد مواد بديلة متاحة حاليًا.', 'error');
        return;
      }

      const modal = document.createElement('div');
      modal.style.position = 'fixed';
      modal.style.inset = '0';
      modal.style.background = 'rgba(15, 23, 42, 0.65)';
      modal.style.display = 'flex';
      modal.style.alignItems = 'center';
      modal.style.justifyContent = 'center';
      modal.style.zIndex = '2000';
      modal.style.padding = '1rem';

      const card = document.createElement('div');
      card.style.width = 'min(520px, 100%)';
      card.style.background = 'var(--panel)';
      card.style.color = 'var(--text)';
      card.style.border = '1px solid var(--border)';
      card.style.borderRadius = '16px';
      card.style.padding = '1.25rem';
      card.style.boxShadow = 'var(--shadow)';

      const selectId = `courseSwapSelect-${Date.now()}`;
      card.innerHTML = `
        <div style="display:flex;justify-content:space-between;align-items:center;gap:1rem;margin-bottom:1rem;">
          <h3 style="margin:0;font-size:1.3rem;">تبديل المادة</h3>
          <button type="button" class="student-btn student-btn-secondary" data-swap-close="true">إغلاق</button>
        </div>
        <p style="margin:0 0 0.75rem;color:var(--muted);">من: <strong style="color:var(--text);">${course.name}</strong></p>
        <label class="student-form-row" style="margin-bottom:0.75rem;display:grid;gap:0.5rem;">
          <span style="color:var(--text);font-weight:600;">اختر المادة البديلة</span>
          <select id="${selectId}" style="width:100%;padding:0.7rem;border-radius:10px;border:1px solid var(--border);background:var(--panel);color:var(--text);">
            ${validAlternatives
              .map((item) => `<option value="${item.id}">${item.name} - ${formatMoney(item.price)} ل.س</option>`)
              .join('')}
          </select>
        </label>
        <label class="student-form-row" style="margin-bottom:0.75rem;display:grid;gap:0.5rem;">
          <span style="color:var(--text);font-weight:600;">سبب الطلب (اختياري)</span>
          <textarea id="swapReason" rows="3" placeholder="مثال: أريد مادة مختلفة في نفس التخصص" style="width:100%;padding:0.7rem;border-radius:10px;border:1px solid var(--border);background:var(--panel);color:var(--text);resize:vertical;"></textarea>
        </label>
        <div style="display:flex;justify-content:flex-end;gap:0.75rem;">
          <button type="button" class="student-btn student-btn-secondary" data-swap-close="true">إلغاء</button>
          <button type="button" class="student-btn student-btn-primary" data-swap-submit="true">إرسال طلب التبديل</button>
        </div>
      `;

      modal.appendChild(card);
      document.body.appendChild(modal);

      const closeButtons = modal.querySelectorAll('[data-swap-close="true"]');
      closeButtons.forEach((button) => button.addEventListener('click', () => modal.remove()));

      const submitButton = modal.querySelector('[data-swap-submit="true"]');
      submitButton.addEventListener('click', async () => {
        const selectedId = Number(modal.querySelector(`#${selectId}`).value);
        const reason = String(modal.querySelector('#swapReason')?.value || '').trim();
        if (!selectedId) {
          showToast('يرجى اختيار مادة بديلة.', 'error');
          return;
        }

        try {
          await apiPost('/course-swap-requests', {
            old_purchase_id: Number(course.purchase_id),
            new_course_id: selectedId,
            reason: reason || null,
          });
          modal.remove();
          showToast('تم إرسال طلب تبديل المادة بنجاح. بانتظار موافقة الإدارة.', 'success');
          await refreshSwapRequests();
        } catch (error) {
          showToast(error?.message || 'تعذر إرسال طلب التبديل.', 'error');
        }
      });
    } catch (error) {
      showToast(error?.message || 'تعذر تحميل المواد البديلة.', 'error');
    }
  }

  async function refreshSwapRequests() {
    try {
      const requests = await apiGet('/course-swap-requests');
      const swapPanel = document.getElementById('swapRequestsPanel');
      if (!swapPanel) {
        return;
      }

      if (!Array.isArray(requests) || !requests.length) {
        swapPanel.innerHTML = '<div class="student-empty-inline">لا توجد طلبات تبديل.</div>';
        return;
      }

      swapPanel.innerHTML = requests
        .map((request) => {
          const statusText = request.status === 'APPROVED' ? 'موافقة' : request.status === 'REJECTED' ? 'مرفوضة' : 'قيد المراجعة';
          const statusClass = request.status === 'APPROVED' ? 'student-badge success' : request.status === 'REJECTED' ? 'student-badge error' : 'student-badge';
          return `
            <article class="student-card student-compact">
              <div class="student-card-row">
                <strong>${request.old_course_name || 'المادة الحالية'}</strong>
                <span class="${statusClass}">${statusText}</span>
              </div>
              <p class="student-muted">إلى: ${request.new_course_name || 'مادة بديلة'}</p>
              ${request.admin_note ? `<p class="student-muted">ملاحظة الإدارة: ${request.admin_note}</p>` : ''}
            </article>
          `;
        })
        .join('');
    } catch (_error) {
      const swapPanel = document.getElementById('swapRequestsPanel');
      if (swapPanel) {
        swapPanel.innerHTML = '<div class="student-empty-inline">تعذر تحميل طلبات التبديل.</div>';
      }
    }
  }

  function showTab(tab) {
    if (tab === 'payments') {
      paymentsSection.hidden = false;
      coursesSection.hidden = true;
      tabPayments.classList.add('is-active');
      tabCourses.classList.remove('is-active');
      renderBreadcrumb(breadcrumb, [
        { label: 'الرئيسية', href: '/student/index.html' },
        { label: 'مدفوعاتي' },
      ]);
    } else {
      coursesSection.hidden = false;
      paymentsSection.hidden = true;
      tabCourses.classList.add('is-active');
      tabPayments.classList.remove('is-active');
      renderBreadcrumb(breadcrumb, [
        { label: 'الرئيسية', href: '/student/index.html' },
        { label: 'مقرراتي' },
      ]);
    }
  }

  function getCourseStatus(course) {
    if (course?.is_granted || course?.source === 'GRANTED') {
      return { label: 'مجاني', className: 'student-badge success' };
    }
    return { label: 'مشترى', className: 'student-badge success' };
  }

  function renderPaymentsChunk() {
    const chunk = payments.slice(paymentsVisible, paymentsVisible + PAYMENTS_STEP);

    if (!payments.length) {
      paymentsList.innerHTML = window.Polish?.emptyState
        ? window.Polish.emptyState({
          title: 'لا توجد مدفوعات حتى الآن',
          message: 'عند شراء أي مادة، ستظهر تفاصيل عمليات الدفع هنا.',
        })
        : '<div class="student-empty-inline">لا توجد مدفوعات حتى الآن.</div>';
      paymentsMore.hidden = true;
      return;
    }

    paymentsList.insertAdjacentHTML(
      'beforeend',
      chunk
        .map((item) => `
          <article class="student-card student-compact">
            <div class="student-card-row">
              <strong>${item.description || 'شراء مادة'}</strong>
              <strong>${formatMoney(item.amount)} ل.س</strong>
            </div>
            <p class="student-muted">الرصيد بعد العملية: ${formatMoney(item.balance_after)} ل.س</p>
            <p class="student-muted">${formatDate(item.created_at)}</p>
          </article>
        `)
        .join(''),
    );

    paymentsVisible += chunk.length;
    paymentsMore.hidden = paymentsVisible >= payments.length;
  }

  tabCourses.addEventListener('click', () => showTab('courses'));
  tabPayments.addEventListener('click', () => showTab('payments'));
  paymentsMore.addEventListener('click', () => renderPaymentsChunk());

  try {
    setViewState(state, {
      type: 'loading',
      title: 'جار التحميل',
      message: 'يتم جلب دوراتك ومدفوعاتك...',
      variant: 'table',
    });

    const [myCourses, myPayments] = await Promise.all([
      apiGet('/me/courses'),
      apiGet('/me/payments'),
    ]);

    if (!myCourses.length) {
      coursesList.innerHTML = window.Polish?.emptyState
        ? window.Polish.emptyState({
          title: 'لم تشترِ أي مادة بعد',
          message: 'ابدأ من صفحة الكتالوج لاختيار المواد المناسبة لك.',
          actionHref: '/student/index.html',
          actionLabel: 'استعراض الكتالوج',
        })
        : '<div class="student-empty-inline">لم تشترِ أي مادة بعد.</div>';
    } else {
      coursesList.innerHTML = myCourses
        .map((course) => {
          const status = getCourseStatus(course);
          return `
            <article class="student-card">
              <div class="student-card-row">
                <h3>${course.name}</h3>
                <span class="${status.className}">${status.label}</span>
              </div>
              <p>${course.description || 'لا يوجد وصف.'}</p>
              <p class="student-muted">المدرس: ${course.teacher_full_name || 'غير محدد'}</p>
              <p class="student-muted">تاريخ الشراء: ${formatDate(course.purchased_at)}</p>
              <div style="display:flex;flex-wrap:wrap;gap:0.75rem;margin-top:1rem;">
                <a class="student-btn student-btn-primary" href="/student/course.html?id=${course.id}&name=${encodeURIComponent(course.name)}&price=${encodeURIComponent(course.price)}&purchased=1&from=my-courses">
                  متابعة الدروس
                </a>
                <button type="button" class="student-btn student-btn-secondary" data-swap-course="${course.purchase_id || ''}" data-course-name="${encodeURIComponent(course.name)}">
                  طلب تبديل المادة
                </button>
              </div>
            </article>
          `;
        })
        .join('');

      const swapButtons = coursesList.querySelectorAll('[data-swap-course]');
      swapButtons.forEach((button) => {
        button.addEventListener('click', async () => {
          const purchaseId = Number(button.getAttribute('data-swap-course'));
          const courseName = decodeURIComponent(button.getAttribute('data-course-name') || '');
          const course = myCourses.find((item) => Number(item.purchase_id) === purchaseId && item.name === courseName);
          if (!course) {
            showToast('تعذر العثور على هذه المادة.', 'error');
            return;
          }
          await openSwapModal(course);
        });
      });
    }

    await refreshSwapRequests();

    payments = Array.isArray(myPayments) ? myPayments : [];
    paymentsList.innerHTML = '';
    paymentsVisible = 0;
    renderPaymentsChunk();

    showTab('courses');
    setViewState(state, null);
  } catch (error) {
    setViewState(state, {
      type: 'error',
      title: 'تعذر تحميل بياناتك',
      message: error?.message || 'حاول مرة أخرى.',
      actionHref: '/student/courses.html',
      actionLabel: 'إعادة المحاولة',
    });
  }
});
