import Dependencies
import SwiftUI

struct BiometricSettingsView: View {
    @State private var viewModel: BiometricSettingsViewModel

    init() {
        @Dependency(\.biometricRepository) var biometricRepository
        @Dependency(\.biometricAuthenticating) var biometricAuthenticating
        @Dependency(\.biometricCredentialStore) var biometricCredentialStore

        _viewModel = State(initialValue: BiometricSettingsViewModel(
            enableBiometricUseCase: EnableBiometricUseCase(repository: biometricRepository),
            disableBiometricUseCase: DisableBiometricUseCase(repository: biometricRepository),
            checkBiometricStatusUseCase: CheckBiometricStatusUseCase(repository: biometricRepository),
            biometricAuthenticating: biometricAuthenticating,
            biometricCredentialStore: biometricCredentialStore
        ))
    }

    var body: some View {
        Form {
            if viewModel.isAvailable {
                Toggle(
                    "Face ID / Touch ID Login",
                    isOn: Binding(
                        get: { viewModel.isEnabled },
                        set: { newValue in
                            Task { await viewModel.setEnabled(newValue) }
                        }
                    )
                )
                .disabled(viewModel.isLoading)
            } else {
                Text("Face ID/Touch ID is not available on this device.")
                    .foregroundStyle(.secondary)
            }

            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .foregroundStyle(.red)
                    .font(.caption)
            }
        }
        .navigationTitle("Biometric Login")
        .task {
            await viewModel.loadStatus()
        }
    }
}

#Preview {
    NavigationStack {
        BiometricSettingsView()
    }
}
