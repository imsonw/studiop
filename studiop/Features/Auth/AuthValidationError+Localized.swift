import Foundation

extension AuthValidationError {
    var localizedMessage: String {
        switch self {
        case .emptyEmail:
            String(localized: "auth.error.emptyEmail", defaultValue: "Vui lòng nhập email")
        case .invalidEmailFormat:
            String(localized: "auth.error.invalidEmailFormat", defaultValue: "Email không đúng định dạng")
        }
    }
}
