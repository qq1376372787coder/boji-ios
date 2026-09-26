import SwiftUI

struct RootView: View {
    @EnvironmentObject private var session: SessionStore

    var body: some View {
        Group {
            switch session.phase {
            case .launching:
                LaunchView()
            case .loggedOut:
                LoginView()
            case .onboarding:
                OnboardingView()
            case .ready:
                HomeView()
            }
        }
        .animation(.easeInOut(duration: 0.22), value: session.phase)
    }
}

private struct LaunchView: View {
    var body: some View {
        VStack(spacing: 18) {
            Image(systemName: "figure.strengthtraining.traditional")
                .font(.system(size: 62, weight: .semibold))
                .foregroundStyle(Color.accentColor)
            Text("薄肌俱乐部")
                .font(.title.bold())
            ProgressView()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }
}
