import Foundation

/// Mirrors `/v1/biometric/*` in docs/api-reference.md. `loginWithBiometric` uses the backend's
/// public token, not a signed-in user's token — that distinction is a Data-layer/NetworkClient
/// concern, not something this protocol needs to express.
///
/// Confirmed against the Flutter source app's `BiometricCubit` (2026-07-23): the backend issues
/// `biometric_token` itself on enable (the client never generates it), and rotates it on every
/// successful `loginWithBiometric` call — see the return types below.
protocol BiometricRepository: Sendable {
    /// Returns the server-issued `biometric_token` to pair with `deviceID`.
    func enableBiometric(deviceID: String, deviceName: String) async throws -> String

    func disableBiometric(deviceID: String) async throws

    func checkBiometricStatus(deviceID: String) async throws -> BiometricDevice

    /// `newBiometricToken` is non-nil when the backend rotates the pairing secret on this login —
    /// callers must overwrite their stored `biometricToken` with it when present.
    func loginWithBiometric(
        deviceID: String,
        biometricToken: String
    ) async throws -> (session: AuthSession, newBiometricToken: String?)
}
