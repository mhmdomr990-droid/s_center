import { Column, Entity, JoinColumn, ManyToOne, Unique } from 'typeorm';

import { BaseColumns } from './BaseColumns';
import { Lecture } from './Lecture';
import { User } from './User';

@Entity({ name: 'lecture_grants' })
@Unique('uq_lecture_grant_user_lecture', ['user', 'lecture'])
export class LectureGrant extends BaseColumns {
  @ManyToOne(() => User, (user) => user.lectureGrants, { onDelete: 'CASCADE', eager: false })
  @JoinColumn({ name: 'user_id' })
  user!: User;

  @ManyToOne(() => Lecture, (lecture) => lecture.lectureGrants, { onDelete: 'CASCADE', eager: false })
  @JoinColumn({ name: 'lecture_id' })
  lecture!: Lecture;

  @ManyToOne(() => User, (user) => user.grantedLectures, { nullable: true, onDelete: 'SET NULL', eager: false })
  @JoinColumn({ name: 'granted_by' })
  grantedBy!: User | null;

  @Column({ name: 'granted_at', type: 'datetime' })
  grantedAt!: Date;

  @Column({ type: 'boolean', default: false })
  revoked!: boolean;
}
