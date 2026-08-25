import Foundation
import Observation

/// 收藏柜数据：品类与玩物拉取、客户端分组、下拉刷新、401 全局处理。View 不直接发请求。
@MainActor
@Observable
final class CabinetStore {
    enum LoadState: Equatable {
        case loading
        case loaded
        case failed(APIError)
    }

    private(set) var state: LoadState = .loading
    private(set) var items: [ItemDTO] = []
    private(set) var categories: [CategoryDTO] = []
    /// 已有内容后刷新失败：顶部横幅（不清空已显示内容，08-states）
    var refreshFailed = false

    private let session: SessionStore

    init(session: SessionStore) {
        self.session = session
    }

    /// 品类分组：仅含有玩物的品类，顺序按 sort_order（服务端已排序，契约 §3.4）
    var sections: [(category: CategoryDTO, items: [ItemDTO])] {
        categories.compactMap { category in
            let matched = items.filter { $0.categoryId == category.id }
            return matched.isEmpty ? nil : (category, matched)
        }
    }

    /// 首次加载（含错误态重试）
    func load() async {
        state = .loading
        do {
            async let categoriesResponse: CategoriesResponse =
                APIClient.shared.request(path: "/categories", token: session.token)
            async let itemsResponse: ItemsResponse =
                APIClient.shared.request(path: "/items", token: session.token)
            let (cats, its) = try await (categoriesResponse, itemsResponse)
            categories = cats.categories
            items = its.items
            state = .loaded
        } catch APIError.authRequired {
            session.signOut()
        } catch let error as APIError {
            state = .failed(error)
        } catch {
            state = .failed(.server)
        }
    }

    /// 下拉刷新：成功替换数据；失败保留内容仅亮横幅。
    func refresh() async {
        do {
            async let categoriesResponse: CategoriesResponse =
                APIClient.shared.request(path: "/categories", token: session.token)
            async let itemsResponse: ItemsResponse =
                APIClient.shared.request(path: "/items", token: session.token)
            let (cats, its) = try await (categoriesResponse, itemsResponse)
            categories = cats.categories
            items = its.items
            refreshFailed = false
            if case .failed = state { state = .loaded }
        } catch APIError.authRequired {
            session.signOut()
        } catch {
            refreshFailed = true
        }
    }
}
