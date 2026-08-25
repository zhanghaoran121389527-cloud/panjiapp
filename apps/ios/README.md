# 盘迹 iOS（apps/ios）

M0+M1 盘迹 iOS 客户端。SwiftUI + async/await，最低 iOS 17，仅 iPhone 竖屏。

## 打开与运行

1. macOS 安装 Xcode 15+。
2. 双击 `PanJi.xcodeproj` 打开。
3. 模拟器直接 Run（Debug 默认 API 地址 `http://localhost:3000`）。

真机运行：在 Signing & Capabilities 选择自己的 Team，并按下方说明修改 API 地址。

## 切换 API 地址

编辑 `Config/Config.xcconfig` 中的 `API_BASE_URL`（一处修改，重新构建生效）：

- 模拟器：`http://localhost:3000`
- 真机：改为开发机局域网 IP，如 `http://192.168.1.100:3000`

注意：xcconfig 中 `//` 是注释，URL 里的 `//` 要写成 `/$()/`。

## 目录结构

- `Config/` — xcconfig 构建配置（baseURL 注入）
- `PanJi/App/` — App 入口与根视图
- `PanJi/Core/` — 网络、身份、图片、设计系统（T-106 起逐步填充）
- `PanJi/Features/` — 功能模块（Auth/Items/Records，随任务建立）
- `PanJi/Resources/` — Info.plist、Assets

## 约定

- API 契约见仓库 `docs/API_CONTRACT.md`（v2，业务前缀 `/v1/`），不得私自改字段。
- API_BASE_URL 为「主机根地址，不含路径」；`/v1/...` 与 `/uploads/...` 由网络层拼接（T-106）。
- 主题色暂定值见 `PanJi/Core/DesignSystem/PanJiTheme.swift`，T-004 设计规范交付后统一替换。
