import Foundation

@MainActor
@Observable
final class CollectEmailViewModel {
    var email = ValidatedField<String>(value: "")
    var errorMessage: String?
    var isLoading: Bool = false

    private let changeUserProfileUseCase: ChangeUserProfileUseCase
    private let appState: AppState

    init(changeUserProfileUseCase: ChangeUserProfileUseCase, appState: AppState) {
        self.changeUserProfileUseCase = changeUserProfileUseCase
        self.appState = appState
    }

    /// Submission endpoint is a working assumption (ChangeUserProfileUseCase, the partial-update
    /// one) -- not confirmed against real backend traffic, since docs/api-reference.md doesn't
    /// name a specific endpoint for "collect email after social login." Flagged for verification.
    func submit() async {
        email.error = AuthFieldValidator.validateEmail(email.value)?.localizedMessage
        guard email.error == nil else { return }

        isLoading = true
        errorMessage = nil

        do {
            _ = try await changeUserProfileUseCase(email: email.value)
            appState.isAuthenticated = true
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}
