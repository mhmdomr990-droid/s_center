import { Column, Entity, JoinColumn, ManyToOne, OneToMany } from 'typeorm';

import { BaseColumns } from './BaseColumns';
import { UserRole } from './enums';
import { Course } from './Course';
import { Notification } from './Notification';
import { Purchase } from './Purchase';
import { Specialization } from './Specialization';
import { TeacherPayout } from './TeacherPayout';
import { TopupRequest } from './TopupRequest';
import { Transaction } from './Transaction';

@Entity({ name: 'users' })
export class User extends BaseColumns {
  @Column({ type: 'varchar', length: 30, unique: true })
  username!: string;

  @Column({ name: 'full_name', type: 'varchar', length: 120 })
  fullName!: string;

  @Column({ name: 'password_hash', type: 'varchar', length: 255 })
  passwordHash!: string;

  @Column({ type: 'enum', enum: UserRole, default: UserRole.STUDENT })
  role!: UserRole;

  @ManyToOne(() => Specialization, (specialization) => specialization.users, { nullable: true, onDelete: 'SET NULL', eager: false })
  @JoinColumn({ name: 'specialization_id' })
  specialization!: Specialization | null;

  @Column({ type: 'varchar', length: 30, nullable: true })
  phone!: string | null;

  @Column({ name: 'token_version', type: 'int', default: 0 })
  tokenVersion!: number;

  @Column({ name: 'is_test', type: 'boolean', default: false })
  isTest!: boolean;

  @Column({ name: 'is_active', type: 'boolean', default: true })
  isActive!: boolean;

  @Column({ type: 'decimal', precision: 12, scale: 2, default: '0.00' })
  balance!: string;

  @Column({ name: 'device_id', type: 'varchar', length: 255, nullable: true })
  deviceId!: string | null;

  @OneToMany(() => Course, (course) => course.teacher)
  taughtCourses!: Course[];

  @OneToMany(() => Purchase, (purchase) => purchase.user)
  purchases!: Purchase[];

  @OneToMany(() => Purchase, (purchase) => purchase.grantedBy)
  grantedCourses!: Purchase[];

  @OneToMany(() => Transaction, (transaction) => transaction.user)
  transactions!: Transaction[];

  @OneToMany(() => TopupRequest, (topupRequest) => topupRequest.user)
  topupRequests!: TopupRequest[];

  @OneToMany(() => TopupRequest, (topupRequest) => topupRequest.reviewedBy)
  reviewedTopupRequests!: TopupRequest[];

  @OneToMany(() => Notification, (notification) => notification.user)
  notifications!: Notification[];

  @OneToMany(() => TeacherPayout, (payout) => payout.teacher)
  teacherPayouts!: TeacherPayout[];

  @OneToMany(() => TeacherPayout, (payout) => payout.createdBy)
  createdTeacherPayouts!: TeacherPayout[];
}
