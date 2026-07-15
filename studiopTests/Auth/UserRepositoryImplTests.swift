import Foundation
import Testing
@testable import studiop

// Shape confirmed against a real captured `/users/info` response (200 OK): the user object is
// wrapped under `data`, same envelope as `/users/login`; `id_encode` is a JSON number.
private let cannedUserJSON = """
{
    "status": 1,
    "msg": "Get info Success.",
    "data": {
        "id": 1,
        "id_encode": 123,
        "name": "Jane Doe",
        "email": "jane@example.com",
        "phone": "0123456789",
        "avatar": null,
        "company_name": null,
        "tax_code": null,
        "social_provider": null
    }
}
"""

private func makeSUT() -> (UserRepositoryImpl, FakeNetworkClient) {
    let fakeNetworkClient = FakeNetworkClient()
    fakeNetworkClient.dataToReturn = Data(cannedUserJSON.utf8)
    return (UserRepositoryImpl(networkClient: fakeNetworkClient), fakeNetworkClient)
}

struct UserRepositoryImplTests {
    @Test func fetchUserInfoSendsCorrectPathAndUserToken() async throws {
        let (sut, fakeNetworkClient) = makeSUT()

        let user = try await sut.fetchUserInfo()

        let request = try #require(fakeNetworkClient.lastRequest)
        #expect(request.path == "users/info")
        #expect(request.method == .get)
        #expect(request.authentication == .userToken)
        #expect(user.email == "jane@example.com")
        #expect(user.idEncode == "123")
    }

    @Test func changePasswordSendsSnakeCaseFieldNames() async throws {
        let (sut, fakeNetworkClient) = makeSUT()

        try await sut.changePassword(currentPassword: "old", newPassword: "new")

        let request = try #require(fakeNetworkClient.lastRequest)
        #expect(request.path == "users/change/password")
        #expect(request.authentication == .userToken)
        let body = try #require(request.body)
        let json = try #require(try JSONSerialization.jsonObject(with: body) as? [String: Any])
        #expect(json["current_password"] as? String == "old")
        #expect(json["new_password"] as? String == "new")
    }

    @Test func changeUserInfoSendsFullProfileAndReturnsUpdatedUser() async throws {
        let (sut, fakeNetworkClient) = makeSUT()
        let user = User(id: 1, idEncode: "abc123", name: "Jane Doe", email: "jane@example.com")

        let updated = try await sut.changeUserInfo(user)

        let request = try #require(fakeNetworkClient.lastRequest)
        #expect(request.path == "users/change/info")
        #expect(updated.email == "jane@example.com")
    }

    @Test func changeUserAddressSendsMainAndShippingAddress() async throws {
        let (sut, fakeNetworkClient) = makeSUT()
        let main = Address(
            fullName: "Jane Doe",
            phone: "0123456789",
            address: "123 Main St",
            houseNumber: "1",
            postalCode: "1000",
            location: "Amsterdam",
            country: "NL"
        )

        try await sut.changeUserAddress(mainAddress: main, shippingAddress: nil)

        let request = try #require(fakeNetworkClient.lastRequest)
        #expect(request.path == "users/change/address")
        let body = try #require(request.body)
        let json = try #require(try JSONSerialization.jsonObject(with: body) as? [String: Any])
        let mainJSON = try #require(json["main_address"] as? [String: Any])
        #expect(mainJSON["full_name"] as? String == "Jane Doe")
        // Swift's synthesized `Encodable` uses `encodeIfPresent` for Optional properties, so a
        // nil `shippingAddress` is omitted from the JSON entirely, not encoded as `null`.
        #expect(json["shipping_address"] == nil)
    }

    @Test func requestAccountRemovalSendsReason() async throws {
        let (sut, fakeNetworkClient) = makeSUT()

        try await sut.requestAccountRemoval(reason: "no longer needed")

        let request = try #require(fakeNetworkClient.lastRequest)
        #expect(request.path == "users/request_remove")
        let body = try #require(request.body)
        let json = try #require(try JSONSerialization.jsonObject(with: body) as? [String: Any])
        #expect(json["reason"] as? String == "no longer needed")
    }

    @Test func fetchUserInfoThrowsOnMalformedResponse() async throws {
        let fakeNetworkClient = FakeNetworkClient()
        fakeNetworkClient.dataToReturn = Data("not json".utf8)
        let sut = UserRepositoryImpl(networkClient: fakeNetworkClient)

        await #expect(throws: Error.self) {
            _ = try await sut.fetchUserInfo()
        }
    }

    // Verbatim real `/users/info` response (200 OK) captured from staging — regression test for
    // the `{data}` wrapper, confirming it matches `/users/login`'s envelope.
    @Test func fetchUserInfoDecodesARealCapturedResponse() async throws {
        let realResponseJSON = """
        {
          "status": 1,
          "msg": "Get info Success.",
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
          }
        }
        """
        let fakeNetworkClient = FakeNetworkClient()
        fakeNetworkClient.dataToReturn = Data(realResponseJSON.utf8)
        let sut = UserRepositoryImpl(networkClient: fakeNetworkClient)

        let user = try await sut.fetchUserInfo()

        #expect(user.idEncode == "2079435752")
        #expect(user.email == "19@yopmail.com")
    }
}
