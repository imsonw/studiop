import Dependencies
import SwiftUI

struct LoginView: View {
    private let appState: AppState
    @State private var viewModel: LoginViewModel

    init(appState: AppState) {
        self.appState = appState

        @Dependency(\.authRepository) var authRepository
        @Dependency(\.userRepository) var userRepository
        @Dependency(\.keychainStore) var keychainStore

        _viewModel = State(initialValue: LoginViewModel(
            loginUseCase: LoginUseCase(repository: authRepository),
            fetchUserInfoUseCase: FetchUserInfoUseCase(repository: userRepository),
            keychainStore: keychainStore,
            appState: appState
        ))
    }

    var body: some View {
        VStack(spacing: 16) {
            Text("Login")
                .font(.title)

            ValidatedTextField(title: "Email", field: $viewModel.email) { value in
                AuthFieldValidator.validateEmail(value)?.localizedMessage
            }
            .keyboardType(.emailAddress)
            .autocorrectionDisabled()
            .disabled(viewModel.isLoading)

            SecureField("Password", text: $viewModel.password)
                .textFieldStyle(.roundedBorder)
                .disabled(viewModel.isLoading)

            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .foregroundStyle(.red)
                    .font(.caption)
            }

            Button(action: {
                Task {
                    await viewModel.login()
                }
            }) {
                if viewModel.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                } else {
                    Text("Sign In")
                        .frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(viewModel.isLoading || viewModel.email.value.isEmpty || viewModel.password.isEmpty)

            Spacer()
        }
        .padding()
    }
}

#Preview {
    LoginView(appState: AppState())
}
