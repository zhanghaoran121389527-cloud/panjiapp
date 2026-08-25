# 盘迹 设计系统（DESIGN_SYSTEM）

- 维护人：UI（产出）、总控（批准）
- 状态：**v1 定稿**（M0-004 交付；替代 v0 占位）
- 变更规则：token/组件规范变更由 UI 提议、总控批准后，iOS 统一在 `apps/ios/PanJi/Core/DesignSystem/PanJiTheme.swift` 替换，**禁止各页面自造颜色/字号**。
- 红线：不新增 M1 之外的页面与组件（社区、消息、商城等一律不做）。

---

## 1. 视觉方向（不变）

东方极简 + 现代感。暖米白、深茶褐、木棕。图片优先、留白、克制、温润。
不做古玩商城、ERP 或传统论坛。禁止：大红大金、复杂国潮纹样、大面积书法、厚重木纹、花哨渐变、过度拟物、大量装饰边框。

v0 的 4 个基色（background/textPrimary/textSecondary/accent）**原值保留**，本版只做补全，不改变品牌方向。

## 2. 色板（完整表，可直接映射 `Color.PanJi.*`）

| Token（SwiftUI） | 色值 | 用途 |
|---|---|---|
| `background` | `#F6F1E7` | 页面背景 · 暖米白 |
| `surface` | `#FFFDF8` | 卡片 / 输入框 / 弹层底 |
| `surfacePressed` | `#F2EBDD` | 卡片、芯片按压态 |
| `textPrimary` | `#4A3728` | 主文字 · 深茶褐 |
| `textSecondary` | `#8A7B6D` | 次文字、说明 |
| `textTertiary` | `#B0A28F` | 占位符、极弱提示 |
| `accent` | `#8C6D4F` | 强调 · 木棕（主按钮、选中、节点） |
| `accentPressed` | `#79593F` | 主按钮按压态 |
| `accentSoft` | `#EFE5D3` | 选中底色、空态图标圆底、封面占位底 |
| `onAccent` | `#FFFDF8` | 主按钮上的文字/图标 |
| `divider` | `#E9E0CE` | 分割线、描边、时间轴线 |
| `disabledFill` | `#EFE9DB` | 禁用按钮底 |
| `disabledText` | `#C7BBA9` | 禁用按钮文字 |
| `danger` | `#B1502F` | 删除等危险操作（暖锈红，非大红） |
| `dangerPressed` | `#98422A` | 危险按钮按压态 |
| `dangerSoft` | `#F7E8E1` | 危险提示条底 |
| `success` | `#6E7F5B` | 仅"已保存"提示图标点缀（灰绿，克制使用） |
| `scrim` | 黑 40% | 全屏蒙层 |

- 用法约束：`success` 只允许出现在保存成功 toast 的图标上，不用于按钮/徽章。
- 图片占位（无封面）：`accentSoft` 底 + `textSecondary` 首字，见 §6.3。
- 深浅色模式：M1 只做浅色（锁浅色外观），不提供深色配色。

## 3. 字号字重（可直接映射 SwiftUI `Font`）

| Token | SwiftUI 写法 | 用途 |
|---|---|---|
| `display` | `.system(size: 40, weight: .semibold)` | 登录页品牌名「盘迹」、圆标内「盘」 |
| `navLargeTitle` | `.largeTitle`（weight .semibold） | 收藏柜导航大标题 |
| `itemTitle` | `.title3`（weight .semibold） | 详情页玩物名 |
| `heading` | `.headline`（weight .semibold） | 分组标题、卡片玩物名、空态标题 |
| `body` | `.body` | 正文、输入内容、时间轴一句话 |
| `secondary` | `.subheadline` | 次要说明、按钮内说明 |
| `caption` | `.caption` | 盘玩天数、时间轴日期与 meta |

- 全部使用系统字体（SF Pro，中文自动回退苹方），不引入自定义字体。
- 所有文本默认开启 Dynamic Type（用 TextStyle 而非固定 pt 的地方不得禁缩放）；仅 `display` 圆标可用固定字号。

## 4. 间距与圆角

| Token | 值 | 用途 |
|---|---|---|
| `spaceXS` | 4 | 图标与文字微距 |
| `spaceS` | 8 | 紧凑间距 |
| `spaceM` | 12 | 常规间距、卡片内距 |
| `spaceL` | 16 | 页面左右边距、区块间距 |
| `spaceXL` | 20 | 大区块间距 |
| `spaceXXL` | 24 | 页头留白 |
| `spaceXXXL` | 32 | 空态上下留白 |

- 页面左右统一内边距 `spaceL`(16)；底部 CTA 距安全区 `spaceL`。
- 圆角：`radiusS`=8（芯片、照片缩略图）、`radiusM`=12（卡片、输入框、按钮）、`radiusL`=16（封面大图、占位大图）。

## 5. 阴影（仅两处，克制）

| Token | 值 |
|---|---|
| `cardShadow` | 颜色 `textPrimary` 透明度 5%，radius 10，offset y 3（卡片用） |
| 其他元素 | 一律不用阴影 |

## 6. 组件规范

### 6.1 按钮（三型）

| 型 | 规范 | 用途 |
|---|---|---|
| 主按钮 Primary | `accent` 底 + `onAccent` 字，高 52，圆角 `radiusM`，按压 `accentPressed` | 每页唯一主操作 |
| 次按钮 Secondary | `surface` 底 + `divider` 描边 + `textPrimary` 字，同尺寸 | 重试等次级操作 |
| 危险文字按钮 | 无底，`danger` 字（`body`） | 「删除玩物」入口 |

- 每页主按钮唯一；禁用态 = `disabledFill` 底 + `disabledText` 字；提交中 = 禁用 + 按钮内 `ProgressView`（`onAccent` 色）+ 文案「保存中…」「创建中…」。
- 文案动词开头、≤6 字：进入盘迹 / 开始盘玩 / 创建 / 保存 / 记录今天 / 记录第一天 / 重试。
- 防连点：提交开始即禁用，一次表单仅允许一次提交（裁决 A14）。

### 6.2 卡片

`surface` 底 + `divider` 发丝描边 + `cardShadow`，圆角 `radiusM`。卡片间距 `spaceM`。

### 6.3 封面/图片占位

- 无封面占位（收藏柜卡片、详情大图、创建页封面区）：`accentSoft` 底 + 玩物名首字（`heading`，`textSecondary`）居中；创建页封面区未选时用 SF Symbol `camera`（`accent` 色）+「添加封面」。
- 图片加载失败：见 `docs/design/08-states.md`。

### 6.4 表单行

- 标签：`caption` + `textSecondary`；输入框：`surface` 底 + `divider` 发丝描边，高 48，圆角 `radiusM`；聚焦态描边 `accent`（1.5pt）。
- 占位符 `textTertiary`。多行输入（备注）最小高 88。
- 折叠区（更多信息/更多记录项）：一行 `secondary` 文字 + `chevron.down/up`，展开/收起带动画（`withAnimation(.easeInOut(duration: 0.2))`），默认折叠。

### 6.5 品类芯片

高 36 胶囊形：未选 = `surface` 底 + `divider` 描边 + `textPrimary` 字；选中 = `accentSoft` 底 + `accent` 字 + `accent` 发丝描边；按压 = `surfacePressed`。只用于 5 个种子品类。

### 6.6 时间轴条目

左侧时间轴：竖线 2pt `divider` 色；节点 8pt 圆点 `accent`。条目 = 日期标签（`caption` `textSecondary`）+ 内容卡片：照片缩略图横向滚动行（96×96 正方形，圆角 `radiusS`，间距 `spaceS`，点击全屏预览）→ 一句话（`body`）→ meta 行（`caption` `textSecondary`，仅有时长/方式时显示：「30 分钟 · 手套盘」）。

### 6.7 空态（通用）

垂直居中：`accentSoft` 圆底（96×96）+ SF Symbol（`accent`，36pt）→ 标题（`heading`）→ 说明（`secondary` `textSecondary`，居中）→ 可选 CTA（主按钮，宽 240）。文案见各页线框。

### 6.8 Toast

保存成功：底部悬浮胶囊（`textPrimary` 底 + `background` 字 + `checkmark.circle.fill` 图标），自动 1.5s 消失，触发一次轻触感反馈（success haptic）。仅用于"已保存/已创建"。

### 6.9 确认弹窗（删除）

用系统 `.confirmationDialog`：标题「删除"<玩物名>"？」、消息「它的全部记录和照片会一起删除，无法恢复。」、按钮「删除」（destructive 角色，红）/「取消」。不自定义弹窗样式。

### 6.10 图标

全部使用 SF Symbols（默认字形），不引入第三方图标集。常用：`camera`、`photo`、`plus`、`pencil`、`trash`、`chevron.right/down/up`、`tray`、`checkmark.circle.fill`、`wifi.slash`、`exclamationmark.triangle`、`clock`。

## 7. 文案语气（全 App）

短句、口语、第二人称；不喊口号、不卖惨、不用"尊敬的"。例：「还没有玩物，创建第一件开始吧」而非「您的收藏柜空空如也，快来开启文玩之旅」。

## 8. 页面线框索引

`docs/design/`（每页含 13 项开发规格 + ASCII 线框）：

| 文件 | 页面 |
|---|---|
| `docs/design/00-README.md` | 索引 + 20 步主链覆盖矩阵 |
| `docs/design/01-dev-login.md` | Dev Login |
| `docs/design/02-nickname.md` | 首次资料（昵称） |
| `docs/design/03-cabinet.md` | 收藏柜（含空态） |
| `docs/design/04-create-item.md` | 创建玩物（含品类选择） |
| `docs/design/05-item-detail.md` | 玩物详情 + 成长时间轴（含空态） |
| `docs/design/06-record.md` | 记录今天 + 历史补录 |
| `docs/design/07-edit-delete.md` | 编辑玩物 + 删除确认 |
| `docs/design/08-states.md` | Loading / Error / 图片失败 / 保存失败（全局状态） |

## 9. 体验指标支撑（20 秒 / 10 秒）

- **创建玩物 ≤20 秒**：必填只有名称 + 品类；打开即聚焦名称输入；品类 = 5 芯片一行点击（不跳页）；封面可跳过；选填默认折叠。正常路径 = 输名字（5s）+ 选品类（1 击）+ 选封面（可选 1 击）+ 创建（1 击）。
- **记录一次 ≤10 秒**：默认表单只有照片 + 一句话 + 保存；打开即聚焦输入；更多记录项默认折叠；保存成功 toast 即回详情。正常路径 = 输入一句（5s）+ 选照片（可选 1 击）+ 保存（1 击）。
- 两条路径核心操作均 ≤3 步，符合产品原则。

## 10. 版本记录

| 版本 | 变更 |
|---|---|
| v0 | 占位：4 个暂定基色（apps/ios PanJiTheme.swift 同步实现） |
| v1 | M0-004 定稿：色板补全 18 token、字号 7 级、间距/圆角/阴影、10 类组件规范、文案语气、线框索引、20s/10s 支撑说明；4 个 v0 基色原值保留 |
