/**
 * 本机无 Docker 时的本地 PostgreSQL 16（仅用 pg_ctl + 项目内 pg 驱动，无额外依赖）。
 * 前置：PG_BIN_DIR（默认 D:\panji-pg-bin）内需存在 PostgreSQL 16 二进制（bin/initdb.exe、pg_ctl.exe）。
 * 注意：PG 二进制与数据目录必须是纯 ASCII 路径（中文路径会导致 initdb 以 GBK 字节
 * 注入 UTF8 服务端而失败）。
 * 用法：node scripts/dev-db.mjs start|stop
 */
import { spawnSync } from 'child_process';
import { existsSync, rmSync, writeFileSync } from 'fs';
import { tmpdir } from 'os';
import { join } from 'path';
import pg from 'pg';

const BIN = process.env.PG_BIN_DIR ?? 'D:\\panji-pg-bin';
const DATA = process.env.PG_DATA_DIR ?? 'D:\\panji-data';
const PORT = Number(process.env.DB_PORT ?? 5432);
const USER = 'panji';
const PASSWORD = 'panji_dev';
const LOG = join(DATA, 'pg.log');

const cmd = process.argv[2] ?? 'start';

function run(exe, args, env = process.env) {
  const r = spawnSync(join(BIN, 'bin', `${exe}.exe`), args, {
    stdio: 'inherit',
    env,
  });
  if (r.status !== 0) {
    console.error(`${exe} failed (exit ${r.status})`);
    process.exit(r.status ?? 1);
  }
}

if (!existsSync(join(BIN, 'bin', 'pg_ctl.exe'))) {
  console.error(
    `PG_BIN_DIR 无 PostgreSQL 二进制：${BIN}\n` +
      '请安装本机 PostgreSQL 16 二进制后通过 PG_BIN_DIR 指向其 bin 目录，' +
      '或使用本机已安装的 PostgreSQL（设置 PG_BIN_DIR 为对应 bin 目录）。',
  );
  process.exit(1);
}

async function ensureDatabase() {
  const client = new pg.Client({
    user: USER,
    password: PASSWORD,
    host: 'localhost',
    port: PORT,
    database: 'postgres',
  });
  await client.connect();
  const { rows } = await client.query(
    `SELECT 1 FROM pg_database WHERE datname = 'panji'`,
  );
  if (rows.length === 0) {
    await client.query('CREATE DATABASE panji');
  } else {
    console.log('database panji already exists, skip create');
  }
  await client.end();
}

if (cmd === 'start') {
  if (!existsSync(join(DATA, 'PG_VERSION'))) {
    // initdb 要求数据目录不存在或为空，pwfile 放临时目录
    const pwfile = join(tmpdir(), 'panji-pw.tmp');
    writeFileSync(pwfile, `${PASSWORD}\n`);
    run('initdb', [
      `--pgdata=${DATA}`,
      '--auth=password',
      `--username=${USER}`,
      `--pwfile=${pwfile}`,
      '--lc-messages=C',
      '--locale=C',
      '--encoding=UTF8',
    ]);
    rmSync(pwfile, { force: true });
  }
  run('pg_ctl', ['-D', DATA, '-l', LOG, '-o', `-p ${PORT}`, 'start']);
  await ensureDatabase();
  console.log(
    `PostgreSQL ready: postgresql://panji:panji_dev@localhost:${PORT}/panji`,
  );
  console.log('停止：npm run db:stop');
} else if (cmd === 'stop') {
  run('pg_ctl', ['-D', DATA, 'stop']);
} else {
  console.error('usage: node scripts/dev-db.mjs [start|stop]');
  process.exit(1);
}
