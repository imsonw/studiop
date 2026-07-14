import Foundation

/// Multipart media upload, per `POST /media/upload/file`.
protocol MediaRepository {
    func uploadFile(
        fileData: Data?,
        sourceURL: String?,
        key: String,
        folder: String,
        storage: String,
        size: Int?,
        type: String,
        ratio: String?,
        forID: String?
    ) async throws -> MediaUploadResult
}
