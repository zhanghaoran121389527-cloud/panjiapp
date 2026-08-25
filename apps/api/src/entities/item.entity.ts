import {
  Check,
  Column,
  CreateDateColumn,
  Entity,
  Index,
  JoinColumn,
  ManyToOne,
  UpdateDateColumn,
} from 'typeorm';
import { BaseEntity } from './base.entity';
import { Category } from './category.entity';
import { User } from './user.entity';

@Entity('items')
@Check('char_length("name") BETWEEN 1 AND 50')
@Index('idx_items_user_id', ['userId'])
export class Item extends BaseEntity {
  @Column({ name: 'user_id', type: 'uuid' })
  userId: string;

  @ManyToOne(() => User, { onDelete: 'RESTRICT' })
  @JoinColumn({ name: 'user_id' })
  user: User;

  @Column({ name: 'category_id', type: 'uuid' })
  categoryId: string;

  @ManyToOne(() => Category, { onDelete: 'RESTRICT' })
  @JoinColumn({ name: 'category_id' })
  category: Category;

  @Column({ name: 'name', type: 'text' })
  name: string;

  @Column({ name: 'cover_image_url', type: 'text', nullable: true })
  coverImageUrl: string | null;

  @Column({ name: 'subcategory', type: 'text', nullable: true })
  subcategory: string | null;

  @Column({ name: 'size_spec', type: 'text', nullable: true })
  sizeSpec: string | null;

  @Column({ name: 'acquired_date', type: 'date', nullable: true })
  acquiredDate: string | null;

  @Column({ name: 'notes', type: 'text', nullable: true })
  notes: string | null;

  /**
   * 逻辑删除时间（DATABASE_SCHEMA v2）：NULL=在用，非 NULL=已删除。
   * 故意不用 @DeleteDateColumn 隐式软删——所有查询必须显式过滤
   * `deleted_at IS NULL`（DATABASE_SCHEMA §9.7，防漏）。
   */
  @Column({ name: 'deleted_at', type: 'timestamptz', nullable: true })
  deletedAt: Date | null;

  @CreateDateColumn({ name: 'created_at', type: 'timestamptz' })
  createdAt: Date;

  @UpdateDateColumn({ name: 'updated_at', type: 'timestamptz' })
  updatedAt: Date;
}
