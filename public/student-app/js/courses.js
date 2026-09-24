import { apiGet } from './api.js';
import { requireAuth } from './auth.js';
import { formatDate, formatMoney } from './format.js';
import { initNav } from './nav.js';
import { renderBreadcrumb, setViewState } from './ui.js';

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
        .map((course) => `
          <article class="student-card">
            <div class="student-card-row">
              <h3>${course.name}</h3>
              <span class="student-badge success">مشترى</span>
            </div>
            <p>${course.description || 'لا يوجد وصف.'}</p>
            <p class="student-muted">المدرس: ${course.teacher_full_name || 'غير محدد'}</p>
            <p class="student-muted">تاريخ الشراء: ${formatDate(course.purchased_at)}</p>
            <a class="student-btn student-btn-primary" href="/student/course.html?id=${course.id}&name=${encodeURIComponent(course.name)}&price=${encodeURIComponent(course.price)}&purchased=1&from=my-courses">
              متابعة الدروس
            </a>
          </article>
        `)
        .join('');
    }

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
