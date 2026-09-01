import Foundation
import Observation

/// 玩物详情数据：详情（§3.7）与时间轴记录（§3.12）并行拉取、下拉刷新、401/NOT_FOUND 处理。
@MainActor
@Observable
final class ItemDetailStore {
    enum LoadState: Equatable {
        case loading
        case loaded
        case failed(APIError)
        case notFound   // 玩物已被删除或不存在（契约 §4.10：对外一律 404）
    }

    private(set) var state: LoadState = .loading
    private(set) var item: ItemDetailDTO?
    private(set) var records: [RecordDTO] = []
    private(set) var categories: [CategoryDTO] = []
    /// 已有内容后刷新失败：顶部横幅（保留内容）
    var refreshFailed = false

    private let session: SessionStore
    let itemId: String

    init(session: SessionStore, itemId: String) {
        self.session = session
        self.itemId = itemId
    }

    /// 品类名（头部 chip 展示用）
    var categoryName: String? {
        categories.first { $0.id == item?.categoryId }?.name
    }

    /// 首次加载（含错误态重试）：详情/记录/品类三接口并行
    func load() async {
        state = .loading
        do {
            let (item, records, categories) = try await fetchAll()
            self.item = item
            self.records = records
            self.categories = categories
            state = .loaded
        } catch APIError.authRequired {
            session.signOut()
        } catch APIError.notFound {
            state = .notFound
        } catch let error as APIError {
            state = .failed(error)
        } catch {
            state = .failed(.server)
        }
    }

    /// 下拉刷新：成功替换数据（记录保存后回详情即时刷新 = M1-010 调本方法）；失败保留内容仅横幅
    func refresh() async {
        do {
            let (item, records, _) = try await fetchAll()
            self.item = item
            self.records = records
            refreshFailed = false
            if case .failed = state { state = .loaded }
        } catch APIError.authRequired {
            session.signOut()
        } catch APIError.notFound {
            state = .notFound
        } catch {
            refreshFailed = true
        }
    }

    private func fetchAll() async throws -> (ItemDetailDTO, [RecordDTO], [CategoryDTO]) {
        async let itemResponse: ItemDetailResponse =
            APIClient.shared.request(path: "/items/\(itemId)", token: session.token)
        async let recordsResponse: RecordsResponse =
            APIClient.shared.request(path: "/items/\(itemId)/records", token: session.token)
        async let categoriesResponse: CategoriesResponse =
            APIClient.shared.request(path: "/categories", token: session.token)
        return try await (itemResponse.item, recordsResponse.records, categoriesResponse.categories)
    }
}
