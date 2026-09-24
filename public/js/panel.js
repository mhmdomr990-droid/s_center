(() => {
  window.Polish?.consumeFlashToasts();
  window.Polish?.initThemeToggle(document);
  window.Polish?.bindCopyButtons(document);

  document.querySelectorAll('.panel-topbar').forEach((bar) => {
    if (bar.querySelector('[data-theme-toggle]')) {
      return;
    }
    const toggle = document.createElement('button');
    toggle.type = 'button';
    toggle.className = 'polish-theme-toggle';
    toggle.setAttribute('data-theme-toggle', '1');
    toggle.setAttribute('aria-label', 'تبديل النمط');
    toggle.innerHTML = '<span class="moon">◐</span><span class="sun">☀</span>';
    bar.appendChild(toggle);
  });
  window.Polish?.initThemeToggle(document);

  const csrfTokenInput = document.querySelector('input[name="csrf_token"]');
  const csrfToken = csrfTokenInput ? csrfTokenInput.value : '';

  document.querySelectorAll('[data-confirm]').forEach((element) => {
    element.addEventListener('click', (event) => {
      const message = element.getAttribute('data-confirm') || '';
      if (!window.confirm(message)) {
        event.preventDefault();
      }
    });
  });

  document.querySelectorAll('[data-modal-open]').forEach((trigger) => {
    trigger.addEventListener('click', () => {
      const modalId = trigger.getAttribute('data-modal-open');
      if (!modalId) {
        return;
      }
      const modal = document.getElementById(modalId);
      if (!modal) {
        return;
      }

      const fillJson = trigger.getAttribute('data-modal-fill');
      if (fillJson) {
        try {
          const fillData = JSON.parse(fillJson);
          modal.querySelectorAll('[data-fill]').forEach((field) => {
            const key = field.getAttribute('data-fill');
            if (key && Object.prototype.hasOwnProperty.call(fillData, key)) {
              if (field instanceof HTMLInputElement || field instanceof HTMLTextAreaElement || field instanceof HTMLSelectElement) {
                field.value = fillData[key] ?? '';
              }
            }
          });
        } catch (error) {
          console.error(error);
        }
      }

      const action = trigger.getAttribute('data-modal-action');
      if (action) {
        const form = modal.querySelector('form');
        if (form) {
          form.setAttribute('action', action);
        }
      }

      modal.classList.add('open');
    });
  });

  document.querySelectorAll('[data-modal-close]').forEach((trigger) => {
    trigger.addEventListener('click', () => {
      const modal = trigger.closest('.panel-modal');
      if (modal) {
        modal.classList.remove('open');
      }
    });
  });

  document.querySelectorAll('form').forEach((form) => {
    form.addEventListener('submit', () => {
      const submit = form.querySelector('button[type="submit"], input[type="submit"]');
      if (submit) {
        window.Polish?.setButtonBusy(submit, true);
      }
    });
  });

  document.querySelectorAll('.panel-modal').forEach((modal) => {
    modal.addEventListener('click', (event) => {
      if (event.target === modal) {
        modal.classList.remove('open');
      }
    });
  });

  document.querySelectorAll('[data-chart]').forEach((canvas) => {
    const chartType = canvas.getAttribute('data-chart');
    const chartData = canvas.getAttribute('data-chart-data');
    if (!chartType || !chartData || typeof Chart === 'undefined') {
      return;
    }

    let parsed;
    try {
      parsed = JSON.parse(chartData);
    } catch (error) {
      return;
    }

    const computed = getComputedStyle(document.documentElement);
    const chartText = computed.getPropertyValue('--muted').trim() || '#6f665b';
    const chartGrid = computed.getPropertyValue('--border').trim() || '#ded7ca';
    Chart.defaults.color = chartText;
    Chart.defaults.borderColor = chartGrid;

    new Chart(canvas, {
      type: chartType,
      data: parsed.data,
      options: {
        maintainAspectRatio: false,
        ...(parsed.options || {}),
      },
    });
  });

  document.querySelectorAll('.panel-stat strong, [data-countup]').forEach((node) => {
    const text = node.textContent || '0';
    const normalized = text.replace(/[٠-٩]/g, (digit) => String('٠١٢٣٤٥٦٧٨٩'.indexOf(digit))).replace(/[^0-9.\-]/g, '');
    const value = Number(normalized);
    if (Number.isFinite(value)) {
      const suffix = text.includes('ل.س') ? ' ل.س' : '';
      const decimals = text.includes('.') || text.includes('٫') ? 2 : 0;
      window.Polish?.animateCount(node, value, { duration: 760, decimals, suffix });
    }
  });
})();
