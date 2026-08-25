import { existsSync, readFileSync } from 'fs';

/**
 * 极简 .env 加载：process.loadEnvFile 在 jest vm 环境静默失效，
 * 此处手写解析（无第三方依赖）；已存在的环境变量不覆盖（e2e 注入依赖此机制）。
 */
function loadDotEnv(): void {
  if (!existsSync('.env')) return;
  const content = readFileSync('.env', 'utf8');
  for (const line of content.split(/\r?\n/)) {
    const match = line.match(/^\s*([A-Za-z_][A-Za-z0-9_]*)\s*=\s*(.*?)\s*$/);
    if (!match) continue;
    let value = match[2];
    if (
      (value.startsWith('"') && value.endsWith('"')) ||
      (value.startsWith("'") && value.endsWith("'"))
    ) {
      value = value.slice(1, -1);
    }
    if (process.env[match[1]] === undefined) process.env[match[1]] = value;
  }
}

loadDotEnv();

export const config = {
  nodeEnv: process.env.NODE_ENV ?? 'development',
  port: Number(process.env.PORT ?? 3000),
  jwtSecret: process.env.JWT_SECRET ?? 'panji-m1-dev-secret',
  uploadDir: process.env.UPLOAD_DIR ?? 'uploads',
  // 对齐 ARCHITECTURE §6 与 infra/.env.example（DBI T-001 交付）
  databaseUrl:
    process.env.DATABASE_URL ??
    'postgresql://panji:panji_dev@localhost:5432/panji',
};
