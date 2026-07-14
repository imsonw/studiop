import Foundation
import Testing
@testable import studiop

private struct StubError: Error, Equatable {}

final class FakePaymentRepository: PaymentRepository, @unchecked Sendable {
    var handoffToReturn = PaymentHandoff(paymentId: "pay-1", provider: "mollie", checkoutURL: "https://pay.example/1")
    var errorToThrow: Error?

    private(set) var lastCreatePaymentArgs: (id: String, source: String)?

    func createPayment(id: String, source: String) async throws -> PaymentHandoff {
        lastCreatePaymentArgs = (id, source)
        if let errorToThrow { throw errorToThrow }
        return handoffToReturn
    }
}

struct PaymentUseCaseTests {
    @Test func createPaymentDefaultsSourceToMobile() async throws {
        let fake = FakePaymentRepository()
        let useCase = CreatePaymentUseCase(repository: fake)

        let result = try await useCase(id: "order-1")

        #expect(fake.lastCreatePaymentArgs?.id == "order-1")
        #expect(fake.lastCreatePaymentArgs?.source == "mobile")
        #expect(result == fake.handoffToReturn)
    }

    @Test func createPaymentForwardsExplicitSource() async throws {
        let fake = FakePaymentRepository()
        let useCase = CreatePaymentUseCase(repository: fake)

        _ = try await useCase(id: "order-1", source: "web")

        #expect(fake.lastCreatePaymentArgs?.source == "web")
    }

    @Test func createPaymentPropagatesError() async throws {
        let fake = FakePaymentRepository()
        fake.errorToThrow = StubError()
        let useCase = CreatePaymentUseCase(repository: fake)

        await #expect(throws: StubError.self) {
            try await useCase(id: "order-1")
        }
    }
}
