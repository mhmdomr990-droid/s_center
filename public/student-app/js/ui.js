export function setViewState(container, state) {
  if (!container) {
    return;
  }

  if (!state) {
    container.innerHTML = '';
    return;
  }

  const { type, title, message, actionHref, actionLabel, variant } = state;

  if (type === 'loading') {
    if (window.Polish?.setSkeleton) {
      window.Polish.setSkeleton(container, variant || 'cards', 4);
      return;
    }
    container.innerHTML = '<section class="student-state student-state-loading"><h3>جار التحميل</h3><p>يرجى الانتظار...</p></section>';
    return;
  }

  if (type === 'empty' && window.Polish?.emptyState) {
    container.innerHTML = window.Polish.emptyState({
      title: title || 'لا توجد بيانات',
      message: message || '',
      actionHref,
      actionLabel,
    });
    return;
  }

  const action = actionHref && actionLabel
    ? `<a class="student-btn student-btn-secondary" href="${actionHref}">${actionLabel}</a>`
    : '';

  container.innerHTML = `
    <section class="student-state student-state-${type}">
      <h3>${title || ''}</h3>
      <p>${message || ''}</p>
      ${action}
    </section>
  `;
}

export async function withSubmitLock(button, task) {
  if (!button || button.disabled) {
    return;
  }

  const originalText = button.textContent;
  if (window.Polish?.setButtonBusy) {
    window.Polish.setButtonBusy(button, true);
  } else {
    button.disabled = true;
    button.classList.add('is-loading');
  }

  try {
    await task();
  } finally {
    if (window.Polish?.setButtonBusy) {
      window.Polish.setButtonBusy(button, false);
    } else {
      button.disabled = false;
      button.classList.remove('is-loading');
    }
    button.textContent = originalText;
  }
}

export function setText(id, text) {
  const element = document.getElementById(id);
  if (element) {
    element.textContent = text;
  }
}

export function showToast(message, type = 'success') {
  if (window.Polish?.toast) {
    window.Polish.toast(message, { type });
    return;
  }
  window.console.log(message);
}

export function renderBreadcrumb(container, items) {
  if (!container) {
    return;
  }

  const list = Array.isArray(items) ? items.filter((item) => item && item.label) : [];
  if (!list.length) {
    container.innerHTML = '';
    return;
  }

  const html = list
    .map((item, index) => {
      const isLast = index === list.length - 1;
      if (!isLast && item.href) {
        return `<li data-breadcrumb-item="true"><a href="${item.href}">${item.label}</a></li>`;
      }
      return `<li data-breadcrumb-item="true"><span aria-current="page">${item.label}</span></li>`;
    })
    .join('');

  container.innerHTML = `
    <nav class="breadcrumb-nav" aria-label="مسار التنقل">
      <ol class="breadcrumb" data-collapsible="true">
        ${html}
      </ol>
    </nav>
  `;

  window.Polish?.refreshBreadcrumbs();
}
