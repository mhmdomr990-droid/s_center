import { Column, Entity, Index } from 'typeorm';

import { BaseColumns } from './BaseColumns';

@Entity({ name: 'app_settings' })
export class AppSetting extends BaseColumns {
  @Index({ unique: true })
  @Column({ type: 'varchar', length: 100 })
  key!: string;

  @Column({ type: 'longtext', nullable: true })
  value!: string | null;
}
