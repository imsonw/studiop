import Foundation

struct UploadMediaUseCase {
    let repository: MediaRepository

    func callAsFunction(
        fileData: Data? = nil,
        sourceURL: String? = nil,
        key: String,
        folder: String,
        storage: String,
        size: Int? = nil,
        type: String,
        ratio: String? = nil,
        forID: String? = nil
    ) async throws -> MediaUploadResult {
        try await repository.uploadFile(
            fileData: fileData,
            sourceURL: sourceURL,
            key: key,
            folder: folder,
            storage: storage,
            size: size,
            type: type,
            ratio: ratio,
            forID: forID
        )
    }
}
