import Foundation
import UIKit
import UserNotifications

@MainActor
final class PushManager: ObservableObject {
    static let shared = PushManager()

    @Published var authorizationStatus: UNAuthorizationStatus = .notDetermined
    @Published var lastRegistrationError: String?

    private var apnsToken: String?
    private let api: APIClientProtocol

    init(api: APIClientProtocol = APIClient.shared) {
        self.api = api
    }

    func requestAuthorization() async {
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(
                options: [.alert, .badge, .sound]
            )
            authorizationStatus = granted ? .authorized : .denied
            if granted {
                UIApplication.shared.registerForRemoteNotifications()
            }
        } catch {
            lastRegistrationError = error.localizedDescription
        }
    }

    func updateAPNSToken(_ data: Data) {
        apnsToken = data.map { String(format: "%02x", $0) }.joined()
        Task { await uploadTokenIfAvailable() }
    }

    func uploadTokenIfAvailable() async {
        guard
            let token = apnsToken,
            !token.isEmpty,
            (try? await KeychainStore.shared.read(.accessToken)).map({ !$0.isEmpty }) == true
        else {
            return
        }

        let version = Bundle.main.object(
            forInfoDictionaryKey: "CFBundleShortVersionString"
        ) as? String ?? "1.0.0"

        let payload = RegisterPushRequest(
            token: token,
            environment: "production",
            appVersion: version
        )

        do {
            let _: SuccessResponse = try await api.sendAuthorized(
                Endpoint("/api/push-token", method: .post, body: payload)
            )
        } catch {
            lastRegistrationError = error.localizedDescription
        }
    }
}
