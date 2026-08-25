import SwiftUI

/// 详情占位（验收②链路用）：创建成功自动进入本页证明导航正确。
/// M1-009 以真实详情页（大图 + 成长时间轴）替换本视图，勿外扩。
struct ItemDetailPlaceholderView: View {
    let item: ItemDTO

    var body: some View {
        ZStack {
            Color.PanJi.background.ignoresSafeArea()
            VStack(spacing: CGFloat.PanJi.spaceM) {
                Text(item.name)
                    .font(Font.PanJi.itemTitle)
                    .foregroundStyle(Color.PanJi.textPrimary)
                Text("详情页将在 M1-009 实现")
                    .font(Font.PanJi.secondary)
                    .foregroundStyle(Color.PanJi.textSecondary)
            }
        }
        .navigationTitle(item.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}
