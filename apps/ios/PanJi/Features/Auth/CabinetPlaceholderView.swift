import SwiftUI

/// 收藏柜占位（M1-006 验收①终点；正式收藏柜由 M1-007 替换本视图）
struct CabinetPlaceholderView: View {
    let nickname: String

    var body: some View {
        VStack(spacing: CGFloat.PanJi.spaceM) {
            Text("你好，\(nickname)")
                .font(Font.PanJi.heading)
                .foregroundStyle(Color.PanJi.textPrimary)
            Text("收藏柜将在 M1-007 实现")
                .font(Font.PanJi.secondary)
                .foregroundStyle(Color.PanJi.textSecondary)
        }
        .navigationTitle("收藏柜")
    }
}
