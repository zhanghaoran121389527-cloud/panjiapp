import SwiftUI

/// 时间轴条目卡片（线框 05 / DS §6.6）：照片缩略图横滚行（0~N，顺序保持）→ 一句话 → meta 行。
/// 点照片 = 全屏预览（B7）；加载失败缩略图点击 = 重试（08-states C）。
struct TimelineCellView: View {
    let record: RecordDTO

    @State private var previewIndex: Int?
    @State private var showPreview = false

    var body: some View {
        VStack(alignment: .leading, spacing: CGFloat.PanJi.spaceS) {
            if !record.photoUrls.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: CGFloat.PanJi.spaceS) {
                        ForEach(Array(record.photoUrls.enumerated()), id: \.offset) { index, path in
                            TimelineThumb(url: APIClient.shared.imageURL(for: path)) {
                                previewIndex = index
                                showPreview = true
                            }
                        }
                    }
                }
            }
            Text(record.content)
                .font(Font.PanJi.body)
                .foregroundStyle(Color.PanJi.textPrimary)
            if let meta = metaText {
                Text(meta)
                    .font(Font.PanJi.caption)
                    .foregroundStyle(Color.PanJi.textSecondary)
            }
        }
        .padding(CGFloat.PanJi.spaceM)
        .background {
            RoundedRectangle(cornerRadius: CGFloat.PanJi.radiusM)
                .fill(Color.PanJi.surface)
            RoundedRectangle(cornerRadius: CGFloat.PanJi.radiusM)
                .strokeBorder(Color.PanJi.divider, lineWidth: 1)
        }
        .fullScreenCover(isPresented: $showPreview) {
            if let previewIndex {
                PhotoPreviewView(urls: record.photoUrls, initialIndex: previewIndex)
            }
        }
    }

    /// meta 行只显示已填项（线框 05：`30 分钟 · 手套盘`，全空则整行隐藏）
    private var metaText: String? {
        var parts: [String] = []
        if let duration = record.durationMinutes {
            parts.append("\(duration) 分钟")
        }
        if let method = record.method, !method.isEmpty {
            parts.append(method)
        }
        return parts.isEmpty ? nil : parts.joined(separator: " · ")
    }
}

/// 96×96 缩略图：成功显示图；加载中显示 surface 底；失败显示 photo 图标 +「加载失败」，点击重试（08-states C）
private struct TimelineThumb: View {
    let url: URL?
    let onTap: () -> Void

    @State private var retryID = 0
    @State private var failed = false

    var body: some View {
        Button {
            if failed {
                retryID += 1
                failed = false
            } else if url != nil {
                onTap()
            }
        } label: {
            ZStack {
                Color.PanJi.surface
                if let url {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                                .onAppear { failed = false }
                        case .failure:
                            failureLabel
                                .onAppear { failed = true }
                        default:
                            Color.PanJi.surface
                        }
                    }
                    .id(retryID)
                } else {
                    failureLabel
                }
            }
            .frame(width: 96, height: 96)
            .clipShape(RoundedRectangle(cornerRadius: CGFloat.PanJi.radiusS))
        }
        .buttonStyle(.plain)
    }

    private var failureLabel: some View {
        VStack(spacing: CGFloat.PanJi.spaceXS) {
            Image(systemName: "photo")
                .font(.system(size: 20))
                .foregroundStyle(Color.PanJi.textSecondary)
            Text("加载失败")
                .font(Font.PanJi.caption)
                .foregroundStyle(Color.PanJi.textSecondary)
        }
    }
}
