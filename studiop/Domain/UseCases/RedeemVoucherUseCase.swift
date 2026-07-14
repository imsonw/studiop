import Foundation

struct RedeemVoucherUseCase {
    let repository: OrderRepository

    init(repository: OrderRepository) {
        self.repository = repository
    }

    func callAsFunction(code: String, orderId: String) async throws -> Voucher {
        try await repository.redeemVoucher(code: code, orderId: orderId)
    }
}
