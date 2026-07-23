import Foundation

/// `enableBiometric`/`disableBiometric`/`checkBiometricStatus` require an already-authenticated
/// session (`.userToken`) — pairing a device only makes sense once logged in. `loginWithBiometric`
/// uses `.publicToken` per docs/api-reference.md ("no user token needed for that call").
final class BiometricRepositoryImpl: BiometricRepository {
    private let networkClient: NetworkClient

    init(networkClient: NetworkClient) {
        self.networkClient = networkClient
    }

    func enableBiometric(deviceID: String, deviceName: String) async throws -> String {
        let dto = EnableBiometricRequestDTO(deviceID: deviceID, deviceName: deviceName)
        let data = try await networkClient.send(
            NetworkRequest(path: "v1/biometric/enable", method: .post, body: try JSONEncoder().encode(dto))
        )
        return try JSONDecoder().decode(EnableBiometricResponseDTO.self, from: data).biometricToken
    }

    func disableBiometric(deviceID: String) async throws {
        let dto = DisableBiometricRequestDTO(deviceID: deviceID)
        _ = try await networkClient.send(
            NetworkRequest(path: "v1/biometric/disable", method: .post, body: try JSONEncoder().encode(dto))
        )
    }

    func checkBiometricStatus(deviceID: String) async throws -> BiometricDevice {
        let data = try await networkClient.send(
            NetworkRequest(
                path: "v1/biometric/check-status",
                queryItems: [URLQueryItem(name: "device_id", value: deviceID)]
            )
        )
        return try JSONDecoder().decode(DataResponseDTO<BiometricStatusDTO>.self, from: data).data.toDomain()
    }

    func loginWithBiometric(
        deviceID: String,
        biometricToken: String
    ) async throws -> (session: AuthSession, newBiometricToken: String?) {
        let dto = LoginWithBiometricRequestDTO(deviceID: deviceID, biometricToken: biometricToken)
        let data = try await networkClient.send(
            NetworkRequest(
                path: "v1/biometric/login",
                method: .post,
                body: try JSONEncoder().encode(dto),
                authentication: .publicToken
            )
        )
        let responseDTO = try JSONDecoder().decode(BiometricLoginResponseDTO.self, from: data)
        return (responseDTO.toDomain(), responseDTO.newBiometricToken)
    }
}
