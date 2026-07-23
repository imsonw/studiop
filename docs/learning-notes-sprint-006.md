# Ghi chú học tập — Sprint 6 (Biometric login)

Tài liệu tổng hợp các kiến thức Swift/iOS **mới** học được khi triển khai và sau đó **sửa lỗi**
luồng Biometric login (`BiometricAuthenticating`, `BiometricCredentialStore`, `BiometricRepository`,
`BiometricRepositoryImpl`, `LoginViewModel.loginWithBiometric`, `BiometricSettingsViewModel`), sau
khi đối chiếu với `BiometricCubit` — bản Flutter gốc của cùng tính năng. Nối tiếp
[docs/learning-notes-sprint-001.md](learning-notes-sprint-001.md) →
[docs/learning-notes-sprint-005.md](learning-notes-sprint-005.md) — không lặp lại kiến thức đã học
ở đó.

---

## 1. `LAContext.evaluatePolicy` là `async throws`, không phải completion callback

```swift
let ok = try await LAContext().evaluatePolicy(
    .deviceOwnerAuthenticationWithBiometrics,
    localizedReason: "Đăng nhập"
)
```

API này **ném lỗi kiểu `LAError`** khi có vấn đề, không trả `false` một cách im lặng — `LAError` có
thuộc tính `.code` cho biết **lý do cụ thể** (không phải một loại lỗi chung chung).

**Bài học:** với API kiểu `async throws -> Bool`, đừng chỉ `catch { }` chung chung — luôn hỏi "lỗi
này có case cụ thể nào cần xử lý khác nhau không" trước khi viết catch block.

---

## 2. Không phải mọi `LAError` đều là "lỗi" cần hiển thị

4 case sau đây là người dùng **tự ý** làm gián đoạn prompt — không phải hệ thống/sinh trắc học thất
bại — nên phải **im lặng bỏ qua**, không hiện thông báo đỏ:

```swift
extension LAError {
    var isSilentDismissal: Bool {
        switch code {
        case .userCancel, .systemCancel, .appCancel, .userFallback:
            return true
        default:
            return false
        }
    }
}
```

- `.userCancel` — user tự bấm Cancel trên hộp thoại.
- `.systemCancel` — hệ thống ngắt ngang (cuộc gọi đến, chuyển app xuống background).
- `.appCancel` — chính app gọi `invalidate()` huỷ ngang.
- `.userFallback` — user bấm "Enter Password" thay vì dùng sinh trắc học.

**Bài học:** khi thiết kế UX quanh một API "có thể thất bại vì nhiều lý do", phải tách rõ **lỗi thật
sự** (cần báo cho user biết để họ sửa) khỏi **lựa chọn chủ động của user** (chỉ cần tôn trọng, không
cần giải thích gì thêm). Gộp chung sẽ tạo ra thông báo lỗi giật gân cho một hành động hoàn toàn bình
thường (bấm Cancel).

---

## 3. Keychain: bộ ba `(class, service, account)` là khoá định danh một item

```swift
private func baseQuery(account: String) -> [String: Any] {
    [
        kSecClass as String: kSecClassGenericPassword,
        kSecAttrService as String: service,   // luôn giống nhau trong cùng 1 app
        kSecAttrAccount as String: account,   // khác nhau cho mỗi "biến" cần lưu riêng
    ]
}
```

`device_id` và `biometric_token` phải dùng **hai `account` khác nhau** (`"biometricDeviceID"` /
`"biometricToken"`) dù luôn được đọc/ghi cùng lúc như một cặp — nếu dùng chung 1 `account`, Keychain
sẽ coi lần ghi thứ hai là "update lên item thứ nhất", **ghi đè mất** giá trị đầu.

**Bài học:** trong Keychain, `(class, service, account)` đóng vai trò như primary key của một bảng
dữ liệu — hai giá trị logic khác nhau, dù liên quan chặt tới nhau, vẫn cần khoá riêng biệt để không
đụng độ.

---

## 4. Ghi vào Keychain phải theo pattern **update trước, add sau** (upsert)

```swift
private func writeString(_ value: String, account: String) {
    let data = Data(value.utf8)
    let query = baseQuery(account: account)
    let updateStatus = SecItemUpdate(query as CFDictionary, [kSecValueData as String: data] as CFDictionary)

    if updateStatus == errSecItemNotFound {
        var addQuery = query
        addQuery[kSecValueData as String] = data
        SecItemAdd(addQuery as CFDictionary, nil)
    }
}
```

`SecItemAdd` báo lỗi trùng (`errSecDuplicateItem`) nếu key đã tồn tại — không tự động ghi đè như
`UserDefaults`. Vì vậy mọi hàm "write" cho Keychain đều phải thử sửa trước, chỉ tạo mới khi xác nhận
chưa từng có.

**Bài học:** đây là lý do chính khiến cơ chế **rotation** (ghi đè `biometric_token` mới sau mỗi lần
login — mục 8) hoạt động đúng mà không cần code gì đặc biệt: lần ghi thứ hai tự động rơi vào nhánh
`SecItemUpdate` vì key đã tồn tại từ lần enable ban đầu.

---

## 5. Vì sao KHÔNG dùng Keychain's built-in biometric access control (`.biometryCurrentSet`)

Keychain có tính năng tự bắt Face ID cho mọi lần đọc (`kSecAttrAccessControl` +
`.biometryCurrentSet`), nhưng project **cố tình không dùng** cho cặp `device_id`/`biometric_token`.

Lý do: `LoginViewModel.init()` cần đọc Keychain **ngay khi màn hình Login xuất hiện** — chỉ để âm
thầm quyết định có nên **hiện nút** Face ID hay không, chưa hề có ý định xác thực gì:

```swift
canUseBiometricLogin = biometricCredentialStore.read() != nil
    && biometricAuthenticating.canEvaluatePolicy()
```

Nếu để Keychain tự bắt Face ID mỗi lần đọc, thao tác "check tồn tại để hiện UI" này cũng sẽ tự động
bật hộp thoại Face ID — **ngay khi mở màn hình**, trước khi user kịp làm gì.

**Bài học tổng quát (không chỉ riêng biometric):** "kiểm tra trạng thái" (cần im lặng) và "hành động
cần xác nhận" (cần tương tác) nên là hai bước **tách biệt, do code chủ động gọi tuần tự** — đừng để
một cơ chế tầng dưới (OS-level) tự quyết định thời điểm xin xác thực thay cho mình. Tính năng
`.biometryCurrentSet` vẫn hữu ích, nhưng chỉ khi "đọc" và "dùng ngay" là cùng một hành động (ví dụ:
password manager hiện mật khẩu khi bấm xem).

---

## 6. Bọc platform API (`LAContext`, Keychain) trong protocol riêng — để **test được**, không phải để "kiến trúc sạch"

```swift
protocol BiometricAuthenticating: Sendable {
    func canEvaluatePolicy() -> Bool
    func authenticate(reason: String) async throws -> Bool
}
```

Gọi thẳng `LAContext()` trong ViewModel khiến unit test không thể chạy tự động, xác định
(deterministic) — mỗi lần chạy cần Face ID thật hoặc thao tác simulator thủ công. Bọc trong protocol
cho phép test inject `AlwaysSucceedsBiometricAuthenticator` (luôn trả `true`), tương tự
`InMemoryBiometricCredentialStore` thay Keychain thật.

**Bài học:** lý do kỹ thuật cụ thể ("test cần chạy nhanh và không phụ thuộc phần cứng") thuyết phục
hơn nhiều so với lý do mơ hồ kiểu "tách lớp cho sạch" — luôn tự hỏi "nếu không bọc, cái gì cụ thể sẽ
không làm được" trước khi quyết định thêm một lớp abstraction.

---

## 7. UseCase 1-dòng vẫn đáng giữ, dù trông "thừa"

```swift
struct EnableBiometricUseCase {
    let repository: BiometricRepository
    func callAsFunction(deviceID: String, deviceName: String) async throws -> String {
        try await repository.enableBiometric(deviceID: deviceID, deviceName: deviceName)
    }
}
```

Không có logic gì thêm ngoài forward 1 lời gọi — nhưng vẫn giữ, vì: (1) `ViewModel` chỉ phụ thuộc
vào **UseCase**, không phụ thuộc trực tiếp `Repository` — nếu sau này `enableBiometric` cần thêm
bước validate/composite nhiều repository, chỉ UseCase đổi, ViewModel không biết gì; (2) tính **nhất
quán** của ranh giới kiến trúc trên cả 16 domain (CLAUDE.md: "one UseCase per user-facing action")
quan trọng hơn việc tiết kiệm 1 file hôm nay — trộn lẫn "domain nào có UseCase, domain nào không" sẽ
gây khó đoán hơn nhiều so với vài UseCase mỏng.

**Bài học:** đừng đánh giá một lớp trung gian chỉ bằng "hôm nay nó có bao nhiêu dòng code" — đánh giá
bằng "ranh giới phụ thuộc nó tạo ra có nhất quán và có ích về lâu dài không".

---

## 8. So sánh với mã nguồn app gốc phát hiện 6 lỗi logic thật (không phải chỉ 1 giả định đã biết)

Sprint 6 (v1) tự flag đúng 1 giả định UNCONFIRMED (`biometric_token` tự sinh UUID thay vì server
cấp). Khi người dùng đưa `BiometricCubit.dart` (Flutter gốc) để đối chiếu trực tiếp, lộ ra thêm **5
lỗi khác** mà v1 không hề flag vì không biết là vấn đề:

| Lỗi | Bản chất |
|---|---|
| `biometric_token` tự sinh | Xác nhận đúng là sai — server cấp, không phải client tự tạo |
| Thiếu xoay vòng `new_biometric_token` | Backend rotate token sau mỗi lần login, client phải ghi đè lại |
| Không phân biệt server-reject vs network-error | Chỉ nên xoá pairing khi server từ chối rõ ràng, không phải mọi lỗi |
| Disable không xoá local khi API lỗi | Nên luôn xoá local (an toàn hơn), bất kể API disable thành công hay không |
| Prompt bị huỷ hiện lỗi giật gân | Đã ghi ở mục 2 |
| Đổi mật khẩu không xoá pairing biometric | Pairing cũ gắn với mật khẩu cũ, cần xoá theo |

**Bài học quan trọng nhất sprint này:** một "1 giả định đã flag đúng cách" **không đảm bảo** đã tìm
hết vấn đề — nó chỉ đảm bảo *phần mình biết mình không biết* đã được ghi lại trung thực. Khi có nguồn
xác nhận thật (ở đây là source code app gốc, cùng độ tin cậy như network capture — xem
[docs/learning-notes-sprint-005.md §1](learning-notes-sprint-005.md)), luôn đáng đối chiếu **toàn bộ
luồng logic**, không chỉ phần đã tự nghi ngờ trước đó — vì các lỗi khác thường "nhìn hợp lý" đúng như
lỗi Sprint 5 mục 3 (bug im lặng, build vẫn qua, test vẫn xanh).

---

## Bảng tổng hợp nhanh

| Khái niệm | File tham chiếu |
|---|---|
| `LAContext.evaluatePolicy` là `async throws`, không phải completion callback | `studiop/Core/BiometricAuthenticating.swift` |
| 4 case `LAError` cần xử lý im lặng, không phải lỗi thật | `studiop/Core/BiometricAuthenticating.swift` (`isSilentDismissal`) |
| `(class, service, account)` là khoá định danh Keychain item — 2 giá trị liên quan vẫn cần `account` riêng | `studiop/Core/BiometricCredentialStore.swift` |
| Ghi Keychain phải theo pattern upsert (update trước, add sau) | `studiop/Core/BiometricCredentialStore.swift` (`writeString`) |
| Không dùng Keychain biometric access-control khi cần tách "check tồn tại âm thầm" khỏi "xác thực chủ động" | `studiop/Features/Auth/Login/LoginViewModel.swift` (`canUseBiometricLogin`) |
| Bọc platform API trong protocol để test được (fake injection), không phải vì kiến trúc trừu tượng | `studiop/Core/BiometricAuthenticating.swift`, `studiop/Core/BiometricCredentialStore.swift` |
| UseCase 1 dòng vẫn giữ để ViewModel không phụ thuộc trực tiếp Repository + nhất quán toàn bộ 16 domain | `studiop/Domain/Auth/UseCases/Biometric/EnableBiometricUseCase.swift` |
| Đối chiếu với source app gốc lộ ra 5 lỗi logic ngoài giả định đã tự flag | `studiop/Data/Auth/Network/BiometricRepositoryImpl.swift`, `.agents/artifacts/sprint-006/dev_report@v2.yaml` |
