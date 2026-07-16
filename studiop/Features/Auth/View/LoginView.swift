import AuthenticationServices
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
            loginWithSocialUseCase: LoginWithSocialUseCase(repository: authRepository),
            fetchUserInfoUseCase: FetchUserInfoUseCase(repository: userRepository),
            keychainStore: keychainStore,
            appState: appState
        ))
    }

    var body: some View {
        NavigationStack {
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

                NavigationLink("Create an account") {
                    RegisterView()
                }

                NavigationLink("Forgot password?") {
                    ResetPasswordRequestView()
                }

                NavigationLink("Verify your account") {
                    VerifyAccountView()
                }

                Divider()

                SignInWithAppleButton(.signIn) { request in
                    request.requestedScopes = [.fullName, .email]
                } onCompletion: { result in
                    switch result {
                    case .success(let authorization):
                        guard
                            let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
                            let tokenData = appleIDCredential.identityToken,
                            let identityToken = String(data: tokenData, encoding: .utf8)
                        else {
                            viewModel.appleSignInFailed(NetworkError.transport("Could not read the Apple ID credential."))
                            return
                        }

                        let fullName = appleIDCredential.fullName.flatMap { components in
                            PersonNameComponentsFormatter().string(from: components)
                        }

                        let credential = AppleSignInCredential(
                            identityToken: identityToken,
                            email: appleIDCredential.email,
                            userIdentifier: appleIDCredential.user,
                            fullName: (fullName?.isEmpty == false) ? fullName : nil
                        )

                        Task {
                            await viewModel.loginWithApple(credential)
                        }

                    case .failure(let error):
                        viewModel.appleSignInFailed(error)
                    }
                }
                .signInWithAppleButtonStyle(.black)
                .frame(height: 44)
                .disabled(viewModel.isLoading)

                // Google/TikTok sign-in need a real developer Client ID and an SPM SDK dependency
                // that hasn't been confirmed yet -- left disabled rather than wired to a fake call.
                Button("Sign in with Google") {}
                    .buttonStyle(.bordered)
                    .frame(maxWidth: .infinity)
                    .disabled(true)

                Button("Sign in with TikTok") {}
                    .buttonStyle(.bordered)
                    .frame(maxWidth: .infinity)
                    .disabled(true)

                Spacer()
            }
            .padding()
            .navigationDestination(isPresented: $viewModel.needsEmailCollection) {
                CollectEmailView(appState: appState)
            }
        }
    }
}

#Preview {
    LoginView(appState: AppState())
}
