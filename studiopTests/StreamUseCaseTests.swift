import Foundation
import Testing
@testable import studiop

private enum FakeError: Error, Equatable {
    case boom
}

private final class FakeStreamRepository: StreamRepository, @unchecked Sendable {
    var liveStreamListResult: Result<[LiveStreamSummary], Error> = .success([])
    var sendChatMessageError: Error?
    var sellingLogResult: Result<StreamSellingLog?, Error> = .success(nil)
    var startStreamError: Error?
    var endStreamError: Error?
    var lastStreamResult: Result<LiveStreamSummary?, Error> = .success(nil)
    var loadMessagesResult: Result<[StreamChatMessage], Error> = .success([])
    var scheduledStreamResult: Result<ScheduledStream, Error> = .failure(FakeError.boom)

    private(set) var receivedType: String?
    private(set) var receivedIdEncode: String?
    private(set) var receivedMessage: StreamChatMessage?
    private(set) var receivedLogId: String?
    private(set) var receivedSort: String?
    private(set) var receivedStartArgs: (productName: String, price: Double, quantity: Int, image: String, imageThumb: String)?
    private(set) var receivedEndId: String?
    private(set) var receivedLoadMessagesId: String?
    private(set) var receivedScheduledId: String?

    func fetchLiveStreamList(type: String?, idEncode: String?) async throws -> [LiveStreamSummary] {
        receivedType = type
        receivedIdEncode = idEncode
        return try liveStreamListResult.get()
    }

    func sendStreamChatMessage(_ message: StreamChatMessage) async throws {
        receivedMessage = message
        if let sendChatMessageError { throw sendChatMessageError }
    }

    func fetchStreamSellingLog(id: String, sort: String) async throws -> StreamSellingLog? {
        receivedLogId = id
        receivedSort = sort
        return try sellingLogResult.get()
    }

    func startStream(productName: String, price: Double, quantity: Int, image: String, imageThumb: String) async throws {
        receivedStartArgs = (productName, price, quantity, image, imageThumb)
        if let startStreamError { throw startStreamError }
    }

    func endStream(id: String) async throws {
        receivedEndId = id
        if let endStreamError { throw endStreamError }
    }

    func fetchLastStream() async throws -> LiveStreamSummary? {
        try lastStreamResult.get()
    }

    func loadStreamMessages(id: String) async throws -> [StreamChatMessage] {
        receivedLoadMessagesId = id
        return try loadMessagesResult.get()
    }

    func fetchScheduledStream(id: String) async throws -> ScheduledStream {
        receivedScheduledId = id
        return try scheduledStreamResult.get()
    }
}

private func makeStream(id: String = "s1") -> LiveStreamSummary {
    LiveStreamSummary(
        id: id,
        title: "Selling sneakers",
        thumbnailURL: nil,
        studioId: "studio1",
        studioName: "Studio One",
        sourceType: .tiktok,
        isLive: true
    )
}

struct StreamUseCaseTests {
    @Test func fetchLiveStreamListForwardsArgsAndResult() async throws {
        let repository = FakeStreamRepository()
        let expected = [makeStream()]
        repository.liveStreamListResult = .success(expected)
        let useCase = FetchLiveStreamListUseCase(repository: repository)

        let result = try await useCase(type: "native", idEncode: "abc")

        #expect(result == expected)
        #expect(repository.receivedType == "native")
        #expect(repository.receivedIdEncode == "abc")
    }

    @Test func fetchLiveStreamListPropagatesError() async throws {
        let repository = FakeStreamRepository()
        repository.liveStreamListResult = .failure(FakeError.boom)
        let useCase = FetchLiveStreamListUseCase(repository: repository)

        await #expect(throws: FakeError.self) {
            try await useCase()
        }
    }

    @Test func sendStreamChatMessageForwardsMessage() async throws {
        let repository = FakeStreamRepository()
        let message = StreamChatMessage(
            messageId: "m1",
            account: "acc",
            fromUser: "user1",
            studioId: "studio1",
            logId: "log1",
            comment: "hello",
            fullName: "User One",
            type: "text",
            sourceType: .twitch
        )
        let useCase = SendStreamChatMessageUseCase(repository: repository)

        try await useCase(message)

        #expect(repository.receivedMessage == message)
    }

    @Test func sendStreamChatMessagePropagatesError() async throws {
        let repository = FakeStreamRepository()
        repository.sendChatMessageError = FakeError.boom
        let useCase = SendStreamChatMessageUseCase(repository: repository)
        let message = StreamChatMessage(
            messageId: "m1",
            account: "acc",
            fromUser: "user1",
            studioId: "studio1",
            logId: "log1",
            comment: "hello",
            fullName: "User One",
            type: "text",
            sourceType: .twitch
        )

        await #expect(throws: FakeError.self) {
            try await useCase(message)
        }
    }

    @Test func fetchStreamSellingLogForwardsArgsAndResult() async throws {
        let repository = FakeStreamRepository()
        let log = StreamSellingLog(
            id: "log1",
            streamId: "s1",
            productName: "Sneakers",
            price: 19.99,
            quantity: 3,
            imageURL: nil,
            imageThumbURL: nil,
            createdAt: nil
        )
        repository.sellingLogResult = .success(log)
        let useCase = FetchStreamSellingLogUseCase(repository: repository)

        let result = try await useCase(id: "s1")

        #expect(result == log)
        #expect(repository.receivedLogId == "s1")
        #expect(repository.receivedSort == "desc")
    }

    @Test func startStreamForwardsArgs() async throws {
        let repository = FakeStreamRepository()
        let useCase = StartStreamUseCase(repository: repository)

        try await useCase(productName: "Sneakers", price: 19.99, quantity: 3, image: "img.png", imageThumb: "thumb.png")

        let args = try #require(repository.receivedStartArgs)
        #expect(args.productName == "Sneakers")
        #expect(args.price == 19.99)
        #expect(args.quantity == 3)
        #expect(args.image == "img.png")
        #expect(args.imageThumb == "thumb.png")
    }

    @Test func endStreamForwardsIdAndPropagatesError() async throws {
        let repository = FakeStreamRepository()
        repository.endStreamError = FakeError.boom
        let useCase = EndStreamUseCase(repository: repository)

        await #expect(throws: FakeError.self) {
            try await useCase(id: "s1")
        }
        #expect(repository.receivedEndId == "s1")
    }

    @Test func fetchLastStreamForwardsResult() async throws {
        let repository = FakeStreamRepository()
        let stream = makeStream()
        repository.lastStreamResult = .success(stream)
        let useCase = FetchLastStreamUseCase(repository: repository)

        let result = try await useCase()

        #expect(result == stream)
    }

    @Test func loadStreamMessagesForwardsArgsAndResult() async throws {
        let repository = FakeStreamRepository()
        let message = StreamChatMessage(
            messageId: "m1",
            account: "acc",
            fromUser: "user1",
            studioId: "studio1",
            logId: "log1",
            comment: "hi",
            fullName: "User One",
            type: "text",
            sourceType: .native
        )
        repository.loadMessagesResult = .success([message])
        let useCase = LoadStreamMessagesUseCase(repository: repository)

        let result = try await useCase(id: "s1")

        #expect(result == [message])
        #expect(repository.receivedLoadMessagesId == "s1")
    }

    @Test func fetchScheduledStreamForwardsArgsAndResult() async throws {
        let repository = FakeStreamRepository()
        let scheduled = ScheduledStream(
            id: "sch1",
            studioId: "studio1",
            studioName: "Studio One",
            title: "Big sale",
            scheduledAt: Date(timeIntervalSince1970: 0),
            thumbnailURL: nil,
            sourceType: .youtube
        )
        repository.scheduledStreamResult = .success(scheduled)
        let useCase = FetchScheduledStreamUseCase(repository: repository)

        let result = try await useCase(id: "sch1")

        #expect(result == scheduled)
        #expect(repository.receivedScheduledId == "sch1")
    }
}
