import Foundation

enum AuthValidationError: Error, Equatable {
    case emptyEmail
    case invalidEmailFormat
    case emptyName
    case emptyPassword
    case emptyPasswordConfirmation
    case passwordConfirmationMismatch
    case termsNotAccepted
}

enum AuthFieldValidator {
    static func validateEmail(_ email: String) -> AuthValidationError? {
        let trimmed = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return .emptyEmail }
        guard trimmed.range(of: #"^\S+@\S+\.\S+$"#, options: .regularExpression) != nil else {
            return .invalidEmailFormat
        }
        return nil
    }

    static func validateName(_ name: String) -> AuthValidationError? {
        name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .emptyName : nil
    }

    static func validatePassword(_ password: String) -> AuthValidationError? {
        password.isEmpty ? .emptyPassword : nil
    }

    static func validatePasswordConfirmation(_ confirmation: String, matches password: String) -> AuthValidationError? {
        guard !confirmation.isEmpty else { return .emptyPasswordConfirmation }
        guard confirmation == password else { return .passwordConfirmationMismatch }
        return nil
    }

    static func validateTermsAccepted(_ accepted: Bool) -> AuthValidationError? {
        accepted ? nil : .termsNotAccepted
    }
}
