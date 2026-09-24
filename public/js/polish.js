(function (global) {
  const THEME_KEY = 'ui_theme';
  const confettiColors = ['#184e77', '#1f7a4d', '#a36d00', '#b23b3b', '#d8e8f5'];

  function prefersReducedMotion() {
    return global.matchMedia && global.matchMedia('(prefers-reduced-motion: reduce)').matches;
  }

  function getStoredTheme() {
    return global.localStorage.getItem(THEME_KEY);
  }

  function detectTheme() {
    const stored = getStoredTheme();
    if (stored === 'light' || stored === 'dark') {
      return stored;
    }
    return global.matchMedia && global.matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'light';
  }

  function applyTheme(theme) {
    const next = theme === 'dark' ? 'dark' : 'light';
    document.documentElement.setAttribute('data-theme', next);
    document.documentElement.style.colorScheme = next;
    return next;
  }

  function setTheme(theme) {
    const next = applyTheme(theme);
    global.localStorage.setItem(THEME_KEY, next);
    refreshThemeToggleState();
  }

  function refreshThemeToggleState() {
    const active = document.documentElement.getAttribute('data-theme') || detectTheme();
    document.querySelectorAll('[data-theme-toggle]').forEach(function (button) {
      button.setAttribute('aria-pressed', String(active === 'dark'));
      button.setAttribute('title', active === 'dark' ? 'تفعيل النمط الفاتح' : 'تفعيل النمط الداكن');
    });
  }

  function initThemeToggle(scope) {
    (scope || document).querySelectorAll('[data-theme-toggle]').forEach(function (button) {
      if (button.dataset.boundThemeToggle === '1') {
        return;
      }
      button.dataset.boundThemeToggle = '1';
      button.addEventListener('click', function () {
        const current = document.documentElement.getAttribute('data-theme') || detectTheme();
        setTheme(current === 'dark' ? 'light' : 'dark');
      });
    });
    refreshThemeToggleState();
  }

  function collapseBreadcrumbs() {
    const compact = global.matchMedia && global.matchMedia('(max-width: 400px)').matches;
    document.querySelectorAll('.breadcrumb[data-collapsible="true"]').forEach(function (list) {
      const items = Array.from(list.querySelectorAll(':scope > li[data-breadcrumb-item="true"]'));

      list.querySelectorAll(':scope > li[data-breadcrumb-collapse="true"]').forEach(function (node) {
        node.remove();
      });

      items.forEach(function (node) {
        node.removeAttribute('data-breadcrumb-hidden');
      });

      if (!compact || items.length <= 3) {
        return;
      }

      for (let i = 1; i < items.length - 1; i += 1) {
        items[i].setAttribute('data-breadcrumb-hidden', 'true');
      }

      const collapseLi = document.createElement('li');
      collapseLi.setAttribute('data-breadcrumb-collapse', 'true');
      const btn = document.createElement('button');
      btn.type = 'button';
      btn.className = 'breadcrumb-collapse';
      btn.textContent = '...';
      btn.setAttribute('aria-label', 'إظهار عناصر المسار الكاملة');
      btn.addEventListener('click', function () {
        items.forEach(function (node) {
          node.removeAttribute('data-breadcrumb-hidden');
        });
        collapseLi.remove();
      });
      collapseLi.appendChild(btn);

      items[0].insertAdjacentElement('afterend', collapseLi);
    });
  }

  function refreshBreadcrumbs() {
    collapseBreadcrumbs();
  }

  function ensureToastRegion() {
    let region = document.querySelector('[data-polish-toast-region]');
    if (region) {
      return region;
    }

    region = document.createElement('section');
    region.className = 'polish-toast-region';
    region.setAttribute('data-polish-toast-region', '1');
    region.setAttribute('aria-live', 'polite');
    region.setAttribute('aria-atomic', 'false');
    document.body.appendChild(region);
    return region;
  }

  function closeToast(node) {
    if (node && node.parentNode) {
      node.parentNode.removeChild(node);
    }
  }

  function toast(message, options) {
    const opts = options || {};
    const region = ensureToastRegion();
    const item = document.createElement('article');
    item.className = 'polish-toast ' + (opts.type || 'info');

    const msg = document.createElement('p');
    msg.textContent = String(message || '');
    msg.style.margin = '0';

    const close = document.createElement('button');
    close.type = 'button';
    close.className = 'polish-toast-close';
    close.setAttribute('aria-label', 'إغلاق');
    close.textContent = '×';
    close.addEventListener('click', function () {
      closeToast(item);
    });

    item.appendChild(msg);
    item.appendChild(close);
    region.appendChild(item);

    const timeout = Number(opts.timeout || 3500);
    global.setTimeout(function () {
      closeToast(item);
    }, timeout);
  }

  function parseNumber(text) {
    const normalized = String(text || '')
      .replace(/[٠-٩]/g, function (d) {
        return String('٠١٢٣٤٥٦٧٨٩'.indexOf(d));
      })
      .replace(/[^0-9.\-]/g, '');

    const value = Number(normalized);
    return Number.isFinite(value) ? value : 0;
  }

  function formatNumber(value, decimals) {
    return new Intl.NumberFormat('ar-SY', {
      minimumFractionDigits: decimals,
      maximumFractionDigits: decimals,
    }).format(value);
  }

  function animateCount(element, nextValue, options) {
    if (!element) {
      return;
    }

    const opts = options || {};
    const start = Number(element.dataset.countCurrent || parseNumber(element.textContent));
    const end = Number(nextValue);
    const safeEnd = Number.isFinite(end) ? end : 0;
    const safeStart = Number.isFinite(start) ? start : 0;
    const decimals = Number.isFinite(Number(opts.decimals)) ? Number(opts.decimals) : 2;
    const suffix = opts.suffix === undefined ? '' : String(opts.suffix);

    if (prefersReducedMotion()) {
      element.textContent = formatNumber(safeEnd, decimals) + suffix;
      element.dataset.countCurrent = String(safeEnd);
      return;
    }

    const duration = Number(opts.duration || 700);
    const startTime = performance.now();

    function easeOut(t) {
      return 1 - Math.pow(1 - t, 3);
    }

    function draw(now) {
      const elapsed = now - startTime;
      const progress = Math.min(1, elapsed / duration);
      const current = safeStart + (safeEnd - safeStart) * easeOut(progress);
      element.textContent = formatNumber(current, decimals) + suffix;
      if (progress < 1) {
        requestAnimationFrame(draw);
        return;
      }
      element.dataset.countCurrent = String(safeEnd);
    }

    requestAnimationFrame(draw);
  }

  function setButtonBusy(button, busy) {
    if (!button) {
      return;
    }
    if (busy) {
      button.classList.add('is-loading');
      button.setAttribute('aria-busy', 'true');
      button.disabled = true;
      return;
    }
    button.classList.remove('is-loading');
    button.removeAttribute('aria-busy');
    button.disabled = false;
  }

  function emptyState(config) {
    const cfg = config || {};
    const icon = cfg.icon || '<svg viewBox="0 0 24 24" aria-hidden="true"><path fill="currentColor" d="M4 5h16v2H4zm0 6h16v2H4zm0 6h10v2H4z"/></svg>';
    const action = cfg.actionHref && cfg.actionLabel
      ? '<a class="student-btn student-btn-secondary" href="' + cfg.actionHref + '">' + cfg.actionLabel + '</a>'
      : '';

    return '<section class="polish-empty">' + icon + '<h4>' + (cfg.title || '') + '</h4><p>' + (cfg.message || '') + '</p>' + action + '</section>';
  }

  function skeleton(variant, count) {
    const type = variant || 'cards';
    const size = Number(count || 4);

    if (type === 'table') {
      const rows = new Array(size).fill('<div class="polish-skeleton-table-row"></div>').join('');
      return '<div class="polish-skeleton polish-skeleton-table">' + rows + '</div>';
    }

    if (type === 'detail') {
      return '<div class="polish-skeleton"><div class="polish-skeleton-line short"></div><div class="polish-skeleton-line"></div><div class="polish-skeleton-line mid"></div><div class="polish-skeleton-block"></div></div>';
    }

    const cards = new Array(size).fill('<article class="polish-skeleton-card"><div class="polish-skeleton-line short"></div><div class="polish-skeleton-line"></div><div class="polish-skeleton-line mid"></div></article>').join('');
    return '<div class="polish-skeleton polish-skeleton-grid">' + cards + '</div>';
  }

  function setSkeleton(container, variant, count) {
    if (!container) {
      return;
    }
    container.innerHTML = skeleton(variant, count);
  }

  async function copyText(value) {
    const text = String(value || '');
    if (!text) {
      return;
    }

    if (navigator.clipboard && global.isSecureContext) {
      await navigator.clipboard.writeText(text);
      return;
    }

    const helper = document.createElement('textarea');
    helper.value = text;
    helper.setAttribute('readonly', '');
    helper.style.position = 'absolute';
    helper.style.left = '-9999px';
    document.body.appendChild(helper);
    helper.select();
    document.execCommand('copy');
    helper.remove();
  }

  function bindCopyButtons(scope) {
    (scope || document).querySelectorAll('[data-copy-text], [data-copy-target]').forEach(function (button) {
      if (button.dataset.boundCopy === '1') {
        return;
      }
      button.dataset.boundCopy = '1';
      button.addEventListener('click', async function () {
        const explicit = button.getAttribute('data-copy-text');
        const targetSelector = button.getAttribute('data-copy-target');
        const target = targetSelector ? document.querySelector(targetSelector) : null;
        const fallback = target && ('value' in target ? target.value : target.textContent);

        try {
          await copyText(explicit || fallback || '');
          toast(button.getAttribute('data-copy-success') || 'تم النسخ بنجاح', { type: 'success' });
        } catch (_error) {
          toast('تعذر النسخ في الوقت الحالي', { type: 'error' });
        }
      });
    });
  }

  function initPullToRefresh(config) {
    const cfg = config || {};
    if (!(global.matchMedia && global.matchMedia('(pointer: coarse)').matches)) {
      return function () {};
    }

    const container = cfg.container || document.querySelector('.student-main') || document.body;
    if (!container) {
      return function () {};
    }

    const indicator = document.createElement('div');
    indicator.className = 'polish-pull-indicator';
    indicator.innerHTML = '<strong>اسحب للتحديث</strong>';
    container.prepend(indicator);

    let startY = 0;
    let pulling = false;
    let distance = 0;

    function resetIndicator() {
      indicator.classList.remove('visible');
      indicator.querySelector('strong').textContent = 'اسحب للتحديث';
      distance = 0;
    }

    function onStart(event) {
      if (window.scrollY > 0) {
        return;
      }
      if (!event.touches || !event.touches.length) {
        return;
      }
      startY = event.touches[0].clientY;
      pulling = true;
    }

    function onMove(event) {
      if (!pulling || !event.touches || !event.touches.length) {
        return;
      }
      const currentY = event.touches[0].clientY;
      distance = Math.max(0, currentY - startY);
      if (distance < 10) {
        return;
      }
      indicator.classList.add('visible');
      indicator.querySelector('strong').textContent = distance > 70 ? 'اترك للإعادة' : 'اسحب للتحديث';
    }

    function onEnd() {
      if (!pulling) {
        return;
      }
      pulling = false;
      if (distance > 70) {
        indicator.classList.add('visible');
        indicator.querySelector('strong').textContent = 'جار التحديث...';
        Promise.resolve(cfg.onRefresh && cfg.onRefresh())
          .then(function () {
            indicator.querySelector('strong').textContent = 'تم التحديث';
            global.setTimeout(resetIndicator, 650);
          })
          .catch(function () {
            indicator.querySelector('strong').textContent = 'تعذر التحديث';
            global.setTimeout(resetIndicator, 650);
          });
      } else {
        resetIndicator();
      }
    }

    container.addEventListener('touchstart', onStart, { passive: true });
    container.addEventListener('touchmove', onMove, { passive: true });
    container.addEventListener('touchend', onEnd, { passive: true });

    return function destroy() {
      container.removeEventListener('touchstart', onStart);
      container.removeEventListener('touchmove', onMove);
      container.removeEventListener('touchend', onEnd);
      if (indicator.parentNode) {
        indicator.parentNode.removeChild(indicator);
      }
    };
  }

  function confettiBurst() {
    if (prefersReducedMotion()) {
      return;
    }
    const wrap = document.createElement('div');
    wrap.className = 'polish-confetti-wrap';
    document.body.appendChild(wrap);

    for (let i = 0; i < 34; i += 1) {
      const piece = document.createElement('div');
      piece.className = 'polish-confetti';
      piece.style.background = confettiColors[i % confettiColors.length];
      piece.style.left = Math.round((i / 34) * 100) + '%';
      piece.style.setProperty('--x', (Math.random() * 140 - 70).toFixed(1) + 'px');
      piece.style.setProperty('--y', (Math.random() * 220 + 90).toFixed(1) + 'px');
      piece.style.setProperty('--r', (Math.random() * 640 - 320).toFixed(1) + 'deg');
      wrap.appendChild(piece);
    }

    global.setTimeout(function () {
      if (wrap.parentNode) {
        wrap.parentNode.removeChild(wrap);
      }
    }, 2100);
  }

  function consumeFlashToasts() {
    document.querySelectorAll('.panel-flash').forEach(function (node) {
      if (node.classList.contains('error')) {
        return;
      }
      const message = node.textContent ? node.textContent.trim() : '';
      if (!message) {
        return;
      }
      toast(message, { type: 'success' });
      node.remove();
    });
  }

  function initGlobalSubmitLock(scope) {
    (scope || document).querySelectorAll('form').forEach(function (form) {
      if (form.dataset.submitLock === 'off') {
        return;
      }
      if (form.dataset.submitLock === '1') {
        return;
      }
      form.dataset.submitLock = '1';
      form.addEventListener('submit', function () {
        const submit = form.querySelector('button[type="submit"], input[type="submit"]');
        if (submit) {
          setButtonBusy(submit, true);
        }
      });
    });
  }

  function init() {
    applyTheme(detectTheme());
    initThemeToggle(document);
    bindCopyButtons(document);
    consumeFlashToasts();
    initGlobalSubmitLock(document);
    refreshBreadcrumbs();
  }

  const api = {
    toast: toast,
    emptyState: emptyState,
    skeleton: skeleton,
    setSkeleton: setSkeleton,
    setButtonBusy: setButtonBusy,
    animateCount: animateCount,
    initThemeToggle: initThemeToggle,
    setTheme: setTheme,
    applyTheme: applyTheme,
    copyText: copyText,
    bindCopyButtons: bindCopyButtons,
    initPullToRefresh: initPullToRefresh,
    confettiBurst: confettiBurst,
    refreshBreadcrumbs: refreshBreadcrumbs,
    consumeFlashToasts: consumeFlashToasts,
    prefersReducedMotion: prefersReducedMotion,
    init: init,
  };

  global.Polish = api;
  document.addEventListener('DOMContentLoaded', function () {
    api.init();
  });
  global.addEventListener('resize', function () {
    api.refreshBreadcrumbs();
  });
})(window);
