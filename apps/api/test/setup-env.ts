import { mkdtempSync } from 'fs';
import { tmpdir } from 'os';
import { join } from 'path';

/**
 * e2e 环境注入（jest setupFiles：先于测试模块加载执行）。
 * DATABASE_URL 沿用 .env / 默认值（本地 panji 库；标准环境 = infra Docker PG）。
 * 注意：main-chain e2e 会重置目标库 public schema（开发期数据可丢弃）。
 */
if (!process.env.UPLOAD_DIR) {
  process.env.UPLOAD_DIR = mkdtempSync(join(tmpdir(), 'panji-e2e-uploads-'));
}
