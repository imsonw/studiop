import Dependencies
import SwiftUI

struct RegisterView: View {
    @State private var viewModel: RegisterViewModel

    init() {
        @Dependency(\.authRepository) var authRepository

        _viewModel = State(initialValue: RegisterViewModel(
            registerUseCase: RegisterUseCase(repository: authRepository)
        ))
    }

    var body: some View {
            ScrollView {
                VStack(spacing: 16) {
                    Text("Register")
                        .font(.title)
                    
                    ValidatedTextField(title: "Name", field: $viewModel.name) { value in
                        AuthFieldValidator.validateName(value)?.localizedMessage
                    }
                    .disabled(viewModel.isLoading)
                    
                    ValidatedTextField(title: "First name", field: $viewModel.firstName) { value in
                        AuthFieldValidator.validateName(value)?.localizedMessage
                    }
                    .disabled(viewModel.isLoading)
                    
                    ValidatedTextField(title: "Email", field: $viewModel.email) { value in
                        AuthFieldValidator.validateEmail(value)?.localizedMessage
                    }
                    .keyboardType(.emailAddress)
                    .autocorrectionDisabled()
                    .disabled(viewModel.isLoading)
                    
                    ValidatedTextField(title: "Password", field: $viewModel.password, isSecure: true) { value in
                        AuthFieldValidator.validatePassword(value)?.localizedMessage
                    }
                    .disabled(viewModel.isLoading)
                    
                    ValidatedTextField(
                        title: "Confirm password",
                        field: $viewModel.passwordConfirmation,
                        isSecure: true
                    ) { value in
                        AuthFieldValidator.validatePasswordConfirmation(value, matches: viewModel.password.value)?.localizedMessage
                    }
                    .disabled(viewModel.isLoading)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Toggle("I agree to the Terms of Service", isOn: $viewModel.agreeToTerms.value)
                            .onChange(of: viewModel.agreeToTerms.value) {
                                viewModel.agreeToTerms.error = AuthFieldValidator
                                    .validateTermsAccepted(viewModel.agreeToTerms.value)?.localizedMessage
                            }
                            .disabled(viewModel.isLoading)

                        if let error = viewModel.agreeToTerms.error {
                            Text(error)
                                .foregroundStyle(.red)
                                .font(.caption)
                        }
                    }

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
                            await viewModel.register()
                        }
                    }) {
                        if viewModel.isLoading {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                        } else {
                            Text("Create account")
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(
                        viewModel.isLoading
                        || viewModel.name.value.isEmpty
                        || viewModel.firstName.value.isEmpty
                        || viewModel.email.value.isEmpty
                        || viewModel.password.value.isEmpty
                        || viewModel.passwordConfirmation.value.isEmpty
                        || !viewModel.agreeToTerms.value
                    )
                }
                .padding()
            }
        }
}

#Preview {
    RegisterView()
}
