import { Column, Entity, JoinColumn, ManyToOne } from 'typeorm';

import { BaseColumns } from './BaseColumns';
import { Course } from './Course';
import { LectureType, LectureUploadStatus } from './enums';
import { User } from './User';

@Entity({ name: 'lectures' })
export class Lecture extends BaseColumns {
  @ManyToOne(() => Course, (course) => course.lectures, { onDelete: 'RESTRICT', eager: false })
  @JoinColumn({ name: 'course_id' })
  course!: Course;

  @ManyToOne(() => User, { nullable: true, onDelete: 'SET NULL', eager: false })
  @JoinColumn({ name: 'created_by' })
  createdBy!: User | null;

  @Column({ type: 'varchar', length: 150 })
  title!: string;

  @Column({ type: 'enum', enum: LectureType })
  type!: LectureType;

  @Column({ type: 'text', nullable: true })
  url!: string | null;

  @Column({ name: 'storage_filename', type: 'varchar', length: 255, nullable: true })
  storageFilename!: string | null;

  @Column({ name: 'file_size', type: 'bigint', nullable: true })
  fileSize!: string | null;

  @Column({ name: 'duration_seconds', type: 'int', nullable: true })
  durationSeconds!: number | null;

  @Column({ name: 'upload_status', type: 'enum', enum: LectureUploadStatus, default: LectureUploadStatus.READY })
  uploadStatus!: LectureUploadStatus;

  @Column({ type: 'text', nullable: true })
  content!: string | null;

  @Column({ name: 'is_published', type: 'boolean', default: true })
  isPublished!: boolean;

  @Column({ name: 'sort_order', type: 'int', default: 0 })
  sortOrder!: number;
}
