import Foundation

struct EnableBiometricUseCase {
    let repository: BiometricRepository

    init(repository: BiometricRepository) {
        self.repository = repository
    }

    func callAsFunction(deviceID: String, deviceName: String) async throws {
        try await repository.enableBiometric(deviceID: deviceID, deviceName: deviceName)
    }
}
