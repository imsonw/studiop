import Dependencies
import Foundation

private struct UnimplementedBiometricRepository: BiometricRepository {
    private struct Unimplemented: Error {}

    func enableBiometric(deviceID: String, deviceName: String) async throws -> String {
        throw Unimplemented()
    }

    func disableBiometric(deviceID: String) async throws {
        throw Unimplemented()
    }

    func checkBiometricStatus(deviceID: String) async throws -> BiometricDevice {
        throw Unimplemented()
    }

    func loginWithBiometric(
        deviceID: String,
        biometricToken: String
    ) async throws -> (session: AuthSession, newBiometricToken: String?) {
        throw Unimplemented()
    }
}

private struct PreviewBiometricRepository: BiometricRepository {
    func enableBiometric(deviceID: String, deviceName: String) async throws -> String {
        "preview-biometric-token"
    }

    func disableBiometric(deviceID: String) async throws {}

    func checkBiometricStatus(deviceID: String) async throws -> BiometricDevice {
        BiometricDevice(deviceID: deviceID, deviceName: "Preview Device", isEnabled: true)
    }

    func loginWithBiometric(
        deviceID: String,
        biometricToken: String
    ) async throws -> (session: AuthSession, newBiometricToken: String?) {
        let session = AuthSession(
            user: User(id: 1, idEncode: "preview-user", name: "Preview User", email: "preview@example.com"),
            token: "preview-token"
        )
        return (session, nil)
    }
}

private enum BiometricRepositoryKey: DependencyKey {
    static var liveValue: BiometricRepository {
        @Dependency(\.networkClient) var networkClient
        return BiometricRepositoryImpl(networkClient: networkClient)
    }

    static let testValue: BiometricRepository = UnimplementedBiometricRepository()
    static let previewValue: BiometricRepository = PreviewBiometricRepository()
}

extension DependencyValues {
    var biometricRepository: BiometricRepository {
        get { self[BiometricRepositoryKey.self] }
        set { self[BiometricRepositoryKey.self] = newValue }
    }
}
