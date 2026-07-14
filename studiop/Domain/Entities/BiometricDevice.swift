import Foundation

/// The pairing/enable state of a device for biometric login, per `/v1/biometric/*`.
struct BiometricDevice: Equatable, Sendable {
    var deviceID: String
    var deviceName: String
    var isEnabled: Bool

    init(deviceID: String, deviceName: String, isEnabled: Bool) {
        self.deviceID = deviceID
        self.deviceName = deviceName
        self.isEnabled = isEnabled
    }
}
