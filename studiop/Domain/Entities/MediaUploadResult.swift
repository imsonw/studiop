import Foundation

/// Uploaded asset shape, per `POST /media/upload/file`.
struct MediaUploadResult: Equatable {
    let url: String
    let key: String
    let folder: String
    let storage: String
    let size: Int
    let type: String
}
