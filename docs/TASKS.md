# 盘迹 任务看板（TASKS）

- 维护人：总控（Lead）
- 状态词表（唯一）：`BACKLOG` / `READY` / `IN_PROGRESS` / `REVIEW` / `BLOCKED` / `DONE`；`BLOCKED` 必须注明阻塞类型：代码缺陷 / 环境能力 / 契约 / 其他，不得混标
- 事实来源：根 `/AGENTS.md`、`docs/PRODUCT_SPEC.md`、`docs/ARCHITECTURE.md`、`docs/API_CONTRACT.md`、`docs/DATABASE_SCHEMA.md`、`docs/DESIGN_SYSTEM.md`、`docs/handoffs/`
- 红线：只做 M0+M1；新增表/字段/接口须先提交 `*_CHANGE_PROPOSAL` 经总控批准；禁止引入微服务/Redis/ES/消息队列/K8s/AI/GraphQL
- 编号迁移：旧 T-xxx → 新 Mx-xxx（见变更记录）

## 任务总览

| 编号 | 任务 | 负责人 | 前置依赖 | 状态 |
|---|---|---|---|---|
| M0-001 | 本地 PostgreSQL 环境 | DBI | — | DONE |
| M0-002 | NestJS 工程底座 | BE | M0-001 | DONE |
| M0-003 | SwiftUI 工程底座 | iOS | — | DONE |
| M0-004 | M1 UI 开发规格（设计系统+线框） | UI | — | DONE |
| M0-005 | M1 验收清单与测试计划 | QA | — | DONE |
| M0-006 | M0 集成验收 | QA | M0-001~M0-005, M0-006A | DONE |
| M0-006A | macOS/Xcode 构建环境准备 | DBI | — | DONE |
| M0-007 | Backend lint 配置修复 | BE | — | DONE |
| M1-001 | 数据模型实体+迁移+种子（6 表） | BE | M0-002 | DONE |
| M1-002 | Dev Login + 昵称 API | BE | M1-001 | DONE |
| M1-003 | 分类 + 玩物 CRUD（含逻辑删除） | BE | M1-001 | DONE |
| M1-004 | 图片上传 + 静态托管 | BE | M0-002 | DONE |
| M1-005 | 盘玩记录接口 POST/GET（多图+补录） | BE | M1-001, M1-004 | DONE |
| M1-006 | 网络层 + 登录/昵称流程 | iOS | M0-003, M0-004, M1-002 | DONE |
| M1-007 | 收藏柜 | iOS | M1-003, M1-006 | DONE |
| M1-008 | 创建玩物（创建后自动进详情） | iOS | M1-003, M1-004, M1-006, M1-007 | DONE |
| M1-009 | 玩物详情 + 成长时间轴 | iOS | M1-003, M1-005, M1-006, M1-007 | DONE |
| M1-010 | 盘玩记录（多图 + 补录） | iOS | M1-004, M1-005, M1-006, M1-009 | REVIEW |
| M1-011 | 编辑/删除玩物 | iOS | M1-003, M1-004, M1-006, M1-008, M1-009 | BACKLOG |
| M1-012 | M1 主链真机验收（20 步） | QA | M1-001~M1-011, M0-006 | BACKLOG |

---

### M0-001【DBI】本地 PostgreSQL 环境
- 【任务编号】M0-001
- 【任务名称】本地 PostgreSQL 环境
- 【负责人】DBI
- 【状态】DONE
- 【目标】一条命令启动本地 PostgreSQL 16 开发环境（named volume，重启不丢数据），提供连接串。
- 【前置依赖】无
- 【输入】API_CONTRACT（库名 panji）、DATABASE_SCHEMA §0（环境只建空库，不建表）
- 【输出】`infra/`：docker-compose.yml、.env.example、README（启动/连接串/持久化验证/重置）
- 【允许修改范围】`infra/**`
- 【禁止修改范围】不执行任何建表 SQL；不改 API_CONTRACT / DATABASE_SCHEMA；不动 apps/**
- 【验收条件】① 一条命令启动 ② 可连 panji 库（`postgresql://panji:panji_dev@localhost:5432/panji`）③ 服务停启后数据仍在。**B12 口径**：正式开发环境=本机 PostgreSQL 16（`scripts/dev-db.mjs` 或本机已装 PG）；`infra/` compose 文件保持备选，其 Docker 实跑属环境能力豁免（记已知缺口，有 Docker 机器时补验）
- 【QA要求】在装有 Docker 的机器按 infra/README 三条命令实跑并记录输出（已并入 M0-006）
- 【交接对象】BE（连接串）、QA
- 【审核记录】产出已提交（infra/ + handoff T-001；附带 DB-001 数据模型规格已被总控采纳提升为 docs/DATABASE_SCHEMA.md）。QA 复审（M0-001-QA.md）：FAIL-hold——静态核对 8 项全 PASS；实跑 ①②③ 因本机无 Docker 未执行，并入 M0-006；另须在 M0-006 前整改 infra/README 中过期的 CONTRACT-001/T-001 引用。通过后置 DONE。
- 【审核记录·B12】总控裁定（用户确认无任何 Docker 机器）：验收口径改按**本机 PG16 路线**复核（BE/QA 已在真实 PG16 上完成结构/幂等/RESTRICT 实测，证据链真实）；compose 文件静态合规即交付达标，Docker 实跑豁免并记入已知缺口。DBI 需把 infra/README 同步为 B12 口径（标准=本地 PG 路线，compose 备选）。
- 【审核记录·收尾】DBI 整改验收通过（总控实读 infra/README.md：首屏 B12 口径、本机路线 start/stop/验证三步、ASCII 路径注意、compose 降为备选并标注豁免；grep 旧引用 0 命中）。QA 本机真实 PG16 复核 ①②③ 全 PASS（启动 ready / 实连 PG16.14 / 停启后探测数据仍在）。→ **DONE**。遗留 BE 小项：dev-db.mjs 报错文案仍指向 docker compose（已并入 M1-002 附带修正项）。

### M0-002【BE】NestJS 工程底座
- 【任务编号】M0-002
- 【任务名称】NestJS 工程底座
- 【负责人】BE
- 【状态】DONE
- 【目标】可运行后端骨架：配置、统一错误、JWT 工具、健康检查。
- 【前置依赖】M0-001（连接串；脚手架可并行，联调验收需 M0-001 通过）
- 【输入】API_CONTRACT §1（错误格式、JWT、`/v1/` 前缀）、ARCHITECTURE §3/§6
- 【输出】`apps/api/`：NestJS + TypeScript（pnpm）；`GET /v1/health` 返回 `{"status":"ok"}`；统一错误中间件；JwtService 封装；.env 支持
- 【允许修改范围】`apps/api/**`、`docs/handoffs/M0-002.md`
- 【禁止修改范围】不建业务表/实体（M1-001 负责）；不实现业务接口；不改契约
- 【验收条件】① `pnpm dev` 启动 ② health 通过 ③ 未知路由返回契约 `{code,message}` ④ JWT 签发/校验自测通过
- 【QA要求】typecheck/lint 通过并附输出；M0-006 复核启动与 health
- 【交接对象】BE（M1-001/M1-004）、iOS（联调）、QA
- 【审核记录·预审】产出已落 `apps/api/`（handoff 未提交，仍 IN_PROGRESS）。预审发现，提交时须一并整改：① `main.ts` 全局前缀 `api/v1` 应为 **`v1`**（契约违规，必须改）② DB 默认账号密码与 infra 不一致（应为 `panji`/`panji_dev`，.env.example 同步）③ 移除 `embedded-postgres`（重依赖；M1-001 起 e2e 用 infra 的 Docker PG）④ 仓库根 `.npm-cache/` 须移出并 gitignore ⑤ 注释中 "CONTRACT-001" 改为 API_CONTRACT 现行名
- 【审核记录·提交】交接单 `docs/handoffs/M0-002.md` 已提交，状态 → REVIEW。预审 5 项全部整改：① /v1 前缀（app-setup 统一装配）② panji/panji_dev + .env.example 同步 ③ embedded-postgres 已移除（e2e 连外部 DATABASE_URL；本机无 Docker，另备无依赖 pg_ctl 脚本 dev-db.mjs 仅供本机）④ 根 .npm-cache 已删 + 根 .gitignore ⑤ 注释已改 API_CONTRACT/DATABASE_SCHEMA。验证证据：typecheck/lint/unit(6)/e2e(29, 真实 PG16)/build 全绿 + 真实进程冒烟 + migration:run 幂等重跑。**注意**：M1-001~M1-005 代码已随 e2e 预置于 apps/api（modules/entities/migrations），不属于本任务验收范围，随派发分别 REVIEW。
- 【审核记录·总控】审核通过 → **DONE**。证据复核：单测 6/6、e2e 29/29（真实 PG16）、lint/typecheck/build 全绿、migration 幂等、进程冒烟 /v1/health 200。**流程裁决 B9**：预置 M1 代码违反"不提前开发"红线，不删除但 M1 各任务仍逐一 REVIEW 对照契约，不符即退回。**B10**：接受 npm 替代 pnpm。M0-006 用 infra 的 Docker PG 复核。
- 【审核记录·M0-006 复核】QA 现场复核：运行/HTTP 契约（启动、/v1 前缀、health、404/401 错误格式、无泄漏）全 PASS。lint FAIL（scripts glob）与 e2e DELETE 红（预置 M1 删除语义漂移）**不重开本任务**：lint → M0-007；删除 service/e2e → M1-003。M0-002 维持 DONE。

### M0-003【iOS】SwiftUI 工程底座
- 【任务编号】M0-003
- 【任务名称】SwiftUI 工程底座
- 【负责人】iOS
- 【状态】DONE
- 【阻塞类型】环境能力阻塞（已解除；历史记录）
- 【目标】可编译的 SwiftUI 工程（apps/ios）：baseURL 可配置、ATS 局域网例外、主题占位。
- 【前置依赖】无
- 【输入】API_CONTRACT §1（前缀 `/v1/`）、PRODUCT_SPEC §8、DESIGN_SYSTEM v0（暂定色值）
- 【输出】`apps/ios/`：PanJi.xcodeproj、Config.xcconfig（API_BASE_URL）、Info.plist 注入、AppConfig、PanJiTheme、占位 RootView、README
- 【允许修改范围】`apps/ios/**`、`docs/handoffs/M0-003.md`
- 【禁止修改范围】不实现业务页面（M1-006 起）；不改契约
- 【验收条件】① Xcode 构建成功（附构建日志）② 模拟器运行显示占位页与注入的 API 地址 ③ README 说明 baseURL 切换方式
- 【QA要求】核对构建证据与 xcconfig 注入链路；README 引用契约文件名必须为 `docs/API_CONTRACT.md`
- 【交接对象】iOS（M1-006）、QA
- 【审核记录】目录已迁回 `apps/ios/`（B1 落实，根级 `ios/` 已删除，交接单更名 M0-003.md）。QA 复审（M0-003-QA.md）：FAIL-hold——静态核对 12 项 + pbxproj/scheme 独立结构校验全 PASS；唯一阻断 = 无 Xcode 构建/运行证据（NOT VERIFIED）→ 并入 M0-006（macOS 执行 xcodebuild 并留存日志）。证据补齐后置 DONE。
- 【审核记录·总控】BLOCKED 正式确认（变更记录 v3.5）：不把构建任务再派给 Windows iOS Agent；macOS 能力 = 独立环境任务 M0-006A；静态通过 ≠ DONE，验收标准不降。M0-006A DONE 后由 QA 回填 M0-003 验收①② → DONE。
- 【审核记录·解除】M0-006A 云端 CI 真绿（run #32833177820，pipefail 生效）：** BUILD SUCCEEDED **；产物 Info.plist 实测 `APIBaseURL => http://localhost:3000`（注入链真实生效，且 CFBundleDisplayName=盘迹、iOS 17.0、竖屏、ATS 局域网例外全部正确）；模拟器安装并 launch 成功（pid 7543，无启动崩溃）；截图已生成并回传 `ci-logs/m0-003-simulator.png`。验收①②③ 证据齐备 → **M0-003 DONE**（截图像素级目视由 QA 在 M0-006 收尾确认，非阻断）。iOS 线解冻。

### M0-004【UI】M1 UI 开发规格（设计系统 + 线框）
- 【任务编号】M0-004
- 【任务名称】M1 UI 开发规格（设计系统 + 线框）
- 【负责人】UI
- 【状态】DONE
- 【目标】视觉方向落成可直接映射 SwiftUI 的 token + 主链全部页面线框。
- 【前置依赖】无
- 【输入】PRODUCT_SPEC §8/§9、DESIGN_SYSTEM v0（现状暂定色值）
- 【输出】`docs/DESIGN_SYSTEM.md` 定稿 v1 + `docs/design/` 线框：登录、昵称、收藏柜（含空态）、创建玩物、记录、详情时间轴（含空态）、编辑玩物
- 【允许修改范围】`docs/DESIGN_SYSTEM.md`、`docs/design/**`
- 【禁止修改范围】不直接改 apps/ios 代码（替换由 iOS 在 M1-006 起执行）；不新增 M1 外组件/页面
- 【验收条件】① token 可 1:1 映射 SwiftUI ② 线框覆盖 20 步主链全部页面与空态 ③ 支撑"创建 ≤20 秒、记录 ≤10 秒" ④ 不含 M1 外功能
- 【QA要求】总控 + QA 共同评审；作为后续视觉走查依据
- 【交接对象】iOS（M1-006 起全部页面）、QA
- 【审核记录】总控审核通过 → **DONE**。DESIGN_SYSTEM v1（18 色 token + 字号/间距/圆角/组件规范）+ docs/design/ 9 线框（8 页 + 20 步覆盖矩阵），验收 ①②③④ 复核通过。设计裁决已批：B4 品类芯片并入创建页、B5 昵称不可跳过、B6 M1 无 TabBar、B7 时间轴照片全屏预览、B8 DEBUG-only 切号入口（B18 冒烟用）。

### M0-005【QA】M1 验收清单与测试计划
- 【任务编号】M0-005
- 【任务名称】M1 验收清单与测试计划
- 【负责人】QA
- 【状态】DONE
- 【目标】20 步主链验收清单 + 异常边界 + 持久化专项，成为 M0-006 / M1-012 的唯一依据。
- 【前置依赖】无
- 【输入】PRODUCT_SPEC §4（20 步）、API_CONTRACT v2.2、DATABASE_SCHEMA、本看板
- 【输出】`docs/qa/验收清单.md` v2 + `docs/handoffs/M0-005.md`
- 【允许修改范围】`docs/qa/**`、`docs/handoffs/M0-005.md`
- 【禁止修改范围】不改契约；待裁决项报总控，不得自行拍板
- 【验收条件】① 20 步主链全覆盖（含空态、创建后自动进详情、"记录第一天"入口）② 异常边界 ≥15 项 ③ 持久化专项（杀进程/后端重启/容器重建）④ 编辑/删除冒烟项 ⑤ 契约核对表对齐 v2.2 ⑥ 引用最新文档名
- 【QA要求】总控审核通过后作为 M0-006/M1-012 依据
- 【交接对象】全体
- 【审核记录】v1 已退回：基于旧契约（19 步、单图、无删除、/api/v1）。**v2 已提交（docs/handoffs/M0-005.md）**：20 步主链（A01~A20）、异常边界 21 项（B01~B21）、持久化专项 5 项（C01~C05）、编辑/删除冒烟 7 项（E01~E07）、契约核对表对齐 v2.2（/v1/、photoUrls、PATCH/DELETE、GET records、A10~A18）与 DATABASE_SCHEMA、引用最新文档名、旧引用自校验清零。QA 已另交 M0-001/M0-003 复审单（FAIL-hold，并入 M0-006）。状态 → REVIEW，待总控审核。
- 【审核记录·总控】v2 审核通过 → **DONE**（成为 M0-006 / M1-012 唯一验收依据）。非阻断小项：§0 的 `pnpm dev` 按裁决 B10 应写 `npm run dev`，QA 下次顺手修正。

### M0-006【QA】M0 集成验收
- 【任务编号】M0-006
- 【任务名称】M0 集成验收
- 【负责人】QA
- 【状态】DONE
- 【目标】确认工程底座完整，总控放行进入 M1。
- 【前置依赖】M0-001 ~ M0-005、M0-006A（macOS 证据段）
- 【拆分说明】非 macOS 部分（DB 实跑、后端 health/错误格式复核、BE 预置 M1 代码预核）可先行；整体 PASS 须待 M0-006A DONE。DB 实跑按 B12 本地 PG16 路线复核；compose 的 Docker 实跑环境豁免（团队无任何 Docker 机器）。
- 【输入】各任务交接单、M0-005 清单
- 【输出】`docs/qa/M0-验收报告.md`
- 【允许修改范围】`docs/qa/**`
- 【禁止修改范围】不改任何代码与契约
- 【验收条件】① DB 实跑验证通过（B12 本地 PG16 路线，代验 M0-001 ①②③：启动/连接/重启持久化；compose 静态合规 + Docker 豁免）② API health 通过 ③ iOS 构建证据确认（B13 云端 CI 产出）④ DESIGN_SYSTEM v1 与验收清单 v2 就绪 ⑤ 问题清零或已裁决
- 【QA要求】报告含每项命令与输出
- 【交接对象】总控（放行 M1）
- 【审核记录】QA 已交 `docs/handoffs/M0-006.md`（PARTIAL PASS）：底座运行/HTTP 契约 PASS；lint FAIL、e2e DELETE 红、Docker NOT VERIFIED、macOS 待 M0-006A（其本身 BLOCKED：无 Mac、无 git 远程）。剩余阻塞见变更记录 v3.6。
- 【审核记录·更新】iOS 证据段已就绪（M0-006A DONE，M0-003 DONE）；lint 已修复（M0-007 DONE）。**M0-006 剩余 = ① B12 本机 PG 路线复核（QA）② M1-003 e2e 复测（BE 提交后）③ 截图像素目视确认（QA）**。全部完成后 M0-006 可 PASS、M0 放行。
- 【审核记录·进度】① M0-001 B12 复核 ✓（QA 实测 PASS，M0-001 DONE）② lint ✓（M0-007 DONE）③ iOS 构建证据 ✓（CI 真绿，M0-006A/M0-003 DONE；截图像素目视待 QA）④ DESIGN_SYSTEM v1 + 清单 v2 ✓ ⑤ M1-003 e2e：BE 已全绿（29/29），待 QA 独立复核时复跑。**剩余 = QA 完成 M1-003 复核 + 截图目视 + 汇总报告 → M0-006 PASS → M0 放行。**
- 【审核记录·总控批准】QA 收尾报告（docs/qa/M0-验收报告.md）：五项验收 ①~⑤ 全部 PASS，PARTIAL 遗留全部核销（M1-003 QA 复核 PASS + e2e 复跑 29/29；截图程序化像素核验通过：1206×2622、暖米白 96.3% + 木棕圆标 + 深茶褐文字，非崩溃屏；人工目视最终确认由用户在 GitHub 侧 10 秒完成，非阻断）。总控批准 → **M0-006 DONE，M0 全部 9 任务 DONE → M0 PASS，正式放行 M1。**

### M0-006A【DBI】macOS/Xcode 构建环境准备
- 【任务编号】M0-006A
- 【任务名称】macOS/Xcode 构建环境准备（环境能力任务，非代码任务）
- 【负责人】DBI（环境获取与就绪牵头）；构建执行：iOS 或 QA 在 Mac 上按 runbook 操作
- 【状态】DONE
- 【阻塞类型】环境能力（已解除；历史记录）
- 【目标】为 apps/ios 提供 macOS + Xcode 构建验证能力，产出 M0-003 验收①②的构建/运行证据。**B13：默认路径=云端 macOS CI（GitHub Actions macOS runner 或 Codemagic），无需自有 Mac。**
- 【前置依赖】无（纯环境）
- 【输入】docs/handoffs/M0-003.md §12 runbook、ARCHITECTURE B11
- 【输出】① 云端 macOS CI 就绪（前置：用户建 Git 远程并推送仓库；GitHub Actions workflow `ios-build.yml` 或 Codemagic 配置）② build-m0-003.log 归档 docs/qa/ ③ 模拟器运行截图（占位页显示「盘迹」与注入 API 地址）④ baseURL 切换复验记录
- 【允许修改范围】无代码修改；若建 CI 仅限 `.github/workflows/**`（新增）；`docs/handoffs/M0-006A.md`
- 【禁止修改范围】不改 apps/ios 代码（构建暴露代码缺陷 → 转交 iOS 修复，记为 M0-003 代码阻塞）；不开发任何 M1 功能；不改契约
- 【验收条件】① xcodebuild 构建成功且日志归档 ② 模拟器启动显示占位页（目视截图）③ 产物 Info.plist 的 APIBaseURL 与 xcconfig 一致 ④ 全程无 M1 代码产生
- 【QA要求】复核证据后回填 M0-003 验收①②，M0-003 解除 BLOCKED → DONE
- 【交接对象】iOS（若需修代码）、QA（证据复核）
- 【审核记录】DBI 环境核查（docs/handoffs/M0-006A.md）：执行环境 Windows，xcodebuild/xcrun/sw_vers/simctl 全 ABSENT；无可达真实 Mac（known_hosts 仅 github.com、无 ssh config）；工作区非 git 仓库、无 GitHub 远程，macOS CI 不可行且 B11-CI 过渡未获批准；DOCKER_AVAILABLE=NO。结论 REAL_MAC_UNAVAILABLE → BLOCKED。待总控裁决：提供真实 Mac（首选）或批准 B11-CI + 建 GitHub 仓库（获批后 DBI 交付 ios-build.yml）
- 【审核记录·B13】总控裁定（用户确认无任何 Mac）：默认路径改**云端 macOS CI**。解除 BLOCKED 的条件 = 用户提供 Git 托管账号/仓库（GitHub 优先：公有仓库无限免费 macOS 分钟，私有约 200 macOS 分钟/月够用；或 Codemagic 500 分钟/月）+ 代码推送成功。此后 DBI 交付 workflow、跑出构建证据。真机验收（M1-012）方案延后至 M1 后期决策。
- 【审核记录·完成】run #32833177820（v5，pipefail 真绿）：构建/注入核对/模拟器启动/截图/回传全 success。总控核验回传日志：BUILD SUCCEEDED、APIBaseURL 注入正确、launch pid 7543、截图落盘。验收 ①②③④ 达成 → **DONE**。
- 【审核记录·仓库】用户指示总控负责建 Git 托管仓库：总控已执行 `git init` + 基线提交（105 文件，root-commit）+ 交付 `.github/workflows/ios-build.yml`（B13 云 CI：xcodebuild 构建 → Info.plist 注入核对 → 模拟器启动 → 截图 → 归档工件）。**推送已完成**（用户授权后 push 成功，main@16027ad），GitHub Actions `ios-build` 运行中（2026-08-25T08:55Z）。结果处理：绿 → QA 收工件复核 → M0-006A DONE；红 → 转 M0-003 代码阻塞，派 iOS 修复。
- 【审核记录·首跑】run #32829136499 **failure，但根因在 CI 脚本而非工程**：STEP3 `xcodebuild` 构建 **success**（真实 Mac/Xcode 编译通过，手写工程无代码缺陷）；STEP4 核对脚本失败（find 未命中 .app，脚本缺陷）。总控已交付 workflow v2（合并核对+启动+截图为一步、APP 路径自诊断、产物多归档 built-info）。待推送后自动重跑。
- 【审核记录·次跑】run #32830202147（v2）：STEP3 Build success，STEP4 失败——用户提供日志：`APP=` 为空且 DerivedData 下 `find -name '*.app'` 零结果（构建成功但产物不在默认位置）。总控处置：v3 固定 `-derivedDataPath build/DerivedData`（确定性路径，消除 find 猜测）；v4 新增"回传日志到仓库"步骤（GITHUB_TOKEN 把 build/step4/screenshot 提交回 `ci-logs/`，总控可匿名直读日志，不再依赖用户转贴）。
- 【审核记录·三跑（关键真相）】run #32831900251（v4）六步全 success 系**假绿**：日志回传后总控发现 build-m0-003.log 实为 `xcodebuild: error: Unable to find a device matching {name:iPhone 15}`——runner 无 iPhone 15 模拟器（仅 My Mac/占位 destination）；步骤"success"是因为 GitHub 默认 shell 无 pipefail，`xcodebuild | tee` 管道吞掉了非零退出码。**工程代码仍无缺陷**。v5 处置：① 构建改 `-destination 'generic/platform=iOS Simulator'`（不依赖具名设备）② 第 4 步按需 `simctl create` 建设备（runtimes 已随 runner 预装）③ 全部管道加 `set -o pipefail`，杜绝假绿再犯。待用户推送后重跑。

### M0-007【BE】Backend lint 配置修复
- 【任务编号】M0-007
- 【任务名称】Backend lint 配置修复
- 【负责人】BE
- 【状态】REVIEW
- 【目标】`npm run lint` 在现有目录结构下稳定执行并 PASS。
- 【前置依赖】无（在 M0-002 DONE 基础上修复）
- 【输入】QA M0-006 证据：eslint exit 2——`scripts/**/*.ts` glob 无匹配文件（scripts/ 现仅 dev-db.mjs）
- 【输出】apps/api/package.json lint 脚本 glob 修正（如 `scripts/**/*.{ts,mjs}` 或等价）+ 执行输出
- 【允许修改范围】`apps/api/package.json`、`apps/api/eslint.config.mjs`
- 【禁止修改范围】不改业务功能、API、Schema；不得用"忽略全部 scripts"方式掩盖问题
- 【验收条件】① `npm run lint` exit 0 ② lint 仍实际覆盖 src/ 与 test/ ③ 附执行输出
- 【审核记录】交接单 `docs/handoffs/M0-007.md` 已提交，状态 → REVIEW。lint 脚本 glob 改为 `src/**/*.ts` + `test/**/*.ts` + `scripts/**/*.mjs`（对齐 scripts/ 实际只有 dev-db.mjs 的现状，dev-db.mjs 纳入真实 lint）；eslint.config.mjs 为 scripts mjs 声明 Node 全局（process/console），未关闭规则、未扩大 ignore。验证：真实 `npm run lint` exit 0；三个 glob 分跑均 exit 0；反向验证（临时移除 globals → 14 个 no-undef → 恢复 → 0）证明 dev-db.mjs 被真实检查；typecheck/build/unit 全 PASS；业务代码零变化。
- 【审核记录·总控】审核通过 → **DONE**：glob 与实际目录一致、dev-db.mjs 被真实 lint（反向验证证明非跳过）、仅改两配置文件、`npm run lint` exit 0 且 typecheck/build/unit 通过。M0-006 的 lint 阻塞项解除。
- 【QA要求】M0-006 复测时重跑 lint 复核
- 【交接对象】QA

### M1-001【BE】数据模型实体 + 迁移 + 种子（6 表）
- 【任务编号】M1-001
- 【任务名称】数据模型实体 + 迁移 + 种子（6 表）
- 【负责人】BE
- 【状态】REVIEW
- 【目标】DATABASE_SCHEMA 的 6 表以 TypeORM 实体 + migration 落地，种子 5 品类（固定 UUID）幂等写入。
- 【前置依赖】M0-002、M0-001（库可连）
- 【输入】DATABASE_SCHEMA（全量）、API_CONTRACT §2
- 【输出】`apps/api/src/entities/`、migrations（CreateTables、SeedCategories）、seed
- 【允许修改范围】`apps/api/src/entities/**`、`apps/api/src/migrations/**`、`docs/handoffs/M1-001.md`
- 【禁止修改范围】不改 schema 字段/约束（变更须 SCHEMA_CHANGE_PROPOSAL）；不写业务接口
- 【验收条件】① `pnpm migration:run` 可重复执行（含幂等种子）② 表结构与 DATABASE_SCHEMA 逐字段一致 ③ FK 动作矩阵与 DATABASE_SCHEMA v2 一致（records→items RESTRICT、images→records CASCADE、auth→users CASCADE、items FK RESTRICT）、唯一约束/CHECK 齐全 ④ uuid 应用侧生成、date 映射 string、timezone UTC ⑤ migration 执行输出留存
- 【QA要求】对照 DATABASE_SCHEMA 逐字段核对；复核幂等重跑
- 【审核记录】交接单 `docs/handoffs/M1-001.md` 已提交，状态 → REVIEW。按 DATABASE_SCHEMA v2（逻辑删除）重写首版迁移：items 新增 deleted_at（显式列，禁隐式软删）、item_records.item_id FK CASCADE→RESTRICT；删除旧硬删除迁移（§8"随首版迁移一次落地，无增量迁移"）。验证：空库迁移/幂等重跑/结构逐字段对照/ FK RESTRICT 实测（物理删被拒）/逻辑删除模拟/回滚倒序成功/unit 6/6/lint/typecheck/build 全绿/e2e 28/29（1 个预期失败=旧硬删除 DELETE 断言，属 M1-003 待改）。遗留待总控裁决：API_CONTRACT §3.9/A16 仍 v2.2 硬删除口径、SCHEMA_CHANGE_PROPOSAL-001 状态"待总控批准"、QA 清单 B17 旧口径。
- 【审核记录·总控】SCHEMA_CHANGE_PROPOSAL-001 **已批准**（逻辑删除为最终语义，API_CONTRACT 已同步 v2.3）。数据层（entities+migration+seed）与 DATABASE_SCHEMA v2 一致 → **可送 QA 正式 REVIEW**，不因 M1-003 的 service 未改而阻止。
- 【审核记录·QA+总控】QA 独立库全量验证 **ALL PASS**（docs/handoffs/M1-001-QA.md：表清单、deleted_at、FK 矩阵 5 项、3 唯一、2 索引、6 CHECK、迁移幂等、回滚重建、RESTRICT 实测、seed 幂等；无阻断）。总控确认 → **DONE**，解锁 M1-002 / M1-003。
- 【交接对象】BE（M1-002/M1-003/M1-005）、QA

### M1-002【BE】Dev Login + 昵称 API
- 【任务编号】M1-002
- 【任务名称】Dev Login + 昵称 API
- 【负责人】BE
- 【状态】DONE
- 【目标】实现契约 3.1 / 3.2 / 3.3。
- 【前置依赖】M1-001
- 【输入】API_CONTRACT §3.1~3.3、§4
- 【输出】`apps/api/src/modules/auth/`、`users/` + curl 自测记录
- 【允许修改范围】`apps/api/src/modules/auth/**`、`apps/api/src/modules/users/**`、`docs/handoffs/M1-002.md`
- 【禁止修改范围】不改契约字段/状态码；不动实体定义
- 【验收条件】① 新号 isNewUser=true 且带 token ② 老号 isNewUser=false ③ PATCH /me 生效且校验 1~20 字 ④ 无 token 访问受保护接口返回 AUTH_REQUIRED ⑤ 附 curl 自测输出
- 【QA要求】契约核对表 3.1~3.3 逐项勾选
- 【交接对象】iOS（M1-006）、QA

### M1-003【BE】分类 + 玩物 CRUD（含逻辑删除）
- 【任务编号】M1-003
- 【任务名称】分类 + 玩物 CRUD（含逻辑删除）
- 【负责人】BE
- 【状态】REVIEW
- 【目标】实现契约 3.4 ~ 3.9，并按 v2.3 逻辑删除口径修正预置代码：`remove()` 改 UPDATE deleted_at；全部 items 查询显式过滤 `deleted_at IS NULL`；e2e DELETE 用例改新语义。
- 【前置依赖】M1-001（含 QA 通过）、API_CONTRACT v2.3
- 【输入】API_CONTRACT v2.3 §3.4~3.9、§4 规则 4/10、DATABASE_SCHEMA v2
- 【输出】`apps/api/src/modules/categories/`、`items/`（service 删除与查询过滤）+ e2e 用例更新 + curl 自测记录
- 【允许修改范围】`apps/api/src/modules/categories/**`、`apps/api/src/modules/items/**`、`apps/api/test/**`（DELETE 相关用例）、`docs/handoffs/M1-003.md`
- 【禁止修改范围】不改契约（v2.3 为最终口径）；不改 entities/migrations（M1-001 已定）；不实现记录接口（M1-005）；不增加恢复/回收站功能
- 【验收条件】① POST 返回完整对象，name 1~50 校验 ② GET 列表仅本人数据、含 dayCount 且**不含已删除玩物** ③ GET :id 不含 records、越权/已删除一律 404 ④ PATCH 部分更新、可传 null 清空选填、对已删除玩物 404 ⑤ DELETE 204=逻辑删除（UPDATE deleted_at）：带 records 的玩物删除成功且 records/images **物理保留**；不存在/他人/已删除 → 404 ⑥ list/getById/findOwned 等全部查询显式过滤 deleted_at IS NULL ⑦ e2e 全绿（新语义）⑧ 附 curl 自测输出
- 【QA要求】契约核对表 3.4~3.9（v2.3）逐项勾选；B17/B18/E05~E07 冒烟
- 【交接对象】iOS（M1-007/M1-008/M1-009/M1-011）、QA
- 【审核记录·总控初审】实读代码核验通过：`remove()` = QueryBuilder UPDATE `deletedAt=now()` WHERE id+user_id+`deleted_at IS NULL`，`!affected → 404`（v2.3 口径，未照抄旧"重复删除 204"）；`list()` 与 `findOwned()` 均 `deletedAt: IsNull()`，getById/PATCH/records 入口经 findOwned 自动过滤；e2e 新用例含 DB 级断言（item 行在 + deleted_at 置位 + records/images 物理保留）。BE 自证 e2e 29/29、curl 五场景、lint/typecheck/build/unit 全绿。**交 QA 独立复核**（契约核对表 3.4~3.9 + B17/B18/E05~E07 + e2e 复跑）后置 DONE。
- 【审核记录·QA+总控】QA 独立复核 **PASS**（docs/handoffs/M1-003-QA.md）：契约 3.4~3.9 逐项独立实测 + 冒烟 11/11（含 DB 级：item 行在 / deleted_at 置位 / records 物理保留 / 重复删 404 / B 越权全 404）+ 独立 e2e 复跑 29/29 全绿。总控确认 → **DONE**。已知小项（非阻断）：① 共享 panji 库并发跑 e2e 撞 pg 目录索引——后续 e2e 建议独立库（QA/BE 已共识）② e2e describe 标题"契约 v2.2"文案待顺手更新。
- 【审核记录·QA+总控】QA 独立复核 **PASS**（docs/handoffs/M1-003-QA.md）：契约 3.4~3.9 逐项独立实测 + 冒烟 11/11（含 DB 级：item 行在/deleted_at 置位/records 物理保留/重复删 404/B 越权全 404）+ 独立 e2e 复跑 29/29 全绿。总控确认 → **DONE**。已知小项（非阻断）：① 共享 panji 库并发跑 e2e 会撞 pg 目录索引——建议 e2e 用独立库（QA/BE 已共识）② e2e describe 标题"契约 v2.2"文案待顺手更新。

### M1-004【BE】图片上传 + 静态托管
- 【任务编号】M1-004
- 【任务名称】图片上传 + 静态托管
- 【负责人】BE
- 【状态】DONE
- 【目标】实现契约 3.10。
- 【前置依赖】M0-002
- 【输入】API_CONTRACT §3.10
- 【输出】`apps/api/src/modules/uploads/` + 静态路由
- 【允许修改范围】`apps/api/src/modules/uploads/**`、`docs/handoffs/M1-004.md`
- 【禁止修改范围】不改契约；不引第三方存储 SDK
- 【验收条件】① multipart 字段名 `file`，返回相对 URL ② jpeg/png/heic/webp 放行、其余 UNSUPPORTED_TYPE ③ >10MB 返回 UPLOAD_TOO_LARGE ④ 文件 uuid 重命名落 `uploads/`，重启服务仍可访问 ⑤ 附 curl 自测输出
- 【QA要求】契约核对表 3.10 勾选；B20 上传边界冒烟
- 【交接对象】iOS（M1-008/M1-010/M1-011）、QA
- 【审核记录·总控初审】实读 uploads.controller 核验：全局守卫（需登录）、FileInterceptor('file')、mime+扩展名双白名单（含 heif）、10MB、uuid 重命名、相对 URL、静态公开 ✓。BE curl 七场景 + lint/typecheck/build + e2e 29/29 全绿。小注（非阻断）：mime 白名单未含 image/heif（扩展名校验兜底，heif 实传已过）。→ **交 QA 独立复核（3.10 核对表 + B20）**。
- 【审核记录·QA+总控】QA 独立复核 **PASS**（docs/handoffs/M1-004-QA.md）：3.10 逐项独立实测（401/png 201/txt 415/11MB 413/heif 201/公开静态/重启仍可访问）+ B20 冒烟 7/7 + e2e 独立复跑 29/29（专用库），无阻断。总控确认 → **DONE**。解锁 M1-005。

### M1-005【BE】盘玩记录接口 POST/GET（多图 + 补录）
- 【任务编号】M1-005
- 【任务名称】盘玩记录接口 POST/GET（多图 + 补录）
- 【负责人】BE
- 【状态】DONE
- 【目标】实现契约 3.11 / 3.12。
- 【前置依赖】M1-001、M1-004
- 【输入】API_CONTRACT §3.11~3.12、§4、DATABASE_SCHEMA §5/§6
- 【输出】`apps/api/src/modules/records/`（photoUrls 落 record_images）+ curl 自测记录
- 【允许修改范围】`apps/api/src/modules/records/**`、`docs/handoffs/M1-005.md`
- 【禁止修改范围】不改契约；不改上传模块（M1-004）
- 【验收条件】① 默认日期=今天（北京时间）② 过去日期可补录 ③ photoUrls 落 record_images 且顺序保持 ④ GET records 按 recordedDate 倒序、同日期 createdAt 倒序 ⑤ 归属校验（他人 item 404）⑥ recordedDate 晚于今天返回 VALIDATION_ERROR ⑦ 长度校验按裁决 A12 ⑧ 附 curl 自测输出
- 【QA要求】契约核对表 3.11/3.12 勾选；补录与排序冒烟
- 【交接对象】iOS（M1-009/M1-010）、QA
- 【审核记录·总控初审】实读 records.service 核验：findOwned 门（他人/已删 404）、recordedDate 默认北京今天 + 未来日期 400（A10）、事务落 record_images（sortOrder=数组下标）、GET 排序 recordedDate DESC + createdAt DESC、图片按 sortOrder ASC 组装 ✓。BE curl 十场景 + e2e 29/29 全绿。→ **交 QA 独立复核（3.11/3.12 核对表 + 补录/排序冒烟）**。
- 【审核记录·QA+总控】QA 独立复核 **PASS**（docs/handoffs/M1-005-QA.md）：3.11/3.12 逐项实测 + 冒烟 8/8（含 DB 级 sort_order=0,1 核验、排序 [今天#2,今天#1,昨天]、未来日期/A12/越权全 400/404）+ 独立 e2e 复跑 29/29（专用库）。总控确认 → **DONE**。**BE 侧 M1 主链接口（M1-002~M1-005）全部交付完毕，BE 进入待命（联调与修复）。**

### M1-006【iOS】网络层 + 登录/昵称流程
- 【任务编号】M1-006
- 【任务名称】网络层 + 登录/昵称流程
- 【负责人】iOS
- 【状态】DONE
- 【目标】API client + Dev Login 页 + 昵称页 + token 持久化 + 启动恢复 + 基础异常处理。
- 【前置依赖】M0-003、M0-004、M1-002
- 【输入】API_CONTRACT §3.1~3.3、DESIGN_SYSTEM v1、M0-004 线框
- 【输出】`apps/ios/PanJi/Core/Network/`（请求封装：baseURL 拼接 `/v1/`、token 注入、统一错误码/网络错误提示）、`Features/Auth/`（LoginView、NicknameView）、SessionStore（UserDefaults）
- 【允许修改范围】`apps/ios/PanJi/Core/Network/**`、`apps/ios/PanJi/Features/Auth/**`、`docs/handoffs/M1-006.md`
- 【禁止修改范围】不实现收藏柜及以后页面（M1-007 起）；不改契约
- 【验收条件】① 首次登录→设昵称→进入收藏柜占位 ② 杀进程重开直接恢复登录态 ③ 401 回登录页 ④ 断网/超时显示可读提示不崩溃 ⑤ Xcode 构建成功附日志 ⑥ 换 DESIGN_SYSTEM v1 token
- 【QA要求】B01~B05/B12 冒烟；构建证据核对
- 【交接对象】iOS（M1-007）、QA
- 【审核记录·总控初审】实读 8 新文件核验：APIClient（/v1 拼接、Bearer、10s 超时、六错误码映射+网络异常）✓；SessionStore 阶段机 + UserDefaults（A7）+ /v1/me 恢复 + 401 清 token + 断网重试态 ✓；LoginView/NicknameView 校验、防连点、B5 不可跳过 ✓；PanJiTheme 18 色 token 与 DESIGN_SYSTEM v1 逐值一致（实查 18/18）✓。裁决：① 线框两处微不一致以 08-states 全局规范为准，实现正确，线框不回改（UI 待命）② RootView/pbxproj 越界修改=机械必需且已申报，接受 ③ B8 DEBUG-only 切号入口归 M1-007。**剩余 = 云端 CI 构建证据（推送后）+ QA 冒烟（B01~B05/B12）**。
- 【审核记录·CI+总控】run #32839079301（head e4480d5，含 M1-006 全部代码）**真绿**：xcodebuild 真实编译 12 个 Swift 文件 BUILD SUCCEEDED；模拟器安装 + launch 成功（pid 8874，Dev Login 页正常渲染）；截图更新。验收⑤⑥ ✓ → **DONE**。注：运行态交互项 ①~④ 由 **M1-012 真机 20 步主链**统一验收（A02~A05/A19 + B01~B05 已入 M0-005 清单），不重复单列。

### M1-007【iOS】收藏柜
- 【任务编号】M1-007
- 【任务名称】收藏柜
- 【负责人】iOS
- 【状态】DONE
- 【目标】品类分组陈列（封面/名称/盘玩天数）+ 空态引导 + 下拉刷新 + DEBUG-only「开发：切换账号」入口（裁决 B8，QA B18 冒烟用）。
- 【前置依赖】M1-003、M1-006
- 【输入】API_CONTRACT §3.4/3.5、M0-004 线框、DESIGN_SYSTEM v1
- 【输出】`apps/ios/PanJi/Features/Items/`（CabinetView、ItemCardView、空态）
- 【允许修改范围】`apps/ios/PanJi/Features/Items/**`、`docs/handoffs/M1-007.md`
- 【禁止修改范围】不实现创建/详情页（M1-008/M1-009）；不改契约
- 【验收条件】① 按品类分组正确 ② 卡片三要素齐全 ③ 空态显示"创建第一件玩物"引导 ④ 下拉刷新可用 ⑤ 构建成功附日志 ⑥ DEBUG-only 切号入口仅 DEBUG 构建可见（#if DEBUG）
- 【QA要求】B07 无封面占位、B18 隔离冒烟
- 【交接对象】iOS（M1-008/M1-009）、QA
- 【审核记录·总控初审】实读核验：CabinetStore async let 并发拉取、客户端分组（仅含有玩物品类、sort_order 序）、刷新失败保留内容+横幅、401 signOut ✓；CabinetView 三要素卡片 + AsyncImage 静默降级首字占位 + 空态 CTA + 骨架/错误重试 + #if DEBUG 切号（B8 编译级排除，Release 无）✓；APIClient.imageURL 归网络层 ✓；Auth/Network 4 处触点=移除占位视图的机械连带，接受。**剩余 = 云端 CI 构建证据（推送后）+ QA（B07/B18）**。
- 【审核记录·QA+总控】QA 复核 **PASS**（docs/handoffs/M1-007-QA.md）：三要素/首字占位/空态文案/#if DEBUG 切号编译级排除/B19 隔离链路/401/横幅/骨架/并发拉取/imageURL 全 PASS；CI 证据 18:56 运行 BUILD SUCCEEDED + launch + STEP4_ALL_OK（总控独立复核 run #32840481220 success）；新截图像素核验为登录页特征、启动无崩溃。交互级走查（占位视觉/切号点按/刷新动效）并入 M1-012。总控确认 → **DONE**。解锁 M1-008/M1-009。

### M1-008【iOS】创建玩物（创建后自动进详情）
- 【任务编号】M1-008
- 【任务名称】创建玩物（创建后自动进详情）
- 【负责人】iOS
- 【状态】DONE
- 【阻塞类型】代码缺陷（已解除；历史：两次编译错误经 CI 捕获并修复）
- 【目标】约 20 秒、≤3 步创建玩物；创建成功自动进入详情。
- 【前置依赖】M1-003、M1-004、M1-006、M1-007
- 【输入】API_CONTRACT §3.6/3.10、M0-004 线框
- 【输出】`apps/ios/PanJi/Features/Items/CreateItemView.swift`（封面选图/跳过、名称、品类；选填区折叠：子类/入手日期/尺寸/备注）+ 照片选择器封装
- 【允许修改范围】`apps/ios/PanJi/Features/Items/**`（创建相关）、`docs/handoffs/M1-008.md`
- 【禁止修改范围】不实现编辑页（M1-011，表单可复用）；不改契约
- 【验收条件】① 带图与跳图均可创建 ② 创建成功自动进入详情页 ③ 选填区默认折叠 ④ 名称必填校验、品类必选 ⑤ 防重复提交 ⑥ 构建成功附日志
- 【QA要求】B08/B09/B10/B12 冒烟（v2.1 编号：上传失败/防连点/名称校验/无封面创建）；20 秒体验观察项
- 【交接对象】iOS（M1-009/M1-011，表单复用）、QA
- 【审核记录·总控初审】实读核验：CreateItemStore 两段式（先 3.10 上传拿相对 URL 缓存，创建失败重试不重传）、trim→null、名称 1~50、品类必选、防连点（submitting/uploadingCover 双态）、入手日期北京时间 + 上限=北京今天 ✓；APIClient.uploadImage multipart 字段 `file` + Bearer ✓；CreateItemView 原生 PhotosPicker（零第三方库）、封面跳过/更换/移除、更多信息折叠、错误态齐备 ✓。Network/DesignSystem 触点=最小必要已申报，接受。**剩余 = 云端 CI 构建证据（推送后）+ QA（B08/B09/B10/B12 + 20 秒观察）**。
- 【审核记录·退回】总控独立复核 CI：run #32843110073（head 416164b，M1-008 代码）**BUILD FAILED**——`CreateItemStore.swift:74` 等 3 文件编译失败（6 处：CreateItemView/CreateItemStore/ItemDetailPlaceholderView × arm64/x86_64）：`token: session.token` 把 `String?` 传给非可选参数（M1-007 起 session.token 为 internal 的 `String?`，而 uploadImage 的 token 形参为 `String`）。**QA 的 PASS 所引"19:18 CI 绿"为更早运行的误引（该绿运行 head=0e0008f，早于 M1-008 提交）**；QA 静态结论保留有效，CI 证据段作废。→ **退回 iOS 整改**：uploadImage(token:) 改 `String?`（与 request() 一致，非空才注入 Bearer），禁止 `!` 强解包；修复后推送重跑 CI，真绿后再交 QA 复核。
- 【审核记录·退回2】iOS 修复 token 形参后重跑：run #32957685059 仍 **BUILD FAILED**（5 处）——新暴露 `CreateItemView.swift:82/123`：`store.coverURL = nil` 直接赋值，而 `coverURL` 为 `private(set)`。→ 再退回：CreateItemStore 提供 `removeCover()`（清 coverData + coverURL），View 不得直接写 store 私有字段；同时自查是否还有其他对 private(set)/内部字段的直接写入。
- 【审核记录·CI+总控】二次修复后 run #33510273974（head 3e46f18）**真绿**：BUILD SUCCEEDED + launch + STEP4_ALL_OK（总控实读日志确认）。QA 静态冒烟结论（B08/B09/B10/B12 + 20s 支撑）保留有效，交互计时并入 M1-012。总控批准 → **DONE**。解锁 M1-009（已 READY，立即派发）。

### M1-009【iOS】玩物详情 + 成长时间轴
- 【任务编号】M1-009
- 【任务名称】玩物详情 + 成长时间轴
- 【负责人】iOS
- 【状态】REVIEW
- 【目标】大图 + 记录时间轴（多图、一句话、日期、时长/方式）+ 空态 CTA"记录第一天" + 编辑入口。
- 【前置依赖】M1-003、M1-005、M1-006、M1-007
- 【输入】API_CONTRACT §3.7/3.12、M0-004 线框
- 【输出】`apps/ios/PanJi/Features/Items/ItemDetailView.swift`、`TimelineView.swift`、`TimelineCellView.swift`
- 【允许修改范围】`apps/ios/PanJi/Features/Items/**`（详情相关）、`docs/handoffs/M1-009.md`
- 【禁止修改范围】不实现记录表单（M1-010）、编辑表单（M1-011）；不改契约
- 【验收条件】① 时间轴按 recordedDate 倒序 ② 多图记录完整展示且顺序保持 ③ 空态显示"记录第一天"入口 ④ 记录保存后回详情即时刷新 ⑤ 编辑入口可达 ⑥ 构建成功附日志
- 【QA要求】A14~A16 主链步核对；B09/B10 冒烟
- 【交接对象】iOS（M1-010/M1-011）、QA
- 【审核记录·总控初审】实读核验：ItemDetailStore 三接口并行 + notFound 态 + 401 + refresh()（供 M1-010 保存后回刷）✓；TimelineView 空态 CTA + 日期三态（今天/M月d日/yyyy年M月d日，北京时间）✓；TimelineCellView 多图 96×96 顺序保持 + fullScreenCover 预览 + 缩略图失败重试 ✓；PhotoPreviewView TabView 翻页（B7）✓；ItemDetailView dayCount 用服务端值、底部「记录今天/记录第一天」双态 + sheet onDismiss 回刷 ✓。裁决：① 入手信息不单独成行=同意（原则 9：相册日记非仪表盘）② 全屏预览关闭用按钮=接受（线框二选一已满足）。**剩余 = 云端 CI 构建证据（推送后）+ QA（A14~A16/B09/B10）**。

### M1-010【iOS】盘玩记录（多图 + 补录）
- 【任务编号】M1-010
- 【任务名称】盘玩记录（多图 + 补录）
- 【负责人】iOS
- 【状态】REVIEW
- 【目标】约 10 秒完成：默认只有"照片 + 一句话 + 保存"；"更多记录项"折叠出时长/方式/日期（过去日期=补录）。
- 【前置依赖】M1-004、M1-005、M1-006、M1-009
- 【输入】API_CONTRACT §3.10/3.11、M0-004 线框
- 【输出】`apps/ios/PanJi/Features/Records/RecordView.swift`（照片多选 0~N、一句话、保存；更多项折叠）
- 【允许修改范围】`apps/ios/PanJi/Features/Records/**`、`docs/handoffs/M1-010.md`
- 【禁止修改范围】不改时间轴（M1-009）；不改契约
- 【验收条件】① 默认表单只有照片/一句话/保存 ② 无照片可保存 ③ 多图顺序保持 ④ 补录历史日期后时间轴归位 ⑤ 日期选择上限=今天（北京时间）⑥ 连点保存仅一条（防重）⑦ 构建成功附日志
- 【QA要求】A12~A16 主链步核对；B02/B04/B14 冒烟；10 秒体验观察项
- 【交接对象】QA
- 【审核记录·总控初审】实读核验：RecordStore 照片状态机（local/uploading/uploaded/failed）+ 按选择顺序逐张上传 + 失败张单独重试（已成功不重传）+ 无照片可保存 + 时长 0→null、方式 trim→null、日期未动不传（服务端默认）+ 防连点 + hasUnsavedChanges 放弃确认 ✓；RecordView 默认表单只有三样、DatePicker `in: ...endOfBeijingToday()`（未来灰置）、Stepper 0~1440 步进 5、confirmationDialog 放弃确认 ✓。北京时区工具与 CreateItemStore 重复持有=M1 规模内接受（M1-011 顺带收敛，已注明）。**剩余 = 云端 CI 构建证据（推送后）+ QA（A12~A16/B02/B04/B14 + 10s 观察）**。

### M1-011【iOS】编辑/删除玩物
- 【任务编号】M1-011
- 【任务名称】编辑/删除玩物
- 【负责人】iOS
- 【状态】BACKLOG
- 【目标】详情页可编辑玩物字段/换封面、可删除（需确认）。
- 【前置依赖】M1-003、M1-004、M1-006、M1-008、M1-009
- 【输入】API_CONTRACT §3.8/3.9/3.10、M0-004 线框
- 【输出】`apps/ios/PanJi/Features/Items/EditItemView.swift`（复用 CreateItemView 表单）、删除确认弹窗
- 【允许修改范围】`apps/ios/PanJi/Features/Items/**`（编辑/删除相关）、`docs/handoffs/M1-011.md`
- 【禁止修改范围】不改契约；不新增批量操作
- 【验收条件】① 编辑字段/封面后详情与列表同步 ② 删除需确认弹窗 ③ 删除后回收藏柜消失、时间轴数据随之消失 ④ 构建成功附日志
- 【QA要求】编辑/删除冒烟项（M0-005 清单内）
- 【交接对象】QA

### M1-012【QA】M1 主链真机验收（20 步）
- 【任务编号】M1-012
- 【任务名称】M1 主链真机验收（20 步）
- 【负责人】QA
- 【状态】BACKLOG
- 【目标】真实 iPhone 完成 PRODUCT_SPEC §4 全部 20 步，通过后总控批准进入 M2。
- 【前置依赖】M1-001 ~ M1-011、M0-006
- 【输入】M0-005 验收清单 v2、真机 + 局域网联调环境
- 【输出】`docs/qa/M1-验收报告.md`（每步结果 + 持久化 + 缺陷清单）
- 【允许修改范围】`docs/qa/**`
- 【禁止修改范围】不改代码与契约
- 【验收条件】① 20 步全部通过 ② 重启 App 数据仍在（含图片）③ 时间轴排序正确 ④ 缺陷清零或明确裁决遗留
- 【QA要求】报告附每步操作与结果截图/记录
- 【交接对象】总控（决定是否进入 M2）

---

## 任务依赖关系

```
M0-001 ──► M0-002 ──► M1-001 ──► M1-002 ──► M1-006 ──► M1-007 ──► M1-008 ──┐
                │                    └──► M1-003 ──► M1-006/7/8/9/11         │
                └──► M1-004 ──► M1-005 ──► M1-009 ──► M1-010                │
M0-003 ──► M1-006                                                          ▼
M0-004 ──► M1-006/M1-007/M1-008/M1-009/M1-010/M1-011                  M1-011 ──► M1-012
M0-005 ──► M0-006 ──►（放行 M1）────────────► M1-012（20 步真机验收 → M2 闸门）
```

## 工作流程

1. 派发：总控按依赖解锁派发（READY → IN_PROGRESS）；一次一个角色一个可独立验收任务。
2. 执行：先读 AGENTS/PRODUCT_SPEC/ARCHITECTURE/API_CONTRACT/DATABASE_SCHEMA/DESIGN_SYSTEM/TASKS 与相关 handoff。
3. 提交：产出 + `docs/handoffs/<TASK-ID>.md`（16 项格式）+ 验证证据 → 状态 REVIEW。
4. 总控审核：阅读实际文件/diff（不只相信自述）→ 判断是否需要 QA → 检查契约违规 → 通过 DONE / 退回 IN_PROGRESS；更新本看板后再派下一任务。

## 变更记录

| 日期 | 变更 |
|---|---|
| 建立日 v1~v2 | 看板建立（T-xxx 编号）；对齐项目总规则（record_images 多图、编辑/删除、/v1/ 前缀） |
| 同日 v3 | 全面对齐新总控规范：编号迁移 Mx-xxx（T-001→M0-001，T-002→M0-002，T-003→M0-003，T-004→M0-004，T-005→M0-005，T-101→M1-001，T-102→M1-002，T-103→M1-003，T-104→M1-004，T-105→M1-005，T-106→M1-006，T-107→M1-007，T-108→M1-008，T-109→M1-009，T-110→M1-010，T-111→M1-011，T-201→M0-006，T-202→M1-012）；状态词表改 BACKLOG/READY/IN_PROGRESS/REVIEW/BLOCKED/DONE；任务字段扩充为 13 项；主链改 20 步；DATABASE_SCHEMA.md 与 DESIGN_SYSTEM.md 拆分；AGENTS.md 移至仓库根；采纳 DBI 的 DB-001（→DATABASE_SCHEMA）；M0-001 REVIEW（待实跑）、M0-003 退回整改、M0-005 修订中 |
| 同日 v3.1 | 收 iOS 交接单（T-003）：裁决确认 iPhone-only/锁竖屏/iOS 17.0/Bundle ID 占位；布局最终裁定 apps/<端>（iOS 迁回 apps/ios/）；BE apps/api 预审发现 5 项（/api/v1 前缀违规、DB 默认账号、embedded-postgres、.npm-cache、旧文档名）待 handoff 时整改 |
| 同日 v3.2 | iOS 执行 B1 迁移（根级 ios/ → apps/ios/）并交新格式交接单 docs/handoffs/M0-003.md（原 T-003.md 更名）；M0-003 状态 IN_PROGRESS → REVIEW，待总控置 DONE |
| 同日 v3.3 | BE 提交 M0-002（docs/handoffs/M0-002.md）：预审 5 项整改完成，验证证据全绿，状态 → REVIEW；M1-001~M1-005 代码已预置于 apps/api（未验收，随派发分别 REVIEW） |
| 同日 v3.4 | 总控评审：M0-002 → DONE（B9 预置代码流程裁决、B10 npm 接受）；M0-004 → DONE（DESIGN_SYSTEM v1 + 9 线框，B4~B8 设计裁决）；M0-001/M0-003 经 QA 复审 FAIL-hold（缺实跑/构建证据，并入 M0-006）；M0-005 清单 v2 仍未交 |
| 同日 v3.5 | M0-003 BLOCKED 正式确认（阻塞类型=环境能力，非代码）；新增环境任务 M0-006A（macOS/Xcode 构建环境，DBI）；M0-006 拆段（非 macOS 部分 READY，整体 PASS 待 M0-006A）；M0-005 v2 审核通过 → DONE；M1-001/M1-004 依赖满足 → READY；iOS M1-006~M1-011 禁止启动直至 M0-006A DONE |
| 同日 v3.6 | SCHEMA_CHANGE_PROPOSAL-001 APPROVED（逻辑删除为最终语义，重复删除=404）；API_CONTRACT → v2.3（3.9 逻辑删除、A16 改写、deleted_at/FK RESTRICT 说明、业务规则 10、3.10 补需登录+heif）；TASKS：M1-001 验收③ 改 v2 口径并可送 QA、M1-003 重写为逻辑删除任务、新增 M0-007（lint 修复，READY）；QA 清单 → v2.1（B17/E06/§5.1/§5.2/§6）；M0-002 维持 DONE 不重开 |
| 同日 v3.5 | QA 提交 M0-005 清单 v2（docs/qa/验收清单.md 重写：20 步主链 + 21 项异常边界 + 5 项持久化 + 7 项编辑/删除冒烟 + 契约核对表 v2.2 + 旧引用清零）+ handoff（docs/handoffs/M0-005.md），状态 → REVIEW，待总控审核 |
| 同日 v3.6 | 总控要求 iOS 补齐 M0-003 构建证据：iOS 环境核查=Windows 无 macOS/Xcode，xcodebuild 不存在，构建 NOT EXECUTED（不伪造证据）；6 验证点静态映射 20/20 PASS，macOS 构建 runbook 存档于 docs/handoffs/M0-003.md §12；M0-003 → BLOCKED（阻断=构建证据需 macOS 执行环境，待总控裁决：M0-006 于 macOS 执行或提供 macOS 机） |
| 同日 v3.7 | M0-006A（DBI）：环境核查 REAL_MAC_UNAVAILABLE——Windows 无 Xcode/Simulator、无真实 Mac 访问通道、工作区非 git 仓库故 macOS CI 不可行（B11-CI 未批）、Docker 无 → BLOCKED（环境能力），待总控裁决环境方案（真实 Mac 或批准 CI 过渡） |
| 同日 v3.9 | BE 提交 M0-007（docs/handoffs/M0-007.md）：lint glob 改为 src/test 的 ts + scripts 的 mjs（dev-db.mjs 纳入真实 lint），eslint.config.mjs 声明 Node 全局；npm run lint/分 glob/反向验证/typecheck/build/unit 全 PASS，业务代码零变化；状态 → REVIEW |
| 同日 v3.8 | BE 提交 M1-001（docs/handoffs/M1-001.md）：对齐 DATABASE_SCHEMA v2 逻辑删除，首版迁移重写（deleted_at + item_records RESTRICT），验证全绿（e2e 28/29 其中 1 个为旧硬删除断言待 M1-003 改），状态 → REVIEW；遗留 API_CONTRACT §3.9/A16 同步待总控裁决 |
| 同日 v3.10 | 总控评审：M0-007 → DONE（lint 修复通过，M0-006 lint 阻塞解除）；M1-001 → DONE（QA 独立库全量验证 ALL PASS）；解锁 M1-002 / M1-003 → READY；DATABASE_SCHEMA §8 命令统一 npm（B10） |
| 同日 v3.11 | 用户确认无 Mac/Docker 机器 → 总控裁定 B12（DB 标准环境=本机 PG16 路线，compose 备选，Docker 实跑豁免记已知缺口）、B13（iOS 构建默认云端 macOS CI，选型待用户确认 Git 渠道；真机验收延后决策）；M0-001 验收改 B12 口径、M0-006 验收①/拆分说明同步、M0-006A 目标/输出改云 CI；QA 清单 §0/C03 同步 |
| 同日 v3.12 | 用户指示总控建 Git 托管仓库：总控完成 git init + 基线提交（105 文件）+ `.github/workflows/ios-build.yml`；M0-006A 解除 BLOCKED 仅剩 GitHub 建仓推送一步 |
| 同日 v3.13 | CI 五轮迭代定位（v1 脚本缺陷 → v2 日志暴露 DerivedData 无产物 → v4 假绿=无 pipefail 掩盖 xcodebuild 失败 → v5 generic 目标+按需建模拟器+pipefail）。**run #32833177820 真绿**：BUILD SUCCEEDED、APIBaseURL 注入实测正确、模拟器 launch 成功、截图回传。M0-006A DONE、M0-003 解除 BLOCKED → DONE，iOS 线解冻（M1-006 待 M1-002） |
| 同日 v3.14 | M0-001 收尾整改验收通过 + QA 本机 PG 复核全 PASS → DONE；M1-003 总控初审通过（实读代码：逻辑删除/查询过滤/e2e DB 级断言符合 v2.3）→ REVIEW 交 QA 独立复核；M0-006 五项中四项已就绪，仅剩 QA 复核收尾 |
| 同日 v3.15 | **M0 PASS，正式放行 M1**：M0-006 五项验收全 PASS（QA 报告 + 总控批准），M0 全部 9 任务 DONE；M1-002 总控实核 → DONE（生产门禁/事务建号/文案修正）；M1-003 经 QA 独立复核 PASS → DONE（e2e 29/29）；**M1-006 → READY（iOS 网络层+登录可派发）** |
| 同日 v3.16 | iOS 提交 M1-006（docs/handoffs/M1-006.md）：网络层 3 文件（APIClient/APIError/APIDTOs）+ Auth 5 文件（AuthRootView/LoginView/NicknameView/SessionStore/CabinetPlaceholderView）+ PanJiTheme v1 全量替换 + RootView 接管 + pbxproj 注册 8 文件；静态校验全 PASS；状态 → REVIEW，构建证据待推送后云端 CI（ios-build workflow） |
| 同日 v3.17 | 总控初审 M1-006（实读 8 文件：/v1、Bearer、错误映射、阶段机、18 色 token 全一致）→ REVIEW 待 CI 证据+QA 冒烟；裁决：线框微不一致以 08-states 为准不回改、RootView/pbxproj 越界=机械必需接受、B8 切号入口归 M1-007；M1-004 总控初审通过（uploads 实核）→ REVIEW 交 QA；M1-007 验收增 B8 项 |
| 同日 v3.18 | iOS 提交 M1-007（docs/handoffs/M1-007.md）：Features/Items 3 文件（CabinetView/ItemCardView/CabinetStore）+ CabinetPlaceholderView 移除 + Auth/Network 4 处机械触点（token 可见性、imageURL、DTO、AuthRootView 接线）+ pbxproj 增删注册；静态自检 20/20 PASS（含 #if DEBUG 切号编译级排除）；状态 → REVIEW，构建证据待推送后 CI |
| 同日 v3.20 | 总控初审 M1-005（records.service 实核：findOwned 门/事务落图/排序/未来日期 400）→ REVIEW 交 QA；总控初审 M1-007（CabinetStore/View 实核：#if DEBUG 切号、静默降级占位、刷新横幅、401）→ REVIEW 待 CI 证据 + QA B07/B18 |
| 同日 v3.21 | iOS 提交 M1-008（docs/handoffs/M1-008.md）：CreateItemView/CreateItemStore/ItemDetailPlaceholderView 3 新文件 + 收藏柜接线（sheet→创建页、创建后 push 占位详情+回刷、CreatePlaceholderView 移除）+ Network 上传能力（multipart/MIME）+ PanJiTextField 多行扩展 + pbxproj 注册；静态自检 28/28 PASS；状态 → REVIEW，构建证据待推送后 CI |
| 同日 v3.22 | 总控初审 M1-008 通过（两段式上传缓存、trim→null、北京时区日期、防连点、原生 PhotosPicker）→ REVIEW 待 CI + QA（B08/B09/B10/B12 + 20s 观察） |
| 同日 v3.23 | **M1-008 退回整改（首个 CI 捕获的真实代码缺陷）**：run #32843110073 BUILD FAILED——CreateItemStore.swift:74 `session.token`（String?）传给 uploadImage(token: String)，3 文件 6 处编译失败；QA 所引"19:18 CI 绿"系更早运行误引（head=0e0008f）。→ iOS 修复 uploadImage 形参改 String? 后重推重跑 |
| 同日 v3.24 | iOS 完成 M1-008 修复：uploadImage token 形参改 `String?` + if-let 注入（无强解包）、清除 categoryId!（guard 兜底）、三输入框 FocusState 分离（修复多框同亮）；静态复检 F1~F9 全 PASS + pbxproj 72/72 + UTF-8；handoff 补记 §20/§21 → 复报 REVIEW，待推送后 CI 真绿 |
| 同日 v3.25 | **M1-008 二次退回**（CI 重跑暴露）：CreateItemView 直写 private(set) 的 store.coverURL。iOS 修复：store 新增 selectCover()/removeCover() 方法，View 两处改走方法；全文件自查 private(set) 零直写、公开字段写入合法；静态复检 A/B/C 组全 PASS → 复报 REVIEW，待 CI 复跑 |
| 同日 v3.26 | M1-008 二次修复后 CI **真绿**（run #33510273974：BUILD SUCCEEDED + STEP4_ALL_OK，总控实读确认）→ **DONE**（QA 静态冒烟保留，交互计时并入 M1-012）。解锁 M1-009 派发 |
| 同日 v3.27 | iOS 提交 M1-009（docs/handoffs/M1-009.md）：ItemDetailStore/ItemDetailView/TimelineView/TimelineCellView/PhotoPreviewView 5 新文件 + 收藏柜接线（卡片点击进详情、返回回刷、onChange(showDetail)）+ ItemDetailPlaceholderView 移除 + APIDTOs 追加 §3.7/3.12 + pbxproj 增删注册；静态自检 30/30 PASS；状态 → REVIEW，构建证据待推送后 CI |
| 同日 v3.28 | 总控初审 M1-009 通过（三接口并行、notFound、日期三态、多图顺序、B7 预览、服务端 dayCount）；裁决：入手信息不单独成行=同意（原则 9）、预览关闭按钮=接受 → REVIEW 待 CI + QA |
| 同日 v3.29 | M1-009 CI 真绿一次通过（run #33946900102：BUILD SUCCEEDED + 全步骤 success）→ **DONE**（A14~A16/B09/B10 并入 M1-012 主链核验）。解锁 M1-010 → READY |
| 同日 v3.30 | iOS 提交 M1-010（docs/handoffs/M1-010.md）：RecordView/RecordStore 2 新文件（默认表单三样、多选顺序上传、失败张单独重试、补录日期未动不传、Stepper 时长、防连点、放弃确认）+ 详情页接线（真记录 sheet/保存成功 toast/sensoryFeedback/onDismiss 回刷）+ APIDTOs 追加 §3.11 + pbxproj 注册 Records 分组；静态自检 30/30 PASS；状态 → REVIEW，构建证据待推送后 CI |
| 同日 v3.31 | 总控初审 M1-010 通过（照片状态机/顺序上传/单张重试/日期未动不传/防连点/放弃确认/未来灰置）→ REVIEW 待 CI + QA（A12~A16/B02/B04/B14 + 10s 观察） |
