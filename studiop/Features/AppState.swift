import Foundation

@MainActor
@Observable
final class AppState {
    var isAuthenticated: Bool = false
}
