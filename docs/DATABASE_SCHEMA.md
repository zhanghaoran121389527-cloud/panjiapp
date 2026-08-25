# 盘迹 数据库公共规格（DATABASE_SCHEMA）

- 文档编号：DATABASE_SCHEMA（数据库层唯一权威）
- 版本：v2（删除策略裁决变更：items 改逻辑删除）
- 维护人：总控（批准）；起草：DBI（源自其 DB-001 交付，经总控审核采纳并提升为本文件）；实施：BE（TypeORM entity + migration）
- 依据：`docs/API_CONTRACT.md` v2.2（接口视角字段语义）；两者不得偏离
- 变更控制：任何表/字段/约束/ID 策略变更必须先提交 `SCHEMA_CHANGE_PROPOSAL`，经总控批准并更新本文档

## 0. 通用约定（全部 6 张表一致）

| 项 | 约定 |
|---|---|
| ID | `uuid` 主键，uuid v4，**应用侧生成**（不用数据库 default、不依赖 uuid-ossp） |
| 时间戳 | `timestamptz`，UTC 存储；API 输出 ISO 8601 UTC（createdAt / updatedAt） |
| 日期 | `date` 类型，仅存日历日期；按北京时间（Asia/Shanghai）解释，API 传输 `YYYY-MM-DD` 字符串 |
| 命名 | 数据库 snake_case；API camelCase |
| 空值 | 可选字段一律 `null`，不用空字符串 |
| 建表 | 不由 `infra/` 环境执行；BE TypeORM migration 落库（裁决 A1） |
| 删除策略 | items 逻辑删除（`deleted_at`，v2）；其余 5 表 M1 无删除接口、物理行保留 |

> 时区红线：`date` 列不做任何数据库层日期 CHECK（`CURRENT_DATE` 是 UTC 日期，与北京"今天"最多差一天，会误拒合法数据）。日期合法性由 API 层用北京时间校验。
>
> 用户本地显示：时间戳由客户端按设备本地时区渲染；`date` 字段仅展示 `YYYY-MM-DD` 字面值；数据库不做本地化。

## 1. users

| 字段 | 类型 | Nullable | 默认值 | 说明 |
|---|---|---|---|---|
| id | uuid | NO | — | PK，应用侧生成 |
| nickname | text | YES | NULL | 设置时 1~20 字（CHECK） |
| created_at | timestamptz | NO | now() | |
| updated_at | timestamptz | NO | now() | 应用层随更新维护 |

- 用途：用户主体；M1 仅昵称，手机号只作为 dev 身份标识存 auth_identities。
- FK：无；Unique：无；Index：无（仅 PK）
- 删除策略：无删除接口（逻辑删除不适用）；物理删除被 items.user_id 的 RESTRICT 挡住。

## 2. auth_identities

| 字段 | 类型 | Nullable | 默认值 | 说明 |
|---|---|---|---|---|
| id | uuid | NO | — | PK |
| user_id | uuid | NO | — | FK → users.id |
| provider | text | NO | — | M1 恒为 `'dev'` |
| identifier | text | NO | — | Dev Login 输入的手机号 |
| created_at | timestamptz | NO | now() | |

- 用途：登录身份；dev-login 按 provider+identifier 定位用户。
- FK：`user_id` → users(id) ON DELETE CASCADE（身份依附用户，防御性）
- Unique：`(provider, identifier)`——同一身份只对应一个用户，同时覆盖 dev-login 查询路径
- 删除策略：无删除接口；仅随 user 物理删除级联（防御性，M1 不会发生）。

## 3. categories（种子，M1 无品类管理）

| 字段 | 类型 | Nullable | 默认值 | 说明 |
|---|---|---|---|---|
| id | uuid | NO | — | PK，种子用固定 UUID |
| name | text | NO | — | 唯一 |
| sort_order | integer | NO | — | 1~5 |

- 用途：品类字典；固定 5 条种子，M1 无品类管理。
- Unique：`name`；被 items.category_id RESTRICT 保护。
- 删除策略：种子数据无删除接口（逻辑删除不适用）；物理删除被 items.category_id RESTRICT 拒绝。

### 3.1 种子数据（固定 UUID，幂等）

| id | name | sort_order |
|---|---|---|
| `a1b2c3d4-0001-4000-8000-000000000001` | 核桃 | 1 |
| `a1b2c3d4-0002-4000-8000-000000000002` | 菩提 | 2 |
| `a1b2c3d4-0003-4000-8000-000000000003` | 木质 | 3 |
| `a1b2c3d4-0004-4000-8000-000000000004` | 玉石 | 4 |
| `a1b2c3d4-0005-4000-8000-000000000005` | 其他 | 5 |

BE 种子迁移：`INSERT ... ON CONFLICT (id) DO NOTHING`。

## 4. items

| 字段 | 类型 | Nullable | 默认值 | 说明 |
|---|---|---|---|---|
| id | uuid | NO | — | PK |
| user_id | uuid | NO | — | FK → users.id，隔离键 |
| category_id | uuid | NO | — | FK → categories.id |
| name | text | NO | — | 1~50 字（CHECK） |
| cover_image_url | text | YES | NULL | 封面，相对 URL |
| subcategory | text | YES | NULL | 子类，自由文本 |
| size_spec | text | YES | NULL | 尺寸/规格，自由文本 |
| acquired_date | date | YES | NULL | 入手日期 |
| notes | text | YES | NULL | 备注 |
| deleted_at | timestamptz | YES | NULL | 逻辑删除时间（UTC）；NULL=在用，非 NULL=已删除 |
| created_at | timestamptz | NO | now() | |
| updated_at | timestamptz | NO | now() | 应用层随编辑更新 |

- 用途：玩物；一切查询按 user_id 隔离。
- FK：`user_id` → users(id) ON DELETE RESTRICT；`category_id` → categories(id) ON DELETE RESTRICT
- Index：`idx_items_user_id ON items (user_id)`
- 删除策略（v2 逻辑删除，替代 A16 硬删除）：DELETE 接口 = `UPDATE items SET deleted_at = now() WHERE id=? AND user_id=? AND deleted_at IS NULL`（响应 204，需校验归属）；物理行与 item_records / record_images 全部保留。所有 items 查询（3.5 列表 / 3.7 详情 / 3.8 编辑 / 3.11·3.12 记录入口）一律过滤 `deleted_at IS NULL`；已删除玩物对外视为不存在（404），其记录不可达但数据保留可恢复。M1 无恢复接口。

## 5. item_records

| 字段 | 类型 | Nullable | 默认值 | 说明 |
|---|---|---|---|---|
| id | uuid | NO | — | PK |
| item_id | uuid | NO | — | FK → items.id |
| content | text | NO | — | "一句话"，1~500 字（CHECK） |
| duration_minutes | integer | YES | NULL | 1~1440（CHECK） |
| method | text | YES | NULL | ≤20 字（CHECK） |
| recorded_date | date | NO | — | 默认当天；过去日期=补录 |
| created_at | timestamptz | NO | now() | 无 updated_at：M1 记录不可编辑 |

- 用途：盘玩记录（一句话 + 多图 + 时长/方式/日期）。
- FK：`item_id` → items(id) ON DELETE RESTRICT（v2：防物理误删多年记录；正常删除走 items 逻辑删除，本表物理保留）
- Index：`idx_item_records_item_id ON item_records (item_id)`
- 删除策略：无删除接口；随 item 逻辑删除对外不可见、物理保留。
- 归属校验经 `item_id → items.user_id` 间接完成；不建 (recorded_date, created_at) 复合索引（不过早优化）。

## 6. record_images

| 字段 | 类型 | Nullable | 默认值 | 说明 |
|---|---|---|---|---|
| id | uuid | NO | — | PK |
| record_id | uuid | NO | — | FK → item_records.id |
| image_url | text | NO | — | 相对 URL |
| sort_order | integer | NO | — | 0 起，按客户端提交顺序（CHECK ≥0） |
| created_at | timestamptz | NO | now() | |

- 用途：记录的 0~N 张照片；对外统一 photoUrls 数组，本表不直接出 API。
- FK：`record_id` → item_records(id) ON DELETE CASCADE
- Unique：`(record_id, sort_order)`（裁决 A18），同时覆盖 record_id 前缀查询
- 删除策略：无删除接口；item 逻辑删除后随 record 一并物理保留。

## 7. 参考 DDL（供 BE 对照，非执行文件）

```sql
-- 删除策略：items 逻辑删除（deleted_at）；item_records.item_id FK RESTRICT 防物理误删
CREATE TABLE users (
    id         uuid PRIMARY KEY,
    nickname   text CHECK (nickname IS NULL OR (char_length(nickname) BETWEEN 1 AND 20)),
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE auth_identities (
    id         uuid PRIMARY KEY,
    user_id    uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    provider   text NOT NULL,
    identifier text NOT NULL,
    created_at timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT uq_auth_identities_provider_identifier UNIQUE (provider, identifier)
);

CREATE TABLE categories (
    id         uuid PRIMARY KEY,
    name       text NOT NULL UNIQUE,
    sort_order integer NOT NULL
);

CREATE TABLE items (
    id              uuid PRIMARY KEY,
    user_id         uuid NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
    category_id     uuid NOT NULL REFERENCES categories(id) ON DELETE RESTRICT,
    name            text NOT NULL CHECK (char_length(name) BETWEEN 1 AND 50),
    cover_image_url text,
    subcategory     text,
    size_spec       text,
    acquired_date   date,
    notes           text,
    deleted_at      timestamptz,
    created_at      timestamptz NOT NULL DEFAULT now(),
    updated_at      timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX idx_items_user_id ON items (user_id);

CREATE TABLE item_records (
    id               uuid PRIMARY KEY,
    item_id          uuid NOT NULL REFERENCES items(id) ON DELETE RESTRICT,
    content          text NOT NULL CHECK (char_length(content) BETWEEN 1 AND 500),
    duration_minutes integer CHECK (duration_minutes IS NULL OR duration_minutes BETWEEN 1 AND 1440),
    method           text CHECK (method IS NULL OR (char_length(method) BETWEEN 1 AND 20)),
    recorded_date    date NOT NULL,
    created_at       timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX idx_item_records_item_id ON item_records (item_id);

CREATE TABLE record_images (
    id         uuid PRIMARY KEY,
    record_id  uuid NOT NULL REFERENCES item_records(id) ON DELETE CASCADE,
    image_url  text NOT NULL,
    sort_order integer NOT NULL CHECK (sort_order >= 0),
    created_at timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT uq_record_images_record_sort UNIQUE (record_id, sort_order)
);

INSERT INTO categories (id, name, sort_order) VALUES
  ('a1b2c3d4-0001-4000-8000-000000000001', '核桃', 1),
  ('a1b2c3d4-0002-4000-8000-000000000002', '菩提', 2),
  ('a1b2c3d4-0003-4000-8000-000000000003', '木质', 3),
  ('a1b2c3d4-0004-4000-8000-000000000004', '玉石', 4),
  ('a1b2c3d4-0005-4000-8000-000000000005', '其他', 5)
ON CONFLICT (id) DO NOTHING;
```

CHECK 全部来自契约 v2 明确取值（裁决 A12）；API 是第一道校验，DB 是第二道防线（BE 实体加 `@Check`）。

## 8. 迁移拆分（BE 执行）

| # | 迁移 | 内容 | 回滚 |
|---|---|---|---|
| 1 | CreateTables | 建 6 表（含 items.deleted_at）+ 2 索引 + 唯一约束 + CHECK | drop 表（倒序） |
| 2 | SeedCategories | 5 条品类（固定 UUID，ON CONFLICT 幂等） | `DELETE FROM categories WHERE id IN (5 个固定 UUID)` |

运行/回滚：`npm run migration:run` / `npm run migration:revert`（apps/api 内配置；裁决 B10 统一 npm）。

> M1-001 已实施完毕并经 QA 独立库验证通过（2026-08-19）：v2 变更随首版迁移一次落地，无增量迁移。

## 9. TypeORM 实施要点（给 BE）

1. uuid v4 应用侧生成：`@PrimaryColumn('uuid')` + `crypto.randomUUID()`，**不用** `@PrimaryGeneratedColumn('uuid')`（依赖 uuid-ossp）。
2. `date` 列映射为 string（`YYYY-MM-DD`），避免 JS Date 时区漂移；timestamptz 用 Date/ISO 8601 UTC。
3. 级联删除必须落在 DB 层（FK ON DELETE CASCADE 写入 migration），不能只写实体级 cascade。
4. `updated_at` 用 `@UpdateDateColumn` 维护；item_records 无 updated_at。
5. 连接参数建议 `timezone: 'UTC'`。
6. dayCount：北京"今天"由应用层计算后注入查询，禁用 DB `CURRENT_DATE`。
7. items 逻辑删除：`deleted_at` 为显式列；DELETE 接口改 `UPDATE deleted_at = now()`；所有查询显式 `AND deleted_at IS NULL`（勿依赖 ORM 隐式软删，防漏）。

## 10. 一致性核对（全链）

| 链 | 保护 |
|---|---|
| users → items | user_id NOT NULL + FK RESTRICT + idx_items_user_id |
| items → item_records | item_id NOT NULL + FK RESTRICT（防物理误删；删除走 items.deleted_at 逻辑删除）+ idx_item_records_item_id |
| item_records → record_images | record_id NOT NULL + FK CASCADE + UNIQUE(record_id, sort_order) |
| 记录归属 | record 经 item 间接校验归属；record_images 经 record 间接，无直连 user 字段 |
| users → auth_identities | user_id NOT NULL + FK CASCADE + UNIQUE(provider, identifier) |

## 11. 变更记录

| 版本 | 变更 |
|---|---|
| v1 | 自 DBI 交付 DB-001 提升为正式公共规格并经总控批准：6 表 + 种子固定 UUID + 参考 DDL + 迁移拆分 + TypeORM 要点；明确硬删除口径（裁决 A16） |
| v2 | 删除策略裁决变更（总控指令）：items 由硬删除（A16）改为逻辑删除（+deleted_at）；item_records.item_id FK 由 CASCADE 改 RESTRICT；明确已删除玩物 404、记录保留不可达；同步提交 SCHEMA_CHANGE_PROPOSAL-001，API_CONTRACT §3.9/A16 与 TASKS 验收项待总控同步 |
