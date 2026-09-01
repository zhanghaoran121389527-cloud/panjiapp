import SwiftUI

/// 玩物详情（线框 05 · 契约 3.7/3.12）：封面大图 + 名称/品类/盘玩天数 + 成长时间轴 + 底部常驻「记录今天」。
/// 「记录」入口 = M1-010 接线点；「编辑」入口 = M1-011 接线点（当前均为占位 sheet）。
@MainActor
struct ItemDetailView: View {
    let session: SessionStore
    let itemId: String

    @State private var store: ItemDetailStore
    @State private var showRecordPlaceholder = false
    @State private var showEditPlaceholder = false

    init(session: SessionStore, itemId: String) {
        self.session = session
        self.itemId = itemId
        _store = State(initialValue: ItemDetailStore(session: session, itemId: itemId))
    }

    var body: some View {
        ZStack {
            Color.PanJi.background.ignoresSafeArea()
            switch store.state {
            case .loading:
                detailSkeleton
            case .failed(let error):
                loadFailedView(error)
            case .notFound:
                notFoundView
            case .loaded:
                if let item = store.item {
                    content(item)
                }
            }
        }
        .navigationTitle(store.item?.name ?? "")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("编辑") { showEditPlaceholder = true }   // 验收⑤ 编辑入口可达
            }
        }
        .sheet(isPresented: $showRecordPlaceholder, onDismiss: {
            Task { await store.refresh() }   // 记录保存后回详情即时刷新（验收④；M1-010 替换本 sheet）
        }) {
            RecordPlaceholderView()
        }
        .sheet(isPresented: $showEditPlaceholder) {
            EditPlaceholderView()
        }
        .task { await store.load() }
    }

    // MARK: 已加载内容

    private func content(_ item: ItemDetailDTO) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: CGFloat.PanJi.spaceL) {
                if store.refreshFailed {
                    Text("刷新失败，下拉重试")
                        .font(Font.PanJi.caption)
                        .foregroundStyle(Color.PanJi.danger)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, CGFloat.PanJi.spaceS)
                        .background(Color.PanJi.dangerSoft)
                }
                coverHero(item)
                VStack(alignment: .leading, spacing: CGFloat.PanJi.spaceXS) {
                    Text(item.name)
                        .font(Font.PanJi.itemTitle)
                        .foregroundStyle(Color.PanJi.textPrimary)
                    HStack(spacing: CGFloat.PanJi.spaceS) {
                        if let categoryName = store.categoryName {
                            Text(categoryName)
                                .font(Font.PanJi.caption)
                                .foregroundStyle(Color.PanJi.accent)
                                .padding(.horizontal, CGFloat.PanJi.spaceM)
                                .padding(.vertical, CGFloat.PanJi.spaceXS)
                                .background(Capsule().fill(Color.PanJi.accentSoft))
                        }
                        Text(headerStats(item))
                            .font(Font.PanJi.secondary)
                            .foregroundStyle(Color.PanJi.textSecondary)
                    }
                }
                TimelineView(records: store.records) {
                    showRecordPlaceholder = true
                }
            }
            .padding(CGFloat.PanJi.spaceL)
        }
        .refreshable { await store.refresh() }
        .safeAreaInset(edge: .bottom) {
            Button {
                showRecordPlaceholder = true
            } label: {
                Text(store.records.isEmpty ? "记录第一天" : "记录今天")
            }
            .buttonStyle(PanJiPrimaryButtonStyle())
            .padding(.horizontal, CGFloat.PanJi.spaceL)
            .padding(.vertical, CGFloat.PanJi.spaceS)
            .background(Color.PanJi.background)
        }
    }

    /// 头部信息：`盘玩第 X 天 · N 次记录`（X 用服务端 dayCount，客户端不算，契约 §4.1）
    private func headerStats(_ item: ItemDetailDTO) -> String {
        let dayText = item.dayCount > 0 ? "盘玩第 \(item.dayCount) 天" : "尚未开始盘玩"
        return "\(dayText) · \(store.records.count) 次记录"
    }

    /// 封面大图 1:1 radiusL；无封面/加载中/失败 → accentSoft + 首字占位（08-states C 静默降级）
    @ViewBuilder
    private func coverHero(_ item: ItemDetailDTO) -> some View {
        if let path = item.coverImageUrl, let url = APIClient.shared.imageURL(for: path) {
            AsyncImage(url: url) { phase in
                if case .success(let image) = phase {
                    image
                        .resizable()
                        .scaledToFill()
                } else {
                    coverPlaceholder(item)
                }
            }
            .aspectRatio(1, contentMode: .fit)
            .frame(maxWidth: .infinity)
            .clipShape(RoundedRectangle(cornerRadius: CGFloat.PanJi.radiusL))
        } else {
            coverPlaceholder(item)
                .aspectRatio(1, contentMode: .fit)
                .frame(maxWidth: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: CGFloat.PanJi.radiusL))
        }
    }

    private func coverPlaceholder(_ item: ItemDetailDTO) -> some View {
        ZStack {
            Color.PanJi.accentSoft
            Text(String(item.name.prefix(1)))
                .font(Font.PanJi.heading)
                .foregroundStyle(Color.PanJi.textSecondary)
        }
    }

    // MARK: 加载 / 错误 / 删除态

    /// 首载骨架（08-states：1 大图 + 3 条目色块呼吸，无文字线条）
    private var detailSkeleton: some View {
        VStack(alignment: .leading, spacing: CGFloat.PanJi.spaceL) {
            SkeletonBlock()
                .aspectRatio(1, contentMode: .fit)
            ForEach(0..<3, id: \.self) { _ in
                SkeletonBlock()
                    .frame(height: 88)
            }
            Spacer()
        }
        .padding(CGFloat.PanJi.spaceL)
    }

    private func loadFailedView(_ error: APIError) -> some View {
        VStack(spacing: CGFloat.PanJi.spaceM) {
            ZStack {
                Circle()
                    .fill(Color.PanJi.accentSoft)
                    .frame(width: 96, height: 96)
                Image(systemName: error == .networkUnreachable ? "wifi.slash" : "exclamationmark.triangle")
                    .font(.system(size: 36))
                    .foregroundStyle(Color.PanJi.accent)
            }
            Text(error == .networkUnreachable ? "网络不太顺畅" : "出了点问题")
                .font(Font.PanJi.heading)
                .foregroundStyle(Color.PanJi.textPrimary)
            Text(error == .networkUnreachable ? "请检查网络后重试" : "请稍后再试")
                .font(Font.PanJi.secondary)
                .foregroundStyle(Color.PanJi.textSecondary)
            Button("重试") {
                Task { await store.load() }
            }
            .buttonStyle(PanJiPrimaryButtonStyle())
            .frame(width: 240)
            .padding(.top, CGFloat.PanJi.spaceS)
        }
    }

    /// 玩物已被删除（线框 05）：提示 + 返回收藏柜（返回后收藏柜自动刷新列表）
    private var notFoundView: some View {
        @Environment(\.dismiss) var dismiss
        return VStack(spacing: CGFloat.PanJi.spaceM) {
            ZStack {
                Circle()
                    .fill(Color.PanJi.accentSoft)
                    .frame(width: 96, height: 96)
                Image(systemName: "exclamationmark.triangle")
                    .font(.system(size: 36))
                    .foregroundStyle(Color.PanJi.accent)
            }
            Text("这件玩物不存在或已被删除")
                .font(Font.PanJi.heading)
                .foregroundStyle(Color.PanJi.textPrimary)
            Button("返回收藏柜") { dismiss() }
                .buttonStyle(PanJiPrimaryButtonStyle())
                .frame(width: 240)
                .padding(.top, CGFloat.PanJi.spaceS)
        }
    }
}

/// 骨架色块（呼吸动画，08-states）
private struct SkeletonBlock: View {
    @State private var pulse = false

    var body: some View {
        RoundedRectangle(cornerRadius: CGFloat.PanJi.radiusM)
            .fill(Color.PanJi.surface)
            .frame(maxWidth: .infinity)
            .opacity(pulse ? 1.0 : 0.6)
            .animation(.easeInOut(duration: 1).repeatForever(autoreverses: true), value: pulse)
            .onAppear { pulse = true }
    }
}

/// 记录入口临时占位（M1-010 以真实记录页替换）
private struct RecordPlaceholderView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color.PanJi.background.ignoresSafeArea()
                Text("记录盘玩将在 M1-010 实现")
                    .font(Font.PanJi.secondary)
                    .foregroundStyle(Color.PanJi.textSecondary)
            }
            .navigationTitle("记录")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("关闭") { dismiss() }
                }
            }
        }
    }
}

/// 编辑入口临时占位（M1-011 以真实编辑页替换）
private struct EditPlaceholderView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color.PanJi.background.ignoresSafeArea()
                Text("编辑玩物将在 M1-011 实现")
                    .font(Font.PanJi.secondary)
                    .foregroundStyle(Color.PanJi.textSecondary)
            }
            .navigationTitle("编辑玩物")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("关闭") { dismiss() }
                }
            }
        }
    }
}
