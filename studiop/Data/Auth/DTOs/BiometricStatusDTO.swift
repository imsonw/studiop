import Foundation

/// Response payload for `GET /v1/biometric/check-status`, decoded via `DataResponseDTO<
/// BiometricStatusDTO>` (this backend's general `{data: ...}` envelope).
///
/// - Note: UNCONFIRMED — docs/api-reference.md documents only the request
///   (`?device_id=`), not this response shape. Assumed the backend echoes back `device_id`/
///   `device_name` alongside `is_enabled` (it already has both from `/v1/biometric/enable`), so
///   `toDomain()` doesn't need a device name passed in separately. Verify against the Flutter
///   source or real captured traffic before treating this as confirmed — same discipline as the
///   `biometric_token` origin question flagged in `.agents/artifacts/sprint-006/sprint_plan@v1.yaml`.
struct BiometricStatusDTO: Decodable {
    let deviceID: String
    let deviceName: String
    let isEnabled: Bool

    enum CodingKeys: String, CodingKey {
        case deviceID = "device_id"
        case deviceName = "device_name"
        case isEnabled = "is_enabled"
    }

    func toDomain() -> BiometricDevice {
        BiometricDevice(deviceID: deviceID, deviceName: deviceName, isEnabled: isEnabled)
    }
}
