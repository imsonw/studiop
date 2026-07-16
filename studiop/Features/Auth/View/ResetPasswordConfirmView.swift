import Dependencies
import SwiftUI

struct ResetPasswordConfirmView: View {
    @State private var viewModel: ResetPasswordConfirmViewModel

    init() {
        @Dependency(\.authRepository) var authRepository

        _viewModel = State(initialValue: ResetPasswordConfirmViewModel(
            confirmResetPasswordUseCase: ConfirmResetPasswordUseCase(repository: authRepository)
        ))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Text("Reset Password")
                    .font(.title)

                ValidatedTextField(title: "Email", field: $viewModel.email) { value in
                    AuthFieldValidator.validateEmail(value)?.localizedMessage
                }
                .keyboardType(.emailAddress)
                .autocorrectionDisabled()
                .disabled(viewModel.isLoading)

                TextField("Reset code", text: $viewModel.resetToken)
                    .textFieldStyle(.roundedBorder)
                    .disabled(viewModel.isLoading)

                ValidatedTextField(title: "New password", field: $viewModel.newPassword, isSecure: true) { value in
                    AuthFieldValidator.validatePassword(value)?.localizedMessage
                }
                .disabled(viewModel.isLoading)

                ValidatedTextField(
                    title: "Confirm new password",
                    field: $viewModel.newPasswordConfirmation,
                    isSecure: true
                ) { value in
                    AuthFieldValidator.validatePasswordConfirmation(value, matches: viewModel.newPassword.value)?
                        .localizedMessage
                }
                .disabled(viewModel.isLoading)

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
                    Task {
                        await viewModel.confirmReset()
                    }
                }) {
                    if viewModel.isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                    } else {
                        Text("Reset password")
                            .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(
                    viewModel.isLoading
                        || viewModel.email.value.isEmpty
                        || viewModel.resetToken.isEmpty
                        || viewModel.newPassword.value.isEmpty
                        || viewModel.newPasswordConfirmation.value.isEmpty
                )
            }
            .padding()
        }
    }
}

#Preview {
    ResetPasswordConfirmView()
}
