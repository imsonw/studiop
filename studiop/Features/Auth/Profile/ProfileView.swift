import Dependencies
import SwiftUI

/// The account/settings hub for this sprint -- surfaces Biometric settings (F-012) and account
/// deletion (F-015) alongside profile editing, ahead of the full bottom-tab shell (Sprint 9's
/// F-028). See sprint-006/sprint_plan@v1.yaml, F-014 acceptance criteria.
struct ProfileView: View {
    private let appState: AppState
    @State private var viewModel: ProfileViewModel

    init(appState: AppState) {
        self.appState = appState

        @Dependency(\.userRepository) var userRepository
        @Dependency(\.biometricCredentialStore) var biometricCredentialStore

        _viewModel = State(initialValue: ProfileViewModel(
            fetchUserInfoUseCase: FetchUserInfoUseCase(repository: userRepository),
            changeUserProfileUseCase: ChangeUserProfileUseCase(repository: userRepository),
            changePasswordUseCase: ChangePasswordUseCase(repository: userRepository),
            biometricCredentialStore: biometricCredentialStore
        ))
    }

    var body: some View {
        Form {
            Section("Profile") {
                ValidatedTextField(title: "Name", field: $viewModel.name) { _ in nil }
                ValidatedTextField(title: "Email", field: $viewModel.email) { _ in nil }
                    .keyboardType(.emailAddress)
                    .autocorrectionDisabled()
                ValidatedTextField(title: "Phone", field: $viewModel.phone) { _ in nil }
                    .keyboardType(.phonePad)
                ValidatedTextField(title: "Company name", field: $viewModel.companyName) { _ in nil }
                ValidatedTextField(title: "Tax code", field: $viewModel.taxCode) { _ in nil }

                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                        .font(.caption)
                }
                if let successMessage = viewModel.successMessage {
                    Text(successMessage)
                        .foregroundStyle(.green)
                        .font(.caption)
                }

                Button(action: {
                    Task { await viewModel.saveProfile() }
                }) {
                    if viewModel.isLoading {
                        ProgressView()
                    } else {
                        Text("Save")
                    }
                }
                .disabled(viewModel.isLoading)
            }

            Section("Change Password") {
                SecureField("Current password", text: $viewModel.currentPassword)
                SecureField("New password", text: $viewModel.newPassword)

                if let passwordErrorMessage = viewModel.passwordErrorMessage {
                    Text(passwordErrorMessage)
                        .foregroundStyle(.red)
                        .font(.caption)
                }
                if let passwordSuccessMessage = viewModel.passwordSuccessMessage {
                    Text(passwordSuccessMessage)
                        .foregroundStyle(.green)
                        .font(.caption)
                }

                Button(action: {
                    Task { await viewModel.changePassword() }
                }) {
                    if viewModel.isChangingPassword {
                        ProgressView()
                    } else {
                        Text("Change Password")
                    }
                }
                .disabled(
                    viewModel.isChangingPassword
                    || viewModel.currentPassword.isEmpty
                    || viewModel.newPassword.isEmpty
                )
            }

            Section("Security") {
                NavigationLink("Face ID / Touch ID") {
                    BiometricSettingsView()
                }
            }

            Section("Address Book") {
                NavigationLink("Manage Addresses") {
                    AddressListView()
                }
            }

            Section {
                NavigationLink("Delete Account") {
                    AccountDeletionRequestView(appState: appState)
                }
                .foregroundStyle(.red)
            }
        }
        .navigationTitle("Account")
        .task {
            await viewModel.loadProfile()
        }
    }
}

#Preview {
    NavigationStack {
        ProfileView(appState: AppState())
    }
}
