import Foundation

/// An order status filter tab — `GET /shop/users/orders/menu`.
struct OrderStatusFilter: Equatable, Identifiable, Sendable {
    let id: String
    let label: String
    let status: String
    let count: Int?

    init(id: String, label: String, status: String, count: Int? = nil) {
        self.id = id
        self.label = label
        self.status = status
        self.count = count
    }
}
