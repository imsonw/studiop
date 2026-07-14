import Foundation

struct ChangeUserProfileUseCase {
    let repository: UserRepository

    init(repository: UserRepository) {
        self.repository = repository
    }

    func callAsFunction(
        name: String? = nil,
        phone: String? = nil,
        email: String? = nil,
        companyName: String? = nil,
        taxCode: String? = nil,
        socialProvider: String? = nil
    ) async throws -> User {
        try await repository.changeUserProfile(
            name: name,
            phone: phone,
            email: email,
            companyName: companyName,
            taxCode: taxCode,
            socialProvider: socialProvider
        )
    }
}
