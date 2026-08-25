import { Column, Entity } from 'typeorm';
import { BaseEntity } from './base.entity';

@Entity('categories')
export class Category extends BaseEntity {
  @Column({ name: 'name', type: 'text', unique: true })
  name: string;

  @Column({ name: 'sort_order', type: 'int' })
  sortOrder: number;
}
