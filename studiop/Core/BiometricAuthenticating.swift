import Dependencies
import Foundation
import LocalAuthentication

/// The on-device Face ID/Touch ID prompt itself — distinct from `BiometricRepository`, which only
/// talks to the backend pairing/login endpoints. `canEvaluatePolicy` is a capability check (no
/// prompt shown); `authenticate(reason:)` actually shows the system prompt.
protocol BiometricAuthenticating: Sendable {
    func canEvaluatePolicy() -> Bool
    func authenticate(reason: String) async throws -> Bool
}

struct DeviceBiometricAuthenticator: BiometricAuthenticating {
    func canEvaluatePolicy() -> Bool {
        LAContext().canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
    }

    func authenticate(reason: String) async throws -> Bool {
        try await LAContext().evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason)
    }
}

/// Deterministic fakes for tests/previews — never touch real biometry hardware.
struct AlwaysSucceedsBiometricAuthenticator: BiometricAuthenticating {
    func canEvaluatePolicy() -> Bool { true }
    func authenticate(reason: String) async throws -> Bool { true }
}

struct UnavailableBiometricAuthenticator: BiometricAuthenticating {
    func canEvaluatePolicy() -> Bool { false }
    func authenticate(reason: String) async throws -> Bool {
        throw LAError(.biometryNotAvailable)
    }
}

extension LAError {
    /// User-initiated dismissals of the system biometric prompt (Cancel, "Enter Password", the
    /// system interrupting it) — not real failures, shouldn't surface as an error message. Mirrors
    /// the Flutter source app's `BiometricCubit._isSilentException` (2026-07-23).
    var isSilentDismissal: Bool {
        switch code {
        case .userCancel, .systemCancel, .appCancel, .userFallback:
            return true
        default:
            return false
        }
    }
}

private enum BiometricAuthenticatingKey: DependencyKey {
    static let liveValue: BiometricAuthenticating = DeviceBiometricAuthenticator()
    static let testValue: BiometricAuthenticating = UnavailableBiometricAuthenticator()
    static let previewValue: BiometricAuthenticating = AlwaysSucceedsBiometricAuthenticator()
}

extension DependencyValues {
    var biometricAuthenticating: BiometricAuthenticating {
        get { self[BiometricAuthenticatingKey.self] }
        set { self[BiometricAuthenticatingKey.self] = newValue }
    }
}
