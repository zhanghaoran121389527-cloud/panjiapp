# 盘迹 API 契约（API_CONTRACT）

- 文档编号：API_CONTRACT（唯一事实来源）
- 版本：v2.3（对齐项目总规则；v2.3=逻辑删除口径 + uploads 鉴权/heif 补录）
- 维护人：总控（Lead）
- 变更规则：**任何 Agent 不得自行改变本契约**。变更必须由总控批准并更新本文件；跨模块交接以本文件为准。

---

## 0. 适用范围

M0 + M1 全部接口。M1 只服务主链：Dev Login → 设置昵称 → 收藏柜 → 创建/编辑玩物 → 记录盘玩（含补录）→ 成长时间轴 → 数据持久化。

## 1. 命名与通用约定

| 项 | 约定 |
|---|---|
| API 前缀 | 业务接口 `https://<host>/v1/...`；静态图片 `https://<host>/uploads/...` |
| JSON 字段 | camelCase（`coverImageUrl`、`photoUrls`、`dayCount`、`recordedDate`） |
| 数据库字段 | snake_case（`cover_image_url`、`recorded_date`） |
| 主键 | uuid v4，应用侧生成 |
| 日期 | `YYYY-MM-DD`；**一律按北京时间（Asia/Shanghai）解释**，不传时区 |
| 时间戳 | ISO 8601 UTC（`createdAt` / `updatedAt`） |
| 认证 | `Authorization: Bearer <token>`；JWT HS256，payload `{ sub: userId }`，有效期 365 天（M1 不过期，保证重启 App 仍登录） |
| 错误格式 | 统一 `{ "code": "STRING_CODE", "message": "人类可读描述" }` + 合理 HTTP 状态码 |
| 错误码 | `AUTH_REQUIRED`、`VALIDATION_ERROR`、`NOT_FOUND`、`UPLOAD_TOO_LARGE`、`UNSUPPORTED_TYPE`、`INTERNAL` |
| 空值 | 可选字段一律 `null`，不用空字符串 |

## 2. 数据模型（M1 共 6 张表，增表/重大字段变更须总控批准）

> 数据库层权威规格（约束、索引、级联、种子 UUID、参考 DDL、TypeORM 映射要点）见 `docs/DATABASE_SCHEMA.md`；本节为接口视角的字段语义。两者不得偏离。

### users
| 字段 | 类型 | 约束 | 说明 |
|---|---|---|---|
| id | uuid | PK | |
| nickname | text | nullable | 注册后为空，强制引导设置（1~20 字） |
| created_at / updated_at | timestamptz | not null | |

手机号不存 users，只作为 dev 身份标识存在 auth_identities。

### auth_identities
| 字段 | 类型 | 约束 | 说明 |
|---|---|---|---|
| id | uuid | PK | |
| user_id | uuid | FK → users.id | |
| provider | text | not null | M1 恒为 `'dev'` |
| identifier | text | not null | Dev Login 输入的手机号 |
| created_at | timestamptz | not null | |
| 唯一约束 | (provider, identifier) | | |

### categories（种子，M1 不提供品类管理）
| 字段 | 类型 | 约束 | 说明 |
|---|---|---|---|
| id | uuid | PK | |
| name | text | not null, unique | |
| sort_order | int | not null | |

种子固定 5 个：`核桃(1)、菩提(2)、木质(3)、玉石(4)、其他(5)`

### items
| 字段 | 类型 | 约束 | 说明 |
|---|---|---|---|
| id | uuid | PK | |
| user_id | uuid | FK → users.id | **一切查询按 user_id 隔离** |
| category_id | uuid | FK → categories.id | |
| name | text | not null | 1~50 字 |
| cover_image_url | text | nullable | 封面，允许跳过 |
| subcategory | text | nullable | 子类，自由文本，无字典，≤50 字 |
| size_spec | text | nullable | 尺寸/规格，自由文本，≤100 字 |
| acquired_date | date | nullable | 入手日期 |
| notes | text | nullable | 备注，≤500 字 |
| created_at / updated_at | timestamptz | not null | |
| deleted_at | timestamptz | nullable | 逻辑删除时间（UTC）；**不出现在任何 API 响应**；NULL=在用 |

> 删除语义（SCHEMA_CHANGE_PROPOSAL-001 已批准）：DELETE 为逻辑删除（见 3.9）；所有接口对已删除玩物一律视为不存在（404），数据物理保留。

### item_records
| 字段 | 类型 | 约束 | 说明 |
|---|---|---|---|
| id | uuid | PK | |
| item_id | uuid | FK → items.id | FK RESTRICT；**item 逻辑删除时本表物理保留** |
| content | text | not null | "一句话"，1~500 字 |
| duration_minutes | int | nullable | 盘玩时长（分钟），1~1440 |
| method | text | nullable | 盘玩方式，自由文本，≤20 字 |
| recorded_date | date | not null | 默认当天；**传过去日期即补录** |
| created_at | timestamptz | not null | |

### record_images
| 字段 | 类型 | 约束 | 说明 |
|---|---|---|---|
| id | uuid | PK | |
| record_id | uuid | FK → item_records.id | **删除 record 时级联删除** |
| image_url | text | not null | 上传接口返回的相对 URL |
| sort_order | int | not null | 0 起，按客户端提交顺序 |
| created_at | timestamptz | not null | |

记录照片不冗余存在 item_records 上；对外统一以 `photoUrls` 数组（按 sort_order）暴露，record_images 不直接出 API。

## 3. API 契约（M1 全量）

### 3.1 POST /v1/auth/dev-login
请求：`{ "phone": "13800138000" }`（11 位数字）
响应 200：`{ "token": "<jwt>", "user": { "id": "...", "nickname": null }, "isNewUser": true }`
规则：按 `provider='dev' + identifier=phone` 查 auth_identities；不存在则创建 user + identity，`isNewUser=true`；存在则返回原 user。**M1 无任何短信验证。**

### 3.2 GET /v1/me
响应 200：`{ "user": { "id": "...", "nickname": "..." } }`（启动恢复登录态用；401 → 回登录页）

### 3.3 PATCH /v1/me
请求：`{ "nickname": "盘友小王" }`
响应 200：`{ "user": { ... } }`

### 3.4 GET /v1/categories
响应 200：`{ "categories": [ { "id": "...", "name": "核桃" }, ... ] }`（按 sort_order）

### 3.5 GET /v1/items
响应 200：
```json
{ "items": [ { "id": "...", "name": "四座楼狮子头", "coverImageUrl": null,
    "categoryId": "...", "dayCount": 0, "createdAt": "..." } ] }
```
规则：仅当前用户数据；按 createdAt 倒序；客户端按 categoryId 分组。

### 3.6 POST /v1/items
请求（`name`、`categoryId` 必填，其余选填）：
```json
{ "name": "四座楼狮子头", "categoryId": "<uuid>", "coverImageUrl": null,
  "subcategory": null, "acquiredDate": null, "sizeSpec": null, "notes": null }
```
响应 201：`{ "item": { 完整 item 对象 } }`
规则：封面 = 先调 3.10 上传拿 url 再创建；跳过则传 null。

### 3.7 GET /v1/items/:id
响应 200：`{ "item": { id, name, coverImageUrl, categoryId, subcategory, sizeSpec, acquiredDate, notes, dayCount, createdAt, updatedAt } }`
规则：**不含 records**（时间轴用 3.12 单独拉取）；校验归属，他人 item 返回 404。

### 3.8 PATCH /v1/items/:id（编辑玩物）
请求：上述字段的**部分更新**（至少一个；可传 null 清空选填字段）
响应 200：`{ "item": { ... } }`
规则：校验归属，他人 item 返回 404。

### 3.9 DELETE /v1/items/:id（删除玩物，逻辑删除）
响应 204。规则：**逻辑删除**——`UPDATE items SET deleted_at = now() WHERE id = :id AND user_id = :userId AND deleted_at IS NULL`；命中 → 204；未命中（不存在 / 他人 / 已删除）→ 404 NOT_FOUND。
item_records 与 record_images **物理保留**；已删除玩物对所有正常接口视为不存在（3.5 / 3.7 / 3.8 / 3.11 / 3.12 一律 404）。M1 无恢复/回收站接口。
已知限制：已上传的物理文件 M1 不回收。

### 3.10 POST /v1/uploads
请求：multipart/form-data，字段名 `file`
响应 201：`{ "url": "/uploads/<uuid>.<ext>" }`
规则：**需登录（Bearer token）**；jpeg / png / heic / heif / webp；≤10MB；落本地磁盘 `uploads/`，uuid 重命名；`GET /uploads/*` 静态输出（公开可读）。
> 裁决：M1 图片存后端本地磁盘，接口只回相对 URL。将来换腾讯云 COS 时仅后端替换实现，**iOS 零改动**。

### 3.11 POST /v1/items/:itemId/records（当日记录 + 历史补录，同一接口）
请求：
```json
{ "photoUrls": [ "/uploads/a.jpg", "/uploads/b.jpg" ],
  "content": "盘了半小时", "durationMinutes": 30, "method": "手套盘",
  "recordedDate": "2025-01-03" }
```
- `photoUrls`：选填，0~N 张，先经 3.10 上传，落 record_images（sort_order=数组下标）
- `content`：必填；`durationMinutes` / `method` / `recordedDate`：选填；`recordedDate` 默认今天，过去日期=补录
- 校验：`recordedDate` 不得晚于北京时间今天，否则 `VALIDATION_ERROR`；客户端日期选择上限=今天
响应 201：`{ "record": { id, photoUrls, content, durationMinutes, method, recordedDate, createdAt } }`
规则：校验 item 归属，他人 item 返回 404。

### 3.12 GET /v1/items/:itemId/records
响应 200：`{ "records": [ { id, photoUrls, content, durationMinutes, method, recordedDate, createdAt }, ... ] }`
规则：按 recordedDate 倒序、同日期按 createdAt 倒序；校验归属。

## 4. 业务规则

1. **盘玩天数 dayCount**：服务端计算，客户端不算。
   有记录 → `今天 − min(recorded_date) 的天数 + 1`；无记录 → `0`。入手日期不参与。
2. **用户隔离**：items / item_records 的一切查询写入必须校验归属（record 经所属 item 间接校验），越权一律 404。
3. **补录**：与正常记录同一接口（3.11），recordedDate 为过去日期。
4. **编辑/删除玩物**在 M1 范围内（3.8 / 3.9），编辑复用创建字段；**删除=逻辑删除**（3.9），records/images 物理保留。
5. **补录与入手日期**：不校验 recordedDate 与 acquired_date 的先后，不提示（YAGNI）。
6. **"今天"的定义**：客户端生成默认日期、限制日期上限时，一律按北京时间（Asia/Shanghai）。
7. **防重复提交**：客户端保存必须防连点（一次表单仅允许一次提交）；服务端幂等 M1 不做。
8. **已知限制**：删除玩物/记录后已上传的物理文件不回收；上传成功但后续创建失败的孤儿文件不清理，M1 接受。
9. **M1 不做**：记录编辑/删除、社区、真实短信/微信/Apple 登录、品类管理、Android、Web 客户端。
10. **已删除玩物**：对外一律 404（含其记录接口），数据物理保留；M1 无恢复接口（SCHEMA_CHANGE_PROPOSAL-001）。

## 5. 架构裁决记录（总控）

| # | 裁决 | 理由 |
|---|---|---|
| A1 | NestJS + TypeORM，实体即 schema 事实来源，TypeORM migration 落库 | 后端与 DBA 不出现两套 schema |
| A2 | record_images 启用：记录支持 0~N 张照片，对外为 `photoUrls` 数组 | 项目总规则明确该表在 M1 数据模型内；多选照片不增加操作步骤 |
| A3 | 图片走本地磁盘 + 相对 URL（3.10） | 换 COS 时 iOS 零改动 |
| A4 | Dev Login 用 phone 作 dev 身份标识，不发短信 | M1 禁止真实短信 |
| A5 | 子类、盘玩方式为自由文本 | 不做字典表，减少表单与后台 |
| A6 | 玩物编辑/删除纳入 M1（PATCH/DELETE items） | 项目总规则列为主要接口 |
| A7 | JWT 365 天 + iOS UserDefaults | 满足"重启 App 数据仍在"，最简实现 |
| A8 | 所有日期按北京时间 | 避免补录日期漂移 |
| A9 | API 前缀 `/v1/` | 对齐项目总规则的接口清单 |
| A10 | recordedDate 不得晚于北京时间今天（服务端校验） | 防止 dayCount 为负；客户端日期上限=今天 |
| A11 | 补录不校验与入手日期先后，不提示 | 少操作；入手日期不参与计算 |
| A12 | 文本上限：name 1~50、content 1~500、nickname 1~20、notes ≤500、size_spec ≤100、subcategory ≤50、method ≤20 | 统一校验口径，避免 UI 破版 |
| A13 | 客户端"今天"按北京时间生成 | 防时区导致补录错一天 |
| A14 | 客户端必须防重复提交；服务端幂等 M1 不做 | 最简实现 |
| A15 | 删除后物理文件/孤儿文件 M1 不回收 | 记录为已知限制 |
| A16 | items 删除=**逻辑删除**（deleted_at；SCHEMA_CHANGE_PROPOSAL-001 批准，替代 v2.2 硬删除口径）；records/images 物理保留，已删玩物对外 404，M1 无恢复 | 保护用户多年盘玩记录、误删可恢复；成本=一列+查询过滤 |
| A17 | 种子品类固定 UUID（见 DATABASE_SCHEMA §3.1） | 幂等、各环境一致 |
| A18 | 采纳 UNIQUE(record_id, sort_order) | 同记录内顺序位唯一 |

## 6. 变更记录

| 版本 | 变更 |
|---|---|
| v1 | 初始（前缀 /api/v1、无 record_images、无编辑删除） |
| v2 | 对齐总规则：前缀 /v1/；恢复并启用 record_images（photoUrls 多图）；新增 PATCH/DELETE items、GET records；拆分 records 出 item 详情 |
| v2.1 | QA 待裁决 E1~E7 拍板：删除在范围、recordedDate≤今天、文本上限、客户端北京时间、防重、孤儿文件接受（新增裁决 A10~A15、业务规则 5~8） |
| v2.2 | 数据库层规格拆分至 docs/DATABASE_SCHEMA.md（采纳 DBI 的 DB-001）；裁决 A16~A18；仓库布局定稿 apps/<端>；任务编号迁移 Mx-xxx |
| v2.3 | SCHEMA_CHANGE_PROPOSAL-001 APPROVED：§3.9 改逻辑删除、A16 改写、§2 items 增 deleted_at、item_records FK RESTRICT 说明、业务规则 10；§3.10 补录"需登录"与 heif 白名单 |
