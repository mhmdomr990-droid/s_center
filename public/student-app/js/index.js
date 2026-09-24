import { apiGet } from './api.js';
import { requireAuth } from './auth.js';
import { formatMoney } from './format.js';
import { initNav } from './nav.js';
import { renderBreadcrumb, setViewState } from './ui.js';

function getParams() {
  const params = new URLSearchParams(window.location.search);
  return {
    specializationId: Number(params.get('specialization') || 0) || null,
    year: Number(params.get('year') || 0) || null,
  };
}

function buildHomeLink(specializationId, year) {
  const query = new URLSearchParams();
  if (specializationId) {
    query.set('specialization', String(specializationId));
  }
  if (year) {
    query.set('year', String(year));
  }
  return `/student/index.html${query.toString() ? `?${query.toString()}` : ''}`;
}

function renderSpecializations(items) {
  return items
    .map((item) => `
      <a class="student-card student-tap" href="${buildHomeLink(item.id, null)}">
        <h3>${item.name}</h3>
        <p>عرض السنوات والمواد المتاحة</p>
      </a>
    `)
    .join('');
}

function renderYears(specializationId, specializationName) {
  const years = [1, 2, 3, 4, 5];
  return `
    <section class="student-headline">
      <h2>${specializationName}</h2>
      <p>اختر السنة الدراسية</p>
      <a class="student-link" href="/student/index.html">العودة إلى الاختصاصات</a>
    </section>
    <section class="student-grid">
      ${years
        .map(
          (year) => `
            <a class="student-card student-tap" href="${buildHomeLink(specializationId, year)}">
              <h3>السنة ${year}</h3>
              <p>عرض المواد المتاحة</p>
            </a>
          `,
        )
        .join('')}
    </section>
  `;
}

function renderCourses(specializationId, year, specializationName, courses) {
  if (!courses.length) {
    return `
      <section class="student-headline">
        <h2>${specializationName} - السنة ${year}</h2>
        <a class="student-link" href="${buildHomeLink(specializationId, null)}">اختيار سنة أخرى</a>
      </section>
      <section class="student-state student-state-empty">
        <h3>لا توجد مواد</h3>
        <p>لم تُنشر مواد لهذه السنة بعد.</p>
      </section>
    `;
  }

  return `
    <section class="student-headline">
      <h2>${specializationName} - السنة ${year}</h2>
      <a class="student-link" href="${buildHomeLink(specializationId, null)}">اختيار سنة أخرى</a>
    </section>
    <section class="student-grid">
      ${courses
        .map((course) => {
          const detailUrl = `/student/course.html?id=${course.id}&name=${encodeURIComponent(course.name)}&price=${encodeURIComponent(course.price)}&purchased=${course.purchased ? '1' : '0'}&from=catalog&specialization=${encodeURIComponent(specializationId)}&specializationName=${encodeURIComponent(specializationName)}&year=${encodeURIComponent(year)}`;
          return `
            <article class="student-card">
              <div class="student-card-row">
                <h3>${course.name}</h3>
                ${course.purchased ? '<span class="student-badge success">مُشترى</span>' : '<span class="student-badge">غير مشترى</span>'}
              </div>
              <p>${course.description || 'لا يوجد وصف.'}</p>
              <p class="student-muted">المدرس: ${course.teacher_full_name || 'غير محدد'}</p>
              <p class="student-price">${formatMoney(course.price)} ل.س</p>
              <a class="student-btn student-btn-primary" href="${detailUrl}">عرض الدروس</a>
            </article>
          `;
        })
        .join('')}
    </section>
  `;
}

document.addEventListener('DOMContentLoaded', async () => {
  initNav('home');
  await requireAuth();

  const state = document.getElementById('homeState');
  const content = document.getElementById('homeContent');
  const breadcrumb = document.getElementById('studentBreadcrumb');

  if (!state || !content) {
    return;
  }

  try {
    setViewState(state, {
      type: 'loading',
      title: 'جار التحميل',
      message: 'يتم جلب الاختصاصات...',
      variant: 'cards',
    });

    const { specializationId, year } = getParams();
    const specializations = await apiGet('/specializations');

    setViewState(state, null);

    if (!specializations.length) {
      setViewState(state, {
        type: 'empty',
        title: 'لا توجد اختصاصات منشورة',
        message: 'سيتم عرض الاختصاصات هنا عند النشر.',
      });
      return;
    }

    if (!specializationId) {
      renderBreadcrumb(breadcrumb, []);
      content.innerHTML = `
        <section class="student-headline">
          <h1>اختر اختصاصك</h1>
          <p>ابدأ بتحديد الاختصاص ثم السنة للوصول إلى المواد.</p>
        </section>
        <section class="student-grid">${renderSpecializations(specializations)}</section>
      `;
      return;
    }

    const specialization = specializations.find((item) => item.id === specializationId);

    if (!specialization) {
      setViewState(state, {
        type: 'error',
        title: 'اختصاص غير موجود',
        message: 'لم نتمكن من العثور على هذا الاختصاص.',
        actionHref: '/student/index.html',
        actionLabel: 'عودة للرئيسية',
      });
      return;
    }

    if (!year) {
      renderBreadcrumb(breadcrumb, [
        { label: 'الرئيسية', href: '/student/index.html' },
        { label: specialization.name },
      ]);
      content.innerHTML = renderYears(specializationId, specialization.name);
      return;
    }

    renderBreadcrumb(breadcrumb, [
      { label: 'الرئيسية', href: '/student/index.html' },
      { label: specialization.name, href: buildHomeLink(specializationId, null) },
      { label: `السنة ${year}` },
    ]);

    const courses = await apiGet('/courses', {
      query: { specializationId, year },
    });

    content.innerHTML = renderCourses(specializationId, year, specialization.name, courses);
  } catch (error) {
    setViewState(state, {
      type: 'error',
      title: 'تعذر تحميل البيانات',
      message: error?.message || 'حاول مرة أخرى بعد قليل.',
      actionHref: '/student/index.html',
      actionLabel: 'إعادة المحاولة',
    });
  }
});
