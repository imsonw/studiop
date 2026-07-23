import Foundation

/// Body for `POST /v1/biometric/disable`.
struct DisableBiometricRequestDTO: Encodable {
    let deviceID: String

    enum CodingKeys: String, CodingKey {
        case deviceID = "device_id"
    }
}
