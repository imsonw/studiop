import Foundation

extension AuthValidationError {
    var localizedMessage: String {
        switch self {
        case .emptyEmail:
            String(localized: "auth.error.emptyEmail", defaultValue: "Vui lòng nhập email")
        case .invalidEmailFormat:
            String(localized: "auth.error.invalidEmailFormat", defaultValue: "Email không đúng định dạng")
        case .emptyName:
            String(localized: "auth.error.emptyName", defaultValue: "Vui lòng nhập họ tên")
        case .emptyPassword:
            String(localized: "auth.error.emptyPassword", defaultValue: "Vui lòng nhập mật khẩu")
        case .emptyPasswordConfirmation:
            String(localized: "auth.error.emptyPasswordConfirmation", defaultValue: "Vui lòng xác nhận mật khẩu")
        case .passwordConfirmationMismatch:
            String(localized: "auth.error.passwordConfirmationMismatch", defaultValue: "Mật khẩu xác nhận không khớp")
        case .termsNotAccepted:
            String(localized: "auth.error.termsNotAccepted", defaultValue: "Vui lòng đồng ý với điều khoản sử dụng")
        }
    }
}
