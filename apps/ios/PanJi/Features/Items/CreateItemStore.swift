import Foundation
import Observation

/// 玩物表单状态与提交流程（线框 04/07 · 契约 3.6/3.8/3.9/3.10）。
/// 双模式：创建（POST）与编辑（PATCH + 删除），编辑复用同一表单与上传两段式。
@MainActor
@Observable
final class CreateItemStore {
    var name = ""
    var categoryId: String?
    var subcategory = ""
    var sizeSpec = ""
    var notes = ""
    var acquiredDate: Date?
    var coverData: Data?                       // 已选封面原始数据（未上传）
    private(set) var coverURL: String?         // 封面相对 URL（编辑=当前值；创建=上传结果）
    private(set) var categories: [CategoryDTO] = []
    private(set) var submitting = false
    private(set) var uploadingCover = false
    private(set) var deleting = false
    var categoriesError: String?
    var coverError: String?
    var saveError: String?
    var deleteError: String?

    private let session: SessionStore
    private let editingItem: ItemDetailDTO?

    init(session: SessionStore, editingItem: ItemDetailDTO? = nil) {
        self.session = session
        self.editingItem = editingItem
        if let item = editingItem {
            name = item.name
            categoryId = item.categoryId
            subcategory = item.subcategory ?? ""
            sizeSpec = item.sizeSpec ?? ""
            notes = item.notes ?? ""
            acquiredDate = item.acquiredDate.flatMap { BeijingDate.date(from: $0) }
            coverURL = item.coverImageUrl
        }
    }

    var isEditing: Bool { editingItem != nil }
    var editingItemName: String? { editingItem?.name }

    /// 编辑模式「更多信息」默认展开条件：有已填选填项（线框 07）
    var shouldExpandMore: Bool {
        guard editingItem != nil else { return false }
        return !subcategory.isEmpty || !sizeSpec.isEmpty || !notes.isEmpty || acquiredDate != nil
    }

    /// 重选封面：更新原始数据并使已上传 URL 失效（换图后需重新上传）
    func selectCover(_ data: Data) {
        coverData = data
        coverURL = nil
        coverError = nil
    }

    /// 移除封面：清原始数据与 URL（编辑模式 PATCH 传 null 清空，契约 3.8 规则）
    func removeCover() {
        coverData = nil
        coverURL = nil
        coverError = nil
    }

    var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// 编辑模式：任一字段与原值不同即算有变化（无变化禁用保存，线框 07）
    var hasChanges: Bool {
        guard let item = editingItem else { return true }
        if trimmedName != item.name { return true }
        if categoryId != item.categoryId { return true }
        if Self.trimmed(subcategory) != (item.subcategory ?? "") { return true }
        if Self.trimmed(sizeSpec) != (item.sizeSpec ?? "") { return true }
        if Self.trimmed(notes) != (item.notes ?? "") { return true }
        let currentDate = acquiredDate.map { BeijingDate.string(from: $0) }
        if currentDate != item.acquiredDate { return true }
        if coverData != nil { return true }
        if coverURL != item.coverImageUrl { return true }
        return false
    }

    var canSubmit: Bool {
        !trimmedName.isEmpty && trimmedName.count <= 50
            && categoryId != nil && !submitting && !uploadingCover && !deleting
            && (isEditing ? hasChanges : true)
    }

    func loadCategories() async {
        do {
            let response: CategoriesResponse = try await APIClient.shared.request(
                path: "/categories", token: session.token)
            categories = response.categories
            categoriesError = nil
        } catch APIError.authRequired {
            session.signOut()
        } catch let error as APIError {
            categoriesError = error.userMessage ?? "品类加载失败"
        } catch {
            categoriesError = "品类加载失败，请重试"
        }
    }

    /// 提交：有封面先上传拿相对 URL，再创建（POST）/编辑（PATCH）。成功返回玩物。
    /// 编辑采用整单重发（等价于"只发变化字段"的行为：未动字段回传原值、清空字段传 null，契约 3.8 合法）。
    func submit() async -> ItemDTO? {
        guard canSubmit else { return nil }
        submitting = true
        saveError = nil
        defer { submitting = false }

        var url = coverURL
        if url == nil, let data = coverData {
            uploadingCover = true
            coverError = nil
            defer { uploadingCover = false }
            do {
                let mime = APIClient.mimeType(for: data)
                let response: UploadResponse = try await APIClient.shared.uploadImage(
                    data: data,
                    mimeType: mime,
                    filename: "cover.\(APIClient.fileExtension(for: mime))",
                    token: session.token)
                url = response.url
                coverURL = response.url
            } catch APIError.authRequired {
                session.signOut()
                return nil
            } catch let error as APIError {
                coverError = error.userMessage ?? "上传失败，请重试"
                return nil
            } catch {
                coverError = "上传失败，请重试"
                return nil
            }
        }

        guard let categoryId else { return nil }
        let method = isEditing ? "PATCH" : "POST"
        let path = editingItem.map { "/items/\($0.id)" } ?? "/items"
        do {
            let request = CreateItemRequest(
                name: trimmedName,
                categoryId: categoryId,
                coverImageUrl: url,
                subcategory: Self.nilIfBlank(subcategory),
                acquiredDate: acquiredDate.map { BeijingDate.string(from: $0) },
                sizeSpec: Self.nilIfBlank(sizeSpec),
                notes: Self.nilIfBlank(notes))
            let response: ItemResponse = try await APIClient.shared.request(
                method: method, path: path, body: request, token: session.token)
            return response.item
        } catch APIError.authRequired {
            session.signOut()
            return nil
        } catch let error as APIError {
            saveError = error.userMessage ?? "没保存成功，请重试"
            return nil
        } catch {
            saveError = "没保存成功，请重试"
            return nil
        }
    }

    /// 删除玩物（契约 3.9：逻辑删除，204 成功；不存在/他人/已删 → 404）
    func delete() async -> Bool {
        guard let item = editingItem, !deleting else { return false }
        deleting = true
        deleteError = nil
        defer { deleting = false }
        do {
            try await APIClient.shared.delete(path: "/items/\(item.id)", token: session.token)
            return true
        } catch APIError.authRequired {
            session.signOut()
            return false
        } catch let error as APIError {
            deleteError = error == .notFound
                ? (error.userMessage ?? "删除失败，请重试")
                : "删除失败，请重试"
            return false
        } catch {
            deleteError = "删除失败，请重试"
            return false
        }
    }

    private static func trimmed(_ text: String) -> String {
        text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func nilIfBlank(_ text: String) -> String? {
        let trimmed = trimmed(text)
        return trimmed.isEmpty ? nil : trimmed
    }
}
