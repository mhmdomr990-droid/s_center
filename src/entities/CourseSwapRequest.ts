import { Column, Entity, JoinColumn, ManyToOne } from 'typeorm';

import { BaseColumns } from './BaseColumns';
import { Course } from './Course';
import { CourseSwapStatus } from './enums';
import { Purchase } from './Purchase';
import { User } from './User';

@Entity({ name: 'course_swap_requests' })
export class CourseSwapRequest extends BaseColumns {
  @ManyToOne(() => User, (user) => user.id, { onDelete: 'CASCADE', eager: false })
  @JoinColumn({ name: 'student_id' })
  student!: User;

  @ManyToOne(() => Purchase, { nullable: true, onDelete: 'SET NULL', eager: false })
  @JoinColumn({ name: 'old_purchase_id' })
  oldPurchase!: Purchase | null;

  @ManyToOne(() => Course, { nullable: true, onDelete: 'RESTRICT', eager: false })
  @JoinColumn({ name: 'old_course_id' })
  oldCourse!: Course;

  @ManyToOne(() => Course, { nullable: false, onDelete: 'RESTRICT', eager: false })
  @JoinColumn({ name: 'new_course_id' })
  newCourse!: Course;

  @ManyToOne(() => User, { nullable: true, onDelete: 'SET NULL', eager: false })
  @JoinColumn({ name: 'old_teacher_id' })
  oldTeacher!: User | null;

  @ManyToOne(() => User, { nullable: true, onDelete: 'SET NULL', eager: false })
  @JoinColumn({ name: 'new_teacher_id' })
  newTeacher!: User | null;

  @Column({ name: 'old_teacher_share', type: 'decimal', precision: 12, scale: 2, default: '0.00' })
  oldTeacherShare!: string;

  @Column({ name: 'new_teacher_share', type: 'decimal', precision: 12, scale: 2, default: '0.00' })
  newTeacherShare!: string;

  @Column({ type: 'enum', enum: CourseSwapStatus, default: CourseSwapStatus.PENDING })
  status!: CourseSwapStatus;

  @Column({ type: 'text', nullable: true })
  reason!: string | null;

  @Column({ name: 'admin_note', type: 'text', nullable: true })
  adminNote!: string | null;

  @ManyToOne(() => User, { nullable: true, onDelete: 'SET NULL', eager: false })
  @JoinColumn({ name: 'approved_by' })
  approvedBy!: User | null;

  @ManyToOne(() => User, { nullable: true, onDelete: 'SET NULL', eager: false })
  @JoinColumn({ name: 'rejected_by' })
  rejectedBy!: User | null;

  @Column({ name: 'approved_at', type: 'datetime', nullable: true })
  approvedAt!: Date | null;

  @Column({ name: 'rejected_at', type: 'datetime', nullable: true })
  rejectedAt!: Date | null;
}
