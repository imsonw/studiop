import SwiftUI

/// Same viewModel instance as `AccountDeletionRequestView` (passed in, not re-constructed) so the
/// reason/request state and the confirm state stay one continuous flow. `@Bindable` is required
/// here (unlike the constructing views) because `viewModel` arrives as a plain reference, not this
/// view's own `@State`/`@Binding` -- see learning-notes-sprint-004.md §8.
struct AccountDeletionConfirmView: View {
    @Bindable var viewModel: AccountDeletionViewModel

    var body: some View {
        Form {
            ValidatedTextField(title: "Email", field: $viewModel.email) { value in
                AuthFieldValidator.validateEmail(value)?.localizedMessage
            }
            .keyboardType(.emailAddress)
            .autocorrectionDisabled()
            .disabled(viewModel.isConfirming)

            TextField("Confirmation code", text: $viewModel.code)
                .textFieldStyle(.roundedBorder)
                .disabled(viewModel.isConfirming)

            if let confirmErrorMessage = viewModel.confirmErrorMessage {
                Text(confirmErrorMessage)
                    .foregroundStyle(.red)
                    .font(.caption)
            }

            Button(action: {
                Task { await viewModel.confirmRemoval() }
            }) {
                if viewModel.isConfirming {
                    ProgressView()
                } else {
                    Text("Confirm Deletion")
                }
            }
            .disabled(viewModel.isConfirming || viewModel.email.value.isEmpty || viewModel.code.isEmpty)
        }
        .navigationTitle("Confirm Deletion")
    }
}
