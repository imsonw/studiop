import Foundation

/// See docs/api-reference.md -> `OrderRepository`.
protocol OrderRepository: Sendable {
    func fetchOrderStatusFilters() async throws -> [OrderStatusFilter]
    func fetchOrders(page: Int?, status: String?, search: String?, createFrom: Date?) async throws -> [Order]
    func fetchOrderDetail(id: String) async throws -> Order
    func updateOrderAddress(id: String, addressId: String) async throws -> Order
    func redeemVoucher(code: String, orderId: String) async throws -> Voucher
}
