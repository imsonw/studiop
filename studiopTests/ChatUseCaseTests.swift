import Foundation
import Testing
@testable import studiop

private final class FakeChatRepository: ChatRepository {
    var ablyTokenResult: Result<AblyTokenGrant, Error> = .success(AblyTokenGrant(token: "t", ttlSeconds: 3600))
    var conversationsResult: Result<[Conversation], Error> = .success([])
    var orderMessagesResult: Result<[ChatMessage], Error> = .success([])
    var sendOrderMessageResult: Result<ChatMessage, Error> = .failure(FakeError.unset)
    var supportMessagesResult: Result<[ChatMessage], Error> = .success([])
    var sendSupportMessageResult: Result<ChatMessage, Error> = .failure(FakeError.unset)
    var setActiveError: Error?
    var clearActiveError: Error?
    var markReadError: Error?
    var syncUnreadError: Error?

    private(set) var lastConversationsContext: Conversation.Context?
    private(set) var lastConversationsChannel: String?
    private(set) var lastConversationsPage: Int?
    private(set) var lastConversationsPerPage: Int?

    private(set) var lastOrderMessagesOrderID: String?
    private(set) var lastOrderMessagesLimit: Int?
    private(set) var lastOrderMessagesBeforeTimestamp: Date?
    private(set) var lastOrderMessagesBeforeID: String?
    private(set) var lastOrderMessagesPreview: Bool?

    private(set) var lastSendOrderOrderID: String?
    private(set) var lastSendOrderBody: String?
    private(set) var lastSendOrderBodyHTML: String?
    private(set) var lastSendOrderRequestID: String?

    private(set) var lastSupportLimit: Int?
    private(set) var lastSupportBeforeTimestamp: Date?
    private(set) var lastSupportPreview: Bool?

    private(set) var lastSendSupportBody: String?
    private(set) var lastSendSupportBodyHTML: String?
    private(set) var lastSendSupportRequestID: String?

    private(set) var lastSetActiveConversationID: String?
    private(set) var lastSetActiveTTL: Int?
    private(set) var lastClearActiveConversationID: String?
    private(set) var lastMarkReadConversationID: String?
    private(set) var syncUnreadCallCount = 0

    enum FakeError: Error { case unset }

    func issueAblyToken() async throws -> AblyTokenGrant {
        try ablyTokenResult.get()
    }

    func fetchConversations(
        context: Conversation.Context,
        channel: String?,
        page: Int?,
        perPage: Int?
    ) async throws -> [Conversation] {
        lastConversationsContext = context
        lastConversationsChannel = channel
        lastConversationsPage = page
        lastConversationsPerPage = perPage
        return try conversationsResult.get()
    }

    func fetchOrderMessages(
        orderID: String,
        limit: Int?,
        beforeTimestamp: Date?,
        beforeID: String?,
        preview: Bool?
    ) async throws -> [ChatMessage] {
        lastOrderMessagesOrderID = orderID
        lastOrderMessagesLimit = limit
        lastOrderMessagesBeforeTimestamp = beforeTimestamp
        lastOrderMessagesBeforeID = beforeID
        lastOrderMessagesPreview = preview
        return try orderMessagesResult.get()
    }

    func sendOrderMessage(
        orderID: String,
        body: String,
        bodyHTML: String?,
        requestID: String?
    ) async throws -> ChatMessage {
        lastSendOrderOrderID = orderID
        lastSendOrderBody = body
        lastSendOrderBodyHTML = bodyHTML
        lastSendOrderRequestID = requestID
        return try sendOrderMessageResult.get()
    }

    func fetchSupportMessages(
        limit: Int?,
        beforeTimestamp: Date?,
        preview: Bool?
    ) async throws -> [ChatMessage] {
        lastSupportLimit = limit
        lastSupportBeforeTimestamp = beforeTimestamp
        lastSupportPreview = preview
        return try supportMessagesResult.get()
    }

    func sendSupportMessage(
        body: String,
        bodyHTML: String?,
        requestID: String?
    ) async throws -> ChatMessage {
        lastSendSupportBody = body
        lastSendSupportBodyHTML = bodyHTML
        lastSendSupportRequestID = requestID
        return try sendSupportMessageResult.get()
    }

    func setConversationActive(conversationID: String, ttlSeconds: Int) async throws {
        lastSetActiveConversationID = conversationID
        lastSetActiveTTL = ttlSeconds
        if let setActiveError { throw setActiveError }
    }

    func clearConversationActive(conversationID: String) async throws {
        lastClearActiveConversationID = conversationID
        if let clearActiveError { throw clearActiveError }
    }

    func markConversationRead(conversationID: String) async throws {
        lastMarkReadConversationID = conversationID
        if let markReadError { throw markReadError }
    }

    func syncUnread() async throws {
        syncUnreadCallCount += 1
        if let syncUnreadError { throw syncUnreadError }
    }
}

private enum TestError: Error, Equatable { case boom }

struct ChatUseCaseTests {
    @Test func issueAblyTokenForwardsRepositoryResult() async throws {
        let fake = FakeChatRepository()
        fake.ablyTokenResult = .success(AblyTokenGrant(token: "abc", ttlSeconds: 3600))
        let useCase = IssueAblyTokenUseCase(repository: fake)

        let grant = try await useCase()

        #expect(grant.token == "abc")
        #expect(grant.ttlSeconds == 3600)
    }

    @Test func issueAblyTokenPropagatesError() async throws {
        let fake = FakeChatRepository()
        fake.ablyTokenResult = .failure(TestError.boom)
        let useCase = IssueAblyTokenUseCase(repository: fake)

        do {
            _ = try await useCase()
            Issue.record("Expected error to be thrown")
        } catch {
            #expect(error as? TestError == .boom)
        }
    }

    @Test func fetchConversationsForwardsParametersAndResult() async throws {
        let fake = FakeChatRepository()
        let expected = [Conversation(id: "1", context: .account, channel: "c", lastMessagePreview: nil, lastMessageAt: nil, unreadCount: 0)]
        fake.conversationsResult = .success(expected)
        let useCase = FetchConversationsUseCase(repository: fake)

        let result = try await useCase(context: .studio, channel: "ch", page: 2, perPage: 20)

        #expect(result == expected)
        #expect(fake.lastConversationsContext == .studio)
        #expect(fake.lastConversationsChannel == "ch")
        #expect(fake.lastConversationsPage == 2)
        #expect(fake.lastConversationsPerPage == 20)
    }

    @Test func fetchOrderChatMessagesForwardsParameters() async throws {
        let fake = FakeChatRepository()
        let expected = [ChatMessage(id: "m1", body: "hi", bodyHTML: nil, senderID: "u1", senderName: nil, sentAt: Date(), requestID: nil)]
        fake.orderMessagesResult = .success(expected)
        let useCase = FetchOrderChatMessagesUseCase(repository: fake)

        let result = try await useCase(orderID: "o1", limit: 10, beforeTimestamp: nil, beforeID: "m0", preview: true)

        #expect(result == expected)
        #expect(fake.lastOrderMessagesOrderID == "o1")
        #expect(fake.lastOrderMessagesLimit == 10)
        #expect(fake.lastOrderMessagesBeforeID == "m0")
        #expect(fake.lastOrderMessagesPreview == true)
    }

    @Test func sendOrderChatMessageForwardsBodyAndReturnsMessage() async throws {
        let fake = FakeChatRepository()
        let expected = ChatMessage(id: "m2", body: "hello", bodyHTML: "<p>hello</p>", senderID: "u1", senderName: "Me", sentAt: Date(), requestID: "req-1")
        fake.sendOrderMessageResult = .success(expected)
        let useCase = SendOrderChatMessageUseCase(repository: fake)

        let result = try await useCase(orderID: "o1", body: "hello", bodyHTML: "<p>hello</p>", requestID: "req-1")

        #expect(result == expected)
        #expect(fake.lastSendOrderOrderID == "o1")
        #expect(fake.lastSendOrderBody == "hello")
        #expect(fake.lastSendOrderBodyHTML == "<p>hello</p>")
        #expect(fake.lastSendOrderRequestID == "req-1")
    }

    @Test func fetchSupportChatMessagesForwardsParameters() async throws {
        let fake = FakeChatRepository()
        let expected = [ChatMessage(id: "s1", body: "support", bodyHTML: nil, senderID: "agent", senderName: nil, sentAt: Date(), requestID: nil)]
        fake.supportMessagesResult = .success(expected)
        let useCase = FetchSupportChatMessagesUseCase(repository: fake)

        let result = try await useCase(limit: 5, beforeTimestamp: nil, preview: false)

        #expect(result == expected)
        #expect(fake.lastSupportLimit == 5)
        #expect(fake.lastSupportPreview == false)
    }

    @Test func sendSupportChatMessageForwardsBody() async throws {
        let fake = FakeChatRepository()
        let expected = ChatMessage(id: "s2", body: "need help", bodyHTML: nil, senderID: "u1", senderName: nil, sentAt: Date(), requestID: "req-2")
        fake.sendSupportMessageResult = .success(expected)
        let useCase = SendSupportChatMessageUseCase(repository: fake)

        let result = try await useCase(body: "need help", bodyHTML: nil, requestID: "req-2")

        #expect(result == expected)
        #expect(fake.lastSendSupportBody == "need help")
        #expect(fake.lastSendSupportRequestID == "req-2")
    }

    @Test func setConversationActiveForwardsTTL() async throws {
        let fake = FakeChatRepository()
        let useCase = SetConversationActiveUseCase(repository: fake)

        try await useCase(conversationID: "c1", ttlSeconds: 60)

        #expect(fake.lastSetActiveConversationID == "c1")
        #expect(fake.lastSetActiveTTL == 60)
    }

    @Test func setConversationActivePropagatesError() async throws {
        let fake = FakeChatRepository()
        fake.setActiveError = TestError.boom
        let useCase = SetConversationActiveUseCase(repository: fake)

        do {
            try await useCase(conversationID: "c1", ttlSeconds: 60)
            Issue.record("Expected error to be thrown")
        } catch {
            #expect(error as? TestError == .boom)
        }
    }

    @Test func clearConversationActiveForwardsID() async throws {
        let fake = FakeChatRepository()
        let useCase = ClearConversationActiveUseCase(repository: fake)

        try await useCase(conversationID: "c2")

        #expect(fake.lastClearActiveConversationID == "c2")
    }

    @Test func markConversationReadForwardsID() async throws {
        let fake = FakeChatRepository()
        let useCase = MarkConversationReadUseCase(repository: fake)

        try await useCase(conversationID: "c3")

        #expect(fake.lastMarkReadConversationID == "c3")
    }

    @Test func syncUnreadCallsRepositoryOnce() async throws {
        let fake = FakeChatRepository()
        let useCase = SyncUnreadUseCase(repository: fake)

        try await useCase()

        #expect(fake.syncUnreadCallCount == 1)
    }

    @Test func syncUnreadPropagatesError() async throws {
        let fake = FakeChatRepository()
        fake.syncUnreadError = TestError.boom
        let useCase = SyncUnreadUseCase(repository: fake)

        do {
            try await useCase()
            Issue.record("Expected error to be thrown")
        } catch {
            #expect(error as? TestError == .boom)
        }
    }
}
