import path from 'path';

import type { Page } from '@playwright/test';

export async function fillFormWithDummyData(page: Page, formSelector: string, videoPath: string, uniqueSeed: string) {
  const form = page.locator(formSelector).first();
  if (!(await form.count())) {
    return;
  }

  const fields = form.locator('input, textarea, select');
  const count = await fields.count();

  for (let i = 0; i < count; i += 1) {
    const field = fields.nth(i);
    const tagName = (await field.evaluate((el) => el.tagName.toLowerCase())) as string;
    const name = (await field.getAttribute('name')) || '';
    const type = ((await field.getAttribute('type')) || '').toLowerCase();
    const disabled = await field.isDisabled();
    const hidden = type === 'hidden';

    if (disabled || hidden) {
      continue;
    }

    if (tagName === 'select') {
      const options = field.locator('option');
      const optionCount = await options.count();
      if (optionCount > 1) {
        const secondValue = (await options.nth(1).getAttribute('value')) ?? '';
        await field.selectOption(secondValue);
      }
      continue;
    }

    if (type === 'checkbox' || type === 'radio') {
      try {
        await field.check();
      } catch {
        // Ignore non-interactable options.
      }
      continue;
    }

    if (type === 'file') {
      await field.setInputFiles(videoPath);
      continue;
    }

    const value = buildValue(name, type, uniqueSeed, path.basename(videoPath));
    if (value !== null) {
      await field.fill(value);
    }
  }
}

function buildValue(name: string, type: string, uniqueSeed: string, _videoName: string) {
  const lowered = name.toLowerCase();

  if (lowered.includes('csrf')) {
    return null;
  }
  if (lowered.includes('username')) {
    return `e2e_user_${uniqueSeed}`;
  }
  if (lowered.includes('full_name') || lowered.includes('sender_name') || lowered.includes('name')) {
    return `E2E ${uniqueSeed}`;
  }
  if (lowered.includes('password')) {
    return 'pass12345';
  }
  if (lowered.includes('reference')) {
    return `REF-${uniqueSeed}`;
  }
  if (lowered.includes('amount')) {
    return '10.00';
  }
  if (lowered.includes('percent')) {
    return '30.00';
  }
  if (lowered.includes('price')) {
    return '100.00';
  }
  if (lowered.includes('year')) {
    return '1';
  }
  if (lowered.includes('title')) {
    return `E2E Title ${uniqueSeed}`;
  }
  if (lowered.includes('description') || lowered.includes('content') || lowered.includes('body') || lowered.includes('note')) {
    return `E2E note ${uniqueSeed}`;
  }

  if (type === 'email') {
    return `e2e_${uniqueSeed}@example.com`;
  }
  if (type === 'number') {
    return '1';
  }
  if (type === 'url') {
    return 'https://example.com';
  }

  return `e2e_${uniqueSeed}`;
}
