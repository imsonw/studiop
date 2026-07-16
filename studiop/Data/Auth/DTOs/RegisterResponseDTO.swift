import Foundation

/// Response shape for a successful `/users/register` — confirmed against a real captured response
/// to have no `data`/`token` (unlike login), just the backend's own confirmation message: the
/// account isn't usable until email verification. See docs/api-reference.md -> AuthRepository.
struct RegisterResponseDTO: Decodable {
    let msg: String
}
