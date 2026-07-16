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

    @Test func validNamePassesValidation() {
        #expect(AuthFieldValidator.validateName("Jane Doe") == nil)
    }

    @Test func emptyNameFails() {
        #expect(AuthFieldValidator.validateName("") == .emptyName)
        #expect(AuthFieldValidator.validateName("   ") == .emptyName)
    }

    @Test func nonEmptyPasswordPassesValidation() {
        #expect(AuthFieldValidator.validatePassword("secret123") == nil)
    }

    @Test func emptyPasswordFails() {
        #expect(AuthFieldValidator.validatePassword("") == .emptyPassword)
    }

    @Test func matchingPasswordConfirmationPassesValidation() {
        #expect(AuthFieldValidator.validatePasswordConfirmation("secret123", matches: "secret123") == nil)
    }

    @Test func emptyPasswordConfirmationFails() {
        #expect(AuthFieldValidator.validatePasswordConfirmation("", matches: "secret123") == .emptyPasswordConfirmation)
    }

    @Test func mismatchedPasswordConfirmationFails() {
        #expect(AuthFieldValidator.validatePasswordConfirmation("different", matches: "secret123") == .passwordConfirmationMismatch)
    }
}
