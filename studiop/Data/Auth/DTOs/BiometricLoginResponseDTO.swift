import Foundation

/// Response for `POST /v1/biometric/login`. Same envelope shape as `AuthSessionResponseDTO`
/// (`{token, data}`), plus an optional top-level `new_biometric_token` — confirmed against the
/// Flutter source app's `BiometricCubit.biometricLogin` (2026-07-23): the backend rotates the
/// pairing secret on every successful biometric login, and the client must overwrite its stored
/// `biometric_token` with this value when present.
struct BiometricLoginResponseDTO: Decodable {
    let token: String
    let data: UserDTO
    let newBiometricToken: String?

    enum CodingKeys: String, CodingKey {
        case token
        case data
        case newBiometricToken = "new_biometric_token"
    }

    func toDomain() -> AuthSession {
        AuthSession(user: data.toDomain(), token: token)
    }
}
