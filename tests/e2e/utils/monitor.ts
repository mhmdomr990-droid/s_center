import type { Page, Request, ConsoleMessage, Response } from '@playwright/test';

export interface PageHealth {
  consoleErrors: string[];
  pageErrors: string[];
  requestFailures: string[];
  badResponses: string[];
}

export function monitorPageHealth(page: Page) {
  const health: PageHealth = {
    consoleErrors: [],
    pageErrors: [],
    requestFailures: [],
    badResponses: [],
  };

  const onConsole = (message: ConsoleMessage) => {
    if (message.type() === 'error') {
      health.consoleErrors.push(message.text());
    }
  };

  const onPageError = (error: Error) => {
    health.pageErrors.push(error.message);
  };

  const onRequestFailed = (request: Request) => {
    const failure = request.failure();
    health.requestFailures.push(`${request.method()} ${request.url()} :: ${failure?.errorText || 'failed'}`);
  };

  const onResponse = (response: Response) => {
    const status = response.status();
    if (status >= 400) {
      health.badResponses.push(`${status} ${response.request().method()} ${response.url()}`);
    }
  };

  page.on('console', onConsole);
  page.on('pageerror', onPageError);
  page.on('requestfailed', onRequestFailed);
  page.on('response', onResponse);

  return {
    health,
    stop: () => {
      page.off('console', onConsole);
      page.off('pageerror', onPageError);
      page.off('requestfailed', onRequestFailed);
      page.off('response', onResponse);
    },
  };
}

export function summarizeHealth(health: PageHealth) {
  const errors = [
    ...health.pageErrors.map((item) => `pageerror: ${item}`),
    ...health.consoleErrors.map((item) => `console: ${item}`),
    ...health.requestFailures.map((item) => `requestfailed: ${item}`),
    ...health.badResponses.map((item) => `http: ${item}`),
  ];
  return errors;
}
