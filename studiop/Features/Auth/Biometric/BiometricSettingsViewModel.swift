import Foundation
import LocalAuthentication
import UIKit

@MainActor
@Observable
final class BiometricSettingsViewModel {
    private(set) var isEnabled: Bool = false
    private(set) var isAvailable: Bool
    var isLoading: Bool = false
    var errorMessage: String?

    private let enableBiometricUseCase: EnableBiometricUseCase
    private let disableBiometricUseCase: DisableBiometricUseCase
    private let checkBiometricStatusUseCase: CheckBiometricStatusUseCase
    private let biometricAuthenticating: BiometricAuthenticating
    private let biometricCredentialStore: BiometricCredentialStoring

    init(
        enableBiometricUseCase: EnableBiometricUseCase,
        disableBiometricUseCase: DisableBiometricUseCase,
        checkBiometricStatusUseCase: CheckBiometricStatusUseCase,
        biometricAuthenticating: BiometricAuthenticating,
        biometricCredentialStore: BiometricCredentialStoring
    ) {
        self.enableBiometricUseCase = enableBiometricUseCase
        self.disableBiometricUseCase = disableBiometricUseCase
        self.checkBiometricStatusUseCase = checkBiometricStatusUseCase
        self.biometricAuthenticating = biometricAuthenticating
        self.biometricCredentialStore = biometricCredentialStore
        isAvailable = biometricAuthenticating.canEvaluatePolicy()
    }

    func loadStatus() async {
        guard isAvailable, let pairing = biometricCredentialStore.read() else {
            isEnabled = false
            return
        }

        isLoading = true
        do {
            let device = try await checkBiometricStatusUseCase(deviceID: pairing.deviceID)
            isEnabled = device.isEnabled
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func setEnabled(_ newValue: Bool) async {
        isLoading = true
        errorMessage = nil

        if newValue {
            do {
                let confirmed = try await biometricAuthenticating.authenticate(
                    reason: "Enable Face ID / Touch ID login"
                )
                guard confirmed else {
                    isLoading = false
                    return
                }

                let deviceID = biometricCredentialStore.read()?.deviceID
                    ?? UIDevice.current.identifierForVendor?.uuidString
                    ?? UUID().uuidString

                let biometricToken = try await enableBiometricUseCase(
                    deviceID: deviceID,
                    deviceName: UIDevice.current.name
                )
                biometricCredentialStore.write(deviceID: deviceID, biometricToken: biometricToken)
                isEnabled = true
            } catch let error as LAError where error.isSilentDismissal {
                // User canceled the prompt -- not an error.
            } catch {
                errorMessage = error.localizedDescription
            }
        } else {
            // Mirrors BiometricCubit.disableBiometric: always clear the local pairing, even if
            // the disable call fails on the network -- leaving a stale pairing behind after the
            // user asked to turn this off is worse than an unpaired device on the backend.
            if let pairing = biometricCredentialStore.read() {
                do {
                    try await disableBiometricUseCase(deviceID: pairing.deviceID)
                } catch {
                    // Network/server error -- fall through and clear locally anyway.
                }
                biometricCredentialStore.clear()
            }
            isEnabled = false
        }

        isLoading = false
    }
}
