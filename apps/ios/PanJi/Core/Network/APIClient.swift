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

    /// 静态图片相对路径（裁决 A3）解析为完整 URL；各页面用它加载 `/uploads/...` 图片，禁止自行拼 URL。
    func imageURL(for relativePath: String) -> URL? {
        URL(string: relativePath, relativeTo: baseURL)
    }

    // MARK: - 图片上传（契约 3.10：multipart 字段名 `file`，需登录）

    func uploadImage(data: Data, mimeType: String, filename: String, token: String) async throws -> UploadResponse {
        let boundary = "PanJi-\(UUID().uuidString)"
        var url = baseURL.appendingPathComponent("v1")
        url.appendPathComponent("uploads")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        var body = Data()
        body.append(Data("--\(boundary)\r\n".utf8))
        body.append(Data("Content-Disposition: form-data; name=\"file\"; filename=\"\(filename)\"\r\n".utf8))
        body.append(Data("Content-Type: \(mimeType)\r\n\r\n".utf8))
        body.append(data)
        body.append(Data("\r\n--\(boundary)--\r\n".utf8))
        request.httpBody = body
        return try await perform(request)
    }

    /// 常见图片类型 MIME 推断（契约 3.10 白名单：jpeg/png/heic/heif/webp）
    static func mimeType(for data: Data) -> String {
        if data.starts(with: [0xFF, 0xD8, 0xFF]) { return "image/jpeg" }
        if data.starts(with: [0x89, 0x50, 0x4E, 0x47]) { return "image/png" }
        if data.starts(with: [0x52, 0x49, 0x46, 0x46]), data.count > 12,
           let tag = String(data: data.subdata(in: 8..<12), encoding: .ascii), tag == "WEBP" {
            return "image/webp"
        }
        if data.count > 12,
           let brand = String(data: data.subdata(in: 8..<12), encoding: .ascii),
           ["heic", "heix", "hevc", "hevx", "mif1", "msf1", "heif"].contains(brand) {
            return "image/heic"
        }
        return "image/jpeg"
    }

    static func fileExtension(for mimeType: String) -> String {
        switch mimeType {
        case "image/png": return "png"
        case "image/heic", "image/heif": return "heic"
        case "image/webp": return "webp"
        default: return "jpg"
        }
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
