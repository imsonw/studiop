import Dependencies
import SwiftUI

struct CollectEmailView: View {
    @State private var viewModel: CollectEmailViewModel

    init(appState: AppState) {
        @Dependency(\.userRepository) var userRepository

        _viewModel = State(initialValue: CollectEmailViewModel(
            changeUserProfileUseCase: ChangeUserProfileUseCase(repository: userRepository),
            appState: appState
        ))
    }

    var body: some View {
        VStack(spacing: 16) {
            Text("One more step")
                .font(.title)

            Text("This social account didn't share an email with us. Please provide one to continue.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

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

            Button(action: {
                Task {
                    await viewModel.submit()
                }
            }) {
                if viewModel.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                } else {
                    Text("Continue")
                        .frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(viewModel.isLoading || viewModel.email.value.isEmpty)

            Spacer()
        }
        .padding()
        .navigationBarBackButtonHidden(true)
    }
}

#Preview {
    NavigationStack {
        CollectEmailView(appState: AppState())
    }
}
