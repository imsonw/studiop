import Foundation
import Testing
@testable import studiop

struct AuthFieldValidatorTests {
    @Test func validEmailPassesValidation() {
        #expect(AuthFieldValidator.validateEmail("jane@example.com") == nil)
    }

    @Test func emptyEmailFails() {
        #expect(AuthFieldValidator.validateEmail("") == .emptyEmail)
        #expect(AuthFieldValidator.validateEmail("   ") == .emptyEmail)
    }

    @Test func malformedEmailFails() {
        #expect(AuthFieldValidator.validateEmail("jane@") == .invalidEmailFormat)
        #expect(AuthFieldValidator.validateEmail("jane.example.com") == .invalidEmailFormat)
        #expect(AuthFieldValidator.validateEmail("jane@example") == .invalidEmailFormat)
    }
}
