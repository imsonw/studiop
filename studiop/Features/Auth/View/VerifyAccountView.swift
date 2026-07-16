import Dependencies
import SwiftUI

struct VerifyAccountView: View {
    @State private var viewModel: VerifyAccountViewModel

    init() {
        @Dependency(\.authRepository) var authRepository

        _viewModel = State(initialValue: VerifyAccountViewModel(
            verifyAccountUseCase: VerifyAccountUseCase(repository: authRepository)
        ))
    }

    var body: some View {
        VStack(spacing: 16) {
            Text("Verify Account")
                .font(.title)

            ValidatedTextField(title: "Email", field: $viewModel.email) { value in
                AuthFieldValidator.validateEmail(value)?.localizedMessage
            }
            .keyboardType(.emailAddress)
            .autocorrectionDisabled()
            .disabled(viewModel.isLoading)

            TextField("Verification code", text: $viewModel.code)
                .textFieldStyle(.roundedBorder)
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
                    await viewModel.verify()
                }
            }) {
                if viewModel.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                } else {
                    Text("Verify")
                        .frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(viewModel.isLoading || viewModel.email.value.isEmpty || viewModel.code.isEmpty)

            Spacer()
        }
        .padding()
    }
}

#Preview {
    VerifyAccountView()
}
