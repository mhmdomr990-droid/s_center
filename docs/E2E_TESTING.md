# End-to-End Browser Testing (Playwright)

This project now includes a real browser E2E suite under `tests/e2e`.

## 1) Test database isolation

The E2E run uses `NODE_ENV=test` and requires a separate schema via `DB_NAME_TEST`.

Required environment variables before running:

- `DB_HOST`
- `DB_PORT`
- `DB_USER`
- `DB_PASSWORD`
- `DB_NAME`
- `DB_NAME_TEST` (must be different from `DB_NAME`)
- `DB_SYNC` (recommended: `true` in test env)
- `JWT_SECRET`
- `JWT_EXPIRES_IN`
- `CORS_ORIGINS`
- `ADMIN_USERNAME`
- `ADMIN_PASSWORD`

Important:

- `DB_NAME_TEST` is now honored automatically when `NODE_ENV=test`.
- Never point `DB_NAME_TEST` to production data.

## 2) One-time browser install

```bash
npx playwright install chromium
```

## 3) Run tests

Headless:

```bash
npm run test:e2e
```

Headed (watch browser):

```bash
npm run test:e2e:headed
```

## 4) What the suite does

- Seeds admin via `npm run seed:admin` in global setup.
- Creates test-only teachers/students/specialization/course/lecture.
- Uploads a real tiny MP4 test file from `tests/e2e/fixtures/tiny.mp4`.
- Runs money-critical and authorization scenarios.
- Crawls role nav pages from live DOM and clicks/interacts with visible controls.
- Captures console errors, page errors, network failures, and HTTP 4xx/5xx responses.
- Saves failure screenshots in `test-results/e2e-failures`.
- Writes:
  - `test-results/e2e-action-report.json`
  - `test-results/e2e-action-report.md`

## 5) Notes

- All destructive actions are intended for test-only generated data.
- The report includes a deduplicated "قائمة المشاكل" section sorted by severity.
