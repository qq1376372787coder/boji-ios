import SwiftUI

struct ProfileView: View {
    @EnvironmentObject private var session: SessionStore
    @Environment(\.dismiss) private var dismiss
    @State private var showLogoutConfirmation = false

    var body: some View {
        NavigationStack {
            List {
                Section("账号") {
                    LabeledContent("手机号", value: session.user?.phone ?? "—")
                    if let name = session.user?.displayName, !name.isEmpty {
                        LabeledContent("昵称", value: name)
                    }
                }

                Section("会员") {
                    LabeledContent("状态", value: session.user?.membership.active == true ? "已开通" : "未开通")
                    if let expiresAt = session.user?.membership.expiresAt {
                        LabeledContent("有效期至", value: expiresAt.formatted(date: .long, time: .omitted))
                    }
                }

                Section("通知") {
                    Button("设置训练提醒") {
                        Task { await PushManager.shared.requestAuthorization() }
                    }
                }

                Section("隐私") {
                    Link("用户协议", destination: URL(string: "https://123.gongxiang.cloud/legal/terms")!)
                    Link("隐私政策", destination: URL(string: "https://123.gongxiang.cloud/legal/privacy")!)
                    Link("账号注销", destination: URL(string: "https://123.gongxiang.cloud/legal/delete-account")!)
                }

                Section {
                    Button("退出登录", role: .destructive) {
                        showLogoutConfirmation = true
                    }
                }
            }
            .navigationTitle("个人中心")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("完成") { dismiss() }
                }
            }
            .confirmationDialog(
                "确定退出当前账号吗？",
                isPresented: $showLogoutConfirmation,
                titleVisibility: .visible
            ) {
                Button("退出登录", role: .destructive) {
                    Task {
                        await session.logout()
                        dismiss()
                    }
                }
                Button("取消", role: .cancel) {}
            }
        }
    }
}
