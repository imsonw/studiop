import Foundation

struct StartStreamUseCase {
    let repository: StreamRepository

    func callAsFunction(
        productName: String,
        price: Double,
        quantity: Int,
        image: String,
        imageThumb: String
    ) async throws {
        try await repository.startStream(
            productName: productName,
            price: price,
            quantity: quantity,
            image: image,
            imageThumb: imageThumb
        )
    }
}
