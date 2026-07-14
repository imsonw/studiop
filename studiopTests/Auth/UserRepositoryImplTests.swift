import Foundation
import Testing
@testable import studiop

private let cannedUserJSON = """
{
    "id": 1,
    "id_encode": "abc123",
    "name": "Jane Doe",
    "email": "jane@example.com",
    "phone": "0123456789",
    "avatar": null,
    "company_name": null,
    "tax_code": null,
    "social_provider": null
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
        #expect(user.idEncode == "abc123")
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
}
