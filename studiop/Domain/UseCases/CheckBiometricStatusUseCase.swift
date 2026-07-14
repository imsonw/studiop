import Foundation

struct CheckBiometricStatusUseCase {
    let repository: BiometricRepository

    init(repository: BiometricRepository) {
        self.repository = repository
    }

    func callAsFunction(deviceID: String) async throws -> BiometricDevice {
        try await repository.checkBiometricStatus(deviceID: deviceID)
    }
}
