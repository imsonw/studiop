import Foundation

enum AuthValidationError: Error, Equatable {
    case emptyEmail
    case invalidEmailFormat
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
}
