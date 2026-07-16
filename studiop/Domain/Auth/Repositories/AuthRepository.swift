import Foundation

/// Mirrors the auth endpoints in docs/api-reference.md exactly: register, login, email-link
/// verification, password reset (request + confirm), and social login (Google/Apple/TikTok).
protocol AuthRepository: Sendable {
    func register(
        name: String,
        firstName: String,
        email: String,
        password: String,
        passwordConfirmation: String,
        agreeToTerms: Bool
    ) async throws -> String

    func login(email: String, password: String) async throws -> AuthSession

    func verifyAccount(email: String, code: String) async throws

    func resetPassword(email: String) async throws

    func confirmResetPassword(
        email: String,
        resetToken: String,
        newPassword: String,
        newPasswordConfirmation: String
    ) async throws

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
    ) async throws -> AuthSession
}
