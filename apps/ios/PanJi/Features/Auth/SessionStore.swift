import Foundation
import Observation

/// 登录态：token 持久化（UserDefaults，裁决 A7）+ 启动恢复（契约 3.2）+ 阶段机。
@MainActor
@Observable
final class SessionStore {
    enum Phase: Equatable {
        case restoring      // 启动恢复中
        case restoreFailed  // 恢复失败（网络），可重试
        case needLogin      // 无登录态 / 401 后
        case needNickname   // 新用户或昵称为空（强制引导，裁决 B5）
        case signedIn       // 已登录且昵称齐备
    }

    private(set) var phase: Phase = .restoring
    private(set) var nickname: String?

    private static let tokenKey = "session.token"
    private static let nicknameKey = "session.nickname"
    private static let lastPhoneKey = "session.lastPhone"

    private var token: String? { UserDefaults.standard.string(forKey: Self.tokenKey) }

    /// 登录页开发便利：回填上次成功登录的手机号（线框 01 默认状态）
    var lastPhone: String { UserDefaults.standard.string(forKey: Self.lastPhoneKey) ?? "" }

    /// 启动恢复：有 token 则 GET /v1/me；401 清 token 回登录；网络失败给出重试态。
    func restore() async {
        guard let token else {
            phase = .needLogin
            return
        }
        do {
            let response: UserResponse = try await APIClient.shared.request(path: "/me", token: token)
            nickname = response.user.nickname
            cacheNickname(response.user.nickname)
            phase = response.user.nickname == nil ? .needNickname : .signedIn
        } catch APIError.authRequired {
            signOut()
        } catch {
            phase = .restoreFailed
        }
    }

    /// Dev Login（契约 3.1）：成功存 token；新用户或昵称为空 → 昵称页，否则直进收藏柜。
    func login(phone: String) async throws {
        let response: DevLoginResponse = try await APIClient.shared.request(
            method: "POST", path: "/auth/dev-login", body: DevLoginRequest(phone: phone))
        UserDefaults.standard.set(response.token, forKey: Self.tokenKey)
        UserDefaults.standard.set(phone, forKey: Self.lastPhoneKey)
        nickname = response.user.nickname
        cacheNickname(response.user.nickname)
        phase = (response.isNewUser || response.user.nickname == nil) ? .needNickname : .signedIn
    }

    /// 设置昵称（契约 3.3）：成功即进收藏柜，同步本地用户缓存（线框 02）。
    func saveNickname(_ name: String) async throws {
        let response: UserResponse = try await APIClient.shared.request(
            method: "PATCH", path: "/me", body: NicknameRequest(nickname: name), token: token)
        nickname = response.user.nickname
        cacheNickname(response.user.nickname)
        phase = .signedIn
    }

    /// 401 全局处理（08-states B 表）：清登录态回登录页，保留上次手机号。
    func signOut() {
        UserDefaults.standard.removeObject(forKey: Self.tokenKey)
        UserDefaults.standard.removeObject(forKey: Self.nicknameKey)
        nickname = nil
        phase = .needLogin
    }

    private func cacheNickname(_ value: String?) {
        if let value {
            UserDefaults.standard.set(value, forKey: Self.nicknameKey)
        } else {
            UserDefaults.standard.removeObject(forKey: Self.nicknameKey)
        }
    }
}
