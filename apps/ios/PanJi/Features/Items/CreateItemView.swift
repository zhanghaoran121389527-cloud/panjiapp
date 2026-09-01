import SwiftUI
import PhotosUI

/// 创建玩物（线框 04 · 契约 3.6/3.10）：封面（强引导可跳过）→ 名称/品类必填 → 「更多信息」折叠。
/// 创建成功回调 `onCreated`，由收藏柜关闭 sheet 并自动进入详情（验收②）。
@MainActor
struct CreateItemView: View {
    let session: SessionStore
    let onCreated: (ItemDTO) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var store: CreateItemStore
    @State private var showMore = false
    @State private var coverPickerItem: PhotosPickerItem?
    @FocusState private var nameFocused: Bool
    @FocusState private var subcategoryFocused: Bool
    @FocusState private var sizeFocused: Bool
    @FocusState private var notesFocused: Bool

    init(session: SessionStore, onCreated: @escaping (ItemDTO) -> Void) {
        self.session = session
        self.onCreated = onCreated
        _store = State(initialValue: CreateItemStore(session: session))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: CGFloat.PanJi.spaceL) {
                    coverArea
                    nameField
                    categoryField
                    moreInfoSection
                    if let error = store.createError {
                        Text(error)
                            .font(Font.PanJi.caption)
                            .foregroundStyle(Color.PanJi.danger)
                    }
                }
                .padding(CGFloat.PanJi.spaceL)
            }
            .safeAreaInset(edge: .bottom) {
                createButton
                    .padding(.horizontal, CGFloat.PanJi.spaceL)
                    .padding(.top, CGFloat.PanJi.spaceS)
                    .padding(.bottom, CGFloat.PanJi.spaceL)
                    .background(Color.PanJi.background)
            }
            .navigationTitle("新建玩物")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
            }
            .task {
                try? await Task.sleep(for: .milliseconds(400))  // sheet 弹出后再聚焦，键盘稳定升起
                nameFocused = true
            }
            .task { await store.loadCategories() }
        }
    }

    // MARK: 封面区

    private var coverArea: some View {
        PhotosPicker(selection: $coverPickerItem, matching: .images) {
            ZStack {
                RoundedRectangle(cornerRadius: CGFloat.PanJi.radiusL)
                    .fill(Color.PanJi.accentSoft)
                    .frame(height: 200)
                if let data = store.coverData, let image = UIImage(data: data) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 200)
                        .clipShape(RoundedRectangle(cornerRadius: CGFloat.PanJi.radiusL))
                        .overlay(alignment: .topTrailing) {
                            Button("移除") {
                                store.removeCover()
                            }
                            .font(Font.PanJi.caption)
                            .foregroundStyle(Color.PanJi.danger)
                            .padding(.horizontal, CGFloat.PanJi.spaceM)
                            .padding(.vertical, CGFloat.PanJi.spaceS)
                            .background(Capsule().fill(Color.PanJi.surface.opacity(0.9)))
                            .padding(CGFloat.PanJi.spaceS)
                        }
                        .overlay(alignment: .bottomTrailing) {
                            PhotosPicker(selection: $coverPickerItem, matching: .images) {
                                Text("更换")
                                    .font(Font.PanJi.caption.weight(.semibold))
                                    .foregroundStyle(Color.PanJi.onAccent)
                                    .padding(.horizontal, CGFloat.PanJi.spaceM)
                                    .padding(.vertical, CGFloat.PanJi.spaceS)
                                    .background(Capsule().fill(Color.PanJi.accent))
                            }
                            .padding(CGFloat.PanJi.spaceS)
                        }
                } else {
                    VStack(spacing: CGFloat.PanJi.spaceS) {
                        Image(systemName: "camera")
                            .font(.system(size: 32))
                            .foregroundStyle(Color.PanJi.accent)
                        Text("添加封面")
                            .font(Font.PanJi.secondary)
                            .foregroundStyle(Color.PanJi.textSecondary)
                        Text("（可跳过）")
                            .font(Font.PanJi.caption)
                            .foregroundStyle(Color.PanJi.textTertiary)
                    }
                }
            }
        }
        .onChange(of: coverPickerItem) { _, item in
            guard let item else { return }
            Task {
                if let data = try? await item.loadTransferable(type: Data.self) {
                    store.selectCover(data)
                }
                coverPickerItem = nil
            }
        }
        .overlay(alignment: .bottom) {
            if let error = store.coverError {
                Text(error)
                    .font(Font.PanJi.caption)
                    .foregroundStyle(Color.PanJi.danger)
                    .padding(.bottom, -CGFloat.PanJi.spaceL)
            }
        }
    }

    // MARK: 名称 / 品类

    private var nameField: some View {
        VStack(alignment: .leading, spacing: CGFloat.PanJi.spaceS) {
            Text("名称")
                .font(Font.PanJi.caption)
                .foregroundStyle(Color.PanJi.textSecondary)
            PanJiTextField(placeholder: "如：四座楼狮子头", text: $store.name, isFocused: $nameFocused)
                .onChange(of: store.name) { _, newValue in
                    if newValue.count > 50 { store.name = String(newValue.prefix(50)) }
                }
                .onSubmit { nameFocused = false }
        }
    }

    private var categoryField: some View {
        VStack(alignment: .leading, spacing: CGFloat.PanJi.spaceS) {
            Text("品类")
                .font(Font.PanJi.caption)
                .foregroundStyle(Color.PanJi.textSecondary)
            if store.categories.isEmpty {
                if let error = store.categoriesError {
                    HStack(spacing: CGFloat.PanJi.spaceS) {
                        Text(error)
                            .font(Font.PanJi.caption)
                            .foregroundStyle(Color.PanJi.danger)
                        Button("重试") {
                            Task { await store.loadCategories() }
                        }
                        .font(Font.PanJi.caption)
                        .foregroundStyle(Color.PanJi.accent)
                    }
                } else {
                    ProgressView()
                        .tint(Color.PanJi.accent)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, CGFloat.PanJi.spaceS)
                }
            } else {
                ChipFlowLayout {
                    ForEach(store.categories, id: \.id) { category in
                        CategoryChip(
                            name: category.name,
                            selected: store.categoryId == category.id
                        ) {
                            store.categoryId = category.id
                        }
                    }
                }
            }
        }
    }

    // MARK: 更多信息（折叠）

    private var moreInfoSection: some View {
        VStack(alignment: .leading, spacing: CGFloat.PanJi.spaceM) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) { showMore.toggle() }
            } label: {
                HStack {
                    Text("更多信息")
                        .font(Font.PanJi.secondary)
                        .foregroundStyle(Color.PanJi.textPrimary)
                    Spacer()
                    Image(systemName: showMore ? "chevron.up" : "chevron.down")
                        .foregroundStyle(Color.PanJi.textSecondary)
                }
            }
            if showMore {
                VStack(alignment: .leading, spacing: CGFloat.PanJi.spaceL) {
                    optionalField(label: "子类", placeholder: "如：狮子头", text: $store.subcategory, limit: 50, isFocused: $subcategoryFocused)
                    acquiredDateRow
                    optionalField(label: "尺寸/规格", placeholder: "如：42mm", text: $store.sizeSpec, limit: 100, isFocused: $sizeFocused)
                    VStack(alignment: .leading, spacing: CGFloat.PanJi.spaceS) {
                        Text("备注")
                            .font(Font.PanJi.caption)
                            .foregroundStyle(Color.PanJi.textSecondary)
                        PanJiTextField(placeholder: "写点什么…", text: $store.notes, isFocused: $notesFocused,
                                       axis: .vertical, minHeight: 88)
                            .onChange(of: store.notes) { _, newValue in
                                if newValue.count > 500 { store.notes = String(newValue.prefix(500)) }
                            }
                    }
                }
            }
        }
    }

    private func optionalField(label: String, placeholder: String, text: Binding<String>, limit: Int, isFocused: FocusState<Bool>.Binding) -> some View {
        VStack(alignment: .leading, spacing: CGFloat.PanJi.spaceS) {
            Text(label)
                .font(Font.PanJi.caption)
                .foregroundStyle(Color.PanJi.textSecondary)
            PanJiTextField(placeholder: placeholder, text: text, isFocused: isFocused)
                .onChange(of: text.wrappedValue) { _, newValue in
                    if newValue.count > limit { text.wrappedValue = String(newValue.prefix(limit)) }
                }
        }
    }

    private var acquiredDateRow: some View {
        VStack(alignment: .leading, spacing: CGFloat.PanJi.spaceS) {
            Text("入手日期")
                .font(Font.PanJi.caption)
                .foregroundStyle(Color.PanJi.textSecondary)
            HStack {
                if let date = store.acquiredDate {
                    DatePicker(
                        "",
                        selection: Binding(
                            get: { date },
                            set: { store.acquiredDate = $0 }),
                        in: ...CreateItemStore.endOfBeijingToday(),
                        displayedComponents: .date)
                        .labelsHidden()
                    Button("清除") { store.acquiredDate = nil }
                        .font(Font.PanJi.caption)
                        .foregroundStyle(Color.PanJi.danger)
                } else {
                    Button("选择日期") { store.acquiredDate = Date() }
                        .font(Font.PanJi.body)
                        .foregroundStyle(Color.PanJi.accent)
                }
            }
        }
    }

    // MARK: 主按钮

    private var createButton: some View {
        Button {
            submit()
        } label: {
            if store.submitting {
                HStack(spacing: CGFloat.PanJi.spaceS) {
                    ProgressView().tint(Color.PanJi.onAccent)
                    Text(store.uploadingCover ? "上传封面中…" : "创建中…")
                }
            } else {
                Text("创建")
            }
        }
        .buttonStyle(PanJiPrimaryButtonStyle())
        .disabled(!store.canSubmit)
    }

    private func submit() {
        guard store.canSubmit else { return }
        nameFocused = false
        Task { @MainActor in
            if let item = await store.submit() {
                onCreated(item)
            }
        }
    }
}

/// 品类芯片（DS §6.5）：36 高胶囊，选中 accentSoft+accent，按压 surfacePressed；单选不可取消（线框 04）
private struct CategoryChip: View {
    let name: String
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(name)
                .font(Font.PanJi.body)
                .foregroundStyle(selected ? Color.PanJi.accent : Color.PanJi.textPrimary)
                .padding(.horizontal, CGFloat.PanJi.spaceL)
                .frame(height: 36)
                .background(Capsule().fill(selected ? Color.PanJi.accentSoft : Color.PanJi.surface))
                .overlay(Capsule().strokeBorder(selected ? Color.PanJi.accent : Color.PanJi.divider, lineWidth: 1))
        }
        .buttonStyle(ChipPressButtonStyle())
    }
}

private struct ChipPressButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .overlay(
                Capsule()
                    .fill(Color.PanJi.surfacePressed)
                    .opacity(configuration.isPressed ? 1 : 0)
            )
    }
}

/// 芯片流式换行布局（5 品类自动换行，Dynamic Type 友好）
private struct ChipFlowLayout: Layout {
    var spacing: CGFloat = CGFloat.PanJi.spaceS

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var totalWidth: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x > 0, x + size.width > maxWidth {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
            totalWidth = max(totalWidth, x - spacing)
        }
        let width = maxWidth == .infinity ? totalWidth : maxWidth
        return CGSize(width: width, height: y + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x > bounds.minX, x + size.width > bounds.maxX {
                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}
