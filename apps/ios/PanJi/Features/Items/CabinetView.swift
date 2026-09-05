import SwiftUI

/// 收藏柜（线框 03 · 契约 3.4/3.5）：品类分组陈列 + 空态引导 + 下拉刷新 + DEBUG-only 切号（裁决 B8）。
@MainActor
struct CabinetView: View {
    let session: SessionStore

    @State private var store: CabinetStore
    @State private var showCreate = false
    @State private var detailItem: ItemDTO?
    @State private var showDetail = false

    init(session: SessionStore) {
        self.session = session
        _store = State(initialValue: CabinetStore(session: session))
    }

    private let columns = [
        GridItem(.flexible(), spacing: CGFloat.PanJi.spaceM),
        GridItem(.flexible(), spacing: CGFloat.PanJi.spaceM),
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: CGFloat.PanJi.spaceM) {
                if store.refreshFailed {
                    Text("刷新失败，下拉重试")
                        .font(Font.PanJi.caption)
                        .foregroundStyle(Color.PanJi.danger)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, CGFloat.PanJi.spaceS)
                        .background(Color.PanJi.dangerSoft)
                }

                switch store.state {
                case .loading:
                    skeletonGrid
                case .failed(let error):
                    loadFailedView(error)
                        .padding(.top, 120)
                case .loaded:
                    if store.sections.isEmpty {
                        emptyView
                            .padding(.top, 120)
                    } else {
                        LazyVStack(alignment: .leading, spacing: CGFloat.PanJi.spaceXL) {
                            ForEach(store.sections, id: \.category.id) { section in
                                VStack(alignment: .leading, spacing: CGFloat.PanJi.spaceM) {
                                    Text(section.category.name)
                                        .font(Font.PanJi.heading)
                                        .foregroundStyle(Color.PanJi.textPrimary)
                                    LazyVGrid(columns: columns, spacing: CGFloat.PanJi.spaceM) {
                                        ForEach(section.items, id: \.id) { item in
                                            Button {
                                                detailItem = item
                                                showDetail = true
                                            } label: {
                                                ItemCardView(item: item)
                                            }
                                            .buttonStyle(.plain)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, CGFloat.PanJi.spaceL)
            .padding(.top, CGFloat.PanJi.spaceS)
        }
        .navigationTitle("收藏柜")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showCreate = true
                } label: {
                    Image(systemName: "plus")
                }
            }
            #if DEBUG
            ToolbarItem(placement: .topBarTrailing) {
                Button("开发：切换账号") {
                    session.signOut()
                }
            }
            #endif
        }
        .sheet(isPresented: $showCreate) {
            CreateItemView(session: session, onSaved: { item in
                showCreate = false
                detailItem = item
                showDetail = true
                Task { await store.refresh() }
            })
        }
        .navigationDestination(isPresented: $showDetail) {
            if let detailItem {
                ItemDetailView(session: session, itemId: detailItem.id)
            }
        }
        .onChange(of: showDetail) { _, newValue in
            if !newValue {
                Task { await store.refresh() }   // 详情返回回刷（线框 03 注意事项）
            }
        }
        .refreshable { await store.refresh() }
        .task { await store.load() }
        .task(id: store.refreshFailed) {
            guard store.refreshFailed else { return }
            try? await Task.sleep(for: .seconds(3))
            store.refreshFailed = false
        }
    }

    /// 首次加载骨架（08-states：4 个 surface 色块呼吸动画，无文字线条）
    private var skeletonGrid: some View {
        LazyVGrid(columns: columns, spacing: CGFloat.PanJi.spaceM) {
            ForEach(0..<4, id: \.self) { _ in
                SkeletonCard()
            }
        }
    }

    /// 空态（线框 03）：tray 图标 + 标题 + 说明 + CTA；与右上角「+」行为一致
    private var emptyView: some View {
        VStack(spacing: CGFloat.PanJi.spaceM) {
            ZStack {
                Circle()
                    .fill(Color.PanJi.accentSoft)
                    .frame(width: 96, height: 96)
                Image(systemName: "tray")
                    .font(.system(size: 36))
                    .foregroundStyle(Color.PanJi.accent)
            }
            Text("还没有玩物")
                .font(Font.PanJi.heading)
                .foregroundStyle(Color.PanJi.textPrimary)
            Text("创建第一件玩物，开始记录它的变化")
                .font(Font.PanJi.secondary)
                .foregroundStyle(Color.PanJi.textSecondary)
                .multilineTextAlignment(.center)
            Button("创建第一件玩物") {
                showCreate = true
            }
            .buttonStyle(PanJiPrimaryButtonStyle())
            .frame(width: 240)
            .padding(.top, CGFloat.PanJi.spaceS)
        }
    }

    /// 首次加载失败的整页错误态（08-states A）
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
            Text(title(for: error))
                .font(Font.PanJi.heading)
                .foregroundStyle(Color.PanJi.textPrimary)
            Text(description(for: error))
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

    private func title(for error: APIError) -> String {
        error == .networkUnreachable ? "网络不太顺畅" : "出了点问题"
    }

    private func description(for error: APIError) -> String {
        error == .networkUnreachable ? "请检查网络后重试" : "请稍后再试"
    }
}

/// 骨架卡片：呼吸动画（08-states 加载规范）
private struct SkeletonCard: View {
    @State private var pulse = false

    var body: some View {
        RoundedRectangle(cornerRadius: CGFloat.PanJi.radiusM)
            .fill(Color.PanJi.surface)
            .aspectRatio(1.35, contentMode: .fit)
            .opacity(pulse ? 1.0 : 0.6)
            .animation(.easeInOut(duration: 1).repeatForever(autoreverses: true), value: pulse)
            .onAppear { pulse = true }
    }
}
