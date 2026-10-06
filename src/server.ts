import 'reflect-metadata';

import { AppDataSource } from './config/data-source';
import { env } from './config/env';
import { app } from './app';
import { cleanupExpiredIdempotencyKeys } from './services/idempotency';
import { ensureDefaultAdmin } from './seed-admin';

let idempotencyCleanupTimer: NodeJS.Timeout | undefined;

async function bootstrap() {
  await AppDataSource.initialize();
  await ensureDefaultAdmin();
  await cleanupExpiredIdempotencyKeys();
  idempotencyCleanupTimer = setInterval(() => {
    void cleanupExpiredIdempotencyKeys();
  }, 6 * 60 * 60 * 1000);

  app.listen(env.PORT, () => {
    // Intentionally minimal startup output.
    console.log(`Student Bot backend listening on port ${env.PORT}`);
  });
}

bootstrap().catch((error) => {
  if (idempotencyCleanupTimer) {
    clearInterval(idempotencyCleanupTimer);
  }
  console.error('Failed to start server:');
  if (error instanceof Error) {
    console.error(error.message);
    console.error(error.stack);
  } else {
    console.error(error);
  }
  process.exit(1);
});
