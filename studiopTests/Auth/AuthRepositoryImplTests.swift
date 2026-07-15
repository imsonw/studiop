import Foundation
import Testing
@testable import studiop

// Shape confirmed against a real captured `/users/login` response (200 OK): the user object is
// under `data`, not `user`; `id_encode` is a JSON number, not a string.
private let cannedAuthSessionJSON = """
{
    "status": 1,
    "code": "U200",
    "msg": "Logged in successfully.",
    "data": {
        "id": 1,
        "id_encode": 123,
        "name": "Jane Doe",
        "email": "jane@example.com",
        "phone": "0123456789",
        "avatar": "https://example.com/avatar.png",
        "company_name": null,
        "tax_code": null,
        "social_provider": null
    },
    "token": "session-token"
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
        #expect(session.user.idEncode == "123")
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

    // Verbatim real `/users/login` response (200 OK) captured from staging — regression test for
    // the `{data}` (not `{user}`) wrapper and `id_encode` being a JSON number, not a string.
    @Test func loginDecodesARealCapturedSuccessResponse() async throws {
        let realResponseJSON = """
        {
          "status": 1,
          "code": "U200",
          "msg": "Logged in successfully.",
          "data": {
            "id": 14915,
            "id_encode": 2079435752,
            "code": "U00014915",
            "username": "19_yopmail_com",
            "name": "Nam",
            "email": "19@yopmail.com",
            "status": 1,
            "delete_code": null,
            "deleted_reason": null,
            "avatar": "https://cdn.action89.eu/devstream/thumb/200_200_fit/27fb2fe965c1139f14de65cf31aed033.webp",
            "gender": null,
            "whatsapp": null,
            "phone": "94949",
            "active": 1,
            "company": null,
            "shipping_address": null,
            "tiktok_username": null,
            "vat_id": null,
            "role": "customer",
            "is_studio": false,
            "nickname": "2079435752"
          },
          "token": "u6cd426e6-6562-42a4-9db6-7ffa472600e6"
        }
        """
        let fakeNetworkClient = FakeNetworkClient()
        fakeNetworkClient.dataToReturn = Data(realResponseJSON.utf8)
        let sut = AuthRepositoryImpl(networkClient: fakeNetworkClient)

        let session = try await sut.login(email: "19@yopmail.com", password: "123456789")

        #expect(session.token == "u6cd426e6-6562-42a4-9db6-7ffa472600e6")
        #expect(session.user.idEncode == "2079435752")
        #expect(session.user.email == "19@yopmail.com")
    }
}
