import Foundation
import Testing
@testable import studiop

private struct StubError: Error, Equatable {}

@MainActor
struct CollectEmailViewModelTests {
    @Test func submitSuccessAuthenticates() async {
        let fakeUser = FakeUserRepository()
        let appState = AppState()
        let viewModel = CollectEmailViewModel(
            changeUserProfileUseCase: ChangeUserProfileUseCase(repository: fakeUser),
            appState: appState
        )
        viewModel.email.value = "jane@example.com"

        await viewModel.submit()

        #expect(appState.isAuthenticated)
        #expect(viewModel.errorMessage == nil)
        #expect(fakeUser.lastChangeUserProfile?.email == "jane@example.com")
    }

    @Test func submitWithInvalidEmailSetsFieldErrorAndSkipsRepository() async {
        let fakeUser = FakeUserRepository()
        let appState = AppState()
        let viewModel = CollectEmailViewModel(
            changeUserProfileUseCase: ChangeUserProfileUseCase(repository: fakeUser),
            appState: appState
        )
        viewModel.email.value = "not-an-email"

        await viewModel.submit()

        #expect(viewModel.email.error != nil)
        #expect(!appState.isAuthenticated)
        #expect(fakeUser.lastChangeUserProfile == nil)
    }

    @Test func submitFailurePropagatesError() async {
        let fakeUser = FakeUserRepository()
        fakeUser.errorToThrow = StubError()
        let appState = AppState()
        let viewModel = CollectEmailViewModel(
            changeUserProfileUseCase: ChangeUserProfileUseCase(repository: fakeUser),
            appState: appState
        )
        viewModel.email.value = "jane@example.com"

        await viewModel.submit()

        #expect(!appState.isAuthenticated)
        #expect(viewModel.errorMessage != nil)
    }
}
