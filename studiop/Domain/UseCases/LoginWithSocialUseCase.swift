import Foundation

struct LoginWithSocialUseCase {
    let repository: AuthRepository

    init(repository: AuthRepository) {
        self.repository = repository
    }

    func callAsFunction(
        provider: String,
        socialToken: String,
        socialEmail: String? = nil,
        socialUserId: String? = nil,
        socialName: String? = nil,
        socialAvatar: String? = nil,
        authCode: String? = nil,
        codeVerifier: String? = nil,
        redirectURI: String? = nil
    ) async throws -> AuthSession {
        try await repository.loginWithSocial(
            provider: provider,
            socialToken: socialToken,
            socialEmail: socialEmail,
            socialUserId: socialUserId,
            socialName: socialName,
            socialAvatar: socialAvatar,
            authCode: authCode,
            codeVerifier: codeVerifier,
            redirectURI: redirectURI
        )
    }
}
