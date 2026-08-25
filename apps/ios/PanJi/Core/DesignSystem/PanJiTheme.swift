import SwiftUI

extension Color {
    /// 盘迹主题色（暂定值，T-004 设计规范 tokens.md 交付后以其为准统一替换）
    enum PanJi {
        /// 暖米白 · 页面背景  #F6F1E7
        static let background = Color(red: 246 / 255, green: 241 / 255, blue: 231 / 255)
        /// 深茶褐 · 主文字  #4A3728
        static let textPrimary = Color(red: 74 / 255, green: 55 / 255, blue: 40 / 255)
        /// 次文字  #8A7B6D
        static let textSecondary = Color(red: 138 / 255, green: 123 / 255, blue: 109 / 255)
        /// 木棕 · 强调  #8C6D4F
        static let accent = Color(red: 140 / 255, green: 109 / 255, blue: 79 / 255)
    }
}
