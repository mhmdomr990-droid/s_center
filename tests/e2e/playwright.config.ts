import path from 'path';
import { defineConfig } from '@playwright/test';

const projectRoot = path.resolve(__dirname, '..', '..');
const outputDir = path.resolve(projectRoot, 'test-results');

export default defineConfig({
  testDir: path.resolve(__dirname, 'specs'),
  timeout: 900_000,
  fullyParallel: false,
  reporter: [['list']],
  outputDir,
  use: {
    baseURL: process.env.E2E_BASE_URL || 'http://127.0.0.1:3000',
    channel: process.env.PW_CHANNEL || 'msedge',
    headless: true,
    trace: 'retain-on-failure',
    screenshot: 'only-on-failure',
    video: 'retain-on-failure',
  },
  globalSetup: path.resolve(__dirname, 'global-setup.ts'),
  webServer: {
    command: 'node dist/server.js',
    cwd: projectRoot,
    url: process.env.E2E_BASE_URL || 'http://127.0.0.1:3000',
    timeout: 180_000,
    reuseExistingServer: false,
    env: {
      ...process.env,
      NODE_ENV: 'test',
    },
  },
});
