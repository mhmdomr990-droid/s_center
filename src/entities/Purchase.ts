import { Column, Entity, JoinColumn, ManyToOne, Unique } from 'typeorm';

import { BaseColumns } from './BaseColumns';
import { Course } from './Course';
import { PurchaseSource } from './enums';
import { User } from './User';

@Entity({ name: 'purchases' })
@Unique('uq_purchase_user_course', ['user', 'course'])
export class Purchase extends BaseColumns {
  @ManyToOne(() => User, (user) => user.purchases, { onDelete: 'CASCADE', eager: false })
  @JoinColumn({ name: 'user_id' })
  user!: User;

  @ManyToOne(() => Course, (course) => course.purchases, { onDelete: 'RESTRICT', eager: false })
  @JoinColumn({ name: 'course_id' })
  course!: Course;

  @ManyToOne(() => User, { nullable: true, onDelete: 'SET NULL', eager: false })
  @JoinColumn({ name: 'teacher_id' })
  teacher!: User | null;

  @Column({ type: 'enum', enum: PurchaseSource, default: PurchaseSource.PURCHASED })
  source!: PurchaseSource;

  @ManyToOne(() => User, (user) => user.grantedCourses, { nullable: true, onDelete: 'SET NULL', eager: false })
  @JoinColumn({ name: 'granted_by' })
  grantedBy!: User | null;

  @Column({ name: 'price_paid', type: 'decimal', precision: 12, scale: 2 })
  pricePaid!: string;

  @Column({ name: 'teacher_share', type: 'decimal', precision: 12, scale: 2, default: '0.00' })
  teacherShare!: string;
}
