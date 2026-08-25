# 盘迹 架构说明（ARCHITECTURE）

## 1. 范围

本文档覆盖 M0 + M1。所有裁决以本文档 + `docs/API_CONTRACT.md` §5 为准；变更须总控批准（AGENTS §3）。

## 2. 总体架构（M1 开发态）

```
真实 iPhone（局域网 http，ATS NSAllowsLocalNetworking）
   │
   ▼
NestJS API（apps/api，开发机 :3000）  ← 业务接口 /v1/*；图片静态 /uploads/*
   │  TypeORM
   ▼
PostgreSQL 16（infra/ Docker :5432） ← 库名 panji，named volume 持久化
```

- 图片：M1 存 API 本机磁盘 `uploads/`，接口只回相对 URL；正式版换腾讯云 COS 时仅后端替换实现，iOS 零改动。
- 认证：JWT HS256，payload `{sub}`，365 天，Bearer 头；Dev Login 无短信。
- 真机联调：iOS baseURL 经 xcconfig 注入 `http://<开发机局域网IP>:3000`。
- 数据库时区：timestamptz 存 UTC；`date` 列按北京时间解释；dayCount 用北京"今天"由应用层计算（禁用 DB CURRENT_DATE）。

## 3. 仓库布局与模块所有权

| 路径 | 内容 | 所有者 |
|---|---|---|
| `/AGENTS.md` | Agent 工作规则 | 总控 |
| `docs/PRODUCT_SPEC.md` | 产品规格 | 总控 |
| `docs/ARCHITECTURE.md` | 本文档 | 总控 |
| `docs/API_CONTRACT.md` | 接口契约（唯一事实来源） | 总控（批准）、各角色提议 |
| `docs/DATABASE_SCHEMA.md` | 数据库公共规格（约束/索引/种子/DDL） | 总控（批准）、DBI 起草、BE 实施 |
| `docs/DESIGN_SYSTEM.md` | 设计系统 token | UI 产出、总控批准 |
| `docs/TASKS.md` | 任务看板 | 总控 |
| `docs/handoffs/` | 各任务交接单（TASK-ID.md） | 各角色 |
| `docs/design/` | 页面线框 | UI |
| `docs/qa/` | 验收清单与报告 | QA |
| `infra/` | docker-compose、环境模板（只建空库） | DBI |
| `apps/api/` | NestJS + TypeScript | BE |
| `apps/ios/` | SwiftUI 工程 | iOS |

角色只改自己的路径；跨模块输入输出一律以契约文档为准。

## 4. 技术裁决

| # | 裁决 |
|---|---|
| A1 | NestJS + TypeORM；实体即 schema 事实来源，TypeORM migration 落库（infra 不执行建表 SQL） |
| A2 | record_images 启用，记录支持 0~N 张照片，对外为 `photoUrls` 数组 |
| A3 | 图片本地磁盘 + 相对 URL，换 COS 时 iOS 零改动 |
| A4 | Dev Login 用 phone 作 dev 身份标识，无短信 |
| A5 | 子类、盘玩方式为自由文本，无字典表 |
| A6 | 玩物编辑/删除纳入 M1（PATCH/DELETE items） |
| A7 | JWT 365 天 + iOS UserDefaults |
| A8 | 所有日期按北京时间 |
| A9 | API 前缀 `/v1/` |
| A10 | recordedDate 不得晚于北京时间今天（服务端校验） |
| A11 | 补录不校验与入手日期先后，不提示 |
| A12 | 文本上限：name 1~50、content 1~500、nickname 1~20、notes ≤500、size_spec ≤100、subcategory ≤50、method ≤20 |
| A13 | 客户端"今天"按北京时间生成 |
| A14 | 客户端必须防重复提交；服务端幂等 M1 不做 |
| A15 | 删除后物理文件/孤儿文件 M1 不回收 |
| A16 | items 删除=**逻辑删除**（deleted_at，SCHEMA_CHANGE_PROPOSAL-001 APPROVED）；item_records FK RESTRICT；已删玩物对外 404、数据物理保留 |
| A17 | 种子品类固定 UUID（见 DATABASE_SCHEMA） |
| A18 | 采纳 UNIQUE(record_id, sort_order) |
| B1 | 仓库布局最终裁定：统一 `apps/<端>`——`apps/ios` + `apps/api`；iOS 由根级 `ios/` 迁回 `apps/ios/`，BE 保持 `apps/api/` |
| B2 | iOS 目标形态：仅 iPhone（TARGETED_DEVICE_FAMILY=1）、锁定竖屏、最低 iOS 17.0 | 采纳 iOS 提议；锁竖屏支撑 20 秒/10 秒体验 |
| B3 | Bundle ID 开发期占位 `com.panji.app`，正式发布前由总控定稿 | M1 不阻塞 |
| B4 | 品类选择并入创建页（5 芯片，不单独成页） | 品类固定 5 个，少一次跳转，支撑 ≤3 步/20 秒 |
| B5 | 昵称页不提供"跳过" | 与契约"强制引导设置"一致，避免空昵称状态 |
| B6 | M1 无 TabBar，收藏柜即主页 | 单模块最简；M2 加社区时再引入 |
| B7 | 时间轴照片点击全屏预览 | 相册日记固有展示行为，非新功能；M1-009 实现 |
| B8 | 收藏柜提供 DEBUG-only「开发：切换账号」入口（Release 不出现） | 仅供 QA 用户隔离冒烟（B18）切号用 |
| B9 | BE 预置的 M1-001~M1-005 代码不删除，但各任务仍逐一 REVIEW 对照契约，不符即退回 | 重申红线：不得提前实现未派发任务 |
| B10 | 包管理器接受 npm（package-lock.json）；pnpm 非契约要求 | 团队统一包管理器时再迁移 |
| B11 | iOS 构建验证环境：优先方案 A（真实 Mac 按 M0-003 runbook 执行）；Mac 到位前可选方案 B（GitHub macOS runner 编译验证）作过渡；M1-012 真机验收必然需要真实 Mac。静态校验不构成构建证据，验收标准不降。 | 环境能力阻塞与代码缺陷阻塞分开记账 |
| B12 | 数据库开发环境标准：**本机 PostgreSQL 16 路线**（BE 的 `scripts/dev-db.mjs` 或本机已装 PG）；`infra/` compose 文件保留为备选，其 Docker 实跑属环境能力豁免（团队无任何 Docker 机器），记入已知缺口 | 环境能力适配；真实 PG16 验证标准不变（启动/连接/重启持久化仍须实测） |
| B13 | iOS 构建验证：团队无自有 Mac → **默认云端 macOS CI**（GitHub Actions macOS runner 或 Codemagic，选型待用户确认 Git 账号渠道）；真机验收（M1-012）实施方案延后至 M1 开发后期决策，不在 M0 阻塞 | 云 CI 无需自有硬件，是无 Mac 前提下的唯一可行路径 |

完整理由见 `docs/API_CONTRACT.md` §5。

## 5. 禁止引入（技术红线）

微服务、Redis、Elasticsearch、消息队列、Kubernetes、AI 服务、GraphQL——除非经明确架构评审批准。

## 6. 环境约定

| 变量 | 说明 |
|---|---|
| DATABASE_URL | `postgresql://panji:panji_dev@localhost:5432/panji`（infra/README） |
| JWT_SECRET | HS256 密钥（本地 dev 值即可） |
| PORT | 默认 3000 |
| UPLOAD_DIR | 默认 `./uploads` |

## 7. 验证与状态规范

- 完成声明必须附证据（运行命令、测试/构建结果、验收条件逐条结果）——AGENTS §6。
- 状态词表与流转见 AGENTS §5；任务编号 `M0-xxx`/`M1-xxx`。
- 集成闸门：M0-006（M0 集成验收）→ 总控放行 M1 → M1-012（真机 20 步主链验收）→ 通过才可进入 M2。
