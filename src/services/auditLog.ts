import { AppDataSource } from '../config/data-source';
import { AuditLog } from '../entities/AuditLog';

export async function logAuditEvent(input: {
  action: string;
  actorId?: number | null;
  entityType?: string | null;
  entityId?: number | null;
  metadata?: Record<string, unknown> | null;
}) {
  const repository = AppDataSource.getRepository(AuditLog);
  await repository.save(
    repository.create({
      action: input.action,
      actorId: input.actorId ?? null,
      entityType: input.entityType ?? null,
      entityId: input.entityId ?? null,
      metadata: input.metadata ? JSON.stringify(input.metadata) : null,
    }),
  );
}
