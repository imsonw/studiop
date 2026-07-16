import Foundation

/// Every method here is pre-authentication — no user session exists yet — so every call uses
/// `.publicToken`, per docs/api-reference.md -> Auth mechanism.
final class AuthRepositoryImpl: AuthRepository {
    private let networkClient: NetworkClient

    init(networkClient: NetworkClient) {
        self.networkClient = networkClient
    }

    func register(
        name: String,
        firstName: String,
        email: String,
        password: String,
        passwordConfirmation: String,
        agreeToTerms: Bool
    ) async throws -> String {
        let dto = RegisterRequestDTO(
            name: name,
            firstName: firstName,
            email: email,
            password: password,
            passwordConfirmation: passwordConfirmation,
            checkTerms: agreeToTerms
        )
        let data = try await networkClient.send(
            NetworkRequest(
                path: "users/register",
                method: .post,
                body: try JSONEncoder().encode(dto),
                authentication: .publicToken
            )
        )
        return try JSONDecoder().decode(RegisterResponseDTO.self, from: data).msg
    }

    func login(email: String, password: String) async throws -> AuthSession {
        let dto = LoginRequestDTO(email: email, password: password)
        let data = try await networkClient.send(
            NetworkRequest(
                path: "users/login",
                method: .post,
                body: try JSONEncoder().encode(dto),
                authentication: .publicToken
            )
        )
        return try Self.decodeSession(from: data)
    }

    func verifyAccount(email: String, code: String) async throws {
        let dto = VerifyAccountRequestDTO(email: email, code: code)
        _ = try await networkClient.send(
            NetworkRequest(
                path: "users/verify/account",
                method: .post,
                body: try JSONEncoder().encode(dto),
                authentication: .publicToken
            )
        )
    }

    func resetPassword(email: String) async throws {
        let dto = ResetPasswordRequestDTO(email: email)
        _ = try await networkClient.send(
            NetworkRequest(
                path: "users/reset/password",
                method: .post,
                body: try JSONEncoder().encode(dto),
                authentication: .publicToken
            )
        )
    }

    func confirmResetPassword(
        email: String,
        resetToken: String,
        newPassword: String,
        newPasswordConfirmation: String
    ) async throws {
        let dto = ConfirmResetPasswordRequestDTO(
            email: email,
            resetToken: resetToken,
            newPassword: newPassword,
            newPasswordConfirmation: newPasswordConfirmation
        )
        _ = try await networkClient.send(
            NetworkRequest(
                path: "users/reset/password/confirm",
                method: .post,
                body: try JSONEncoder().encode(dto),
                authentication: .publicToken
            )
        )
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
        let dto = SocialLoginRequestDTO(
            social: provider,
            socialToken: socialToken,
            socialEmail: socialEmail,
            socialUserId: socialUserId,
            socialName: socialName,
            socialAvatar: socialAvatar,
            authCode: authCode,
            codeVerifier: codeVerifier,
            redirectURI: redirectURI
        )
        let data = try await networkClient.send(
            NetworkRequest(
                path: "users/socials",
                method: .post,
                body: try JSONEncoder().encode(dto),
                authentication: .publicToken
            )
        )
        return try Self.decodeSession(from: data)
    }

    private static func decodeSession(from data: Data) throws -> AuthSession {
        try JSONDecoder().decode(AuthSessionResponseDTO.self, from: data).toDomain()
    }
}
