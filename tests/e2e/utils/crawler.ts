import path from 'path';

import type { Page } from '@playwright/test';

import { fillFormWithDummyData } from './form';
import { monitorPageHealth, summarizeHealth } from './monitor';
import type { E2EReport } from './report';

interface ActionCandidate {
  selector: string;
  label: string;
  isDestructive: boolean;
  isSubmit: boolean;
  formSelector: string | null;
}

interface CrawlRoleOptions {
  role: 'ADMIN' | 'TEACHER' | 'STUDENT';
  roleRootUrl: string;
  navLinkSelector: string;
  videoPath: string;
  report: E2EReport;
  screenshotDir: string;
  maxActionsPerPage?: number;
  maxPagesPerRole?: number;
}

export async function crawlRolePages(page: Page, options: CrawlRoleOptions) {
  const maxActions = options.maxActionsPerPage ?? 3;
  const maxPages = options.maxPagesPerRole ?? 2;
  await page.goto(options.roleRootUrl, { waitUntil: 'domcontentloaded' });
  await page.waitForTimeout(400);

  const pageLinks = await page.$$eval(options.navLinkSelector, (anchors) =>
    Array.from(new Set(anchors.map((anchor) => (anchor as HTMLAnchorElement).href))).filter(Boolean),
  );

  const boundedLinks = pageLinks.slice(0, maxPages);

  for (const targetUrl of boundedLinks) {
    await page.goto(targetUrl, { waitUntil: 'domcontentloaded' });
    await page.waitForTimeout(300);

    const candidates = await page.evaluate(() => {
      function cssPath(element: Element): string {
        if (element.id) {
          return `#${CSS.escape(element.id)}`;
        }

        const parts: string[] = [];
        let current: Element | null = element;
        while (current && current.nodeType === Node.ELEMENT_NODE && parts.length < 6) {
          let selector = current.nodeName.toLowerCase();
          const className = current.getAttribute('class');
          if (className) {
            const classToken = className.trim().split(/\s+/).find(Boolean);
            if (classToken) {
              selector += `.${CSS.escape(classToken)}`;
            }
          }
          const parent = current.parentElement;
          if (parent) {
            const siblings = Array.from(parent.children).filter((child) => child.nodeName === current!.nodeName);
            if (siblings.length > 1) {
              selector += `:nth-of-type(${siblings.indexOf(current) + 1})`;
            }
          }
          parts.unshift(selector);
          current = current.parentElement;
        }
        return parts.join(' > ');
      }

      const interactive = Array.from(
        document.querySelectorAll<HTMLElement>('a[href], button, input[type="submit"], input[type="button"], [data-modal-open], [data-confirm]'),
      );

      return interactive
        .filter((item) => {
          const style = window.getComputedStyle(item);
          if (style.visibility === 'hidden' || style.display === 'none') {
            return false;
          }
          const rect = item.getBoundingClientRect();
          if (rect.width <= 0 || rect.height <= 0) {
            return false;
          }
          if ((item as HTMLInputElement).disabled || item.getAttribute('aria-disabled') === 'true') {
            return false;
          }
          return true;
        })
        .map((item) => {
          const text = (item.innerText || item.getAttribute('aria-label') || item.getAttribute('title') || item.getAttribute('name') || item.getAttribute('id') || item.tagName).trim();
          const lowered = text.toLowerCase();
          const isSubmit = item.tagName.toLowerCase() === 'button' || (item.tagName.toLowerCase() === 'input' && ['submit', 'button'].includes((item as HTMLInputElement).type));
          const form = item.closest('form');
          return {
            selector: cssPath(item),
            label: text || item.tagName,
            isDestructive:
              lowered.includes('حذف') ||
              lowered.includes('delete') ||
              lowered.includes('إخفاء') ||
              lowered.includes('reject') ||
              lowered.includes('approve') ||
              lowered.includes('deactivate') ||
              lowered.includes('reset'),
            isSubmit,
            formSelector: form ? cssPath(form) : null,
          };
        });
    });

    const boundedCandidates = candidates.slice(0, maxActions);

    for (let i = 0; i < boundedCandidates.length; i += 1) {
      const candidate = boundedCandidates[i] as ActionCandidate;
      const actionName = `${candidate.label} [${candidate.selector}]`;
      await executeAction(page, options, targetUrl, candidate, actionName, i, 'confirm');
    }
  }
}

async function executeAction(
  page: Page,
  options: CrawlRoleOptions,
  pageUrl: string,
  candidate: ActionCandidate,
  actionName: string,
  index: number,
  mode: 'cancel' | 'confirm',
) {
  try {
    await page.goto(pageUrl, { waitUntil: 'domcontentloaded', timeout: 20_000 });
  } catch (error) {
    options.report.addAction({
      role: options.role,
      page: pageUrl,
      action: `${actionName} (${mode})`,
      result: 'FAIL',
      errorDetail: `navigation failed: ${error instanceof Error ? error.message : String(error)}`,
      screenshotPath: '',
    });
    return;
  }
  await page.waitForTimeout(100);

  const monitor = monitorPageHealth(page);
  let dialogSeen = false;

  const dialogHandler = async (dialog: { accept: () => Promise<void>; dismiss: () => Promise<void> }) => {
    dialogSeen = true;
    if (mode === 'cancel') {
      await dialog.dismiss();
      return;
    }
    await dialog.accept();
  };

  page.on('dialog', dialogHandler as never);

  let result: 'PASS' | 'FAIL' = 'PASS';
  let detail = '';
  let screenshotPath = '';

  try {
    const locator = page.locator(candidate.selector).first();
    await locator.waitFor({ state: 'visible', timeout: 3_000 });

    if (candidate.isSubmit && candidate.formSelector) {
      await fillFormWithDummyData(page, candidate.formSelector, options.videoPath, `${Date.now()}_${index}`);
    }

    await locator.click({ timeout: 5_000 });
    await page.waitForLoadState('domcontentloaded', { timeout: 3_000 }).catch(() => undefined);
    await page.waitForTimeout(100);

    const healthIssues = summarizeHealth(monitor.health);
    if (healthIssues.length > 0) {
      throw new Error(healthIssues.join(' | '));
    }

    const bodyText = await page.textContent('body').catch(() => '');
    if (!bodyText || !bodyText.trim()) {
      throw new Error('Blank page after interaction');
    }

    if (candidate.isDestructive && mode === 'cancel' && !dialogSeen) {
      throw new Error('Expected confirm dialog but none appeared');
    }

    detail = `ok (${mode})`;
  } catch (error) {
    result = 'FAIL';
    detail = error instanceof Error ? error.message : String(error);
    const screenshotName = `${options.role}_${slug(pageUrl)}_${slug(actionName)}_${mode}.png`;
    screenshotPath = path.join(options.screenshotDir, screenshotName);
    await page.screenshot({ path: screenshotPath, fullPage: true }).catch(() => undefined);
  } finally {
    monitor.stop();
    page.off('dialog', dialogHandler as never);
  }

  options.report.addAction({
    role: options.role,
    page: pageUrl,
    action: `${actionName} (${mode})`,
    result,
    errorDetail: detail,
    screenshotPath,
  });
}

function slug(value: string) {
  return value.toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/^-+|-+$/g, '').slice(0, 80) || 'item';
}
