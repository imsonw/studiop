import Foundation

/// Response for `POST /v1/biometric/enable`. Confirmed against the Flutter source app's
/// `BiometricCubit.enableBiometric` (2026-07-23): `biometric_token` is a **top-level** field
/// alongside `status`/`code`/`msg` (not nested under `data`), and is server-issued — the client
/// only generates `device_id`, never the token.
struct EnableBiometricResponseDTO: Decodable {
    let biometricToken: String

    enum CodingKeys: String, CodingKey {
        case biometricToken = "biometric_token"
    }
}
