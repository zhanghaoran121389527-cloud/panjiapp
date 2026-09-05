import SwiftUI

/// 编辑玩物（线框 07 · 契约 3.8/3.9/3.10）：复用 CreateItemView 表单（预填 + PATCH + 删除入口）。
/// 保存成功回调 `onSaved`（详情 toast + 回刷）；删除成功回调 `onDeleted`（详情页一并返回收藏柜）。
@MainActor
struct EditItemView: View {
    let session: SessionStore
    let item: ItemDetailDTO
    let onSaved: () -> Void
    let onDeleted: () -> Void

    var body: some View {
        CreateItemView(
            session: session,
            onSaved: { _ in onSaved() },
            item: item,
            onDeleted: onDeleted)
    }
}
