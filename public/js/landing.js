(function () {
  const menuButton = document.querySelector('[data-nav-toggle]');
  const menu = document.querySelector('[data-nav-menu]');

  if (menuButton && menu) {
    menuButton.addEventListener('click', function () {
      const isExpanded = menuButton.getAttribute('aria-expanded') === 'true';
      menuButton.setAttribute('aria-expanded', String(!isExpanded));
      menu.classList.toggle('is-open');
    });

    menu.querySelectorAll('a').forEach(function (link) {
      link.addEventListener('click', function () {
        menu.classList.remove('is-open');
        menuButton.setAttribute('aria-expanded', 'false');
      });
    });
  }

  const yearElements = document.querySelectorAll('[data-year]');
  const year = new Date().getFullYear();
  yearElements.forEach(function (node) {
    node.textContent = String(year);
  });

  const copyButton = document.querySelector('[data-copy-phone]');
  const toast = document.querySelector('[data-toast]');

  async function copyText(value) {
    if (navigator.clipboard && window.isSecureContext) {
      await navigator.clipboard.writeText(value);
      return;
    }

    const helper = document.createElement('textarea');
    helper.value = value;
    helper.setAttribute('readonly', '');
    helper.style.position = 'absolute';
    helper.style.left = '-9999px';
    document.body.appendChild(helper);
    helper.select();
    document.execCommand('copy');
    helper.remove();
  }

  function showToast() {
    if (!toast) {
      return;
    }

    toast.classList.add('is-visible');
    window.setTimeout(function () {
      toast.classList.remove('is-visible');
    }, 1300);
  }

  if (copyButton) {
    copyButton.addEventListener('click', async function () {
      const value = copyButton.getAttribute('data-phone-value') || '';
      try {
        await copyText(value);
        showToast();
      } catch (_error) {
        copyButton.textContent = 'تعذر النسخ';
        window.setTimeout(function () {
          copyButton.textContent = 'نسخ الرقم';
        }, 1300);
      }
    });
  }
})();
