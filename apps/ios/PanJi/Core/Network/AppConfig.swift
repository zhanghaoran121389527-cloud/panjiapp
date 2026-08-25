import Foundation

/// 应用构建配置。值由 Config/Config.xcconfig 经 Info.plist 注入。
enum AppConfig {
    /// API 根地址，形如 http://192.168.1.100:3000（不含路径）。
    static var apiBaseURL: String {
        guard let value = Bundle.main.object(forInfoDictionaryKey: "APIBaseURL") as? String,
              !value.isEmpty else {
            preconditionFailure("Info.plist 缺少 APIBaseURL（由 Config.xcconfig 的 API_BASE_URL 注入）")
        }
        return value
    }
}
