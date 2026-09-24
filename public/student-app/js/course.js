import { ApiError, apiGet, apiPost } from './api.js';
import { requireAuth } from './auth.js';
import { formatMoney, markdownLite } from './format.js';
import { initNav } from './nav.js';
import { renderBreadcrumb, setViewState, showToast, withSubmitLock } from './ui.js';

function getCourseContext() {
  const params = new URLSearchParams(window.location.search);
  return {
    id: Number(params.get('id') || 0),
    name: params.get('name') || 'تفاصيل المادة',
    price: params.get('price') || null,
    from: params.get('from') || '',
    specializationId: params.get('specialization') || '',
    specializationName: params.get('specializationName') || '',
    year: params.get('year') || '',
  };
}

function buildCourseBreadcrumb(context) {
  if (context.from === 'my-courses') {
    return [
      { label: 'الرئيسية', href: '/student/index.html' },
      { label: 'مقرراتي', href: '/student/courses.html' },
      { label: context.name },
    ];
  }

  if (context.specializationName && context.year) {
    return [
      { label: 'الرئيسية', href: '/student/index.html' },
      { label: context.specializationName, href: `/student/index.html?specialization=${encodeURIComponent(context.specializationId)}` },
      { label: `السنة ${context.year}`, href: `/student/index.html?specialization=${encodeURIComponent(context.specializationId)}&year=${encodeURIComponent(context.year)}` },
      { label: context.name },
    ];
  }

  return [
    { label: 'الرئيسية', href: '/student/index.html' },
    { label: 'المقررات', href: '/student/index.html' },
    { label: context.name },
  ];
}

function renderVideoPlayer(lecture) {
  return `
    <div class="student-media-wrap">
      <video controls preload="metadata" class="student-media" data-media-lecture-id="${lecture.id}"></video>
      <p class="student-muted" data-media-state="${lecture.id}">جارٍ تجهيز الفيديو المحمي...</p>
    </div>
  `;
}

async function hydrateVideoPlayers(root) {
  const players = Array.from(root.querySelectorAll('video[data-media-lecture-id]'));
  await Promise.all(players.map(async (player) => {
    const lectureId = Number(player.getAttribute('data-media-lecture-id') || 0);
    const state = root.querySelector(`[data-media-state="${lectureId}"]`);
    if (!lectureId) {
      return;
    }

    try {
      const response = await apiPost(`/lectures/${lectureId}/stream-url`, {}, { requiresAuth: true });
      player.src = response.url;
      player.setAttribute('preload', 'metadata');
      if (state) {
        state.textContent = 'يمكن تشغيل الفيديو الآن.';
      }
    } catch (error) {
      player.removeAttribute('src');
      player.load();
      if (state) {
        state.textContent = error?.message || 'تعذر تجهيز الفيديو.';
        state.className = 'student-muted student-danger-text';
      }
    }
  }));
}

function renderLectureBody(lecture) {
  if (lecture.type === 'VIDEO') {
    return renderVideoPlayer(lecture);
  }

  if (lecture.type === 'PDF' && lecture.url) {
    return `
      <iframe src="${lecture.url}" class="student-media" loading="lazy" referrerpolicy="no-referrer"></iframe>
      <a class="student-link" href="${lecture.url}" target="_blank" rel="noopener noreferrer">فتح ملف PDF في تبويب جديد</a>
    `;
  }

  if (lecture.type === 'TEXT') {
    return `<div class="student-richtext">${markdownLite(lecture.content || '')}</div>`;
  }

  return '<p class="student-muted">لا يوجد محتوى متاح.</p>';
}

function renderLectures(lectures) {
  if (!lectures.length) {
    return `
      <section class="student-state student-state-empty">
        <h3>لا توجد دروس منشورة</h3>
        <p>سيتم عرض الدروس هنا عند توفرها.</p>
      </section>
    `;
  }

  return lectures
    .map((lecture, index) => {
      if (lecture.locked) {
        return `
          <article class="student-card student-lecture locked">
            <div class="student-card-row">
              <h3>${index + 1}. ${lecture.title}</h3>
              <span class="student-badge warning">مقفل</span>
            </div>
            <div class="polish-lecture-lock" aria-hidden="true">
              <div class="preview">محتوى الدرس متاح بعد الشراء</div>
              <div class="overlay">🔒</div>
            </div>
            <p class="student-muted">اشترِ المادة للوصول إلى هذا الدرس.</p>
          </article>
        `;
      }

      return `
        <article class="student-card student-lecture">
          <div class="student-card-row">
            <h3>${index + 1}. ${lecture.title}</h3>
            <span class="student-badge">${lecture.type}</span>
          </div>
          ${renderLectureBody(lecture)}
        </article>
      `;
    })
    .join('');
}

document.addEventListener('DOMContentLoaded', async () => {
  initNav('courses');
  await requireAuth();

  const state = document.getElementById('courseState');
  const list = document.getElementById('lectureList');
  const title = document.getElementById('courseTitle');
  const buyPanel = document.getElementById('buyPanel');
  const buyMessage = document.getElementById('buyMessage');
  const buyButton = document.getElementById('buyButton');
  const breadcrumb = document.getElementById('studentBreadcrumb');

  if (!state || !list || !title || !buyPanel || !buyMessage || !buyButton) {
    return;
  }

  const context = getCourseContext();
  renderBreadcrumb(breadcrumb, buildCourseBreadcrumb(context));

  if (!context.id) {
    setViewState(state, {
      type: 'error',
      title: 'رابط غير صالح',
      message: 'معرف المادة غير موجود.',
      actionHref: '/student/index.html',
      actionLabel: 'عودة للرئيسية',
    });
    return;
  }

  title.textContent = context.name;

  async function loadLectures() {
    setViewState(state, {
      type: 'loading',
      title: 'جار تحميل الدروس',
      message: 'انتظر قليلًا...',
      variant: 'detail',
    });

    const lectures = await apiGet(`/courses/${context.id}/lectures`);
    list.innerHTML = renderLectures(lectures);
    void hydrateVideoPlayers(list);
    setViewState(state, null);

    const hasLocked = lectures.some((lecture) => lecture.locked);
    if (hasLocked) {
      buyPanel.hidden = false;
      buyButton.textContent = context.price
        ? `شراء المادة (${formatMoney(context.price)} ل.س)`
        : 'شراء المادة';
    } else {
      buyPanel.hidden = true;
    }
  }

  buyButton.addEventListener('click', () => {
    buyMessage.textContent = '';

    void withSubmitLock(buyButton, async () => {
      try {
        const [wallet, beforeCourses] = await Promise.all([
          apiGet('/wallet'),
          apiGet('/me/courses'),
        ]);
        const hadCoursesBeforePurchase = Array.isArray(beforeCourses) && beforeCourses.length > 0;
        const balanceText = formatMoney(wallet.balance);
        const priceText = context.price ? formatMoney(context.price) : 'غير محدد';
        const confirmed = window.confirm(`سعر المادة: ${priceText} ل.س\nرصيدك الحالي: ${balanceText} ل.س\nهل تريد المتابعة؟`);

        if (!confirmed) {
          return;
        }

        await apiPost(`/courses/${context.id}/purchase`, {}, { idempotent: true });
        buyMessage.textContent = 'تم الشراء بنجاح، يتم الآن فتح الدروس.';
        buyMessage.className = 'student-inline-message success';
        showToast('تم شراء المادة بنجاح.', 'success');
        if (!hadCoursesBeforePurchase) {
          window.Polish?.confettiBurst();
        }
        await loadLectures();
      } catch (error) {
        if (error instanceof ApiError && error.status === 400 && String(error.message).includes('Insufficient balance')) {
          let current = 0;
          try {
            const wallet = await apiGet('/wallet');
            current = Number(wallet.balance || 0);
          } catch (_walletError) {
            current = 0;
          }
          const price = Number(context.price || 0);
          const missing = Math.max(0, price - current);
          buyMessage.innerHTML = `الرصيد غير كافٍ. المبلغ الناقص: ${formatMoney(missing)} ل.س. <a href="/student/wallet.html">انتقل إلى شحن المحفظة</a>.`;
          buyMessage.className = 'student-inline-message error';
          return;
        }

        buyMessage.textContent = error?.message || 'تعذر إتمام الشراء.';
        buyMessage.className = 'student-inline-message error';
      }
    });
  });

  try {
    await loadLectures();
  } catch (error) {
    setViewState(state, {
      type: 'error',
      title: 'تعذر تحميل الدروس',
      message: error?.message || 'حاول مرة أخرى.',
      actionHref: window.location.href,
      actionLabel: 'إعادة المحاولة',
    });
  }
});
