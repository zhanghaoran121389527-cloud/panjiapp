import {
  Check,
  Column,
  CreateDateColumn,
  Entity,
  Index,
  JoinColumn,
  ManyToOne,
} from 'typeorm';
import { BaseEntity } from './base.entity';
import { Item } from './item.entity';

@Entity('item_records')
@Check('char_length("content") BETWEEN 1 AND 500')
@Check('"duration_minutes" IS NULL OR "duration_minutes" BETWEEN 1 AND 1440')
@Check('"method" IS NULL OR char_length("method") BETWEEN 1 AND 20')
@Index('idx_item_records_item_id', ['itemId'])
export class ItemRecord extends BaseEntity {
  @Column({ name: 'item_id', type: 'uuid' })
  itemId: string;

  // DATABASE_SCHEMA v2：RESTRICT 防物理误删多年记录；删除走 items.deleted_at 逻辑删除
  @ManyToOne(() => Item, { onDelete: 'RESTRICT' })
  @JoinColumn({ name: 'item_id' })
  item: Item;

  @Column({ name: 'content', type: 'text' })
  content: string;

  @Column({ name: 'duration_minutes', type: 'int', nullable: true })
  durationMinutes: number | null;

  @Column({ name: 'method', type: 'text', nullable: true })
  method: string | null;

  @Column({ name: 'recorded_date', type: 'date' })
  recordedDate: string;

  @CreateDateColumn({ name: 'created_at', type: 'timestamptz' })
  createdAt: Date;
}
