import Foundation

struct DisableBiometricUseCase {
    let repository: BiometricRepository

    init(repository: BiometricRepository) {
        self.repository = repository
    }

    func callAsFunction(deviceID: String) async throws {
        try await repository.disableBiometric(deviceID: deviceID)
    }
}
