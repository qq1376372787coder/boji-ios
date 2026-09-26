import Foundation

@MainActor
final class LoginViewModel: ObservableObject {
    @Published var phone = ""
    @Published var code = ""
    @Published var sending = false
    @Published var verifying = false
    @Published var countdown = 0
    @Published var errorMessage: String?

    private let api: APIClientProtocol

    init(api: APIClientProtocol = APIClient.shared) {
        self.api = api
    }

    var normalizedPhone: String {
        let digits = phone.filter(\.isNumber)
        if digits.hasPrefix("86") {
            return "+" + digits
        }
        return "+86" + digits
    }

    var canSendCode: Bool {
        phone.filter(\.isNumber).count == 11 && !sending && countdown == 0
    }

    var canVerify: Bool {
        code.filter(\.isNumber).count == 6 && !verifying
    }

    func sendCode() async {
        guard canSendCode else { return }
        sending = true
        errorMessage = nil

        do {
            let payload = SendCodePayload(phone: normalizedPhone, purpose: "login")
            let response: SendCodeResponse = try await api.send(
                Endpoint("/api/auth/sms/send", method: .post, body: payload)
            )
            countdown = max(response.retryAfter, 60)
            startCountdown()
        } catch {
            errorMessage = error.localizedDescription
        }

        sending = false
    }

    func verify(session: SessionStore) async {
        guard canVerify else { return }
        verifying = true
        errorMessage = nil

        do {
            try await session.login(phone: normalizedPhone, code: code)
        } catch {
            errorMessage = error.localizedDescription
        }

        verifying = false
    }

    private func startCountdown() {
        Task {
            while countdown > 0 {
                try? await Task.sleep(for: .seconds(1))
                countdown = max(0, countdown - 1)
            }
        }
    }
}

private struct SendCodePayload: Codable, Sendable {
    let phone: String
    let purpose: String
}
