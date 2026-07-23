import Foundation

/// Body for `POST /v1/biometric/enable`.
struct EnableBiometricRequestDTO: Encodable {
    let deviceID: String
    let deviceName: String

    enum CodingKeys: String, CodingKey {
        case deviceID = "device_id"
        case deviceName = "device_name"
    }
}
