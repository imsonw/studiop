import Foundation

struct CreatePaymentUseCase {
    let repository: PaymentRepository

    init(repository: PaymentRepository) {
        self.repository = repository
    }

    func callAsFunction(id: String, source: String = "mobile") async throws -> PaymentHandoff {
        try await repository.createPayment(id: id, source: source)
    }
}
