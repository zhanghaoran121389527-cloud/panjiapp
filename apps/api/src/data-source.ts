import 'reflect-metadata';
import { join } from 'path';
import { DataSource } from 'typeorm';
import { config } from './config';
import { AuthIdentity } from './entities/auth-identity.entity';
import { Category } from './entities/category.entity';
import { ItemRecord } from './entities/item-record.entity';
import { Item } from './entities/item.entity';
import { RecordImage } from './entities/record-image.entity';
import { User } from './entities/user.entity';

export function buildDataSourceOptions() {
  return {
    type: 'postgres' as const,
    url: config.databaseUrl,
    entities: [User, AuthIdentity, Category, Item, ItemRecord, RecordImage],
    migrations: [join(__dirname, 'migrations', '*.ts')],
    synchronize: false,
    // 会话时区固定 UTC（DATABASE_SCHEMA §9.5）
    extra: { timezone: 'UTC' },
  };
}

// TypeORM CLI（migration:generate / run / revert）专用
export const AppDataSource = new DataSource(buildDataSourceOptions());
