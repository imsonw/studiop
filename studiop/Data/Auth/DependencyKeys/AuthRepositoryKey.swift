import Dependencies
import Foundation

private struct UnimplementedAuthRepository: AuthRepository {
    private struct Unimplemented: Error {}

    func register(
        name: String,
        firstName: String,
        email: String,
        password: String,
        passwordConfirmation: String,
        agreeToTerms: Bool
    ) async throws -> String {
        throw Unimplemented()
    }

    func login(email: String, password: String) async throws -> AuthSession {
        throw Unimplemented()
    }

    func verifyAccount(email: String, code: String) async throws {
        throw Unimplemented()
    }

    func resetPassword(email: String) async throws {
        throw Unimplemented()
    }

    func confirmResetPassword(
        email: String,
        resetToken: String,
        newPassword: String,
        newPasswordConfirmation: String
    ) async throws {
        throw Unimplemented()
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
        throw Unimplemented()
    }
}

private struct PreviewAuthRepository: AuthRepository {
    static let cannedSession = AuthSession(
        user: User(id: 1, idEncode: "preview-user", name: "Preview User", email: "preview@example.com"),
        token: "preview-token"
    )

    func register(
        name: String,
        firstName: String,
        email: String,
        password: String,
        passwordConfirmation: String,
        agreeToTerms: Bool
    ) async throws -> String {
        "Registration successful. Please check your email to verify your account."
    }

    func login(email: String, password: String) async throws -> AuthSession {
        Self.cannedSession
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
        Self.cannedSession
    }
}

private enum AuthRepositoryKey: DependencyKey {
    static var liveValue: AuthRepository {
        @Dependency(\.networkClient) var networkClient
        return AuthRepositoryImpl(networkClient: networkClient)
    }

    static let testValue: AuthRepository = UnimplementedAuthRepository()
    static let previewValue: AuthRepository = PreviewAuthRepository()
}

extension DependencyValues {
    var authRepository: AuthRepository {
        get { self[AuthRepositoryKey.self] }
        set { self[AuthRepositoryKey.self] = newValue }
    }
}
