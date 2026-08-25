# 本地 PostgreSQL 开发环境（M0-001）

一条命令启动盘迹 M1 开发数据库（PostgreSQL 16 + named volume，重启不丢数据）。

## 前置

- 安装 Docker Desktop（Windows）
- 可选：`cp .env.example .env` 修改端口/账号（不改则用默认值）

## 启动

```bash
cd infra
docker compose up -d
```

## 连接信息（交给 BE / QA）

| 项 | 值 |
|---|---|
| Host | `localhost` |
| Port | `5432` |
| Database | `panji` |
| User / Password | `panji` / `panji_dev` |
| 连接串（= 后端 `DATABASE_URL`） | `postgresql://panji:panji_dev@localhost:5432/panji` |

## 验证

```bash
# 容器状态（healthy = 就绪）
docker compose ps

# psql 直连
docker exec -it panji-postgres psql -U panji -d panji -c "select version();"

# 持久化验证（对应 M0-001 验收③）：写一行 → 删容器 → 重建 → 数据仍在
docker exec -it panji-postgres psql -U panji -d panji -c "create table _t(id int); insert into _t values (1);"
docker compose down && docker compose up -d
docker exec -it panji-postgres psql -U panji -d panji -c "select * from _t; drop table _t;"
```

## 常用操作

```bash
docker compose down          # 停止（保留数据 volume）
docker compose down -v       # 停止并删除数据（重置环境，谨慎）
docker compose logs -f postgres
```

## 重要约定

- 本环境只创建**空库**，不执行任何建表 SQL。表结构由 BE 的 TypeORM migration 落库（docs/API_CONTRACT.md 裁决 A1；docs/DATABASE_SCHEMA.md §0），避免双份 schema 漂移。
- 端口被占用时改 `.env` 的 `POSTGRES_PORT`。
- 数据库层不设置时区：时间戳统一 `timestamptz`（UTC），日期按北京时间由应用层解释（docs/API_CONTRACT.md 裁决 A8；docs/DATABASE_SCHEMA.md §0 时区红线）。
