import Foundation
import Testing

@testable import studiop

private struct StubError: Error, Equatable {}

private struct FakeAuthRepositorySuccess: AuthRepository {
    let session: AuthSession

    init() {
        self.session = AuthSession(
            user: User(id: 1, idEncode: "test", name: "Test", email: "test@example.com"),
            token: "preview-token"
        )
    }

    func register(
        name: String,
        email: String,
        password: String,
        passwordConfirmation: String,
        phone: String?
    ) async throws -> AuthSession {
        session
    }

    func login(email: String, password: String) async throws -> AuthSession {
        session
    }

    func verifyAccount(email: String, code: String) async throws {}
    func resetPassword(email: String) async throws {}
    func confirmResetPassword(
        email: String,
        resetToken: String,
        newPassword: String,
        newPasswordConfirmation: String
    ) async throws {}
    func loginWithSocial(
        provider: String,
        socialToken: String,
        socialEmail: String?,
        socialUserId: String?,
        socialName: String?,
        socialAvatar: String?,
        authCode: String?,
        codeVerifier: String?,
        redirectURI: String?
    ) async throws -> AuthSession {
        session
    }
}

private struct FakeAuthRepositoryFailure: AuthRepository {
    func register(
        name: String,
        email: String,
        password: String,
        passwordConfirmation: String,
        phone: String?
    ) async throws -> AuthSession {
        throw StubError()
    }

    func login(email: String, password: String) async throws -> AuthSession {
        throw StubError()
    }

    func verifyAccount(email: String, code: String) async throws {}
    func resetPassword(email: String) async throws {}
    func confirmResetPassword(
        email: String,
        resetToken: String,
        newPassword: String,
        newPasswordConfirmation: String
    ) async throws {}
    func loginWithSocial(
        provider: String,
        socialToken: String,
        socialEmail: String?,
        socialUserId: String?,
        socialName: String?,
        socialAvatar: String?,
        authCode: String?,
        codeVerifier: String?,
        redirectURI: String?
    ) async throws -> AuthSession {
        throw StubError()
    }
}

private struct FakeUserRepositorySuccess: UserRepository {
    let user: User

    init() {
        self.user = User(id: 1, idEncode: "test", name: "Test", email: "test@example.com")
    }

    func fetchUserInfo() async throws -> User {
        user
    }

    func changePassword(currentPassword: String, newPassword: String) async throws {}
    func changeUserInfo(_ user: User) async throws -> User { user }
    func changeUserProfile(
        name: String?,
        phone: String?,
        email: String?,
        companyName: String?,
        taxCode: String?,
        socialProvider: String?
    ) async throws -> User {
        user
    }
    func changeUserAddress(mainAddress: Address, shippingAddress: Address?) async throws {}
    func requestAccountRemoval(reason: String) async throws {}
    func confirmAccountRemoval(email: String, code: String) async throws {}
}

private struct FakeUserRepositoryFailure: UserRepository {
    func fetchUserInfo() async throws -> User {
        throw StubError()
    }

    func changePassword(currentPassword: String, newPassword: String) async throws {}
    func changeUserInfo(_ user: User) async throws -> User { user }
    func changeUserProfile(
        name: String?,
        phone: String?,
        email: String?,
        companyName: String?,
        taxCode: String?,
        socialProvider: String?
    ) async throws -> User {
        User(id: 1, idEncode: "test", name: "Test", email: "test@example.com")
    }
    func changeUserAddress(mainAddress: Address, shippingAddress: Address?) async throws {}
    func requestAccountRemoval(reason: String) async throws {}
    func confirmAccountRemoval(email: String, code: String) async throws {}
}

@MainActor
struct LoginViewModelTests {
    @Test func loginSuccess() async {
        let fakeAuth = FakeAuthRepositorySuccess()
        let fakeUser = FakeUserRepositorySuccess()
        let fakeKeychain = InMemoryKeychainStore()
        let appState = AppState()

        let viewModel = LoginViewModel(
            loginUseCase: LoginUseCase(repository: fakeAuth),
            fetchUserInfoUseCase: FetchUserInfoUseCase(repository: fakeUser),
            keychainStore: fakeKeychain,
            appState: appState
        )
        viewModel.email.value = "test@example.com"
        viewModel.password = "password123"

        await viewModel.login()

        #expect(appState.isAuthenticated)
        #expect(viewModel.errorMessage == nil)
        #expect(fakeKeychain.readToken() == "preview-token")
    }

    @Test func loginFailure() async {
        let fakeAuth = FakeAuthRepositoryFailure()
        let fakeUser = FakeUserRepositorySuccess()
        let fakeKeychain = InMemoryKeychainStore()
        let appState = AppState()

        let viewModel = LoginViewModel(
            loginUseCase: LoginUseCase(repository: fakeAuth),
            fetchUserInfoUseCase: FetchUserInfoUseCase(repository: fakeUser),
            keychainStore: fakeKeychain,
            appState: appState
        )
        viewModel.email.value = "test@example.com"
        viewModel.password = "wrong"

        await viewModel.login()

        #expect(!appState.isAuthenticated)
        #expect(viewModel.errorMessage != nil)
        #expect(fakeKeychain.readToken() == nil)
    }

    @Test func loginWithInvalidEmailSetsEmailErrorAndSkipsRepository() async {
        let fakeAuth = FakeAuthRepositorySuccess()
        let fakeUser = FakeUserRepositorySuccess()
        let fakeKeychain = InMemoryKeychainStore()
        let appState = AppState()

        let viewModel = LoginViewModel(
            loginUseCase: LoginUseCase(repository: fakeAuth),
            fetchUserInfoUseCase: FetchUserInfoUseCase(repository: fakeUser),
            keychainStore: fakeKeychain,
            appState: appState
        )
        viewModel.email.value = "not-an-email"
        viewModel.password = "password123"

        await viewModel.login()

        #expect(viewModel.email.error != nil)
        #expect(!appState.isAuthenticated)
        #expect(viewModel.errorMessage == nil)
        #expect(fakeKeychain.readToken() == nil)
    }

    @Test func fetchUserInfoFailureAfterSuccessfulLogin() async {
        let fakeAuth = FakeAuthRepositorySuccess()
        let fakeUser = FakeUserRepositoryFailure()
        let fakeKeychain = InMemoryKeychainStore()
        let appState = AppState()

        let viewModel = LoginViewModel(
            loginUseCase: LoginUseCase(repository: fakeAuth),
            fetchUserInfoUseCase: FetchUserInfoUseCase(repository: fakeUser),
            keychainStore: fakeKeychain,
            appState: appState
        )
        viewModel.email.value = "test@example.com"
        viewModel.password = "password123"

        await viewModel.login()

        #expect(!appState.isAuthenticated)
        #expect(viewModel.errorMessage != nil)
        #expect(fakeKeychain.readToken() == "preview-token")
    }
}
