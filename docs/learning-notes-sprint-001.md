# Ghi chú học tập — Sprint 1 (Core Layer)

Tài liệu tổng hợp các kiến thức Swift/iOS đã học được khi đọc và triển khai
`sprint_plan@v1.yaml` (Core layer: `AppEnvironment`, `KeychainStore`, `UserProfileCache`,
`NetworkClient`, tích hợp `swift-dependencies`). Mỗi mục có: khái niệm, vì sao cần, và trích
đoạn code thật trong project để đối chiếu.

---

## 1. `struct` vs `class` — Value type vs Reference type

- **`struct`** (`AppEnvironment`) → khi gán/truyền đi, Swift **copy toàn bộ giá trị**. Hai biến
  độc lập nhau hoàn toàn sau khi gán.
- **`class`** (`EnvironmentStore`) → khi gán/truyền đi, Swift chỉ copy **địa chỉ tham chiếu**.
  Hai biến vẫn trỏ chung một object — sửa ở đâu, thấy thay đổi ở khắp nơi.

```swift
struct Counter { var value = 0 }
class Box { var value = 0 }

var s1 = Counter(); var s2 = s1; s2.value = 99
var c1 = Box();     var c2 = c1; c2.value = 99

print(s1.value, c1.value)   // in ra: 0 99
```

**Vì sao Sprint 1 chọn khác nhau cho 2 type liên quan:** `AppEnvironment` chỉ là "cục dữ liệu"
tại một thời điểm (base URL, RTDB URL) — hợp lý là `struct`. `EnvironmentStore` phải là "nguồn sự
thật duy nhất" mà mọi nơi (kể cả `NetworkClient`) đều nhìn thấy được giá trị **mới nhất** sau khi
Remote Config cập nhật — bắt buộc phải là `class` (reference type), nếu là `struct` thì mỗi nơi sẽ
giữ một bản copy cũ, không bao giờ thấy update.

---

## 2. `NSLock` — bảo vệ state dùng chung khỏi data race

`EnvironmentStore` là `class` với `var _current` có thể bị nhiều thread đọc/ghi cùng lúc → cần
khoá thủ công:

```swift
final class EnvironmentStore: @unchecked Sendable {
    private let lock = NSLock()
    private var _current: AppEnvironment

    var current: AppEnvironment {
        lock.lock()
        defer { lock.unlock() }
        return _current
    }
}
```

- **Ẩn dụ:** một chiếc chìa khoá nhà vệ sinh duy nhất — ai muốn vào phải lấy chìa khoá; nếu người
  khác đang giữ, phải **đứng chờ** (block), không phải báo lỗi, không phải "chạy ngầm".
- `lock.lock()` **chặn đứng (block)** thread đó tại chỗ cho tới khi lock rảnh — khác hẳn với
  `await` (xem mục 5).
- `defer { lock.unlock() }` đảm bảo luôn trả lại chìa khoá dù hàm return sớm hay throw — quên
  `unlock()` sẽ gây **deadlock** (mọi thread khác chờ mãi mãi).
- **Rủi ro thật:** nếu thread bị chặn là **Main Thread** và phải chờ lâu → app **đơ thật**
  (không phản hồi chạm/cuộn). Nếu là background thread → không ảnh hưởng UI. Trong
  `EnvironmentStore`, critical section chỉ là `return _current` (vài nano giây) nên không đáng lo.

### `NSLock` vs `actor` — khi nào chọn cái nào

`actor` là cách "chuẩn" hơn của Swift concurrency để tránh data race, nhưng **bắt buộc mọi truy
cập từ bên ngoài phải `await`** — kể cả khi chỉ đọc một giá trị tức thời. Cái giá này gọi vui là
*"nhuộm màu async"* (function coloring): hàm gọi nó cũng phải thành `async`, lan ngược lên trên.

| | `class` + `NSLock` | `actor` |
|---|---|---|
| Truy cập đồng bộ (không `await`) | ✅ được | ❌ không được |
| An toàn trước data race | ✅ (nếu khoá đúng chỗ, thủ công) | ✅ (tự động, được compiler đảm bảo) |
| Dùng được trong `SwiftUI.body` (sync) | ✅ | ❌ (phải thêm `@State` để "hứng" giá trị bất đồng bộ) |

→ Sprint 1 chọn `NSLock` vì `environmentStore.current` cần đọc được **đồng bộ** ở nhiều chỗ (kể cả
tương lai trong `body` của một View debug badge), không muốn "nhuộm async" lan khắp nơi.

---

## 3. Dependency Injection — `DependencyKey` / `DependencyValues` / `@TaskLocal`

Thư viện: [**swift-dependencies**](https://github.com/pointfreeco/swift-dependencies) (Point-Free)
— **không phải mặc định của Swift**, được thêm vào project qua Swift Package Manager (TASK-1).

### Vấn đề DI giải quyết

Nếu `ViewModel` tự khởi tạo thẳng `URLSessionNetworkClient(...)`, unit test cho `ViewModel` đó
**không thể** thay `networkClient` thật bằng bản giả (fake) — mọi test sẽ gọi ra mạng thật.

### Công thức 2 phần, lặp lại cho mọi dependency trong Core

```swift
// Phần 1: khai báo 3 giá trị mặc định theo ngữ cảnh chạy
private enum EnvironmentStoreKey: DependencyKey {
    static let liveValue: EnvironmentStore = { /* staging (Debug) hoặc production (Release) */ }()
    static let testValue = EnvironmentStore(initial: .staging)
    static let previewValue = EnvironmentStore(initial: .staging)
}

// Phần 2: "gõ tắt" — để viết @Dependency(\.environmentStore) thay vì @Dependency(EnvironmentStoreKey.self)
extension DependencyValues {
    var environmentStore: EnvironmentStore {
        get { self[EnvironmentStoreKey.self] }
        set { self[EnvironmentStoreKey.self] = newValue }
    }
}
```

- **`liveValue`**: dùng khi chạy app thật, không phải test — phân biệt staging/production bằng
  cấu hình build **Debug/Release** (`#if DEBUG`), **không phải** simulator vs device thật.
- **`testValue`**: tự động dùng khi code chạy trong tiến trình test, trừ khi bị override.
- **`previewValue`**: dùng trong Xcode Canvas `#Preview` — không cần mạng/token thật.
- Hai phần **không gộp được** vì thuộc về 2 type khác nhau: `EnvironmentStoreKey` (do mình viết,
  định nghĩa giá trị mặc định) và `DependencyValues` (do thư viện định nghĩa, chỉ là nơi "gõ tắt"
  truy cập) — giống hệt pattern SwiftUI dùng cho `EnvironmentValues`.

### `@TaskLocal` — vì sao test chạy song song không bị đá nhau

Nếu tự chế DI bằng 1 `static var` toàn cục, 2 test chạy song song set 2 giá trị fake khác nhau sẽ
**đá nhau** (giống hệt bug `MockURLProtocol.requestHandler` ở mục 7). `swift-dependencies` tránh
được nhờ **`@TaskLocal`**: mỗi `Task` (mỗi test) được phát một "tờ giấy riêng" mang theo suốt cây
gọi hàm của nó, tự động lan truyền xuống mọi hàm con (kể cả hàm `async` lồng nhau) **mà không cần
truyền tham số thủ công** — Task khác chạy song song có tờ giấy riêng, không đụng nhau.

```swift
enum Current { @TaskLocal static var environmentStore = EnvironmentStore(initial: .production) }

Current.$environmentStore.withValue(EnvironmentStore(initial: .staging)) {
    childFunction()   // childFunction không nhận tham số nào, vẫn "thấy" bản staging
}
```

### `@Dependency` chỉ cần ở **một chỗ** — nơi định nghĩa `liveValue`

Ở nơi khác (kể cả test), nếu đã biết chính xác giá trị muốn dùng, cứ gọi thẳng constructor —
không cần `@Dependency`:

```swift
// Trong test: tự tay quyết định, không "nhờ hệ thống tự đoán"
let environmentStore = EnvironmentStore(initial: .staging)
URLSessionNetworkClient(session: mockSession, environmentStore: environmentStore, keychainStore: fake)
```

### Lưới an toàn: `testValue` nên "ném lỗi", không nên là bản thật

```swift
private struct UnimplementedNetworkClient: NetworkClient {
    func send(_ request: NetworkRequest) async throws -> Data {
        throw NetworkError.transport("NetworkClient.testValue was not overridden for this test")
    }
}
static let testValue: NetworkClient = UnimplementedNetworkClient()
```

Nếu `testValue` là một `NetworkClient` thật, một test quên override sẽ **âm thầm gọi mạng thật**
mà không ai biết. Ném lỗi ngay giúp phát hiện bug "quên override" tức thì.

---

## 4. Keychain Services — lưu token an toàn

**Ngộ nhận cần tránh:** Keychain **không** tự động bắt Face ID/Touch ID. Sinh trắc học Keychain
(`kSecAttrAccessControl`) là tuỳ chọn riêng, không bật trong `KeychainStore` này (token cần đọc
được **âm thầm** ở mọi network request). Tính năng "đăng nhập nhanh bằng Face ID"
(`BiometricRepository`) là một cơ chế nghiệp vụ hoàn toàn khác, tách biệt.

**Vì sao an toàn hơn `UserDefaults`:** Keychain lưu dữ liệu **mã hoá**, gắn với khoá phần cứng của
thiết bị. `UserDefaults` chỉ là file `.plist` dạng văn bản thô — đọc được ngay nếu ai đó trích xuất
được file (máy jailbreak, phân tích backup).

### `SecItemAdd` không tự ghi đè như `Dictionary`

```swift
func writeToken(_ token: String) {
    let data = Data(token.utf8)
    let query = baseQuery()
    let updateStatus = SecItemUpdate(query as CFDictionary, [kSecValueData as String: data] as CFDictionary)
    if updateStatus == errSecItemNotFound {
        var addQuery = query
        addQuery[kSecValueData as String] = data
        SecItemAdd(addQuery as CFDictionary, nil)   // chỉ add khi CHƯA có
    }
}
```

Keychain coi (`kSecClass`, `kSecAttrService`, `kSecAttrAccount`) là **khoá duy nhất** — giống hệt
`UNIQUE constraint` trong SQL. Gọi `SecItemAdd` khi đã có item trùng khoá sẽ **báo lỗi
`errSecDuplicateItem`, không ghi đè, không tạo bản sao** — nếu không check kỹ, token mới sẽ
"tưởng đã lưu" nhưng thực ra vẫn là token cũ. Đây không phải bug của Apple — API cũ (từ thời Mac OS
Classic), thiết kế có chủ đích để tránh vô tình ghi đè dữ liệu nhạy cảm.

### `SecItemCopyMatching` — API kiểu "out-parameter" cũ

```swift
var result: AnyObject?
let status = SecItemCopyMatching(query as CFDictionary, &result)   // ghi kết quả VÀO result qua con trỏ
guard status == errSecSuccess, let data = result as? Data else { return nil }
```

Khác phong cách Swift hiện đại (`return` trực tiếp) — đây là kiểu C/Core Foundation: đưa vào một
biến trống (`&result`), hàm tự điền giá trị vào đó, rồi trả riêng một `OSStatus` báo thành công hay
lỗi.

### Kiến thức nâng cao (chưa dùng ở Sprint 1, để dành cho sau)

- `kSecAttrAccessible` — kiểm soát *khi nào* đọc được (trước/sau khi mở khoá máy).
- `kSecAttrAccessControl` + `LAContext` — gắn Face ID/Touch ID vào từng item cụ thể.
- `kSecAttrAccessGroup` — chia sẻ Keychain giữa app chính và Extension (Widget, Share Extension).
- `kSecAttrSynchronizable` — đồng bộ qua iCloud Keychain.
- **Bẫy hay gặp:** Keychain **không** bị xoá khi gỡ app (khác `UserDefaults` — luôn bị xoá). Xoá
  app rồi cài lại, token cũ vẫn còn — cần chủ động `clear()` ở lần chạy đầu sau khi cài nếu muốn
  tránh việc "tự nhiên vẫn đăng nhập".

---

## 5. `async`/`await` — suspend, không phải block

So với callback cũ (`URLSession.shared.dataTask(with:completionHandler:)` → dễ callback hell, khó
`try`/`catch`), `async`/`await` cho code đọc tuần tự, rõ ràng:

```swift
func send(_ request: NetworkRequest) async throws -> Data {
    let urlRequest = try makeURLRequest(for: request)
    let (data, response) = try await session.data(for: urlRequest)
    ...
}
```

**Khác biệt cốt lõi với `NSLock`:**

| | `lock.lock()` | `await` |
|---|---|---|
| Hành vi khi phải chờ | **Block** — thread đứng yên, không làm gì khác được | **Suspend** — hàm tạm dừng, **thread được thả ra** làm việc khác |
| Khi việc chờ xong | Thread tự chạy tiếp tại chỗ | Hàm được "đánh thức", chạy tiếp — **có thể trên thread khác** |

**Ẩn dụ:** gọi món ở quầy cà phê — không đứng ì chắn quầy chờ pha xong (block), mà bước sang một
bên, được gọi tên khi xong (suspend/resume).

### Vì sao code sau `await` có thể chạy trên thread khác

Swift Concurrency dùng một **nhóm thread dùng chung** (cooperative thread pool) — không giống GCD
(`DispatchQueue.main.async` tự tay chỉ định hàng đợi). Điều được **đảm bảo** không phải "cùng
thread", mà là **"cùng ngữ cảnh cô lập" (isolation)** — cụ thể là `actor`. Đánh dấu `@MainActor`
trước `class`/`func` đảm bảo code đó **luôn** chạy trên Main Thread dù có bao nhiêu điểm `await` ở
giữa — quan trọng khi cần cập nhật UI an toàn sau một `await`.

---

## 6. `Sendable` / `@unchecked Sendable`

Đây là cách **trình biên dịch** kiểm tra hộ việc "mang" một object từ nơi này sang một ngữ cảnh
đồng thời khác (ví dụ vào trong `Task { }`) có an toàn hay không.

```swift
struct AppEnvironment: Sendable, Equatable { ... }              // struct: compiler tự kiểm chứng được
final class EnvironmentStore: @unchecked Sendable { ... }        // class + var: compiler KHÔNG tự kiểm chứng được
```

- `struct` chỉ chứa các property vốn đã Sendable (`URL`, enum...) → khai `: Sendable` là đủ,
  compiler tự xác minh toàn bộ.
- `class` có `private var _current` (mutable, reference type) → compiler **không đủ thông minh**
  để biết bạn đã khoá `NSLock` đúng chỗ → phải dùng `@unchecked Sendable` như một **lời hứa thủ
  công**: "tôi đã tự đảm bảo an toàn rồi, đừng kiểm tra nữa".

**Rủi ro quan trọng:** `@unchecked Sendable` **tắt hẳn, vĩnh viễn** việc kiểm tra Sendable cho type
đó. Nếu sau này ai thêm 1 property mới mà **quên** bọc bằng lock, compiler sẽ **hoàn toàn im
lặng** — không cảnh báo gì cả. Ngược lại, với `struct: Sendable` thường, nếu ai thêm một property
không an toàn vào, compiler **vẫn báo lỗi ngay**, vì nó tiếp tục chủ động kiểm tra.

**Quy tắc chung để quyết định có cần tự thêm `NSLock` không:** *"Cái mình đang bọc quanh đã tự
thread-safe sẵn chưa?"*

| Type bọc quanh | Tự thread-safe? | Có cần `NSLock` không |
|---|---|---|
| `AppEnvironment` (struct tự viết, giữ trong `class`) | ❌ không | ✅ cần (`EnvironmentStore`) |
| `UserDefaults` | ✅ Apple đảm bảo | ❌ không cần (`UserProfileCache`) |
| Keychain Services (`SecItem...`) | ✅ Apple đảm bảo | ❌ không cần (`KeychainStore`) |

---

## 7. Property wrapper & lỗi trùng tên `Environment`/`@Environment`

`@State`, `@Environment`, `@Binding` **không phải cú pháp riêng của Apple** — chúng chỉ là những
`struct` bình thường được đánh dấu `@propertyWrapper`, ai cũng viết được:

```swift
@propertyWrapper
struct Loud {
    var wrappedValue: String { didSet { print("ĐỔI THÀNH: \(wrappedValue.uppercased())") } }
}
struct Example { @Loud var message: String = "hi" }   // @Loud = tham chiếu tới struct Loud vừa viết
```

`@TênType` luôn là tham chiếu tới **một type tên là TênType**. Vậy `@Environment` chính là tham
chiếu tới `struct Environment<Value>` của SwiftUI.

**Lỗi thật đã gặp:** Sprint 1 ban đầu đặt tên Core type là `struct Environment` — **trùng tên**
với `SwiftUI.Environment`. Swift có luật: **type khai báo trong module hiện tại sẽ "che" (shadow)
type cùng tên import từ framework** → `@Environment(\.modelContext)` trong `ContentView.swift` bị
compiler hiểu nhầm sang `struct Environment` tự viết (không phải property wrapper hợp lệ) → lỗi
biên dịch khó hiểu ("type annotation missing in pattern"), không phải lỗi rõ ràng kiểu "không tìm
thấy type phù hợp".

**Bài học chung:** đặt trùng tên type với bất kỳ thứ gì được `import` vào (SwiftUI, Foundation,
UIKit...) đều có nguy cơ y hệt — không riêng gì `Environment`. → Đã đổi tên thành `AppEnvironment`
để tránh xung đột.

---

## 8. Swift Testing (`@Test`, `#expect`) & vấn đề chạy song song

```swift
struct NetworkClientTests {                     // struct, không kế thừa gì cả
    @Test func aNormalSuccessfulResponseIsReturnedAsIs() async throws { ... }
}
```

So với `XCTest` cũ (`class ... : XCTestCase`, hàm phải đặt tên bắt đầu bằng `test`), Swift Testing
dùng `struct` (không bắt buộc kế thừa) và đánh dấu tường minh bằng `@Test` (không phụ thuộc quy ước
đặt tên, tên hàm có thể là câu mô tả đầy đủ).

**Khác biệt hành vi quan trọng nhất:** Swift Testing chạy các `@Test` **song song mặc định**;
`XCTest` truyền thống chạy tuần tự. Điều này từng gây bug thật trong `NetworkClientTests`:

```swift
private final class MockURLProtocol: URLProtocol, @unchecked Sendable {
    static var requestHandler: (@Sendable (URLRequest) throws -> (HTTPURLResponse, Data))?
}
```

`requestHandler` là **1 biến static dùng chung** cho mọi test trong suite. Chạy song song → test A
vừa gán closure của mình, test B (chạy đồng thời) gán đè ngay lập tức → A vô tình dùng nhầm
closure của B → fail ngẫu nhiên, không phải lỗi logic trong `NetworkClient`.

**Cách sửa:**

```swift
@Suite(.serialized)   // ép các test trong suite này chạy tuần tự, vì chúng share 1 static var
struct NetworkClientTests { ... }
```

---

## 9. `URLComponents`/`URLQueryItem` (chưa học sâu — để dành buổi sau)

Dùng để build URL an toàn (tự động encode ký tự đặc biệt trong query param) thay vì nối chuỗi thủ
công — xem cách dùng trong `NetworkClient.makeURLRequest(for:)`.

---

## Bảng tổng hợp nhanh

| Khái niệm | File tham chiếu |
|---|---|
| `struct` vs `class` | `AppEnvironment.swift` |
| `NSLock`, block vs suspend, `actor` trade-off | `AppEnvironment.swift` (`EnvironmentStore`) |
| `DependencyKey`/`DependencyValues`/`@TaskLocal` | `AppEnvironment.swift`, `KeychainStore.swift`, `UserProfileCache.swift`, `NetworkClient.swift` |
| Keychain Services API | `KeychainStore.swift` |
| `async`/`await`, `@MainActor` | `NetworkClient.swift` |
| `Sendable`/`@unchecked Sendable` | mọi `class` trong `Core/` |
| Property wrapper, name shadowing | lịch sử đổi tên `Environment` → `AppEnvironment` |
| Swift Testing, `@Suite(.serialized)` | `studiopTests/NetworkClientTests.swift` |
| Quy tắc "khi nào cần tự thêm lock" | so sánh `EnvironmentStore` / `KeychainStore` / `UserProfileCache` |
