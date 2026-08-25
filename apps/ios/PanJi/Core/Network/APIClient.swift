import Foundation

/// 网络层唯一入口：根地址拼接 `/v1/`、注入 Bearer token、统一错误映射（08-states B 表）。
/// 页面与业务代码不得自行拼 URL（代码原则 3）。
struct APIClient {
    static let shared = APIClient()

    private let baseURL: URL
    private let session: URLSession

    init() {
        let fallback = URL(string: "http://localhost:3000")!
        baseURL = URL(string: AppConfig.apiBaseURL) ?? fallback
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 10   // 超时 10s（08-states）
        config.timeoutIntervalForResource = 10
        session = URLSession(configuration: config)
    }

    func request<T: Decodable>(
        method: String = "GET",
        path: String,
        body: (any Encodable)? = nil,
        token: String? = nil
    ) async throws -> T {
        var url = baseURL.appendingPathComponent("v1")
        for component in path.split(separator: "/") {
            url.appendPathComponent(String(component))
        }
        var request = URLRequest(url: url)
        request.httpMethod = method
        if let token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        if let body {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONEncoder().encode(body)
        }
        return try await perform(request)
    }

    private func perform<T: Decodable>(_ request: URLRequest) async throws -> T {
        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw APIError.networkUnreachable
        }
        guard let http = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        guard (200..<300).contains(http.statusCode) else {
            throw Self.serverError(from: data, statusCode: http.statusCode)
        }
        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            throw APIError.invalidResponse
        }
    }

    private static func serverError(from data: Data, statusCode: Int) -> APIError {
        struct ServerErrorBody: Decodable {
            let code: String?
            let message: String?
        }
        let body = try? JSONDecoder().decode(ServerErrorBody.self, from: data)
        if statusCode == 401 || body?.code == "AUTH_REQUIRED" { return .authRequired }
        switch body?.code {
        case "VALIDATION_ERROR": return .validation(body?.message ?? "输入有误")
        case "NOT_FOUND": return .notFound
        case "UPLOAD_TOO_LARGE": return .uploadTooLarge
        case "UNSUPPORTED_TYPE": return .unsupportedType
        default: return .server
        }
    }
}
