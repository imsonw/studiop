import Foundation
import Testing
@testable import studiop

private final class FakeMediaRepository: MediaRepository {
    var result: Result<MediaUploadResult, Error> = .failure(FakeError.unset)

    private(set) var lastFileData: Data?
    private(set) var lastSourceURL: String?
    private(set) var lastKey: String?
    private(set) var lastFolder: String?
    private(set) var lastStorage: String?
    private(set) var lastSize: Int?
    private(set) var lastType: String?
    private(set) var lastRatio: String?
    private(set) var lastForID: String?

    enum FakeError: Error { case unset }

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
    ) async throws -> MediaUploadResult {
        lastFileData = fileData
        lastSourceURL = sourceURL
        lastKey = key
        lastFolder = folder
        lastStorage = storage
        lastSize = size
        lastType = type
        lastRatio = ratio
        lastForID = forID
        return try result.get()
    }
}

private enum TestError: Error, Equatable { case boom }

struct MediaUseCaseTests {
    @Test func uploadMediaForwardsParametersAndReturnsResult() async throws {
        let fake = FakeMediaRepository()
        let expected = MediaUploadResult(url: "https://cdn/x.png", key: "k", folder: "chat", storage: "s3", size: 1024, type: "image")
        fake.result = .success(expected)
        let useCase = UploadMediaUseCase(repository: fake)

        let result = try await useCase(
            fileData: Data([0x1]),
            sourceURL: nil,
            key: "k",
            folder: "chat",
            storage: "s3",
            size: 1024,
            type: "image",
            ratio: "1:1",
            forID: "order-1"
        )

        #expect(result == expected)
        #expect(fake.lastKey == "k")
        #expect(fake.lastFolder == "chat")
        #expect(fake.lastStorage == "s3")
        #expect(fake.lastSize == 1024)
        #expect(fake.lastType == "image")
        #expect(fake.lastRatio == "1:1")
        #expect(fake.lastForID == "order-1")
    }

    @Test func uploadMediaPropagatesError() async throws {
        let fake = FakeMediaRepository()
        fake.result = .failure(TestError.boom)
        let useCase = UploadMediaUseCase(repository: fake)

        do {
            _ = try await useCase(key: "k", folder: "chat", storage: "s3", type: "image")
            Issue.record("Expected error to be thrown")
        } catch {
            #expect(error as? TestError == .boom)
        }
    }
}
