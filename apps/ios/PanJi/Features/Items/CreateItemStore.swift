import Foundation
import Observation

/// 创建玩物表单状态与提交流程（线框 04 · 契约 3.6/3.10）。
/// 上传→创建两段式：上传成功记下相对 URL，创建失败重试不重复上传（08-states D）。
@MainActor
@Observable
final class CreateItemStore {
    var name = ""
    var categoryId: String?
    var subcategory = ""
    var sizeSpec = ""
    var notes = ""
    var acquiredDate: Date?
    var coverData: Data?          // 已选封面原始数据（未上传）
    private(set) var coverURL: String?   // 上传成功后的相对 URL
    private(set) var categories: [CategoryDTO] = []
    private(set) var submitting = false
    private(set) var uploadingCover = false
    var categoriesError: String?
    var coverError: String?
    var createError: String?

    private let session: SessionStore

    private static let beijingTimeZone = TimeZone(identifier: "Asia/Shanghai")!

    init(session: SessionStore) {
        self.session = session
    }

    /// 重选封面：更新原始数据并使已上传 URL 失效（换图后需重新上传）
    func selectCover(_ data: Data) {
        coverData = data
        coverURL = nil
        coverError = nil
    }

    /// 移除封面：清原始数据与已上传 URL（跳过封面入口）
    func removeCover() {
        coverData = nil
        coverURL = nil
        coverError = nil
    }

    var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var canSubmit: Bool {
        !trimmedName.isEmpty && trimmedName.count <= 50
            && categoryId != nil && !submitting && !uploadingCover
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

    /// 提交：有封面先上传拿相对 URL（契约 3.6 规则），再创建。成功返回新玩物。
    func submit() async -> ItemDTO? {
        guard canSubmit else { return nil }
        submitting = true
        createError = nil
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
        do {
            let request = CreateItemRequest(
                name: trimmedName,
                categoryId: categoryId,
                coverImageUrl: url,
                subcategory: Self.nilIfBlank(subcategory),
                acquiredDate: acquiredDate.map(acquiredDateString),
                sizeSpec: Self.nilIfBlank(sizeSpec),
                notes: Self.nilIfBlank(notes))
            let response: ItemResponse = try await APIClient.shared.request(
                method: "POST", path: "/items", body: request, token: session.token)
            return response.item
        } catch APIError.authRequired {
            session.signOut()
            return nil
        } catch let error as APIError {
            createError = error.userMessage ?? "创建失败，请重试"
            return nil
        } catch {
            createError = "创建失败，请重试"
            return nil
        }
    }

    /// 入手日期 → `YYYY-MM-DD`（裁决 A8：日期按北京时间解释）
    func acquiredDateString(_ date: Date) -> String {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = Self.beijingTimeZone
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", components.year ?? 0, components.month ?? 0, components.day ?? 0)
    }

    /// 入手日期上限：北京时间今天 23:59:59（线框 04）
    static func endOfBeijingToday() -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = beijingTimeZone
        return calendar.startOfDay(for: Date()).addingTimeInterval(86_399)
    }

    private static func nilIfBlank(_ text: String) -> String? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
