import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var session: SessionStore
    @State private var showPaywall = false
    @State private var showProfile = false
    @State private var selectedPlanMode: PlanFlowView.Mode?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    membershipCard
                    quickActions
                    planCard
                    reminderCard
                }
                .padding(18)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("薄肌俱乐部")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showProfile = true
                    } label: {
                        Image(systemName: "person.crop.circle")
                    }
                }
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView()
            }
            .sheet(item: $selectedPlanMode) { mode in
                PlanFlowView(initialMode: mode)
            }
            .sheet(isPresented: $showProfile) {
                ProfileView()
            }
        }
    }

    private var membershipCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("会员", systemImage: "crown.fill")
                    .font(.headline)
                    .foregroundStyle(.yellow)
                Spacer()
                if session.user?.membership.active == true {
                    Text("已开通")
                        .font(.caption.bold())
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(.green.opacity(0.15), in: Capsule())
                        .foregroundStyle(.green)
                } else {
                    Text("未开通")
                        .font(.caption.bold())
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(.orange.opacity(0.15), in: Capsule())
                        .foregroundStyle(.orange)
                }
            }

            if let expiresAt = session.user?.membership.expiresAt {
                Text("有效期至 \(expiresAt.formatted(date: .long, time: .omitted))")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                Text("开通后可使用 AI 训练计划、计划导入和全部记录功能。")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            if session.user?.membership.active != true {
                Button("开通 6 元年度会员") {
                    showPaywall = true
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background, in: RoundedRectangle(cornerRadius: 20))
    }

    private var quickActions: some View {
        HStack(spacing: 14) {
            HomeActionCard(
                title: "生成计划",
                subtitle: "AI 自动生成",
                icon: "sparkles",
                color: .blue
            ) {
                openPlan(.generate)
            }
            HomeActionCard(
                title: "导入计划",
                subtitle: "截图或文字",
                icon: "square.and.arrow.down",
                color: .purple
            ) {
                openPlan(.importText)
            }
            HomeActionCard(
                title: "自由训练",
                subtitle: "直接记录",
                icon: "figure.strengthtraining.traditional",
                color: .orange
            ) {
                openPlan(.free)
            }
        }
    }

    private var planCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("今日训练", systemImage: "calendar")
                .font(.title3.bold())

            Text("完成建档后，AI 会根据你的目标、器械和时间生成训练计划。")
                .font(.body)
                .foregroundStyle(.secondary)

            Button("开始生成训练计划") {
                openPlan(.generate)
            }
            .buttonStyle(.bordered)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background, in: RoundedRectangle(cornerRadius: 20))
    }

    private var reminderCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("训练提醒", systemImage: "bell.badge")
                .font(.headline)

            Text("开启推送，在训练日及时收到提醒。")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Button("开启通知") {
                Task { await PushManager.shared.requestAuthorization() }
            }
            .buttonStyle(.bordered)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background, in: RoundedRectangle(cornerRadius: 20))
    }
}

extension HomeView {
    fileprivate func openPlan(_ mode: PlanFlowView.Mode) {
        if session.user?.membership.active == true {
            selectedPlanMode = mode
        } else {
            showPaywall = true
        }
    }
}

private struct HomeActionCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    var action: () -> Void = {}

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
                .frame(width: 42, height: 42)
                .background(color.opacity(0.12), in: RoundedRectangle(cornerRadius: 13))
            Text(title)
                .font(.headline)
            Text(subtitle)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: 132, alignment: .leading)
        .background(.background, in: RoundedRectangle(cornerRadius: 18))
        .contentShape(Rectangle())
        .onTapGesture(perform: action)
    }
}

