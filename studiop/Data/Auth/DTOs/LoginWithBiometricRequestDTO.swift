import Foundation

/// Body for `POST /v1/biometric/login`.
struct LoginWithBiometricRequestDTO: Encodable {
    let deviceID: String
    let biometricToken: String

    enum CodingKeys: String, CodingKey {
        case deviceID = "device_id"
        case biometricToken = "biometric_token"
    }
}
