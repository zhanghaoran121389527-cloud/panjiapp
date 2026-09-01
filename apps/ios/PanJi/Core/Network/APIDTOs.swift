import Foundation

/// API_CONTRACT §3.1~3.3 传输对象（camelCase 与契约一致，不得自行改字段）
struct UserDTO: Codable {
    let id: String
    let nickname: String?
}

struct DevLoginRequest: Encodable {
    let phone: String
}

struct DevLoginResponse: Decodable {
    let token: String
    let user: UserDTO
    let isNewUser: Bool
}

struct UserResponse: Decodable {
    let user: UserDTO
}

struct NicknameRequest: Encodable {
    let nickname: String
}

// MARK: - §3.4 / §3.5（M1-007 收藏柜）

struct CategoryDTO: Decodable {
    let id: String
    let name: String
}

struct CategoriesResponse: Decodable {
    let categories: [CategoryDTO]
}

struct ItemDTO: Decodable {
    let id: String
    let name: String
    let coverImageUrl: String?
    let categoryId: String
    let dayCount: Int
    let createdAt: String
}

struct ItemsResponse: Decodable {
    let items: [ItemDTO]
}

// MARK: - §3.6 / §3.10（M1-008 创建玩物）

struct CreateItemRequest: Encodable {
    let name: String
    let categoryId: String
    let coverImageUrl: String?
    let subcategory: String?
    let acquiredDate: String?
    let sizeSpec: String?
    let notes: String?
}

struct ItemResponse: Decodable {
    let item: ItemDTO
}

struct UploadResponse: Decodable {
    let url: String
}

// MARK: - §3.7 / §3.12（M1-009 详情与时间轴）

struct ItemDetailDTO: Decodable {
    let id: String
    let name: String
    let coverImageUrl: String?
    let categoryId: String
    let subcategory: String?
    let sizeSpec: String?
    let acquiredDate: String?
    let notes: String?
    let dayCount: Int
    let createdAt: String
    let updatedAt: String
}

struct ItemDetailResponse: Decodable {
    let item: ItemDetailDTO
}

struct RecordDTO: Decodable {
    let id: String
    let photoUrls: [String]
    let content: String
    let durationMinutes: Int?
    let method: String?
    let recordedDate: String
    let createdAt: String
}

struct RecordsResponse: Decodable {
    let records: [RecordDTO]
}
