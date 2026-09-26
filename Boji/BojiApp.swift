import SwiftUI

@main
struct BojiApp: App {
    @UIApplicationDelegateAdaptor(BojiAppDelegate.self) private var appDelegate
    @StateObject private var session = SessionStore()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(session)
                .task {
                    await session.bootstrap()
                }
                .onChange(of: scenePhase) { _, newPhase in
                    if newPhase == .active {
                        Task {
                            await session.refreshUser()
                            await PushManager.shared.uploadTokenIfAvailable()
                        }
                    }
                }
        }
    }
}

final class BojiAppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        PushManager.shared.updateAPNSToken(deviceToken)
    }

    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        PushManager.shared.lastRegistrationError = error.localizedDescription
    }
}
