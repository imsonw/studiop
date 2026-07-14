# Ghi chú học tập — Sprint 3 (Data Layer)

Tài liệu tổng hợp các kiến thức Swift/iOS **mới** học được khi triển khai
`sprint-003/sprint_plan@v1.yaml` (Data layer: `AuthRepositoryImpl` + `UserRepositoryImpl` gọi
`NetworkClient` thật, DTOs, `DependencyKey` cho 2 Repository). Nối tiếp
[docs/learning-notes-sprint-001.md](learning-notes-sprint-001.md) và
[docs/learning-notes-sprint-002.md](learning-notes-sprint-002.md) — không lặp lại kiến thức đã
học ở đó.

---

## 1. DTO (Data Transfer Object) — vì sao tách riêng khỏi Domain Entity

Sprint 3 có 2 struct gần như giống hệt nhau, đại diện cùng một khái niệm "user":

```swift
// Domain/Auth/Entities/User.swift — nghiệp vụ thuần, không Codable
struct User: Equatable, Sendable, Identifiable {
    let id: Int
    let idEncode: String
    var name: String
    var email: String
    ...
}

// Data/Auth/DTOs/UserDTO.swift — mirror đúng JSON backend
struct UserDTO: Decodable {
    let id: Int
    let idEncode: String
    let name: String
    let email: String
    ...
    func toDomain() -> User { User(id: id, idEncode: idEncode, name: name, email: email, ...) }
}
```

**Lý do không gộp làm một:** `User` (Domain) và `UserDTO` (Data) trả lời **2 câu hỏi độc lập**:
- `User`: *"User là gì về mặt nghiệp vụ?"* (tên, email, sđt) — không quan tâm dữ liệu đến từ đâu.
- `UserDTO`: *"Dữ liệu đó nằm dưới dạng JSON cụ thể nào?"* — hoàn toàn phụ thuộc vào backend
  hiện tại.

Nếu gộp làm một (`User` trực tiếp `Decodable` với `CodingKeys` mirror JSON), khi backend đổi tên
field (`id_encode` → `encoded_id`) hoặc thêm nguồn dữ liệu thứ 2 (cache offline, backend khác),
bạn sẽ phải sửa code ở **Domain layer** — nơi lẽ ra chỉ chứa nghiệp vụ, không nên biết gì về JSON.
Tách riêng: đổi JSON shape chỉ cần sửa `UserDTO` + `toDomain()`, `User` không hề hay biết — đúng
tinh thần "Domain không biết làm thế nào" đã học ở Sprint 2 (Repository protocol).

---

## 2. `Codable`/`CodingKeys` — dịch JSON `snake_case` sang Swift `camelCase`

Backend trả JSON kiểu `snake_case` (`id_encode`, `company_name`, `new_password_confirmation`),
nhưng convention property Swift là `camelCase` (`idEncode`, `companyName`). Cần khai `CodingKeys`
để "dịch":

```swift
struct UserDTO: Decodable {
    let idEncode: String
    let companyName: String?

    enum CodingKeys: String, CodingKey {
        case idEncode = "id_encode"
        case companyName = "company_name"
    }
}
```

Không có `CodingKeys`, `JSONDecoder` sẽ tìm đúng chữ **`"idEncode"`** trong JSON (y hệt tên
property) — không tự suy ra `"id_encode"`. Vì backend chỉ gửi `"id_encode"`, việc decode sẽ
**ném lỗi** `DecodingError.keyNotFound` (nếu property không phải `Optional`).

Tương tự cho `Encodable` khi gửi request body — `Encodable` DTO cũng cần `CodingKeys` để encode
đúng field name backend mong đợi:

```swift
struct ConfirmResetPasswordRequestDTO: Encodable {
    let resetToken: String
    let newPassword: String

    enum CodingKeys: String, CodingKey {
        case resetToken = "reset_token"
        case newPassword = "new_password"
    }
}
```

---

## 3. `encodeIfPresent` — property `Optional` bị nil thì JSON **bỏ hẳn key**, không phải `null`

Bug thật bắt được lúc viết test cho `ChangeUserAddressRequestDTO` (có `shippingAddress:
AddressDTO?`):

```swift
// Test SAI — giả định nil sẽ được encode thành JSON `null`
#expect(json["shipping_address"] is NSNull)
```

Test này fail, vì Swift's synthesized `Encodable` conformance dùng `container.encodeIfPresent(_:
forKey:)` cho mọi property kiểu `Optional` — khi giá trị là `nil`, nó **bỏ hẳn key đó ra khỏi
JSON**, không hề ghi `"shipping_address": null`.

```swift
// Test ĐÚNG — key vắng mặt hoàn toàn, không tồn tại trong dictionary
#expect(json["shipping_address"] == nil)
```

**Bài học:** khi test/debug JSON có field `Optional`, đừng giả định "nil = null trong JSON" —
mặc định của Swift là "nil = key biến mất", trừ khi bạn tự viết `encode(to:)` thủ công để ép ghi
`null` tường minh.

---

## 4. Phải khai tường minh conformance — kể cả cho enum không có associated value

Để viết được `#expect(request.authentication == .publicToken)` trong test, phải sửa:

```swift
// Trước — không so sánh == được
enum Authentication {
    case publicToken
    case userToken
}

// Sau — khai tường minh mới dùng được ==
enum Authentication: Equatable {
    case publicToken
    case userToken
}
```

Đây là **cùng một nguyên tắc** đã học ở Sprint 1 với `@unchecked Sendable`: Swift **không bao giờ
tự động cấp** một protocol conformance (`Equatable`, `Hashable`, `Sendable`,...) nếu type không
khai rõ — kể cả khi enum chỉ có các case trơn, không associated value, "về lý mà nói" so sánh `==`
đáng lẽ phải hoạt động ngay. Swift luôn yêu cầu khai báo tường minh trước khi *synthesize*
(tự sinh) bất kỳ implementation nào.

---

## Bảng tổng hợp nhanh

| Khái niệm | File tham chiếu |
|---|---|
| DTO tách khỏi Domain Entity, `toDomain()` mapping | `Data/Auth/DTOs/UserDTO.swift`, `AuthSessionResponseDTO.swift` |
| `Codable`/`CodingKeys` snake_case ↔ camelCase | mọi file trong `Data/Auth/DTOs/` |
| `encodeIfPresent` bỏ key khi `Optional` là `nil` | lịch sử sửa test `changeUserAddressSendsMainAndShippingAddress` |
| Phải khai tường minh protocol conformance | `Core/NetworkRequest.swift` (`Method`, `Authentication` → `Equatable`) |
