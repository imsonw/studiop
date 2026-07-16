import Foundation
import Testing
@testable import studiop

private struct StubError: Error, Equatable {}

@MainActor
struct ResetPasswordRequestViewModelTests {
    @Test func requestResetSuccess() async {
        let fakeAuth = FakeAuthRepository()
        let viewModel = ResetPasswordRequestViewModel(resetPasswordUseCase: ResetPasswordUseCase(repository: fakeAuth))
        viewModel.email.value = "jane@example.com"

        await viewModel.requestReset()

        #expect(viewModel.successMessage != nil)
        #expect(viewModel.errorMessage == nil)
        #expect(fakeAuth.lastResetPasswordEmail == "jane@example.com")
    }

    @Test func requestResetWithInvalidEmailSetsFieldErrorAndSkipsRepository() async {
        let fakeAuth = FakeAuthRepository()
        let viewModel = ResetPasswordRequestViewModel(resetPasswordUseCase: ResetPasswordUseCase(repository: fakeAuth))
        viewModel.email.value = "not-an-email"

        await viewModel.requestReset()

        #expect(viewModel.email.error != nil)
        #expect(viewModel.successMessage == nil)
        #expect(fakeAuth.lastResetPasswordEmail == nil)
    }

    @Test func requestResetFailurePropagatesError() async {
        let fakeAuth = FakeAuthRepository()
        fakeAuth.errorToThrow = StubError()
        let viewModel = ResetPasswordRequestViewModel(resetPasswordUseCase: ResetPasswordUseCase(repository: fakeAuth))
        viewModel.email.value = "jane@example.com"

        await viewModel.requestReset()

        #expect(viewModel.errorMessage != nil)
        #expect(viewModel.successMessage == nil)
    }
}

@MainActor
struct ResetPasswordConfirmViewModelTests {
    @Test func confirmResetSuccess() async {
        let fakeAuth = FakeAuthRepository()
        let viewModel = ResetPasswordConfirmViewModel(
            confirmResetPasswordUseCase: ConfirmResetPasswordUseCase(repository: fakeAuth)
        )
        viewModel.email.value = "jane@example.com"
        viewModel.resetToken = "reset-token"
        viewModel.newPassword.value = "newPassword123"
        viewModel.newPasswordConfirmation.value = "newPassword123"

        await viewModel.confirmReset()

        #expect(viewModel.successMessage != nil)
        #expect(viewModel.errorMessage == nil)
        #expect(fakeAuth.lastConfirmResetPassword?.email == "jane@example.com")
        #expect(fakeAuth.lastConfirmResetPassword?.resetToken == "reset-token")
        #expect(fakeAuth.lastConfirmResetPassword?.newPassword == "newPassword123")
    }

    @Test func confirmResetWithMismatchedPasswordsSetsFieldErrorAndSkipsRepository() async {
        let fakeAuth = FakeAuthRepository()
        let viewModel = ResetPasswordConfirmViewModel(
            confirmResetPasswordUseCase: ConfirmResetPasswordUseCase(repository: fakeAuth)
        )
        viewModel.email.value = "jane@example.com"
        viewModel.resetToken = "reset-token"
        viewModel.newPassword.value = "newPassword123"
        viewModel.newPasswordConfirmation.value = "different"

        await viewModel.confirmReset()

        #expect(viewModel.newPasswordConfirmation.error != nil)
        #expect(viewModel.successMessage == nil)
        #expect(fakeAuth.lastConfirmResetPassword == nil)
    }

    @Test func confirmResetFailurePropagatesError() async {
        let fakeAuth = FakeAuthRepository()
        fakeAuth.errorToThrow = StubError()
        let viewModel = ResetPasswordConfirmViewModel(
            confirmResetPasswordUseCase: ConfirmResetPasswordUseCase(repository: fakeAuth)
        )
        viewModel.email.value = "jane@example.com"
        viewModel.resetToken = "reset-token"
        viewModel.newPassword.value = "newPassword123"
        viewModel.newPasswordConfirmation.value = "newPassword123"

        await viewModel.confirmReset()

        #expect(viewModel.errorMessage != nil)
        #expect(viewModel.successMessage == nil)
    }
}
