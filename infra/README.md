# 本地 PostgreSQL 开发环境（M0-001）

> **标准开发环境 = 本机 PostgreSQL 16 路线（裁决 B12）**；Docker Compose 仅为**备选（需 Docker）**。

## 标准路线：本机 PostgreSQL 16（B12）

团队无 Docker 机器，日常开发统一使用本机 PG16。BE 已提供一条命令脚本 `apps/api/scripts/dev-db.mjs`：

```bash
cd apps/api
node scripts/dev-db.mjs start    # 首次自动 initdb + 启动 + 幂等创建 panji 库；已启动则直接复用
node scripts/dev-db.mjs stop     # 停止（数据保留）
```

- 前置：本机需有 PostgreSQL 16 二进制，默认取 `PG_BIN_DIR`（默认 `D:\panji-pg-bin`，须含 `bin/initdb.exe`、`bin/pg_ctl.exe`）；数据目录 `PG_DATA_DIR`（默认 `D:\panji-data`）；端口 `DB_PORT`（默认 5432），均可经环境变量覆盖。
- 注意：PG 二进制与数据目录必须是**纯 ASCII 路径**（中文路径会导致 initdb 编码注入失败）。
- 也可直接用本机已装 PG（如 `D:\wzw\.pgsql`）：保证存在 `panji` 库与 `panji`/`panji_dev` 账号即可，连接串一致。
- 启动成功后脚本输出 `PostgreSQL ready: postgresql://...`，即连接可用。

### 验证（本机 PG 路线）

```bash
cd apps/api
node scripts/dev-db.mjs start    # ① 一条命令启动（输出 ready 连接串 = ② 可连）
node scripts/dev-db.mjs stop     # ③ 停止（数据仍在）
node scripts/dev-db.mjs start    # ③ 再启动（检测到 PG_VERSION 跳过 initdb，原数据全部保留）
```

## 连接信息（交给 BE / QA）

| 项 | 值 |
|---|---|
| Host | `localhost` |
| Port | `5432` |
| Database | `panji` |
| User / Password | `panji` / `panji_dev` |
| 连接串（= 后端 `DATABASE_URL`） | `postgresql://panji:panji_dev@localhost:5432/panji` |

## 备选路线：Docker Compose（需 Docker）

> 裁决 B12：团队当前无任何 Docker 机器，compose 仅为备选；其 Docker 实跑属环境能力豁免（记入已知缺口），有 Docker 机器时按下列命令补验。

```bash
cd infra
docker compose up -d                            # ① 启动（镜像 postgres:16-alpine + named volume）
docker compose ps                               # 容器状态（healthy = 就绪）
docker exec -it panji-postgres psql -U panji -d panji -c "select version();"   # ② psql 可连

# ③ 持久化验证（对应 M0-001 验收③）：写一行 → 删容器 → 重建 → 数据仍在
docker exec -it panji-postgres psql -U panji -d panji -c "create table _t(id int); insert into _t values (1);"
docker compose down && docker compose up -d
docker exec -it panji-postgres psql -U panji -d panji -c "select * from _t; drop table _t;"

docker compose down          # 停止（保留数据 volume）
docker compose down -v       # 停止并删除数据（重置环境，谨慎）
docker compose logs -f postgres
```

- 可选：`cp .env.example .env` 修改端口/账号（不改则用默认值）；端口被占用时改 `.env` 的 `POSTGRES_PORT`。

## 重要约定

- 两条路线都只提供**空库**，不执行任何建表 SQL。表结构由 BE 的 TypeORM migration 落库（docs/API_CONTRACT.md 裁决 A1；docs/DATABASE_SCHEMA.md §0），避免双份 schema 漂移。
- 数据库层不设置时区：时间戳统一 `timestamptz`（UTC），日期按北京时间由应用层解释（docs/API_CONTRACT.md 裁决 A8；docs/DATABASE_SCHEMA.md §0 时区红线）。
