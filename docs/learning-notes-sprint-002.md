# Ghi chú học tập — Sprint 2 (Domain Layer)

Tài liệu tổng hợp các kiến thức Swift/iOS **mới** học được khi triển khai
`sprint-002/sprint_plan@v1.yaml` (Domain layer: Entities + Repository protocols + UseCases cho
16 domain trong `docs/api-reference.md`). Nối tiếp
[docs/learning-notes-sprint-001.md](learning-notes-sprint-001.md) — không lặp lại các khái niệm
đã học ở đó (struct/class, NSLock/actor, DependencyKey/@TaskLocal, Keychain, async/await,
Sendable, Swift Testing).

---

## 1. Protocol thuần — ranh giới giữa Domain và Data

`Domain/Repositories/AuthRepository.swift` chỉ khai báo **chữ ký hàm**, không có bất kỳ
implementation nào:

```swift
protocol AuthRepository: Sendable {
    func login(email: String, password: String) async throws -> AuthSession
    func register(...) async throws -> AuthSession
    // ... không có class nào implement thật ở Sprint 2 cả
}
```

`protocol` chỉ định nghĩa **hình dạng** (tên hàm, tham số, kiểu trả về) — hoàn toàn không có
"làm thế nào". Khác hẳn `class`/`struct` luôn có `{ ... }` chứa code thật thực thi.

**Ẩn dụ:** một bản hợp đồng tuyển dụng — ghi rõ "người nhận việc phải biết nấu ăn", nhưng không
quy định ai làm hay cách nấu ra sao.

### Vì sao "cố tình không biết cách làm" lại có lợi

Vì `LoginUseCase` (và sau này `ViewModel`) chỉ biết đến **protocol**, không biết implementation cụ
thể nào, nên có thể **thay implementation mà không sửa bất kỳ code nào ở tầng trên**:

1. **Đổi backend sau này** (đúng mục tiêu CLAUDE.md: tái sử dụng backend hiện tại nhưng để dành
   khả năng đổi sang backend tự build) — chỉ viết lại `AuthRepositoryImpl` (Sprint 3), không đụng
   `LoginUseCase`.
2. **Test** — dùng bản giả (`FakeAuthRepository`, xem mục 3), không cần mạng thật.
3. **SwiftUI Preview** — dùng bản giả tương tự, không cần backend sống.

Đây là nguyên lý **"lập trình theo interface, không theo implementation cụ thể"** — trụ cột của
Protocol-Oriented Programming. Ngược lại, nếu viết `private let repository =
URLSessionAuthRepositoryImpl()` thẳng trong `LoginUseCase`, sẽ **không thể** thay/test được nữa —
implementation bị gắn cứng (hardcode).

### Quy tắc trong sprint_plan@v1.yaml

Không tạo `DependencyKey` cho bất kỳ Repository protocol nào ở Sprint 2 — vì **chưa có class nào
thật sự implement** protocol đó (RepositoryImpl là việc của Sprint 3), nên chưa có `liveValue` để
khai báo. Thử viết `@Dependency(\.authRepository)` lúc này sẽ báo lỗi biên dịch ngay: type
`DependencyValues` chưa có `authRepository` — vì chưa ai viết `extension DependencyValues { var
authRepository: ... }` cả.

---

## 2. UseCase pattern — constructor injection + `callAsFunction`

Mỗi UseCase là một `struct` mỏng, bọc đúng 1 lời gọi Repository:

```swift
struct LoginUseCase {
    let repository: AuthRepository

    init(repository: AuthRepository) {
        self.repository = repository
    }

    func callAsFunction(email: String, password: String) async throws -> AuthSession {
        try await repository.login(email: email, password: password)
    }
}
```

### Constructor injection, không phải `@Dependency`

`LoginUseCase` nhận `repository` qua `init(...)` (**constructor injection**) — **không** dùng
`@Dependency` bên trong UseCase. Đây là quyết định có chủ đích, không phải sơ suất: `@Dependency`
và constructor injection hoạt động ở hai tầng khác nhau, không mâu thuẫn:

```swift
// Ở tầng ViewModel (Sprint 4+), khi thật sự cần dùng:
@Dependency(\.authRepository) var authRepository        // lấy repository qua hệ thống DI
let loginUseCase = LoginUseCase(repository: authRepository)   // tự tay lắp vào UseCase
```

`@Dependency` lấy dependency từ hệ thống DI (cần `DependencyKey`/`liveValue` tồn tại trước — xem
mục 1); constructor injection là cách một type ở tầng Domain (không biết gì về DI) nhận dependency
vào — Domain phải tự chủ, không phụ thuộc thời điểm DI được nối dây.

### `callAsFunction` — gọi instance như một hàm

Tên hàm `callAsFunction` là **tên đặc biệt** mà Swift compiler nhận diện: khi một type có hàm tên
đúng là `callAsFunction`, bạn gọi được **thẳng instance đó** bằng dấu ngoặc, không cần viết
`.callAsFunction`:

```swift
let loginUseCase = LoginUseCase(repository: someAuthRepository)   // (1) đây là gọi init — TẠO instance
try await loginUseCase(email: "a@b.com", password: "123")          // (2) đây mới là callAsFunction — GỌI instance
```

**Lưu ý dễ nhầm:** `TênType(...)` gọi trực tiếp trên tên type **luôn luôn** là gọi `init`, bất kể
có `callAsFunction` hay không. `callAsFunction` chỉ có tác dụng khi gọi `()` trên một **instance đã
tồn tại** (bước 2), không phải trên tên type (bước 1).

---

## 3. Test double tự viết tay (Fake)

Vì protocol chỉ là hợp đồng chữ ký hàm, **bất kỳ** type nào implement đủ hàm đó — kể cả một hàm
rỗng chỉ trả giá trị cứng — đều là implementation hợp lệ về mặt kỹ thuật. Đây là nền tảng cho việc
viết fake test:

```swift
final class FakeAuthRepository: AuthRepository, @unchecked Sendable {
    var authSessionToReturn: AuthSession = AuthSession(...)   // giá trị trả về, set sẵn tuỳ ý
    var errorToThrow: Error?                                   // lỗi muốn ném, nếu test case lỗi
    private(set) var lastLogin: (email: String, password: String)?   // ghi nhớ đã gọi với gì

    func login(email: String, password: String) async throws -> AuthSession {
        lastLogin = (email, password)                 // chỉ ghi nhớ tham số nhận được
        if let errorToThrow { throw errorToThrow }     // không gọi mạng thật, ném lỗi hardcode nếu cần
        return authSessionToReturn                     // trả thẳng giá trị hardcode
    }
}
```

**Không có** `URLSession`, JSON, hay mã trạng thái HTTP nào — zero logic "giả lập API". Test dùng
nó:

```swift
let fake = FakeAuthRepository()
let useCase = RegisterUseCase(repository: fake)
let result = try await useCase(name: "Jane", email: "...", password: "pw", passwordConfirmation: "pw", phone: nil)

#expect(fake.registerCallCount == 1)          // UseCase có thật sự gọi repository đúng 1 lần không
#expect(result == fake.authSessionToReturn)   // UseCase có trả lại nguyên vẹn kết quả không
```

Hai `#expect` này chỉ kiểm tra **"đường dây" (wiring)** của UseCase — có gọi đúng hàm, có trả đúng
kết quả không — **không** kiểm tra nghiệp vụ thật (email hợp lệ, mật khẩu đủ mạnh,...), vì
`RegisterUseCase` chỉ là lớp bọc mỏng, không tự phát minh logic nghiệp vụ.

### Khác với `InMemoryKeychainStore` ở Sprint 1

| | `InMemoryKeychainStore` (Sprint 1) | `FakeAuthRepository` (Sprint 2) |
|---|---|---|
| Nằm ở đâu | Main app target (`Core/KeychainStore.swift`) | Chỉ trong test target (`studiopTests/`) |
| Vai trò | `testValue`/`previewValue` của `DependencyKey` — được **ship** vào app | Test double thuần, không liên quan `DependencyKey`, **không bao giờ ship** |
| Vì sao khác | Sprint 1 đã có `DependencyKey` cho `KeychainStore` | Sprint 2 chưa có `DependencyKey` cho Repository nào — fake chỉ cần thoả `init(repository:)` của UseCase |

---

## 4. Name collision lần 2 — `Category` vs Objective-C runtime, và bài học per-file

Entity `Category` (cho `GET /stores/categories`) biên dịch **bình thường** ở app target
(`studiop`), nhưng lỗi **"ambiguous for type lookup"** ở test target
(`studiopTests/StoreUseCaseTests.swift`):

```
error: 'Category' is ambiguous for type lookup in this context
  found this candidate: studiop/Domain/Entities/Category.swift:4:8
  found this candidate: .../iPhoneSimulator18.5.sdk/usr/include/objc/runtime.h:50:31
```

`Category` cũng là một type có sẵn trong Objective-C runtime (`objc/runtime.h`). `studiopTests` có
`import Testing` (Swift Testing framework) — framework này, để tương tác với cơ chế phát hiện test
kiểu cũ dựa trên Objective-C runtime, khiến type `Category` của ObjC "lộ diện" (visible) trong
phạm vi file test đó. Các file ở app target chỉ `import SwiftUI`/`Foundation`/`Dependencies` —
không có gì trong chuỗi import đó phơi bày `Category` của ObjC runtime ra tên trần trụi
(unqualified) tương tự.

**Đã sửa:** đổi tên `Category` → `ProductCategory` (`Entities/ProductCategory.swift`), cập nhật 5
file tham chiếu — build + test lại xanh.

### Bài học bổ sung cho quy tắc Sprint 1

Sprint 1 rút ra: *"đừng đặt tên type trùng với thứ được import vào."* Lần này bổ sung thêm một vế
quan trọng:

> **Build pass ở một file/target không đảm bảo an toàn ở file/target khác trong cùng project** —
> vì mỗi file có một tập hợp "tên nhìn thấy được" khác nhau, tuỳ vào nó `import` những gì. Một cái
> tên có thể "vô hại" ở 99% project nhưng nổ ở đúng 1 file có import khác biệt (ví dụ file test
> import `Testing`, còn file thường thì không).

**Các tên tiếng Anh thông dụng đã biết là "đã bị Apple claim trước", cần tránh đặt trùng:**
`Environment` (SwiftUI `@propertyWrapper`), `Category` (Objective-C runtime), `Notification`
(Foundation's `Notification`/`NotificationCenter` — Sprint 2 đã né bằng cách đặt tên
`NotificationItem` thay vì `Notification` trần). Khi đặt tên entity mới, nên cân nhắc trước các tên
phổ biến kiểu `Result`, `State`, `Task`, `Error` cũng có nguy cơ tương tự.

---

## Bảng tổng hợp nhanh

| Khái niệm | File tham chiếu |
|---|---|
| Protocol thuần làm ranh giới Domain/Data | `Domain/Repositories/*.swift` (16 file) |
| UseCase + constructor injection + `callAsFunction` | `Domain/UseCases/LoginUseCase.swift` và 91 file khác |
| Test double tự viết tay (Fake, khác `InMemoryKeychainStore`) | `studiopTests/AuthUseCaseTests.swift` (`FakeAuthRepository`) |
| Name collision theo per-file/target (`Category` vs ObjC runtime) | lịch sử đổi tên `Category` → `ProductCategory` |
