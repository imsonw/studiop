import Foundation
import Testing
@testable import studiop

private struct StubError: Error, Equatable {}

@MainActor
struct VerifyAccountViewModelTests {
    @Test func verifySuccess() async {
        let fakeAuth = FakeAuthRepository()
        let viewModel = VerifyAccountViewModel(verifyAccountUseCase: VerifyAccountUseCase(repository: fakeAuth))
        viewModel.email.value = "jane@example.com"
        viewModel.code = "123456"

        await viewModel.verify()

        #expect(viewModel.successMessage != nil)
        #expect(viewModel.errorMessage == nil)
        #expect(fakeAuth.lastVerify?.email == "jane@example.com")
        #expect(fakeAuth.lastVerify?.code == "123456")
    }

    @Test func verifyWithInvalidEmailSetsFieldErrorAndSkipsRepository() async {
        let fakeAuth = FakeAuthRepository()
        let viewModel = VerifyAccountViewModel(verifyAccountUseCase: VerifyAccountUseCase(repository: fakeAuth))
        viewModel.email.value = "not-an-email"
        viewModel.code = "123456"

        await viewModel.verify()

        #expect(viewModel.email.error != nil)
        #expect(viewModel.successMessage == nil)
        #expect(fakeAuth.lastVerify == nil)
    }

    @Test func verifyFailurePropagatesError() async {
        let fakeAuth = FakeAuthRepository()
        fakeAuth.errorToThrow = StubError()
        let viewModel = VerifyAccountViewModel(verifyAccountUseCase: VerifyAccountUseCase(repository: fakeAuth))
        viewModel.email.value = "jane@example.com"
        viewModel.code = "wrong"

        await viewModel.verify()

        #expect(viewModel.errorMessage != nil)
        #expect(viewModel.successMessage == nil)
    }
}
