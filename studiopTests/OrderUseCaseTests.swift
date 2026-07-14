import Foundation
import Testing
@testable import studiop

private struct StubError: Error, Equatable {}

final class FakeOrderRepository: OrderRepository, @unchecked Sendable {
    var statusFiltersToReturn: [OrderStatusFilter] = [OrderStatusFilter(id: "1", label: "All", status: "all")]
    var ordersToReturn: [Order] = [Order(id: "order-1")]
    var orderToReturn = Order(id: "order-1")
    var voucherToReturn = Voucher(code: "SAVE10")
    var errorToThrow: Error?

    private(set) var statusFiltersCallCount = 0
    private(set) var lastFetchOrdersArgs: (page: Int?, status: String?, search: String?, createFrom: Date?)?
    private(set) var lastOrderDetailId: String?
    private(set) var lastUpdateOrderAddressArgs: (id: String, addressId: String)?
    private(set) var lastRedeemVoucherArgs: (code: String, orderId: String)?

    func fetchOrderStatusFilters() async throws -> [OrderStatusFilter] {
        statusFiltersCallCount += 1
        if let errorToThrow { throw errorToThrow }
        return statusFiltersToReturn
    }

    func fetchOrders(page: Int?, status: String?, search: String?, createFrom: Date?) async throws -> [Order] {
        lastFetchOrdersArgs = (page, status, search, createFrom)
        if let errorToThrow { throw errorToThrow }
        return ordersToReturn
    }

    func fetchOrderDetail(id: String) async throws -> Order {
        lastOrderDetailId = id
        if let errorToThrow { throw errorToThrow }
        return orderToReturn
    }

    func updateOrderAddress(id: String, addressId: String) async throws -> Order {
        lastUpdateOrderAddressArgs = (id, addressId)
        if let errorToThrow { throw errorToThrow }
        return orderToReturn
    }

    func redeemVoucher(code: String, orderId: String) async throws -> Voucher {
        lastRedeemVoucherArgs = (code, orderId)
        if let errorToThrow { throw errorToThrow }
        return voucherToReturn
    }
}

struct OrderUseCaseTests {
    @Test func fetchOrderStatusFiltersReturnsAll() async throws {
        let fake = FakeOrderRepository()
        let useCase = FetchOrderStatusFiltersUseCase(repository: fake)

        let result = try await useCase()

        #expect(fake.statusFiltersCallCount == 1)
        #expect(result == fake.statusFiltersToReturn)
    }

    @Test func fetchOrderListForwardsFilters() async throws {
        let fake = FakeOrderRepository()
        let useCase = FetchOrderListUseCase(repository: fake)
        let createFrom = Date(timeIntervalSince1970: 0)

        let result = try await useCase(page: 2, status: "pending", search: "abc", createFrom: createFrom)

        #expect(fake.lastFetchOrdersArgs?.page == 2)
        #expect(fake.lastFetchOrdersArgs?.status == "pending")
        #expect(fake.lastFetchOrdersArgs?.search == "abc")
        #expect(fake.lastFetchOrdersArgs?.createFrom == createFrom)
        #expect(result == fake.ordersToReturn)
    }

    @Test func fetchOrderDetailForwardsId() async throws {
        let fake = FakeOrderRepository()
        let useCase = FetchOrderDetailUseCase(repository: fake)

        let result = try await useCase(id: "order-1")

        #expect(fake.lastOrderDetailId == "order-1")
        #expect(result == fake.orderToReturn)
    }

    @Test func updateOrderAddressForwardsArgs() async throws {
        let fake = FakeOrderRepository()
        let useCase = UpdateOrderAddressUseCase(repository: fake)

        let result = try await useCase(id: "order-1", addressId: "addr-1")

        #expect(fake.lastUpdateOrderAddressArgs?.id == "order-1")
        #expect(fake.lastUpdateOrderAddressArgs?.addressId == "addr-1")
        #expect(result == fake.orderToReturn)
    }

    @Test func redeemVoucherForwardsArgs() async throws {
        let fake = FakeOrderRepository()
        let useCase = RedeemVoucherUseCase(repository: fake)

        let result = try await useCase(code: "SAVE10", orderId: "order-1")

        #expect(fake.lastRedeemVoucherArgs?.code == "SAVE10")
        #expect(fake.lastRedeemVoucherArgs?.orderId == "order-1")
        #expect(result == fake.voucherToReturn)
    }

    @Test func redeemVoucherPropagatesError() async throws {
        let fake = FakeOrderRepository()
        fake.errorToThrow = StubError()
        let useCase = RedeemVoucherUseCase(repository: fake)

        await #expect(throws: StubError.self) {
            try await useCase(code: "BAD", orderId: "order-1")
        }
    }
}
