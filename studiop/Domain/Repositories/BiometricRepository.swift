import Foundation

/// Mirrors `/v1/biometric/*` in docs/api-reference.md. `loginWithBiometric` uses the backend's
/// public token, not a signed-in user's token — that distinction is a Data-layer/NetworkClient
/// concern, not something this protocol needs to express.
protocol BiometricRepository: Sendable {
    func enableBiometric(deviceID: String, deviceName: String) async throws

    func disableBiometric(deviceID: String) async throws

    func checkBiometricStatus(deviceID: String) async throws -> BiometricDevice

    func loginWithBiometric(deviceID: String, biometricToken: String) async throws -> AuthSession
}
