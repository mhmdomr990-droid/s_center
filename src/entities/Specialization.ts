import { Column, Entity, OneToMany } from 'typeorm';

import { BaseColumns } from './BaseColumns';
import { Course } from './Course';
import { User } from './User';

@Entity({ name: 'specializations' })
export class Specialization extends BaseColumns {
  @Column({ type: 'varchar', length: 120 })
  name!: string;

  @Column({ name: 'is_published', type: 'boolean', default: true })
  isPublished!: boolean;

  @Column({ name: 'sort_order', type: 'int', default: 0 })
  sortOrder!: number;

  @OneToMany(() => Course, (course) => course.specialization)
  courses!: Course[];

  @OneToMany(() => User, (user) => user.specialization)
  users!: User[];
}
