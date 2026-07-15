import Foundation

struct ValidatedField<Value: Equatable>: Equatable {
    var value: Value
    var error: String?
}
