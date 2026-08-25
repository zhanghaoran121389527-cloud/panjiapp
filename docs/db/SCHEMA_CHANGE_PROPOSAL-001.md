# SCHEMA_CHANGE_PROPOSAL-001：items 逻辑删除（替代裁决 A16 硬删除）

- 提议人：DBI（数据库/基础设施）
- 类型：SCHEMA_CHANGE_PROPOSAL（含 API 语义联动，需总控批准后同步 API_CONTRACT / TASKS）
- 状态：**APPROVED**（总控批准 2026-08-19；裁决记录见文末 §7）
- 依据：总控最新指令——"玩物删除当前采用逻辑删除；不要未经确认直接 cascade 物理删除用户多年记录；公共删除策略必须写进 docs/DATABASE_SCHEMA.md"

## 1. 背景与冲突

现行 API_CONTRACT v2.2 裁决 A16：items 删除 = 硬删除，DB 层 FK CASCADE 连带删 item_records / record_images。该口径与总控最新指令（逻辑删除）冲突。本建议已按指令先行落进 `docs/DATABASE_SCHEMA.md` v2（DBI 起草、总控指令背书），本文件供总控正式批准并同步其他公共文档。

## 2. 变更内容

### 2.1 Schema（已写入 DATABASE_SCHEMA v2）

| # | 变更 | 原 | 新 |
|---|---|---|---|
| 1 | items 新增 `deleted_at timestamptz NULL` | 无 | NULL=在用；非 NULL=已删除（UTC） |
| 2 | item_records.item_id FK 动作 | ON DELETE CASCADE | ON DELETE **RESTRICT**（防物理误删多年记录） |
| 3 | items 查询规则 | 无过滤 | 全部接口过滤 `deleted_at IS NULL` |

不变：record_images.record_id 仍 ON DELETE CASCADE（记录删除级联，M1 无记录删除接口，防御性）；users/categories 两端 FK 仍 RESTRICT；索引不动（idx_items_user_id 继续有效，不加部分索引）。

### 2.2 API 语义（需总控批准后更新 API_CONTRACT）

- 3.9 DELETE /v1/items/:id：响应仍 204；实现从物理 DELETE 改为 `UPDATE items SET deleted_at=now()`（校验归属、幂等：已删除再删仍 204）。
- 3.5 / 3.7 / 3.8 / 3.11 / 3.12：查询一律过滤已删除玩物；已删除玩物及其记录对外表现为不存在（404），数据保留可恢复。
- 裁决 A16 改写为逻辑删除口径；§2 items 增补 deleted_at 行；§2 item_records "删除 item 时级联删除" 改为"删除 item 时记录保留（逻辑删除）"。

## 3. 影响面（供总控同步）

| 文档/模块 | 需变更 |
|---|---|
| docs/API_CONTRACT.md | §2 items/item_records 说明、§3.9 规则、裁决 A16（总控执行） |
| docs/TASKS.md | M1-001 验收③ 措辞（级联仅剩 record_images）；M1-003 验收⑤ 改为逻辑删除语义；M1-005 输入无变化（总控执行） |
| docs/qa/验收清单.md（M0-005 修订中） | B08 删除口径：删除后收藏柜消失、时间轴数据物理保留但不可见 |
| apps/api（BE 在 M1-001/M1-003 实施，DBI 不代改） | 见 §4 |

## 4. 后端实施清单（BE 执行，M1-001 未开始，随首版迁移一次落地）

1. `item.entity.ts`：加 `deletedAt` 列（`@Column({ type:'timestamptz', nullable:true })`）；migration 中 `deleted_at timestamptz`。
2. `item-record.entity.ts`（现为 `onDelete:'CASCADE'`）：改 `onDelete:'RESTRICT'`。
3. `items.service.ts` remove()（现为 `items.remove(item)` 物理删）：改 UPDATE deleted_at；findOne/列表/详情/编辑/记录入口统一加 `deleted_at IS NULL`。
4. 幂等：重复 DELETE 仍 204；PATCH/记录写入对已删除 item 返回 404。

## 5. 验证计划（M1-001 实施后执行）

1. 正向 migration：6 表结构含 deleted_at、FK RESTRICT 生效（\d item_records 查看 FK 动作）。
2. 非法关系被阻止：物理 `DELETE FROM items`（有记录时）被 RESTRICT 拒绝。
3. 逻辑删除闭环：删 item → 列表/详情 404、记录接口 404；DB 中 item_records/record_images 行数不变。
4. 回滚：`pnpm migration:revert`（倒序 drop）；未执行前可直接重置空库。

## 6. 数据风险

- 逻辑删除后 records 数据保留但不可达：M1 无恢复/导出接口，属预期（后续如需"恢复/彻底清除"须另提 PRODUCT_CHANGE_PROPOSAL）。
- 已删除玩物的封面上传文件不回收（与 A15 一致）。

## 7. 总控裁决记录（APPROVED）

- 批准日期：2026-08-19。最终删除语义以本提案 §2 为准，并作两处最终裁定：
  1. **重复删除/删除已逻辑删除的玩物 → 404 NOT_FOUND**（替代提案 §2.2 的"重复删除仍 204"）：与"已删除=对外不存在"的全接口口径一致，实现上 WHERE 命中失败即 404，无额外状态。
  2. 所有 items 查询（3.5 列表 / 3.7 详情 / 3.8 编辑 / 3.11·3.12 记录入口）必须显式过滤 `deleted_at IS NULL`；已删除玩物及其记录对外一律 404，数据物理保留。
- 同步动作（总控执行完毕）：API_CONTRACT → v2.3（§3.9/A16/§2 items·item_records/§3.10/业务规则 10）；TASKS → M1-001 验收③、M1-003 全量重写为逻辑删除任务、新增 M0-007（lint 修复）；QA 验收清单 → v2.1（B17/E06/§5.1/§5.2/§6）；ARCHITECTURE A16。
- 过程注记：DATABASE_SCHEMA v2 与 BE 首版迁移先于本次正式批准落地（提案流程之外的先行动作），本次批准视为追认；**此后任何公共 schema/API 变更必须先批准后实施**。
