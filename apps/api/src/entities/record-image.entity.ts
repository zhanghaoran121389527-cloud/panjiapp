import {
  Check,
  Column,
  CreateDateColumn,
  Entity,
  JoinColumn,
  ManyToOne,
  Unique,
} from 'typeorm';
import { BaseEntity } from './base.entity';
import { ItemRecord } from './item-record.entity';

@Entity('record_images')
@Check('"sort_order" >= 0')
@Unique('uq_record_images_record_sort', ['recordId', 'sortOrder'])
export class RecordImage extends BaseEntity {
  @Column({ name: 'record_id', type: 'uuid' })
  recordId: string;

  @ManyToOne(() => ItemRecord, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'record_id' })
  record: ItemRecord;

  @Column({ name: 'image_url', type: 'text' })
  imageUrl: string;

  @Column({ name: 'sort_order', type: 'int' })
  sortOrder: number;

  @CreateDateColumn({ name: 'created_at', type: 'timestamptz' })
  createdAt: Date;
}
