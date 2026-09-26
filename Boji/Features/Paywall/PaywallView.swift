import SwiftUI

struct PaywallView: View {
    @EnvironmentObject private var session: SessionStore
    @Environment(\.dismiss) private var dismiss
    @StateObject private var purchase = PurchaseManager()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 22) {
                    hero
                    benefits
                    purchaseButton
                    restoreButton

                    if let message = purchase.successMessage {
                        Text(message)
                            .font(.footnote)
                            .foregroundStyle(.green)
                    }

                    if let message = purchase.errorMessage {
                        Text(message)
                            .font(.footnote)
                            .foregroundStyle(.red)
                    }

                    policy
                }
                .padding(22)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("开通会员")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("关闭") { dismiss() }
                }
            }
            .task {
                await purchase.loadProduct()
            }
            .onChange(of: purchase.successMessage) { _, message in
                if message == "会员开通成功。" {
                    Task {
                        await session.refreshUser()
                        dismiss()
                    }
                }
            }
        }
    }

    private var hero: some View {
        VStack(spacing: 12) {
            Image(systemName: "crown.fill")
                .font(.system(size: 56))
                .foregroundStyle(.yellow)
            Text("薄肌俱乐部年度会员")
                .font(.title2.bold())
            Text("一人一账号，完整使用 AI 训练计划、训练日历和记录功能。")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)

            if let product = purchase.product {
                Text(product.displayPrice)
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                Text("12 个月自动续费")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                Text("6 元")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                Text("12 个月自动续费")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var benefits: some View {
        VStack(alignment: .leading, spacing: 14) {
            BenefitRow(icon: "sparkles", text: "AI 根据身体情况生成训练计划")
            BenefitRow(icon: "calendar", text: "自动生成训练日历")
            BenefitRow(icon: "square.and.arrow.down", text: "导入自己的训练计划")
            BenefitRow(icon: "chart.line.uptrend.xyaxis", text: "训练、饮食和身体趋势")
            BenefitRow(icon: "bell.badge", text: "训练和会员到期提醒")
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background, in: RoundedRectangle(cornerRadius: 20))
    }

    private var purchaseButton: some View {
        Button {
            Task { await purchase.purchase() }
        } label: {
            Group {
                if purchase.purchasing {
                    ProgressView()
                } else {
                    Text(purchase.product == nil ? "加载商品中…" : "通过 Apple 开通")
                        .font(.headline)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 54)
        }
        .buttonStyle(.borderedProminent)
        .disabled(purchase.product == nil || purchase.purchasing)
    }

    private var restoreButton: some View {
        Button("恢复购买") {
            Task { await purchase.restore() }
        }
        .disabled(purchase.restoring)
    }

    private var policy: some View {
        VStack(spacing: 8) {
            Text("订阅将通过 Apple 账户自动续费。你可以随时在 Apple ID 设置中取消。")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            HStack(spacing: 16) {
                Link("用户协议", destination: URL(string: "https://123.gongxiang.cloud/legal/terms")!)
                Link("隐私政策", destination: URL(string: "https://123.gongxiang.cloud/legal/privacy")!)
                Link("订阅条款", destination: URL(string: "https://123.gongxiang.cloud/legal/subscription")!)
            }
            .font(.footnote)
        }
    }
}

private struct BenefitRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(Color.accentColor)
                .frame(width: 28)
            Text(text)
            Spacer()
        }
    }
}
