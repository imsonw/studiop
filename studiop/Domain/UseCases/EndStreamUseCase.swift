import Foundation

struct EndStreamUseCase {
    let repository: StreamRepository

    func callAsFunction(id: String) async throws {
        try await repository.endStream(id: id)
    }
}
