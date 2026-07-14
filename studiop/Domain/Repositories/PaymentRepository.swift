import Foundation

/// See docs/api-reference.md -> `PaymentRepository`.
protocol PaymentRepository: Sendable {
    func createPayment(id: String, source: String) async throws -> PaymentHandoff
}
