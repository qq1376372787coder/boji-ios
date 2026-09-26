import Foundation
import StoreKit

@MainActor
final class PurchaseManager: ObservableObject {
    @Published private(set) var product: Product?
    @Published private(set) var purchasing = false
    @Published private(set) var restoring = false
    @Published var errorMessage: String?
    @Published var successMessage: String?

    private let productID = AppConfig.appleProductID
    private let api: APIClientProtocol

    init(api: APIClientProtocol = APIClient.shared) {
        self.api = api
    }

    func loadProduct() async {
        do {
            let products = try await Product.products(for: [productID])
            product = products.first
        } catch {
            errorMessage = "暂时无法加载会员商品，请检查网络后重试。"
        }
    }

    func purchase() async {
        guard let product else {
            errorMessage = "会员商品尚未加载完成。"
            return
        }

        purchasing = true
        errorMessage = nil
        defer { purchasing = false }

        do {
            let result = try await product.purchase()
            switch result {
            case let .success(verification):
                guard let transaction = try Self.unwrap(verification) else {
                    throw AppError.purchase("Apple 返回了无法验证的交易。")
                }
                try await verify(transaction)
                await transaction.finish()
                successMessage = "会员开通成功。"
                await loadProduct()

            case .userCancelled:
                break

            case .pending:
                successMessage = "购买正在等待批准，请稍后查看会员状态。"

            @unknown default:
                throw AppError.purchase("购买结果未知，请稍后在个人中心恢复购买。")
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func restore() async {
        restoring = true
        errorMessage = nil
        defer { restoring = false }

        do {
            try await AppStore.sync()

            var verifiedAny = false
            for await verification in Transaction.currentEntitlements {
                guard let transaction = try Self.unwrap(verification) else { continue }
                if transaction.productID == productID {
                    try await verify(transaction)
                    verifiedAny = true
                }
            }

            if verifiedAny {
                successMessage = "已恢复有效会员。"
            } else {
                errorMessage = "没有找到可恢复的有效会员。"
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func verify(_ transaction: Transaction) async throws {
        let jws = transaction.jwsRepresentation
        let payload = AppleVerificationRequest(
            transactionJWS: jws,
            environment: transaction.environment == .production ? "production" : "sandbox"
        )

        let _: SuccessResponse = try await api.sendAuthorized(
            Endpoint("/api/billing/apple/verify", method: .post, body: payload)
        )
    }

    private static func unwrap(
        _ verification: VerificationResult<Transaction>
    ) throws -> Transaction? {
        switch verification {
        case let .verified(transaction):
            return transaction
        case .unverified:
            throw AppError.purchase("Apple 交易校验失败。")
        }
    }
}
