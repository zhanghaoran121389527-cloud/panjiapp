import SwiftUI

/// 收藏柜卡片（线框 03）：封面 1:1（缺失/失败→accentSoft 首字占位）+ 名称（1 行截断）+ 盘玩天数。
/// 卡片点击进详情由 M1-009 接线，本任务不实现导航。
struct ItemCardView: View {
    let item: ItemDTO

    private var coverURL: URL? {
        guard let path = item.coverImageUrl else { return nil }
        return APIClient.shared.imageURL(for: path)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            cover
                .aspectRatio(1, contentMode: .fit)
                .frame(maxWidth: .infinity)
                .clipped()
            VStack(alignment: .leading, spacing: CGFloat.PanJi.spaceXS) {
                Text(item.name)
                    .font(Font.PanJi.heading)
                    .foregroundStyle(Color.PanJi.textPrimary)
                    .lineLimit(1)
                Text(dayCountText)
                    .font(Font.PanJi.caption)
                    .foregroundStyle(Color.PanJi.textSecondary)
            }
            .padding(CGFloat.PanJi.spaceM)
        }
        .background {
            RoundedRectangle(cornerRadius: CGFloat.PanJi.radiusM)
                .fill(Color.PanJi.surface)
            RoundedRectangle(cornerRadius: CGFloat.PanJi.radiusM)
                .strokeBorder(Color.PanJi.divider, lineWidth: 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: CGFloat.PanJi.radiusM))
        .panjiCardShadow()
    }

    @ViewBuilder
    private var cover: some View {
        if let coverURL {
            AsyncImage(url: coverURL) { phase in
                if case .success(let image) = phase {
                    image.resizable().scaledToFill()
                } else {
                    placeholder  // 加载中/失败静默降级（08-states C）
                }
            }
        } else {
            placeholder
        }
    }

    private var placeholder: some View {
        ZStack {
            Color.PanJi.accentSoft
            Text(String(item.name.prefix(1)))
                .font(Font.PanJi.heading)
                .foregroundStyle(Color.PanJi.textSecondary)
        }
    }

    private var dayCountText: String {
        switch item.dayCount {
        case 0: return "尚未盘玩"
        case 1: return "盘玩 1 天"
        default: return "盘玩 \(item.dayCount) 天"
        }
    }
}
