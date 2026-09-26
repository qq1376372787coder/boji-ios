import SwiftUI

struct LoginView: View {
    @StateObject private var viewModel = LoginViewModel()
    @EnvironmentObject private var session: SessionStore
    @FocusState private var focus: Field?

    private enum Field {
        case phone
        case code
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    header
                    form
                    notice
                }
                .padding(24)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: "figure.strengthtraining.traditional")
                .font(.system(size: 52, weight: .semibold))
                .foregroundStyle(Color.accentColor)
            Text("登录薄肌俱乐部")
                .font(.largeTitle.bold())
            Text("使用中国大陆手机号登录，生成你的专属训练计划。")
                .font(.body)
                .foregroundStyle(.secondary)
        }
        .padding(.top, 28)
    }

    private var form: some View {
        VStack(spacing: 16) {
            HStack {
                Text("+86")
                    .foregroundStyle(.secondary)
                Divider().frame(height: 24)
                TextField("请输入手机号", text: $viewModel.phone)
                    .keyboardType(.numberPad)
                    .textContentType(.telephoneNumber)
                    .focused($focus, equals: .phone)
            }
            .padding(16)
            .background(.background, in: RoundedRectangle(cornerRadius: 16))

            HStack {
                TextField("6 位验证码", text: $viewModel.code)
                    .keyboardType(.numberPad)
                    .textContentType(.oneTimeCode)
                    .focused($focus, equals: .code)

                Button(viewModel.countdown > 0 ? "\(viewModel.countdown)s" : "获取验证码") {
                    focus = .code
                    Task { await viewModel.sendCode() }
                }
                .disabled(!viewModel.canSendCode)
            }
            .padding(16)
            .background(.background, in: RoundedRectangle(cornerRadius: 16))

            if let message = viewModel.errorMessage {
                Text(message)
                    .font(.footnote)
                    .foregroundStyle(.red)
            }

            Button {
                focus = nil
                Task { await viewModel.verify(session: session) }
            } label: {
                Group {
                    if viewModel.verifying {
                        ProgressView()
                    } else {
                        Text("登录 / 注册")
                            .font(.headline)
                    }
                }
                .frame(maxWidth: .infinity, minHeight: 52)
            }
            .buttonStyle(.borderedProminent)
            .disabled(!viewModel.canVerify)
        }
    }

    private var notice: some View {
        Text("继续即表示你同意《用户协议》和《隐私政策》。手机号仅用于登录、账号安全和会员服务。")
            .font(.footnote)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}
