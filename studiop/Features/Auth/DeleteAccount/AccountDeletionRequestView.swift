import Dependencies
import SwiftUI

struct AccountDeletionRequestView: View {
    @State private var viewModel: AccountDeletionViewModel

    init(appState: AppState) {
        @Dependency(\.userRepository) var userRepository
        @Dependency(\.keychainStore) var keychainStore

        _viewModel = State(initialValue: AccountDeletionViewModel(
            requestAccountRemovalUseCase: RequestAccountRemovalUseCase(repository: userRepository),
            confirmAccountRemovalUseCase: ConfirmAccountRemovalUseCase(repository: userRepository),
            keychainStore: keychainStore,
            appState: appState
        ))
    }

    var body: some View {
        Form {
            Section("Why are you leaving?") {
                ValidatedTextField(title: "Reason", field: $viewModel.reason) { _ in nil }
                    .disabled(viewModel.isRequesting)

                if let requestErrorMessage = viewModel.requestErrorMessage {
                    Text(requestErrorMessage)
                        .foregroundStyle(.red)
                        .font(.caption)
                }
                if let requestSuccessMessage = viewModel.requestSuccessMessage {
                    Text(requestSuccessMessage)
                        .foregroundStyle(.green)
                        .font(.caption)
                }

                Button(action: {
                    Task { await viewModel.requestRemoval() }
                }) {
                    if viewModel.isRequesting {
                        ProgressView()
                    } else {
                        Text("Request Deletion")
                    }
                }
                .disabled(viewModel.isRequesting || viewModel.reason.value.isEmpty)
            }

            if viewModel.requestSuccessMessage != nil {
                Section {
                    NavigationLink("I have a confirmation code") {
                        AccountDeletionConfirmView(viewModel: viewModel)
                    }
                }
            }
        }
        .navigationTitle("Delete Account")
    }
}

#Preview {
    NavigationStack {
        AccountDeletionRequestView(appState: AppState())
    }
}
