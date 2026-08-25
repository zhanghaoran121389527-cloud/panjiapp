import { Check, Column, CreateDateColumn, Entity, UpdateDateColumn } from 'typeorm';
import { BaseEntity } from './base.entity';

@Entity('users')
@Check('"nickname" IS NULL OR char_length("nickname") BETWEEN 1 AND 20')
export class User extends BaseEntity {
  @Column({ name: 'nickname', type: 'text', nullable: true })
  nickname: string | null;

  @CreateDateColumn({ name: 'created_at', type: 'timestamptz' })
  createdAt: Date;

  @UpdateDateColumn({ name: 'updated_at', type: 'timestamptz' })
  updatedAt: Date;
}
