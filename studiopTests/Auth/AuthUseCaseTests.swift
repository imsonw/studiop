import Foundation
import Testing
@testable import studiop

private struct StubError: Error, Equatable {}

final class FakeAuthRepository: AuthRepository, @unchecked Sendable {
    var authSessionToReturn: AuthSession = AuthSession(
        user: User(id: 1, idEncode: "abc", name: "Jane", email: "jane@example.com"),
        token: "token-123"
    )
    var errorToThrow: Error?

    private(set) var registerCallCount = 0
    private(set) var lastLogin: (email: String, password: String)?
    private(set) var lastVerify: (email: String, code: String)?
    private(set) var lastResetPasswordEmail: String?
    private(set) var lastConfirmResetPassword: (email: String, resetToken: String, newPassword: String, newPasswordConfirmation: String)?
    private(set) var lastSocialLogin: (provider: String, socialToken: String)?

    func register(
        name: String,
        email: String,
        password: String,
        passwordConfirmation: String,
        phone: String?
    ) async throws -> AuthSession {
        registerCallCount += 1
        if let errorToThrow { throw errorToThrow }
        return authSessionToReturn
    }

    func login(email: String, password: String) async throws -> AuthSession {
        lastLogin = (email, password)
        if let errorToThrow { throw errorToThrow }
        return authSessionToReturn
    }

    func verifyAccount(email: String, code: String) async throws {
        lastVerify = (email, code)
        if let errorToThrow { throw errorToThrow }
    }

    func resetPassword(email: String) async throws {
        lastResetPasswordEmail = email
        if let errorToThrow { throw errorToThrow }
    }

    func confirmResetPassword(
        email: String,
        resetToken: String,
        newPassword: String,
        newPasswordConfirmation: String
    ) async throws {
        lastConfirmResetPassword = (email, resetToken, newPassword, newPasswordConfirmation)
        if let errorToThrow { throw errorToThrow }
    }

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
        lastSocialLogin = (provider, socialToken)
        if let errorToThrow { throw errorToThrow }
        return authSessionToReturn
    }
}

struct AuthUseCaseTests {
    @Test func registerForwardsAndReturnsSession() async throws {
        let fake = FakeAuthRepository()
        let useCase = RegisterUseCase(repository: fake)

        let result = try await useCase(name: "Jane", email: "jane@example.com", password: "pw", passwordConfirmation: "pw", phone: nil)

        #expect(fake.registerCallCount == 1)
        #expect(result == fake.authSessionToReturn)
    }

    @Test func registerPropagatesError() async throws {
        let fake = FakeAuthRepository()
        fake.errorToThrow = StubError()
        let useCase = RegisterUseCase(repository: fake)

        await #expect(throws: StubError.self) {
            _ = try await useCase(name: "Jane", email: "jane@example.com", password: "pw", passwordConfirmation: "pw", phone: nil)
        }
    }

    @Test func loginForwardsCredentialsAndReturnsSession() async throws {
        let fake = FakeAuthRepository()
        let useCase = LoginUseCase(repository: fake)

        let result = try await useCase(email: "jane@example.com", password: "secret")

        #expect(fake.lastLogin?.email == "jane@example.com")
        #expect(fake.lastLogin?.password == "secret")
        #expect(result == fake.authSessionToReturn)
    }

    @Test func loginThrowsValidationErrorForInvalidEmailWithoutCallingRepository() async throws {
        let fake = FakeAuthRepository()
        let useCase = LoginUseCase(repository: fake)

        await #expect(throws: AuthValidationError.invalidEmailFormat) {
            _ = try await useCase(email: "not-an-email", password: "secret")
        }
        #expect(fake.lastLogin == nil)
    }

    @Test func verifyAccountForwardsEmailAndCode() async throws {
        let fake = FakeAuthRepository()
        let useCase = VerifyAccountUseCase(repository: fake)

        try await useCase(email: "jane@example.com", code: "123456")

        #expect(fake.lastVerify?.email == "jane@example.com")
        #expect(fake.lastVerify?.code == "123456")
    }

    @Test func resetPasswordForwardsEmail() async throws {
        let fake = FakeAuthRepository()
        let useCase = ResetPasswordUseCase(repository: fake)

        try await useCase(email: "jane@example.com")

        #expect(fake.lastResetPasswordEmail == "jane@example.com")
    }

    @Test func confirmResetPasswordForwardsAllFields() async throws {
        let fake = FakeAuthRepository()
        let useCase = ConfirmResetPasswordUseCase(repository: fake)

        try await useCase(email: "jane@example.com", resetToken: "rt", newPassword: "new1", newPasswordConfirmation: "new1")

        #expect(fake.lastConfirmResetPassword?.email == "jane@example.com")
        #expect(fake.lastConfirmResetPassword?.resetToken == "rt")
        #expect(fake.lastConfirmResetPassword?.newPassword == "new1")
        #expect(fake.lastConfirmResetPassword?.newPasswordConfirmation == "new1")
    }

    @Test func loginWithSocialForwardsProviderAndToken() async throws {
        let fake = FakeAuthRepository()
        let useCase = LoginWithSocialUseCase(repository: fake)

        let result = try await useCase(provider: "google", socialToken: "gtok")

        #expect(fake.lastSocialLogin?.provider == "google")
        #expect(fake.lastSocialLogin?.socialToken == "gtok")
        #expect(result == fake.authSessionToReturn)
    }
}
