import Foundation

/// This backend's general `{"data": ...}` success envelope — confirmed against two independent
/// real captured responses (`/users/login`, `/users/info`), both shaped
/// `{status, code?, msg, data, token?}`. Wraps whatever payload a specific endpoint returns.
/// Feature-agnostic — any domain's RepositoryImpl can reuse this, not just Auth/User.
struct DataResponseDTO<T: Decodable>: Decodable {
    let data: T
}
