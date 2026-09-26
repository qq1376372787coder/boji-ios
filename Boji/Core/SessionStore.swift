import Foundation

enum SessionPhase: Equatable, Sendable {
    case launching
    case loggedOut
    case onboarding
    case ready
}

@MainActor
final class SessionStore: ObservableObject {
    @Published private(set) var phase: SessionPhase = .launching
    @Published private(set) var user: User?
    @Published var errorMessage: String?

    private let api: APIClientProtocol

    init(api: APIClientProtocol = APIClient.shared) {
        self.api = api
    }

    func bootstrap() async {
        phase = .launching
        let token = (try? await KeychainStore.shared.read(.accessToken)) ?? ""
        guard !token.isEmpty else {
            phase = .loggedOut
            return
        }

        do {
            let user: User = try await api.sendAuthorized(Endpoint("/api/me"))
            self.user = user
            phase = user.onboarded ? .ready : .onboarding
            await PushManager.shared.uploadTokenIfAvailable()
        } catch {
            await KeychainStore.shared.clearSession()
            user = nil
            phase = .loggedOut
        }
    }

    func login(phone: String, code: String) async throws {
        let payload = PhoneVerificationPayload(phone: phone, code: code)
        let response: AuthResponse = try await api.send(
            Endpoint("/api/auth/sms/verify", method: .post, body: payload)
        )

        try await KeychainStore.shared.save(response.accessToken, for: .accessToken)
        try await KeychainStore.shared.save(response.refreshToken, for: .refreshToken)
        try await KeychainStore.shared.save(String(response.user.id), for: .userID)

        user = response.user
        phase = response.user.onboarded ? .ready : .onboarding
        await PushManager.shared.uploadTokenIfAvailable()
    }

    func completeOnboarding(_ payload: OnboardingPayload) async throws {
        let user: User = try await api.sendAuthorized(
            Endpoint("/api/onboarding", method: .post, body: payload)
        )
        self.user = user
        phase = .ready
    }

    func refreshUser() async {
        guard phase != .loggedOut else { return }
        do {
            let user: User = try await api.sendAuthorized(Endpoint("/api/me"))
            self.user = user
            phase = user.onboarded ? .ready : .onboarding
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func logout() async {
        _ = try? await api.sendVoid(
            Endpoint("/api/auth/logout", method: .post, requiresAuthorization: true)
        )
        await KeychainStore.shared.clearSession()
        user = nil
        phase = .loggedOut
    }
}

struct PhoneVerificationPayload: Codable, Sendable {
    let phone: String
    let code: String
}
