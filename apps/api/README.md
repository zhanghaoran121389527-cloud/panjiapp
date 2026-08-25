# 盘迹 API（apps/api）

盘迹 M1 后端。NestJS + TypeScript + PostgreSQL + REST。唯一接口依据：`docs/API_CONTRACT.md`，数据库规格：`docs/DATABASE_SCHEMA.md`。

## 环境要求

- Node.js ≥ 20（本机已验证 v24.16.0）
- PostgreSQL 16：
  - 标准方式（推荐）：`cd infra && docker compose up -d`（库名 `panji`，连接串见 `infra/README.md`）
  - 本机无 Docker 时的替代：`npm run db:start`（`scripts/dev-db.mjs`，要求 `PG_BIN_DIR`（默认 `D:\panji-pg-bin`）存在 PostgreSQL 二进制；仅本机开发环境使用）

## 启动

```bash
cd apps/api
npm install                 # 沙箱环境若禁 .cmd：node "<nodejs>\node_modules\npm\bin\npm-cli.js" install
npm run db:start            # 或 infra 的 docker compose up -d
npm run migration:run       # 建表 + 品类种子
npm run dev                 # 监听 3000
```

验证：`curl http://127.0.0.1:3000/v1/health` → `{"status":"ok"}`

## 常用命令

| 命令 | 说明 |
|---|---|
| `npm run typecheck` | tsc 类型检查 |
| `npm run lint` | ESLint |
| `npm test` | 单元测试（--runInBand） |
| `npm run test:e2e` | e2e（需本地 PG 已启动；会重置目标库 schema 后跑迁移） |
| `npm run migration:generate -- src/migrations/<Name>` | 生成迁移 |
| `npm run migration:run` / `migration:revert` | 执行 / 回滚迁移 |
| `npm run build` | 编译产物到 dist/ |

## 配置

环境变量见 `.env.example`，均有默认值（`DATABASE_URL` 默认 `postgresql://panji:panji_dev@localhost:5432/panji`，与 infra 一致）。`.env` 可选；已有环境变量优先（e2e 依赖此机制注入）。

## 目录

```
src/
  main.ts / app.module.ts   入口与全局装配
  app-setup.ts              前缀 /v1、ValidationPipe、/uploads 静态托管（main 与 e2e 共用）
  config.ts                 环境变量（Node 原生 loadEnvFile，无 dotenv）
  common/                   统一错误 ApiError、错误过滤器、AuthGuard、@Public、日期工具
  health/                   GET /v1/health
  entities/                 6 张表实体（schema 事实来源）
  migrations/               TypeORM migration（CreateTables + SeedCategories）
  data-source.ts            TypeORM CLI 数据源
  modules/                  auth / users / categories / items / records / uploads
scripts/dev-db.mjs          本机无 Docker 时的本地 PG（pg_ctl，无第三方依赖）
test/                       e2e（m0-002 底座验收 + 主链）
```

## 图片

上传落本地 `uploads/`（gitignore），相对 URL `/uploads/<uuid>.<ext>` 由静态路由直接输出。

## 安全

- Dev Login 仅非生产环境启用：`NODE_ENV=production` 时 `POST /v1/auth/dev-login` 返回 404（正式登录另行实现）。
- JWT 密钥默认值仅限本地开发；生产必须注入 `JWT_SECRET`。
