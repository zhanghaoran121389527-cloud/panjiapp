import SwiftUI

// MARK: - 基础

private extension Color {
    init(panjiHex hex: UInt32) {
        self.init(.sRGB,
                  red: Double((hex >> 16) & 0xFF) / 255,
                  green: Double((hex >> 8) & 0xFF) / 255,
                  blue: Double(hex & 0xFF) / 255,
                  opacity: 1)
    }
}

// MARK: - 色板（DESIGN_SYSTEM v1 §2 · 18 token · M1 仅浅色）

extension Color {
    /// 盘迹色板：公共设计值统一从这里取，禁止各页面自造颜色（DESIGN_SYSTEM 红线）
    enum PanJi {
        static let background = Color(panjiHex: 0xF6F1E7)     // 暖米白 · 页面背景
        static let surface = Color(panjiHex: 0xFFFDF8)        // 卡片 / 输入框 / 弹层
        static let surfacePressed = Color(panjiHex: 0xF2EBDD) // 按压态
        static let textPrimary = Color(panjiHex: 0x4A3728)    // 深茶褐 · 主文字
        static let textSecondary = Color(panjiHex: 0x8A7B6D)  // 次文字
        static let textTertiary = Color(panjiHex: 0xB0A28F)   // 占位符 / 极弱提示
        static let accent = Color(panjiHex: 0x8C6D4F)         // 木棕 · 强调
        static let accentPressed = Color(panjiHex: 0x79593F)
        static let accentSoft = Color(panjiHex: 0xEFE5D3)
        static let onAccent = Color(panjiHex: 0xFFFDF8)       // 主按钮上的文字/图标
        static let divider = Color(panjiHex: 0xE9E0CE)        // 分割线 / 描边
        static let disabledFill = Color(panjiHex: 0xEFE9DB)
        static let disabledText = Color(panjiHex: 0xC7BBA9)
        static let danger = Color(panjiHex: 0xB1502F)         // 删除等危险操作
        static let dangerPressed = Color(panjiHex: 0x98422A)
        static let dangerSoft = Color(panjiHex: 0xF7E8E1)
        static let success = Color(panjiHex: 0x6E7F5B)        // 仅保存成功 toast 图标
        static let scrim = Color.black.opacity(0.4)           // 全屏蒙层
    }
}

// MARK: - 字号字重（DESIGN_SYSTEM v1 §3 · 系统字体 · Dynamic Type）

extension Font {
    enum PanJi {
        static let display = Font.system(size: 40, weight: .semibold)  // 品牌名/圆标内「盘」
        static let navLargeTitle = Font.largeTitle.weight(.semibold)
        static let itemTitle = Font.title3.weight(.semibold)
        static let heading = Font.headline.weight(.semibold)
        static let body = Font.body
        static let secondary = Font.subheadline
        static let caption = Font.caption
    }
}

// MARK: - 间距与圆角（DESIGN_SYSTEM v1 §4）

extension CGFloat {
    enum PanJi {
        static let spaceXS: CGFloat = 4
        static let spaceS: CGFloat = 8
        static let spaceM: CGFloat = 12
        static let spaceL: CGFloat = 16
        static let spaceXL: CGFloat = 20
        static let spaceXXL: CGFloat = 24
        static let spaceXXXL: CGFloat = 32
        static let radiusS: CGFloat = 8
        static let radiusM: CGFloat = 12
        static let radiusL: CGFloat = 16
    }
}

// MARK: - 阴影（DESIGN_SYSTEM v1 §5 · 仅卡片使用）

extension View {
    func panjiCardShadow() -> some View {
        shadow(color: Color.PanJi.textPrimary.opacity(0.05), radius: 10, x: 0, y: 3)
    }
}

// MARK: - 主按钮（DESIGN_SYSTEM v1 §6.1 · 高 52 / radiusM / accent 底 onAccent 字 / 按压与禁用态）

struct PanJiPrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.body.weight(.semibold))
            .foregroundStyle(isEnabled ? Color.PanJi.onAccent : Color.PanJi.disabledText)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(
                RoundedRectangle(cornerRadius: CGFloat.PanJi.radiusM)
                    .fill(fillColor(isPressed: configuration.isPressed))
            )
    }

    private func fillColor(isPressed: Bool) -> Color {
        if !isEnabled { return Color.PanJi.disabledFill }
        return isPressed ? Color.PanJi.accentPressed : Color.PanJi.accent
    }
}

// MARK: - 表单输入框（DESIGN_SYSTEM v1 §6.4 · 高 48 / surface + divider / 聚焦 accent 1.5pt / 占位 textTertiary）

struct PanJiTextField: View {
    let placeholder: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default
    var isFocused: FocusState<Bool>.Binding

    var body: some View {
        HStack(spacing: 0) {
            ZStack(alignment: .leading) {
                if text.isEmpty {
                    Text(placeholder)
                        .font(.body)
                        .foregroundStyle(Color.PanJi.textTertiary)
                }
                TextField("", text: $text)
                    .font(.body)
                    .foregroundStyle(Color.PanJi.textPrimary)
                    .keyboardType(keyboardType)
                    .focused(isFocused)
            }
            .padding(.horizontal, CGFloat.PanJi.spaceM)
        }
        .frame(height: 48)
        .background {
            RoundedRectangle(cornerRadius: CGFloat.PanJi.radiusM)
                .fill(Color.PanJi.surface)
            RoundedRectangle(cornerRadius: CGFloat.PanJi.radiusM)
                .strokeBorder(
                    isFocused.wrappedValue ? Color.PanJi.accent : Color.PanJi.divider,
                    lineWidth: isFocused.wrappedValue ? 1.5 : 1)
        }
    }
}
