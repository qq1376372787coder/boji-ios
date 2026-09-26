import Foundation

struct APIErrorPayload: Codable, Sendable {
    let error: String?
    let message: String?
    let code: String?

    var displayMessage: String {
        error ?? message ?? "服务暂时不可用，请稍后重试。"
    }
}

enum AppError: LocalizedError, Sendable {
    case invalidURL
    case invalidResponse
    case unauthorized
    case server(status: Int, message: String)
    case decoding
    case network(underlying: String)
    case purchase(String)
    case validation(String)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "请求地址不正确。"
        case .invalidResponse:
            return "服务器返回了无法识别的内容。"
        case .unauthorized:
            return "登录状态已失效，请重新登录。"
        case let .server(_, message):
            return message
        case .decoding:
            return "数据解析失败，请更新 App 后重试。"
        case let .network(message):
            return message
        case let .purchase(message):
            return message
        case let .validation(message):
            return message
        }
    }
}
