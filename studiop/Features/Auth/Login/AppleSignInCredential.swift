import Foundation

/// Plain value type extracted from `ASAuthorizationAppleIDCredential` by the View. Apple's
/// credential type has no public initializer, so it can't be constructed in unit tests -- this
/// type lets `LoginViewModel.loginWithApple` stay testable with a plain struct instead of
/// depending on AuthenticationServices' opaque types directly.
struct AppleSignInCredential: Equatable {
    let identityToken: String
    let email: String?
    let userIdentifier: String
    let fullName: String?
}

struct AppleSignInCredentialError: LocalizedError {
    var errorDescription: String? {
        String(localized: "auth.error.appleCredentialUnreadable", defaultValue: "Could not read the Apple ID credential.")
    }
}
