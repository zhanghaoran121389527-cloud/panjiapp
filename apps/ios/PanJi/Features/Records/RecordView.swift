import SwiftUI
import PhotosUI

/// 记录今天 + 历史补录（线框 06 · 契约 3.10/3.11）：默认只有「照片 + 一句话 + 保存」；
/// 「更多记录项」折叠出 记录日期（上限=北京今天，过去=补录）/盘玩时长/盘玩方式。
/// 保存成功 → 关闭 sheet 并回调 `onSaved`（详情页 toast + onDismiss 回刷，M1-009 已接线）。
@MainActor
struct RecordView: View {
    let session: SessionStore
    let itemId: String
    let onSaved: () -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var store: RecordStore
    @State private var showMore = false
    @State private var pickerItems: [PhotosPickerItem] = []
    @State private var showDiscardConfirm = false
    @FocusState private var contentFocused: Bool

    private let gridColumns = Array(
        repeating: GridItem(.flexible(), spacing: CGFloat.PanJi.spaceS), count: 3)

    init(session: SessionStore, itemId: String, onSaved: @escaping () -> Void) {
        self.session = session
        self.itemId = itemId
        self.onSaved = onSaved
        _store = State(initialValue: RecordStore(session: session, itemId: itemId))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: CGFloat.PanJi.spaceL) {
                    photoGrid
                    if store.photoError {
                        Text("这张没传成功，点按重试")
                            .font(Font.PanJi.caption)
                            .foregroundStyle(Color.PanJi.danger)
                    }
                    contentField
                    moreSection
                    if let error = store.saveError {
                        Text(error)
                            .font(Font.PanJi.caption)
                            .foregroundStyle(Color.PanJi.danger)
                    }
                }
                .padding(CGFloat.PanJi.spaceL)
            }
            .safeAreaInset(edge: .bottom) {
                saveButton
                    .padding(.horizontal, CGFloat.PanJi.spaceL)
                    .padding(.top, CGFloat.PanJi.spaceS)
                    .padding(.bottom, CGFloat.PanJi.spaceL)
                    .background(Color.PanJi.background)
            }
            .navigationTitle("记录今天")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        if store.hasUnsavedChanges {
                            showDiscardConfirm = true
                        } else {
                            dismiss()
                        }
                    } label: {
                        Image(systemName: "xmark")
                    }
                }
            }
            .confirmationDialog("放弃这次记录？", isPresented: $showDiscardConfirm, titleVisibility: .visible) {
                Button("放弃", role: .destructive) { dismiss() }
                Button("继续编辑", role: .cancel) {}
            }
            .task {
                try? await Task.sleep(for: .milliseconds(400))  // sheet 弹出后再聚焦，10 秒体验起点
                contentFocused = true
            }
        }
    }

    // MARK: 照片区（0~N，多选，顺序=选择顺序；添加格始终在最后）

    private var photoGrid: some View {
        LazyVGrid(columns: gridColumns, spacing: CGFloat.PanJi.spaceS) {
            ForEach(Array(store.photoStates.enumerated()), id: \.offset) { index, state in
                PhotoCell(state: state,
                          onRemove: { store.removePhoto(at: index) },
                          onRetry: { Task { await store.retryPhoto(at: index) } })
            }
            PhotosPicker(selection: $pickerItems, matching: .images) {
                ZStack {
                    Color.PanJi.accentSoft
                    Image(systemName: "camera")
                        .font(.system(size: 24))
                        .foregroundStyle(Color.PanJi.accent)
                }
                .aspectRatio(1, contentMode: .fit)
                .clipShape(RoundedRectangle(cornerRadius: CGFloat.PanJi.radiusS))
            }
            .onChange(of: pickerItems) { _, items in
                Task {
                    var loaded: [Data] = []
                    for item in items {
                        if let data = try? await item.loadTransferable(type: Data.self) {
                            loaded.append(data)
                        }
                    }
                    if !loaded.isEmpty {
                        store.addPhotos(loaded)   // 选择顺序即展示顺序（验收③）
                    }
                    pickerItems = []
                }
            }
        }
    }

    // MARK: 一句话（唯一必填，打开即聚焦，1~500 截断）

    private var contentField: some View {
        PanJiTextField(placeholder: "今天怎么样？", text: $store.content,
                       isFocused: $contentFocused, axis: .vertical, minHeight: 88)
            .onChange(of: store.content) { _, newValue in
                if newValue.count > 500 { store.content = String(newValue.prefix(500)) }
            }
    }

    // MARK: 更多记录项（默认折叠）

    private var moreSection: some View {
        VStack(alignment: .leading, spacing: CGFloat.PanJi.spaceM) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) { showMore.toggle() }
            } label: {
                HStack {
                    Text("更多记录项")
                        .font(Font.PanJi.secondary)
                        .foregroundStyle(Color.PanJi.textPrimary)
                    Spacer()
                    Image(systemName: showMore ? "chevron.up" : "chevron.down")
                        .foregroundStyle(Color.PanJi.textSecondary)
                }
            }
            if showMore {
                VStack(alignment: .leading, spacing: CGFloat.PanJi.spaceL) {
                    recordedDateRow
                    durationRow
                    methodField
                }
            }
        }
    }

    private var recordedDateRow: some View {
        VStack(alignment: .leading, spacing: CGFloat.PanJi.spaceS) {
            Text("记录日期")
                .font(Font.PanJi.caption)
                .foregroundStyle(Color.PanJi.textSecondary)
            DatePicker(
                "",
                selection: Binding(
                    get: { store.recordedDate },
                    set: { store.setRecordedDate($0) }),
                in: ...BeijingDate.endOfToday(),   // 上限=北京今天，未来日期灰置（验收⑤）
                displayedComponents: .date)
                .labelsHidden()
        }
    }

    private var durationRow: some View {
        HStack {
            Text("盘玩时长")
                .font(Font.PanJi.caption)
                .foregroundStyle(Color.PanJi.textSecondary)
            Spacer()
            Stepper(value: $store.durationMinutes, in: 0...1440, step: 5) {
                Text(store.durationMinutes > 0 ? "\(store.durationMinutes) 分钟" : "未记录")
                    .font(Font.PanJi.body)
                    .foregroundStyle(Color.PanJi.textPrimary)
            }
        }
    }

    private var methodField: some View {
        VStack(alignment: .leading, spacing: CGFloat.PanJi.spaceS) {
            Text("盘玩方式")
                .font(Font.PanJi.caption)
                .foregroundStyle(Color.PanJi.textSecondary)
            PanJiTextField(placeholder: "如：手套盘", text: $store.method, isFocused: $methodFocused)
                .onChange(of: store.method) { _, newValue in
                    if newValue.count > 20 { store.method = String(newValue.prefix(20)) }
                }
        }
    }

    @FocusState private var methodFocused: Bool

    // MARK: 保存

    private var saveButton: some View {
        Button {
            submit()
        } label: {
            if store.submitting {
                HStack(spacing: CGFloat.PanJi.spaceS) {
                    ProgressView().tint(Color.PanJi.onAccent)
                    Text("保存中…")
                }
            } else {
                Text("保存")
            }
        }
        .buttonStyle(PanJiPrimaryButtonStyle())
        .disabled(!store.canSubmit)
    }

    private func submit() {
        guard store.canSubmit else { return }
        contentFocused = false
        Task { @MainActor in
            if await store.submit() != nil {
                dismiss()
                onSaved()
            }
        }
    }
}

/// 单张照片格子：本地图 + 右上「×」移除；上传中 spinner；失败置灰点击重试
private struct PhotoCell: View {
    let state: RecordStore.PhotoState
    let onRemove: () -> Void
    let onRetry: () -> Void

    var body: some View {
        ZStack {
            Color.PanJi.surface
            if let data = displayData, let image = UIImage(data: data) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .opacity(isFailed ? 0.45 : 1)
            }
            if case .uploading = state {
                ProgressView()
                    .tint(Color.PanJi.accent)
            }
            if isFailed {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 20))
                    .foregroundStyle(Color.PanJi.textSecondary)
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: CGFloat.PanJi.radiusS))
        .contentShape(Rectangle())
        .onTapGesture {
            if isFailed { onRetry() }
        }
        .overlay(alignment: .topTrailing) {
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(Color.PanJi.textPrimary.opacity(0.8))
                    .background(Circle().fill(.white.opacity(0.9)))
            }
            .padding(4)
        }
    }

    private var displayData: Data? {
        switch state {
        case .local(let data), .uploading(let data), .failed(let data), .uploaded(_, let data):
            return data
        }
    }

    private var isFailed: Bool {
        if case .failed = state { return true }
        return false
    }
}
