import Foundation
import Testing
@testable import studiop

private struct StubError: Error, Equatable {}

@MainActor
struct RegisterViewModelTests {
    @Test func registerSuccess() async {
        let fakeAuth = FakeAuthRepository()

        let viewModel = RegisterViewModel(registerUseCase: RegisterUseCase(repository: fakeAuth))
        viewModel.name.value = "Jane Doe"
        viewModel.firstName.value = "Jane"
        viewModel.email.value = "jane@example.com"
        viewModel.password.value = "password123"
        viewModel.passwordConfirmation.value = "password123"
        viewModel.agreeToTerms.value = true

        await viewModel.register()

        #expect(viewModel.errorMessage == nil)
        #expect(viewModel.successMessage == fakeAuth.registerMessageToReturn)
    }

    @Test func registerWithMismatchedPasswordsSetsFieldErrorAndSkipsRepository() async {
        let fakeAuth = FakeAuthRepository()

        let viewModel = RegisterViewModel(registerUseCase: RegisterUseCase(repository: fakeAuth))
        viewModel.name.value = "Jane Doe"
        viewModel.firstName.value = "Jane"
        viewModel.email.value = "jane@example.com"
        viewModel.password.value = "password123"
        viewModel.passwordConfirmation.value = "different"
        viewModel.agreeToTerms.value = true

        await viewModel.register()

        #expect(viewModel.passwordConfirmation.error != nil)
        #expect(viewModel.successMessage == nil)
        #expect(fakeAuth.registerCallCount == 0)
    }

    @Test func registerFailurePropagatesError() async {
        let fakeAuth = FakeAuthRepository()
        fakeAuth.errorToThrow = StubError()

        let viewModel = RegisterViewModel(registerUseCase: RegisterUseCase(repository: fakeAuth))
        viewModel.name.value = "Jane Doe"
        viewModel.firstName.value = "Jane"
        viewModel.email.value = "jane@example.com"
        viewModel.password.value = "password123"
        viewModel.passwordConfirmation.value = "password123"
        viewModel.agreeToTerms.value = true

        await viewModel.register()

        #expect(viewModel.successMessage == nil)
        #expect(viewModel.errorMessage != nil)
    }
}
