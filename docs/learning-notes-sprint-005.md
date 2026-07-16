# Ghi chú học tập — Sprint 5 (Register vertical slice)

Tài liệu tổng hợp các kiến thức Swift/iOS **mới** học được khi triển khai và sửa lỗi luồng
Register (`RegisterViewModel`, `RegisterView`, `RegisterUseCase`, `AuthRepositoryImpl.register`).
Nối tiếp [docs/learning-notes-sprint-001.md](learning-notes-sprint-001.md),
[docs/learning-notes-sprint-002.md](learning-notes-sprint-002.md),
[docs/learning-notes-sprint-003.md](learning-notes-sprint-003.md),
[docs/learning-notes-sprint-004.md](learning-notes-sprint-004.md) — không lặp lại kiến thức đã học
ở đó.

---

## 1. Xác nhận request thật qua "nguồn thứ hai" — không chỉ network capture

Sprint 4 (mục 14-16) xác nhận field/response bằng cách **bắt request/response thật** qua proxy.
Sprint 5 dùng một nguồn xác nhận khác nhưng cùng độ tin cậy: đọc thẳng đoạn code Dart của app
Flutter gốc (app đang được rebuild lại) đang tự xây body request register:

```dart
'name': name,
'first_name': firstName,
'email': email,
'password': password,
'password_confirmation': passwordConfirmation,
'check_terms': state.agreeToTerms,
```

So với `RegisterRequestDTO` cũ (đoán từ Sprint 2-3): có field `phone` (không hề tồn tại ở app gốc)
và **thiếu hẳn** `first_name`/`check_terms`.

**Bài học:** "xác nhận thật" không nhất thiết phải là bắt traffic — **source code của bản gốc đang
chạy đúng trong production** cũng là bằng chứng thật, đôi khi còn nhanh và đầy đủ hơn network
capture (thấy được toàn bộ field cùng lúc, không phụ thuộc việc tình cờ trigger đúng edge case lúc
bắt gói tin). Cả hai đều tốt hơn "đoán field theo tên hợp lý" — nguyên tắc CLAUDE.md xuyên suốt từ
Sprint 3.

---

## 2. Tham số tồn tại + được validate ≠ tham số thực sự được dùng

`RegisterUseCase` (trước khi sửa) đã validate `firstName` đàng hoàng:

```swift
func callAsFunction(name: String, firstName: String, ...) async throws -> AuthSession {
    if let error = AuthFieldValidator.validateName(firstName) { throw error }   // có validate
    ...
    return try await repository.register(
        name: name, email: email, password: password,
        passwordConfirmation: passwordConfirmation, phone: phone
        // firstName KHÔNG xuất hiện ở đây — bị rơi mất, dù đã validate ở trên
    )
}
```

Vì `repository.register(...)` không nhận `firstName`, giá trị người dùng gõ vào ô "First name"
không bao giờ tới được backend — dù build vẫn thành công và validate vẫn chạy đúng (nên bug này
**không** lộ ra qua build hay qua test validate riêng lẻ).

**Bài học:** validate một field không đảm bảo field đó được **sử dụng**. Khi thêm 1 tham số vào
`callAsFunction`/hàm bất kỳ, phải rà lại **toàn bộ đường đi** của nó tới điểm cuối (ở đây là lời gọi
`repository.register`), không chỉ chỗ validate — hai việc độc lập nhau, dễ làm 1 mà quên làm 2.

---

## 3. Bug UI: hai field khác nhau vô tình bind chung một nguồn dữ liệu

`RegisterView` (trước khi sửa):

```swift
ValidatedTextField(title: "Name", field: $viewModel.name) { ... }
...
ValidatedTextField(title: "First name", field: $viewModel.name) { ... }   // bind nhầm — vẫn $viewModel.name
```

Cả 2 ô "Name" và "First name" cùng đọc/ghi `viewModel.name` — gõ vào ô nào cũng cập nhật đúng 1
property, `viewModel.firstName` không bao giờ đổi giá trị mặc định (`""`). Bug này **im lặng** vì cả
2 `ValidatedTextField` build đúng, không có lỗi kiểu — SwiftUI không biết (và không cần biết) 2 field
UI có nên trỏ 2 nguồn dữ liệu khác nhau hay không.

**Bài học:** copy-paste một view component để tạo field thứ 2 là nguồn bug rất dễ xảy ra và rất khó
phát hiện bằng mắt (cả 2 dòng nhìn "hợp lý" tương tự nhau) — cách chắc nhất là build xong, tự tay
điền UI thật (hoặc Preview) và gõ thử để thấy giá trị field kia đổi theo, thay vì chỉ đọc code.

---

## 4. `/users/register` phá vỡ "convention chung" mà Sprint 4 vừa tổng quát hoá

Sprint 4 (mục 16) kết luận: xác nhận **2 lần độc lập** (`/users/login`, `/users/info`) đủ để nâng
`{status, msg, data, token}` từ "guess" thành **convention chung** của backend. Sprint 5 test ngay
giả định đó với endpoint thứ 3: response thật của `/users/register` khi thành công lại là:

```json
{
  "status": 1,
  "code": "U2045",
  "message": "Registration successful. Please check your email to verify your account.",
  "msg": "Registration successful. Please check your email to verify your account."
}
```

**Không có `data`, không có `token`** — khác hẳn `data`/`token` luôn có mặt ở login/info. Nguyên
nhân **không phải lỗi backend hay lỗi decode** — đây là hành vi **cố ý theo nghiệp vụ**: tài khoản
vừa đăng ký chưa dùng được ngay, phải verify email trước (`/users/verify/account`, đã có sẵn
`VerifyAccountView`/`VerifyAccountUseCase` từ trước) rồi mới login bình thường để lấy token.

**Bài học quan trọng nhất sprint này:** một "convention chung" suy ra từ nhiều lần xác nhận **vẫn
có thể có ngoại lệ** — không phải do kỹ thuật sai, mà do **ngữ nghĩa nghiệp vụ khác nhau** giữa các
endpoint (đăng nhập cấp session ngay; đăng ký chỉ là bước 1 của quy trình 3 bước). Áp dụng một
convention đã xác nhận sang endpoint mới vẫn cần verify riêng, đặc biệt khi hành động đó có ý nghĩa
nghiệp vụ khác (register ≠ login dù cùng domain Auth).

---

## 5. Cùng một thông điệp lỗi, hai nguyên nhân gốc hoàn toàn khác nhau

UI báo **"The data couldn't be read because it is missing"** — y hệt lỗi đã gặp ở Sprint 4 (mục
15). Nhưng nguyên nhân lần này khác hẳn:

| | Sprint 4 (login) | Sprint 5 (register) |
|---|---|---|
| Nguyên nhân | Sai **tên key** wrapper (`user` thay vì `data`) | Response **thật sự không có** `data`/`token` — không phải sai tên |
| Cách sửa | Đổi tên field trong DTO | Đổi hẳn **kiểu trả về** (`AuthSession` → `String`), vì Entity đó không tồn tại ở bước này |

Cả hai đều là `DecodingError.keyNotFound` bắn ra từ cùng một chỗ (`JSONDecoder().decode(...)`), và
Swift/Foundation bridge nó thành cùng một câu message chung chung — **thông điệp lỗi giống nhau
không có nghĩa nguyên nhân giống nhau**.

**Bài học:** không bao giờ suy luận nguyên nhân chỉ từ text lỗi (nhất là lỗi đã bridge qua
`localizedDescription` như đã ghi ở Sprint 4) — phải luôn quay lại nhìn thẳng response JSON thật của
chính request đang lỗi, dù lỗi trông "quen mặt" từ sprint trước.

---

## 6. UseCase/Repository nên trả về đúng "cái thực sự tồn tại" — không ép thành Entity chưa có

Vì `/users/register` không trả `token`/user data, `AuthRepository.register(...)` **không thể** và
**không nên** trả về `AuthSession` (Entity đó đại diện cho "một phiên đăng nhập đang có token" — thứ
chưa tồn tại ở bước register). Sửa lại: trả `String` (message xác nhận từ backend), và tầng trên
(`RegisterViewModel`) không còn tự động `keychainStore.writeToken(...)` + `appState.isAuthenticated =
true` như trước (hành vi đó vốn copy từ `LoginViewModel`, hợp lý cho login nhưng sai hoàn toàn cho
register).

```swift
// Domain — kiểu trả về phản ánh đúng điều THẬT SỰ xảy ra ở bước này, không phải điều ta muốn
func callAsFunction(...) async throws -> String {   // không phải AuthSession
    ...
    return try await repository.register(...)
}
```

**Bài học kiến trúc:** kiểu trả về của UseCase/Repository nên mô tả đúng những gì **backend thực sự
cam kết** ở bước đó, không phải những gì tiện cho luồng UI mong muốn (auto-login ngay sau khi đăng
ký). Khi hai hành động cùng domain (login, register) có kết quả nghiệp vụ khác nhau, đừng dùng chung
1 kiểu trả về chỉ vì "trông giống nhau" — làm vậy sẽ ép decode sai hoặc phải bịa dữ liệu giả.

---

## 7. `DependencyKey` 3 tầng (`liveValue`/`testValue`/`previewValue`) — vì sao cả 3 đều cần dù trông thừa

Câu hỏi đặt ra khi đọc `AuthRepositoryKey.swift`/`UserRepositoryKey.swift`: mỗi Repository định
nghĩa tận 3 bản (`AuthRepositoryImpl` thật, `UnimplementedAuthRepository`, `PreviewAuthRepository`)
— tại sao không dùng mỗi bản thật cho mọi trường hợp?

**Lý do đầu tiên — kiểu dữ liệu không cho phép "không có gì":**

```swift
extension DependencyValues {
    var authRepository: AuthRepository { ... }   // kiểu AuthRepository, KHÔNG PHẢI AuthRepository?
}
```

`@Dependency(\.authRepository)` luôn phải trả về **một object cụ thể** tồn tại thật trong bộ nhớ,
không thể là `nil` — nên dù đang chạy trong SwiftUI Preview (không có mạng thật, không cần logic
thật), vẫn phải có **một instance nào đó** conform `AuthRepository` đứng ra đóng vai trò đó.

**Lý do thứ hai — không phải code của mình chọn, mà là thư viện `Dependencies` tự chọn theo runtime
context:** không có dòng nào trong project gọi `previewValue`/`testValue` trực tiếp — `@Dependency`
(property wrapper từ package `swift-dependencies`) tự phát hiện đang chạy trong Xcode Preview hay
trong XCTest hay app thật, rồi tự quyết định lấy `previewValue`/`testValue`/`liveValue` tương ứng.

**Lý do thứ ba, quan trọng nhất — default luôn nghiêng về hướng AN TOÀN, không phải về hướng
`liveValue`:** theo tài liệu chính thức của `swift-dependencies`, hệ thống 3 tầng này thực chất là 2
protocol lồng nhau:

```swift
protocol TestDependencyKey {
    associatedtype Value
    static var testValue: Value { get }      // BẮT BUỘC viết — không có default
    static var previewValue: Value { get }   // CÓ default = testValue nếu không override
}

protocol DependencyKey: TestDependencyKey {
    static var liveValue: Value { get }      // BẮT BUỘC viết — không có default
}
```

Chỉ **`previewValue`** là có default, và default đó trỏ về **`testValue`** — không phải `liveValue`.
Nói cách khác: nếu lỡ quên viết `PreviewAuthRepository`, Preview sẽ rơi về dùng
`UnimplementedAuthRepository` (ném lỗi ngay khi gọi) — **không bao giờ** tự động rơi về gọi mạng
thật. Đây là thiết kế "fail-safe theo hướng an toàn": lỡ quên viết bản giả cho Preview/test thì cùng
lắm là Preview crash sớm và rõ ràng, còn hơn vô tình để code test/preview gọi thẳng lên server thật.
Ngược lại, `liveValue`/`testValue` **bắt buộc** phải tự viết tay — compiler báo lỗi ngay nếu thiếu —
vì hậu quả nếu tự động "mượn tạm" 1 trong 2 cái này đều nghiêm trọng (quên `liveValue` = app thật
không chạy được; quên `testValue` = test tự nhiên đụng mạng thật mà không ai biết).

**Việc CHƯA tự kiểm chứng trực tiếp trong source code của package** (chỉ dựa theo tài liệu chính
thức đã biết từ trước) — nếu có dịp, nên mở thẳng
`~/Library/Developer/Xcode/DerivedData/studiop-*/SourcePackages/checkouts/swift-dependencies` để đọc
`DependencyKey.swift` thật, xác nhận lại đúng như mô tả ở trên trước khi coi đây là kiến thức đã
"xác nhận thật" theo đúng tiêu chuẩn CLAUDE.md (hiện tại mới ở mức "tài liệu công khai nói vậy").

---

## Bảng tổng hợp nhanh

| Khái niệm | File tham chiếu |
|---|---|
| Xác nhận field qua source code app gốc — nguồn xác nhận khác network capture nhưng cùng độ tin cậy | `studiop/Data/Auth/DTOs/RegisterRequestDTO.swift`, `docs/api-reference.md` |
| Tham số được validate nhưng quên truyền xuống repository — validate ≠ sử dụng | `studiop/Domain/Auth/UseCases/RegisterUseCase.swift` |
| 2 field UI vô tình bind chung 1 property do copy-paste | `studiop/Features/Auth/View/RegisterView.swift` |
| Convention envelope chung có ngoại lệ do khác biệt nghiệp vụ (register chưa xác thực ngay) | `studiop/Data/Auth/DTOs/RegisterResponseDTO.swift`, `docs/api-reference.md` |
| Cùng 1 thông điệp lỗi (`DecodingError`), 2 nguyên nhân gốc khác nhau giữa 2 sprint | `studiop/Data/Auth/Network/AuthRepositoryImpl.swift` |
| Kiểu trả về của UseCase/Repository phải phản ánh đúng điều backend thật sự cam kết, không ép thành Entity chưa tồn tại | `studiop/Domain/Auth/Repositories/AuthRepository.swift`, `studiop/Features/Auth/ViewModel/RegisterViewModel.swift` |
| `DependencyKey` 3 tầng: `@Dependency` luôn cần 1 giá trị cụ thể; thư viện tự chọn theo runtime context; default (nếu có) luôn nghiêng về hướng an toàn (`previewValue` → `testValue`, không phải `liveValue`) | `studiop/Data/Auth/DependencyKeys/AuthRepositoryKey.swift`, `studiop/Data/Auth/DependencyKeys/UserRepositoryKey.swift` |
