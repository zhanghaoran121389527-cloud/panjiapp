import { randomUUID } from 'crypto';
import { BeforeInsert, PrimaryColumn } from 'typeorm';

/**
 * uuid v4 应用侧生成（DATABASE_SCHEMA §0：不用数据库 default、不依赖 uuid-ossp）。
 */
export abstract class BaseEntity {
  @PrimaryColumn('uuid')
  id!: string;

  @BeforeInsert()
  generateId(): void {
    if (!this.id) this.id = randomUUID();
  }
}
