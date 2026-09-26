import Foundation

protocol APIClientProtocol: Sendable {
    func send<T: Decodable>(_ endpoint: Endpoint) async throws -> T
    func sendAuthorized<T: Decodable>(_ endpoint: Endpoint) async throws -> T
    func sendVoid(_ endpoint: Endpoint) async throws
}

struct Endpoint: Sendable {
    enum Method: String, Sendable {
        case get = "GET"
        case post = "POST"
        case put = "PUT"
        case delete = "DELETE"
    }

    let path: String
    let method: Method
    let body: AnyEncodable?
    let requiresAuthorization: Bool

    init(
        _ path: String,
        method: Method = .get,
        body: Encodable? = nil,
        requiresAuthorization: Bool = false
    ) {
        self.path = path
        self.method = method
        self.body = body.map(AnyEncodable.init)
        self.requiresAuthorization = requiresAuthorization
    }
}

final class APIClient: APIClientProtocol, @unchecked Sendable {
    static let shared = APIClient()

    private let baseURL: URL
    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    init(baseURL: URL = AppConfig.apiBaseURL) {
        self.baseURL = baseURL

        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForRequest = 30
        configuration.timeoutIntervalForResource = 60
        configuration.waitsForConnectivity = true
        self.session = URLSession(configuration: configuration)

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let raw = try container.decode(String.self)

            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = formatter.date(from: raw) {
                return date
            }

            formatter.formatOptions = [.withInternetDateTime]
            if let date = formatter.date(from: raw) {
                return date
            }

            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Invalid date: \(raw)"
            )
        }
        self.decoder = decoder

        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        encoder.dateEncodingStrategy = .iso8601
        self.encoder = encoder
    }

    func send<T: Decodable>(_ endpoint: Endpoint) async throws -> T {
        let request = try await makeRequest(endpoint)
        return try await execute(request)
    }

    func sendAuthorized<T: Decodable>(_ endpoint: Endpoint) async throws -> T {
        let request = try await makeRequest(endpoint, forceAuthorization: true)
        return try await execute(request)
    }

    func sendVoid(_ endpoint: Endpoint) async throws {
        let request = try await makeRequest(endpoint)
        let (_, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw AppError.invalidResponse
        }
        guard (200..<300).contains(http.statusCode) else {
            throw try await mapError(status: http.statusCode, data: Data())
        }
    }

    private func makeRequest(
        _ endpoint: Endpoint,
        forceAuthorization: Bool = false
    ) async throws -> URLRequest {
        guard var components = URLComponents(
            url: baseURL.appendingPathComponent(endpoint.path),
            resolvingAgainstBaseURL: true
        ) else {
            throw AppError.invalidURL
        }

        components.queryItems = nil
        guard let url = components.url else {
            throw AppError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("ios", forHTTPHeaderField: "X-Client-Platform")
        request.setValue(
            Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0.0",
            forHTTPHeaderField: "X-App-Version"
        )

        if let body = endpoint.body {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try encoder.encode(body)
        }

        if endpoint.requiresAuthorization || forceAuthorization {
            guard let token = try? await KeychainStore.shared.read(.accessToken), !token.isEmpty else {
                throw AppError.unauthorized
            }
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        return request
    }

    private func execute<T: Decodable>(_ request: URLRequest) async throws -> T {
        do {
            let (data, response) = try await session.data(for: request)
            guard let http = response as? HTTPURLResponse else {
                throw AppError.invalidResponse
            }
            guard (200..<300).contains(http.statusCode) else {
                throw try await mapError(status: http.statusCode, data: data)
            }

            do {
                return try decoder.decode(T.self, from: data)
            } catch {
                throw AppError.decoding
            }
        } catch let error as AppError {
            throw error
        } catch {
            throw AppError.network(underlying: error.localizedDescription)
        }
    }

    private func mapError(status: Int, data: Data) async -> AppError {
        if status == 401 {
            return .unauthorized
        }

        if let payload = try? decoder.decode(APIErrorPayload.self, from: data) {
            return .server(status: status, message: payload.displayMessage)
        }

        return .server(status: status, message: "服务暂时不可用，请稍后重试。")
    }
}

struct AnyEncodable: Encodable, @unchecked Sendable {
    private let encodeClosure: (Encoder) throws -> Void

    init(_ wrapped: Encodable) {
        self.encodeClosure = wrapped.encode
    }

    func encode(to encoder: Encoder) throws {
        try encodeClosure(encoder)
    }
}

