import Dependencies
import SwiftUI

struct ResetPasswordRequestView: View {
    @State private var viewModel: ResetPasswordRequestViewModel

    init() {
        @Dependency(\.authRepository) var authRepository

        _viewModel = State(initialValue: ResetPasswordRequestViewModel(
            resetPasswordUseCase: ResetPasswordUseCase(repository: authRepository)
        ))
    }

    var body: some View {
        VStack(spacing: 16) {
            Text("Forgot Password")
                .font(.title)

            ValidatedTextField(title: "Email", field: $viewModel.email) { value in
                AuthFieldValidator.validateEmail(value)?.localizedMessage
            }
            .keyboardType(.emailAddress)
            .autocorrectionDisabled()
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

                NavigationLink("I have a reset code") {
                    ResetPasswordConfirmView()
                }
            }

            Button(action: {
                Task {
                    await viewModel.requestReset()
                }
            }) {
                if viewModel.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                } else {
                    Text("Send reset code")
                        .frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(viewModel.isLoading || viewModel.email.value.isEmpty)

            Spacer()
        }
        .padding()
    }
}

#Preview {
    NavigationStack {
        ResetPasswordRequestView()
    }
}
