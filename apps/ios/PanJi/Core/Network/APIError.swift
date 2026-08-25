import Foundation

/// 统一 API 错误（API_CONTRACT §1 错误格式 + 08-states B 表文案映射；网络层单点维护，页面只消费）
enum APIError: Error, Equatable {
    case networkUnreachable  // 网络不可达 / 超时（10s）
    case authRequired        // 401 / AUTH_REQUIRED：清 token 回登录，不显示文案
    case validation(String)  // VALIDATION_ERROR：显示后端 message 原文
    case notFound
    case uploadTooLarge
    case unsupportedType
    case server              // INTERNAL / 其他
    case invalidResponse     // 响应解析失败

    /// 页面直接消费的文案（08-states B 表）；authRequired 为 nil（全局回登录，不展示）
    var userMessage: String? {
        switch self {
        case .networkUnreachable: return "网络不太顺畅，请检查后重试"
        case .authRequired: return nil
        case .validation(let message): return message
        case .notFound: return "内容不存在或已被删除"
        case .uploadTooLarge: return "图片超过 10MB，请换一张"
        case .unsupportedType: return "暂不支持该图片格式"
        case .server, .invalidResponse: return "出了点问题，请稍后再试"
        }
    }
}
