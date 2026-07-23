import Foundation
import LocalAuthentication

@MainActor
@Observable
final class LoginViewModel {
    var email = ValidatedField<String>(value: "")
    var password: String = ""
    var errorMessage: String?
    var isLoading: Bool = false
    /// Set when a social login succeeds but the provider didn't share an email (e.g. Apple only
    /// supplies one on the very first authorization) -- LoginView pushes CollectEmailView when true.
    var needsEmailCollection: Bool = false
    /// True only when a device is already paired (Keychain has a device_id/biometric_token) AND
    /// the device itself can evaluate Face ID/Touch ID right now -- LoginView shows the quick-login
    /// affordance only when this is true.
    private(set) var canUseBiometricLogin: Bool = false

    private let loginUseCase: LoginUseCase
    private let loginWithSocialUseCase: LoginWithSocialUseCase
    private let biometricLoginUseCase: BiometricLoginUseCase
    private let fetchUserInfoUseCase: FetchUserInfoUseCase
    private let keychainStore: KeychainStoring
    private let biometricAuthenticating: BiometricAuthenticating
    private let biometricCredentialStore: BiometricCredentialStoring
    private let appState: AppState

    init(
        loginUseCase: LoginUseCase,
        loginWithSocialUseCase: LoginWithSocialUseCase,
        biometricLoginUseCase: BiometricLoginUseCase,
        fetchUserInfoUseCase: FetchUserInfoUseCase,
        keychainStore: KeychainStoring,
        biometricAuthenticating: BiometricAuthenticating,
        biometricCredentialStore: BiometricCredentialStoring,
        appState: AppState
    ) {
        self.loginUseCase = loginUseCase
        self.loginWithSocialUseCase = loginWithSocialUseCase
        self.biometricLoginUseCase = biometricLoginUseCase
        self.fetchUserInfoUseCase = fetchUserInfoUseCase
        self.keychainStore = keychainStore
        self.biometricAuthenticating = biometricAuthenticating
        self.biometricCredentialStore = biometricCredentialStore
        self.appState = appState
        canUseBiometricLogin = biometricCredentialStore.read() != nil && biometricAuthenticating.canEvaluatePolicy()
    }

    func login() async {
        email.error = AuthFieldValidator.validateEmail(email.value)?.localizedMessage
        guard email.error == nil else { return }

        isLoading = true
        errorMessage = nil

        do {
            let session = try await loginUseCase(email: email.value, password: password)

            keychainStore.writeToken(session.token)

            _ = try await fetchUserInfoUseCase()

            appState.isAuthenticated = true
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    /// Never calls the backend before the on-device prompt passes -- see
    /// `.agents/artifacts/sprint-006/sprint_plan@v1.yaml` F-012's acceptance criteria.
    func loginWithBiometric() async {
        guard let pairing = biometricCredentialStore.read() else { return }

        isLoading = true
        errorMessage = nil

        do {
            let confirmed = try await biometricAuthenticating.authenticate(
                reason: "Log in to your account"
            )
            guard confirmed else {
                isLoading = false
                return
            }

            let result = try await biometricLoginUseCase(
                deviceID: pairing.deviceID,
                biometricToken: pairing.biometricToken
            )

            keychainStore.writeToken(result.session.token)

            _ = try await fetchUserInfoUseCase()

            appState.isAuthenticated = true

            // The backend rotates the pairing secret on every successful login -- overwrite the
            // stored token when it issues a new one, mirroring BiometricCubit.biometricLogin.
            if let newBiometricToken = result.newBiometricToken, !newBiometricToken.isEmpty {
                biometricCredentialStore.write(deviceID: pairing.deviceID, biometricToken: newBiometricToken)
            }
        } catch let error as LAError where error.isSilentDismissal {
            // User canceled the prompt or chose "Enter Password" -- they're already looking at
            // the password fields on this same screen, nothing else to do.
        } catch let error as NetworkError {
            switch error {
            case .apiError, .sessionInvalidated:
                // Server explicitly rejected this pairing (invalid token / account locked) --
                // it's dead, don't leave the quick-login button around to retry against it.
                biometricCredentialStore.clear()
                canUseBiometricLogin = false
                errorMessage = error.localizedDescription
            default:
                // Transport/unexpected error -- keep the pairing so the user can retry.
                errorMessage = error.localizedDescription
            }
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func appleSignInFailed(_ error: Error) {
        errorMessage = error.localizedDescription
    }

    /// `provider` is sent to the backend as-is ("apple") -- not yet confirmed against real
    /// captured traffic what literal value this backend expects, same caveat as the other
    /// DTO-shape assumptions flagged in docs/api-reference.md.
    func loginWithApple(_ credential: AppleSignInCredential) async {
        isLoading = true
        errorMessage = nil

        do {
            let session = try await loginWithSocialUseCase(
                provider: "apple",
                socialToken: credential.identityToken,
                socialEmail: credential.email,
                socialUserId: credential.userIdentifier,
                socialName: credential.fullName
            )

            keychainStore.writeToken(session.token)

            let user = try await fetchUserInfoUseCase()

            if user.email.isEmpty {
                needsEmailCollection = true
            } else {
                appState.isAuthenticated = true
            }
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}
