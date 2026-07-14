import Foundation
import Testing
@testable import studiop

private let cannedAuthSessionJSON = """
{
    "token": "session-token",
    "user": {
        "id": 1,
        "id_encode": "abc123",
        "name": "Jane Doe",
        "email": "jane@example.com",
        "phone": "0123456789",
        "avatar": "https://example.com/avatar.png",
        "company_name": null,
        "tax_code": null,
        "social_provider": null
    }
}
"""

private func makeSUT() -> (AuthRepositoryImpl, FakeNetworkClient) {
    let fakeNetworkClient = FakeNetworkClient()
    fakeNetworkClient.dataToReturn = Data(cannedAuthSessionJSON.utf8)
    return (AuthRepositoryImpl(networkClient: fakeNetworkClient), fakeNetworkClient)
}

struct AuthRepositoryImplTests {
    @Test func loginSendsCorrectPathMethodAndPublicToken() async throws {
        let (sut, fakeNetworkClient) = makeSUT()

        let session = try await sut.login(email: "jane@example.com", password: "hunter2")

        let request = try #require(fakeNetworkClient.lastRequest)
        #expect(request.path == "users/login")
        #expect(request.method == .post)
        #expect(request.authentication == .publicToken)
        #expect(session.token == "session-token")
        #expect(session.user.email == "jane@example.com")
        #expect(session.user.idEncode == "abc123")
    }

    @Test func registerSendsRegistrationFieldsAsBody() async throws {
        let (sut, fakeNetworkClient) = makeSUT()

        _ = try await sut.register(
            name: "Jane Doe",
            email: "jane@example.com",
            password: "hunter2",
            passwordConfirmation: "hunter2",
            phone: "0123456789"
        )

        let request = try #require(fakeNetworkClient.lastRequest)
        #expect(request.path == "users/register")
        #expect(request.authentication == .publicToken)

        let body = try #require(request.body)
        let json = try #require(try JSONSerialization.jsonObject(with: body) as? [String: Any])
        #expect(json["password_confirmation"] as? String == "hunter2")
    }

    @Test func verifyAccountSendsEmailAndCode() async throws {
        let (sut, fakeNetworkClient) = makeSUT()

        try await sut.verifyAccount(email: "jane@example.com", code: "123456")

        let request = try #require(fakeNetworkClient.lastRequest)
        #expect(request.path == "users/verify/account")
        #expect(request.authentication == .publicToken)
    }

    @Test func confirmResetPasswordUsesSnakeCaseFieldNames() async throws {
        let (sut, fakeNetworkClient) = makeSUT()

        try await sut.confirmResetPassword(
            email: "jane@example.com",
            resetToken: "reset-token",
            newPassword: "newpw",
            newPasswordConfirmation: "newpw"
        )

        let request = try #require(fakeNetworkClient.lastRequest)
        #expect(request.path == "users/reset/password/confirm")
        let body = try #require(request.body)
        let json = try #require(try JSONSerialization.jsonObject(with: body) as? [String: Any])
        #expect(json["reset_token"] as? String == "reset-token")
        #expect(json["new_password_confirmation"] as? String == "newpw")
    }

    @Test func loginWithSocialSendsProviderAsSocialField() async throws {
        let (sut, fakeNetworkClient) = makeSUT()

        _ = try await sut.loginWithSocial(
            provider: "google",
            socialToken: "google-token",
            socialEmail: "jane@example.com",
            socialUserId: "g-123",
            socialName: "Jane",
            socialAvatar: nil,
            authCode: nil,
            codeVerifier: nil,
            redirectURI: nil
        )

        let request = try #require(fakeNetworkClient.lastRequest)
        #expect(request.path == "users/socials")
        let body = try #require(request.body)
        let json = try #require(try JSONSerialization.jsonObject(with: body) as? [String: Any])
        #expect(json["social"] as? String == "google")
        #expect(json["social_token"] as? String == "google-token")
    }

    @Test func loginPropagatesTransportError() async throws {
        let fakeNetworkClient = FakeNetworkClient()
        fakeNetworkClient.errorToThrow = NetworkError.transport("no connection")
        let sut = AuthRepositoryImpl(networkClient: fakeNetworkClient)

        await #expect(throws: NetworkError.self) {
            _ = try await sut.login(email: "jane@example.com", password: "hunter2")
        }
    }

    @Test func loginThrowsOnMalformedResponseBody() async throws {
        let fakeNetworkClient = FakeNetworkClient()
        fakeNetworkClient.dataToReturn = Data("not json".utf8)
        let sut = AuthRepositoryImpl(networkClient: fakeNetworkClient)

        await #expect(throws: Error.self) {
            _ = try await sut.login(email: "jane@example.com", password: "hunter2")
        }
    }
}
