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
