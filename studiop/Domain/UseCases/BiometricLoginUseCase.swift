import Foundation

struct BiometricLoginUseCase {
    let repository: BiometricRepository

    init(repository: BiometricRepository) {
        self.repository = repository
    }

    func callAsFunction(deviceID: String, biometricToken: String) async throws -> AuthSession {
        try await repository.loginWithBiometric(deviceID: deviceID, biometricToken: biometricToken)
    }
}
