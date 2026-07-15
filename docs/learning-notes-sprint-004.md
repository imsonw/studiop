# Ghi chú học tập — Sprint 4 (Login Vertical Slice)

Tài liệu tổng hợp các kiến thức Swift/iOS **mới** học được khi triển khai
`sprint-004/sprint_plan@v1.yaml` (Presentation layer đầu tiên của project: `LoginViewModel`,
`LoginView`, `HomeView`, và root navigation trong `studiopApp.swift`). Nối tiếp
[docs/learning-notes-sprint-001.md](learning-notes-sprint-001.md),
[docs/learning-notes-sprint-002.md](learning-notes-sprint-002.md),
[docs/learning-notes-sprint-003.md](learning-notes-sprint-003.md) — không lặp lại kiến thức đã
học ở đó.

---

## 1. Lớp Data gồm những gì — DTO, DataSource, RepositoryImpl, DependencyKey

Trước khi code Sprint 4, ôn lại 4 thành phần của lớp Data (`Data/Auth/`):

- **DTO** — hình dạng dữ liệu qua JSON, có `toDomain()` map sang Entity (đã học kỹ ở Sprint 3).
- **DataSource** — chỉ biết lấy/ghi dữ liệu từ **một nguồn duy nhất** (REST, Firebase, hoặc
  cache). Project hiện **chưa tách** DataSource riêng cho Auth, vì `AuthRepositoryImpl` mới chỉ
  cần gọi REST (một nguồn duy nhất) — DataSource + Repository gộp làm một khi chỉ có 1 nguồn.
- **RepositoryImpl** — "nhạc trưởng" điều phối DataSource + map DTO→Entity + implement protocol
  Domain định nghĩa.
- **DependencyKey** — khai báo cách `swift-dependencies` tạo ra instance thật.

**Bằng chứng trong chính project:** [docs/architecture.md:64-72](../docs/architecture.md#L64) quy
định tên folder theo *nguồn dữ liệu*:

```
Data/<Feature>/
  Network/    RemoteXRepository implementations (REST)
  Firebase/   FirebaseLiveRoomDataSource, ... (chỉ Live)
  Ably/       AblyChatDataSource (chỉ Chat)
```

`Auth` chỉ có `Network/` vì chỉ cần REST. `Live`/`Chat` sẽ có thêm `Firebase/`/`Ably/` vì cần điều
phối ≥ 2 nguồn — lúc đó DataSource mới thực sự tách khỏi Repository. Tên folder chính là dấu hiệu
cho biết feature đó cần điều phối bao nhiêu nguồn dữ liệu.

---

## 2. Ranh giới xử lý lỗi: phát hiện lỗi ẩn trong response nằm ở Core, không phải Data

`Core/NetworkClient.swift` (`URLSessionNetworkClient.send()`) đã tự kiểm tra và `throw` cho **cả
hai** trường hợp lỗi trước khi trả `Data` về cho Repository:

```swift
if httpResponse.statusCode == 200, containsInvalidTokenMessage(data) {
    throw NetworkError.sessionInvalidated   // lỗi "giấu" trong body 200 OK
}
guard (200..<300).contains(httpResponse.statusCode) else {
    throw NetworkError.http(status: httpResponse.statusCode, body: data)  // mọi status ngoài 2xx
}
```

**Bài học:** dù `AuthRepositoryImpl.verifyAccount()` trả về `Void` (không có giá trị để dùng), nó
vẫn `throw` lỗi bình thường — `Void` và `throws` là hai khái niệm độc lập trong Swift, không liên
quan đến nhau. Và quan trọng hơn: "ai phát hiện lỗi" nên đặt ở **tầng thấp nhất nhìn thấy dữ liệu
thô** (`NetworkClient`/Core) — không lặp lại logic parse lỗi ở từng Repository, đúng nguyên tắc
"một lý do để thay đổi" (SRP) đã học.

---

## 3. `@Observable` và `@Dependency` không dùng chung trực tiếp trong một class

Bug thật gặp phải khi build `LoginViewModel` lần đầu:

```swift
// SAI — build lỗi hàng loạt: "ambiguous reference to member '_authRepository'",
// "property wrapper cannot be applied to a computed property"
@Observable
final class LoginViewModel {
    @Dependency(\.authRepository) private var authRepository
    @Dependency(\.userRepository) private var userRepository
}
```

**Lý do:** macro `@Observable` viết lại toàn bộ property thành computed property có
`ObservationTracked` để SwiftUI theo dõi thay đổi. `@Dependency` cũng là property wrapper, tự sinh
ra property `_authRepository` riêng. Hai macro cùng cố "chiếm" quyền sinh code cho cùng một
property → xung đột.

**Cách sửa** — không dùng `@Dependency` bên trong class `@Observable`; đọc dependency ở **View**
(nơi không có macro `@Observable`), rồi truyền vào qua constructor:

```swift
// LoginView.swift — View đọc @Dependency bình thường, không xung đột
struct LoginView: View {
    @Dependency(\.authRepository) var authRepository
    ...
    .onAppear {
        viewModel = LoginViewModel(
            loginUseCase: LoginUseCase(repository: authRepository),
            ...
        )
    }
}
```

---

## 4. ViewModel nên phụ thuộc `UseCase`, không phải `Repository` trực tiếp

Bản đầu tiên của `LoginViewModel` nhận thẳng `AuthRepository`/`UserRepository`, rồi tự tạo UseCase
bên trong `login()`:

```swift
// Bản đầu — ViewModel biết cả Repository lẫn UseCase
init(authRepository: AuthRepository, userRepository: UserRepository, ...) { ... }
func login() async {
    let loginUseCase = LoginUseCase(repository: authRepository)  // tạo mới mỗi lần gọi
    ...
}
```

Về mặt dependency-direction (nguyên tắc Clean Architecture thật sự enforce), cách này **không sai**
— `AuthRepository` vẫn là protocol tầng Domain. Nhưng nó làm yếu đi **ranh giới ngữ nghĩa** mà
UseCase tồn tại để bảo vệ: UseCase đại diện cho "một hành động nghiệp vụ cụ thể", Repository chỉ là
"nơi lấy dữ liệu thô". Nếu ViewModel cầm thẳng Repository, nó có thể gọi bất kỳ method nào của
Repository mà không thông qua UseCase nào — bỏ qua lớp đóng gói business rule.

**Sửa lại** — `LoginView` (nơi có `@Dependency`) tự lắp ráp UseCase, `LoginViewModel` chỉ nhận
UseCase đã lắp sẵn, không biết Repository tồn tại:

```swift
final class LoginViewModel {
    private let loginUseCase: LoginUseCase
    private let fetchUserInfoUseCase: FetchUserInfoUseCase
    // không còn authRepository/userRepository

    init(loginUseCase: LoginUseCase, fetchUserInfoUseCase: FetchUserInfoUseCase, ...) { ... }
    func login() async {
        let session = try await loginUseCase(email: email, password: password)  // dùng luôn, không tạo mới
        ...
    }
}
```

Lợi ích phụ: UseCase giờ chỉ tạo **một lần** (lúc `onAppear`), không bị tạo lại mỗi lần bấm nút
đăng nhập.

---

## 5. Swift Testing (`Testing`) là convention của project — không phải `XCTest`

Viết nhầm `LoginViewModelTests` theo `XCTest` cũ (`import XCTest`, `class ... : XCTestCase`,
`XCTAssertTrue`) trong khi **mọi** test file khác trong project (`UserUseCaseTests`,
`NetworkClientTests`, `PaymentUseCaseTests`...) đều dùng **Swift Testing** — framework mới của
Apple:

```swift
// SAI — không nhất quán với convention project
import XCTest
final class LoginViewModelTests: XCTestCase {
    func testLoginSuccess() async { XCTAssertTrue(...) }
}

// ĐÚNG — Swift Testing, khớp mọi file test khác
import Testing
struct LoginViewModelTests {
    @Test func loginSuccess() async { #expect(...) }
}
```

**Cách nhận biết nhanh:** `import Testing` (không phải `XCTest`), test case là `struct` (không
phải `class ... : XCTestCase`), hàm test có `@Test` (không cần tiền tố `test`), assertion dùng
`#expect(...)` (không phải `XCTAssert*`).

---

## 6. `@ObservationIgnored` — chỉ cần cho `var`, không cần cho `let`

`@Observable` chỉ áp cơ chế theo dõi thay đổi (tracking) cho property **`var`** — vì mục đích là
biết khi nào giá trị đổi để SwiftUI re-render. Property `let` không bao giờ đổi sau `init`, nên
không có gì để theo dõi; đánh dấu `@ObservationIgnored` lên `let` là thừa.

```swift
@Observable
final class LoginViewModel {
    var email: String = ""        // var + cần track UI → giữ nguyên, không ignore
    var isLoading: Bool = false    // var + cần track UI → giữ nguyên, không ignore

    private let loginUseCase: LoginUseCase   // let → macro không tác động, không cần ignore
}
```

`@ObservationIgnored` chỉ thật sự cần khi có một `var` **không** muốn kích hoạt re-render (ví dụ
cache nội bộ, counter debug) — `LoginViewModel` hiện tại không có property nào thuộc dạng này.

---

## 7. `@MainActor` — đảm bảo resume sau `await` vẫn ở main thread

`login()` là `async func` có `await` (gọi mạng thật). Sau khi `await` resume, Swift's concurrency
runtime **không đảm bảo** code tiếp tục chạy trên main thread — có thể resume trên bất kỳ thread
nào trong cooperative thread pool. Nếu `appState.isAuthenticated = true` chạy trên background
thread trong khi SwiftUI đang đọc giá trị đó trên main thread để vẽ `RootView` → **data race**
(không phải "đơ UI" — "đơ" là khi block main thread bằng việc đồng bộ nặng; đây là hai luồng đụng
vào cùng vùng nhớ không đồng bộ, hậu quả là UI cập nhật sai thời điểm hoặc undefined behavior).

**Sửa:** đánh dấu `@MainActor` cho cả `LoginViewModel` và `AppState` — global actor này đảm bảo
mọi property/method của type luôn chạy trên main thread, và sau bất kỳ `await` nào, runtime tự
động "hop" lại main actor trước khi resume phần code còn lại:

```swift
@MainActor
@Observable
final class LoginViewModel { ... }

@MainActor
@Observable
final class AppState { ... }
```

**Tác dụng phụ cần biết:** một khi type là `@MainActor`, bất kỳ code nào gọi vào nó từ context
**không** phải main actor (ví dụ test chạy nonisolated) sẽ bị lỗi biên dịch — phải đánh dấu nơi gọi
cũng `@MainActor`:

```swift
@MainActor   // bắt buộc, nếu không: "main actor-isolated property ... can not be referenced
struct LoginViewModelTests { ... }   // from a nonisolated context"
```

---

## 8. `@Bindable` — tạo `$binding` tới property của một class `@Observable`

`$` không phải cú pháp riêng của SwiftUI — nó là cách truy cập **`projectedValue`** của một
property wrapper. Chỉ property khai báo với `@State`/`@Binding`/`@Bindable`/`@Environment`... mới
có `$`. Bản đầu của `LoginView` viết tay `Binding(get:set:)` vì `vm` chỉ là `let` thường (sau khi
unwrap optional) — không có property wrapper nào bọc nó nên không có `$vm`:

```swift
// Trước — Binding thủ công vì `vm` không có projectedValue
if let vm = viewModel {
    TextField("Email", text: Binding(get: { vm.email }, set: { vm.email = $0 }))
}
```

**Sửa bằng `@Bindable`** — property wrapper ra đời cùng `@Observable`, thay thế `@ObservedObject`
thời `ObservableObject`/Combine cũ, chuyên dùng để lấy `$binding` tới property của một **class**
(reference type) conform `Observable`:

```swift
// Sau — @Bindable cấp cho `vm` một projectedValue ($vm), $vm.email tự sinh Binding<String>
if let viewModel {
    @Bindable var vm = viewModel
    TextField("Email", text: $vm.email)
    SecureField("Password", text: $vm.password)
}
```

**Quy tắc chung cần nhớ:** không thể tự ý viết `$x` cho bất kỳ biến nào — biến đó phải được khai
báo bằng một property wrapper có định nghĩa `projectedValue`. Đây là lý do `$vm.email` không tồn
tại cho tới khi `vm` được bọc lại bằng `@Bindable`.

**Cập nhật quan trọng — hoá ra `@Bindable` ở đây là THỪA:** thử xoá hẳn dòng `@Bindable var vm =
viewModel` và dùng thẳng `$viewModel.email` — build vẫn thành công! Lý do: `viewModel` trong
`LoginView` **đã** là `@State private var viewModel: LoginViewModel` — bản thân `@State` đã có
sẵn `$viewModel` (kiểu `Binding<LoginViewModel>`). Và `Binding<Value>` có sẵn một subscript
`@dynamicMemberLookup` (tồn tại từ trước cả `@Observable`, dùng chung cho mọi `Value`, không chỉ
class `Observable`) cho phép viết `$viewModel.email` để tự suy ra `Binding<String>` — không cần
`@Bindable` nữa:

```swift
// Không cần @Bindable nếu viewModel đã là @State/@Binding sẵn
TextField("Email", text: $viewModel.email)   // $viewModel có sẵn từ @State, dynamicMemberLookup lo phần còn lại
```

**Vậy khi nào THẬT SỰ cần `@Bindable`?** Chỉ khi biến giữ reference tới object `@Observable`
**không** phải `@State`/`@Binding` của chính view đó — ví dụ nhận qua tham số `let model:
SomeObservableClass` (không property wrapper nào bọc), lúc đó không có sẵn `$model` để tận dụng
dynamicMemberLookup, nên mới cần `@Bindable var m = model` để "cấp" cho nó một `$m`. Trường hợp ban
đầu của `LoginView` (đọc từ `if let vm = viewModel` — một `let` unwrap từ Optional) rơi vào đúng
tình huống này; nhưng sau khi bỏ Optional (mục 9, `viewModel` giờ là `@State` non-optional trực
tiếp), điều kiện cần `@Bindable` không còn nữa — mà không ai quay lại dọn dẹp, nên nó tồn tại "thừa"
một thời gian cho tới câu hỏi này.

---

## 9. `body` luôn chạy TRƯỚC `.onAppear`/`.task` — vì sao cần Optional, và cách né nó

Bản đầu của `LoginView` dùng `@State var viewModel: LoginViewModel?` + `.onAppear { viewModel =
... }` + `if let viewModel { ... }`. Câu hỏi đặt ra: `.onAppear` chạy khi view xuất hiện, vậy
`viewModel` có chắc chắn có giá trị trước khi người dùng thấy form không?

**Thứ tự thật sự khi view xuất hiện lần đầu:**
1. SwiftUI gọi `body` lần 1 để biết vẽ gì — `viewModel` **vẫn là `nil`** vì `.onAppear` **chưa
   chạy**.
2. Render xong lần 1 (form trống, vì `if let` false).
3. `.onAppear` (hoặc `.task`) mới chạy → gán `viewModel`.
4. `@State` đổi → SwiftUI gọi lại `body` lần 2 → giờ mới thấy form.

`.task {}` **không** giải quyết được vấn đề này — nó cũng là side-effect chạy **sau** lần render
đầu, y hệt `.onAppear` về mặt thứ tự. Nếu force-unwrap `viewModel!` thay vì `if let`, app sẽ crash
ngay ở bước 1.

**Cách né Optional hoàn toàn** — tạo `viewModel` bên trong `init` của View (chạy trước `body` lần
đầu tiên), đọc `@Dependency` bằng property wrapper cục bộ ngay trong `init`, rồi gán thẳng vào
storage của `@State` bằng cú pháp đặc biệt `_property = State(initialValue:)`:

```swift
struct LoginView: View {
    @State var viewModel: LoginViewModel   // không Optional

    init(appState: AppState) {
        @Dependency(\.authRepository) var authRepository
        ...
        _viewModel = State(initialValue: LoginViewModel(...))  // gán trực tiếp storage, chỉ làm được trong init
    }
}
```

`_viewModel = State(initialValue:)` khác với `viewModel = ...` (gán qua `wrappedValue`) — cách này
chỉ hợp lệ trong `init`, vì lúc đó `@State`'s underlying storage chưa được SwiftUI quản lý.

---

## 10. `@State`/property nội bộ nên là `private` — `private` không cản trở `init` cùng type

Property nào là chi tiết nội bộ của View — không có code bên ngoài nào cần đọc/ghi trực tiếp sau
khi tạo — nên đánh dấu `private`. `@State` gần như luôn đi kèm `private` trong quy ước SwiftUI, vì
bản chất nó là state riêng của đúng view đó quản lý:

```swift
// Trước — không có lý do kỹ thuật nào cần để internal/public
var appState: AppState
@State var viewModel: LoginViewModel

// Sau
private let appState: AppState        // chưa từng gán lại sau init → let luôn
@State private var viewModel: LoginViewModel
```

**Điểm dễ nhầm:** `private` **không** cản trở việc gán giá trị trong `init` — `private` chỉ chặn
truy cập từ **bên ngoài type**. Vì `init` được định nghĩa **bên trong chính `struct LoginView`**,
gán `self.appState = appState` hay `_viewModel = State(initialValue: ...)` từ `init` vẫn hợp lệ
bình thường, kể cả khi property là `private`. Việc `LoginView(appState: appState)` gọi được từ
`RootView` cũng không bị ảnh hưởng — `private` trên property khác hoàn toàn với access level của
tham số `init`.

---

## 11. `@Environment` — tránh "prop drilling", nhưng không đọc được trong `init`

Trước khi sửa, `appState` bị truyền thủ công qua từng tầng: `studiopApp` → `RootView` → `LoginView`
— gọi là **"prop drilling"**: view trung gian (`RootView`) phải nhận rồi chuyển tiếp một giá trị nó
không hề dùng cho chính nó, chỉ để đưa xuống con. Với app lớn (nhiều tầng view lồng sâu), cách này
rất cồng kềnh.

**`@Environment` giải quyết việc này** — inject giá trị **một lần** cao trong cây view, mọi view
con phía dưới đọc trực tiếp, không cần đi qua `init` của các tầng trung gian:

```swift
// Inject một lần, ở gần root nhất
WindowGroup {
    RootView()
        .environment(appState)   // không phải .environmentObject — đó là API cũ cho ObservableObject/Combine
}

// Bất kỳ view con nào (dù sâu bao nhiêu tầng) đọc trực tiếp
struct RootView: View {
    @Environment(AppState.self) var appState   // không cần RootView.init(appState:) nữa
}
```

**Giới hạn quan trọng — không dùng được trong `init`:** thử thật bằng cách đổi `LoginView` sang
`@Environment(AppState.self) private var appState` rồi đọc nó ngay trong `init` (để build
`LoginViewModel`) — build báo lỗi **compile-time** thật:

```
error: 'self' used before all stored properties are initialized
```

**Lý do chính xác** (không phải "environment chưa resolve lúc runtime" như đoán ban đầu — kiểm
chứng bằng compiler mới biết): `appState` qua `@Environment` là một **computed property** (macro
sinh getter đọc `_appState.wrappedValue`). Swift quy định trong `init` của `struct`, phải gán
**xong toàn bộ stored property** trước khi được gọi bất kỳ computed property nào qua `self` — kể cả
đọc gián tiếp qua property wrapper. Ở đây `_viewModel` (stored property khác) đang gán dở, mà biểu
thức gán lại cần đọc `appState` (computed) → Swift chặn ngay lúc biên dịch, không đợi tới runtime.

Vì `LoginView` cần `appState` **ngay trong `init`** để build `LoginViewModel` (mục 9 — cố tình
tránh Optional), `@Environment` không thay được cách truyền hiện tại cho `LoginView`. Nên chỉ áp
dụng `@Environment` cho `RootView` (chỉ đọc `appState.isAuthenticated` trong `body`, không cần gì
lúc `init`) — `RootView` vẫn tự truyền `appState` (lấy từ `@Environment` của chính nó) xuống
`LoginView(appState: appState)`, vì đây chỉ là 1 tầng liền kề, không phải "khoan xuyên" qua nhiều
view không liên quan.

**Bài học:** không có giải pháp "một cỡ vừa tất cả" — `@Environment` hợp cho state chỉ cần **đọc**
ở `body`; view nào cần giá trị **ngay lúc khởi tạo** (để build object khác trong `init`) vẫn phải
nhận qua tham số `init` như bình thường.

---

## 12. Một khai báo `@PropertyWrapper` thực chất sinh ra 3 thứ: `x`, `$x`, `_x`

Mở rộng thêm từ mục 8 (`@Bindable`, `$`) — hoá ra `$` chỉ là **một nửa** câu chuyện. Một dòng khai
báo property wrapper như:

```swift
@State private var viewModel: LoginViewModel
```

compiler thực chất sinh ra **3 thứ** từ đúng 1 dòng đó:

| Tên | Là gì | Kiểu |
|---|---|---|
| `viewModel` | giá trị bên trong (`wrappedValue`) — dùng bình thường | `LoginViewModel` |
| `$viewModel` | **projected value** (mục 8) — dùng cho binding | `Binding<LoginViewModel>` |
| `_viewModel` | **chính instance của property wrapper** — nơi lưu trữ thật | `State<LoginViewModel>` |

Bình thường không bao giờ cần đụng tới `_x` — ví dụ `@State var count = 0`, Swift tự ngầm sinh
`_count = State(initialValue: 0)` cho bạn. Chỉ cần viết tay `_x = Wrapper(...)` khi giá trị khởi
tạo **không thể là một hằng số tĩnh** ngay tại chỗ khai báo (ví dụ phụ thuộc tham số `init`/
`@Dependency`, như trường hợp `_viewModel = State(initialValue: LoginViewModel(...))` ở
`LoginView.init`, mục 9) — lúc đó phải tự tay làm thay phần Swift lẽ ra tự sinh.

---

## 13. Local dev environment không push lên git — `#filePath` + file gitignore, không cần sửa `.pbxproj`

Muốn thêm một `AppEnvironment.local` để trỏ vào backend tự host tại nhà (theo đúng mục tiêu
CLAUDE.md: "pointing at a self-hosted backend later is a one-line change"), nhưng URL đó thường
khác nhau theo từng máy dev (IP local, port...) — không nên commit lên git.

**Cách tránh không cần đụng tới Xcode project (`.xcconfig`, `Info.plist`, hay sửa `.pbxproj`):**
đọc file JSON nằm **cạnh chính source file** bằng `#filePath` (literal đường dẫn tuyệt đối của file
Swift đang biên dịch trên máy hiện tại):

```swift
static var local: AppEnvironment? {
    let localConfigURL = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent()                       // thư mục chứa AppEnvironment.swift
        .appendingPathComponent("local-environment.json")   // file cạnh nó

    guard let data = try? Data(contentsOf: localConfigURL),
          let config = try? JSONDecoder().decode(LocalConfig.self, from: data),
          let apiURL = URL(string: config.apiBaseURL)
    else { return nil }   // file không tồn tại → nil, build/chạy bình thường cho mọi dev khác

    return AppEnvironment(kind: .local, apiBaseURL: apiURL, ...)
}
```

**Vì sao cách này an toàn cho cả team:** `local-environment.json` bị thêm vào `.gitignore` — file
không tồn tại trên máy người khác, `AppEnvironment.local` trả về `nil` một cách êm đẹp (không lỗi
compile, không crash), code rơi về `.staging` như bình thường:

```swift
static let liveValue: EnvironmentStore = {
    #if DEBUG
    EnvironmentStore(initial: .local ?? .staging)   // .local nil ở máy khác → dùng .staging
    #else
    EnvironmentStore(initial: .production)
    #endif
}()
```

Kèm theo một file **mẫu có commit** (`local-environment.example.json`) để dev khác biết cần điền gì
khi muốn tự tạo file thật của riêng họ — giống hệt convention `.env.example` bên web.

**So với các cách khác (`.xcconfig` + `#include?`, biến môi trường qua Scheme cá nhân):** cách này
không cần sửa `project.pbxproj` (tránh rủi ro tự tay chỉnh file `.pbxproj` — dễ hỏng nếu gõ sai ID),
không phụ thuộc Scheme personal/shared, chỉ là Swift + file hệ thống thuần tuý — đơn giản nhất cho
một project ở quy mô hiện tại.

**Giới hạn cần biết:** `#filePath` nhúng đường dẫn tuyệt đối lúc **biên dịch** — chỉ dùng được khi
build trên chính máy đang chạy Simulator (cùng filesystem). Không dùng được cho build chạy trên
thiết bị thật tách biệt hoàn toàn khỏi máy build (nhưng đây vốn chỉ là tiện ích debug cục bộ trên
Simulator, không phải use case đó).

---

## 14. Debug network thật bằng cách so sánh request thành công vs thất bại — thiếu `Content-Type`

Login qua app Studiop trả lỗi `{"status": 0, "msg": "Please enter your Email."}` dù backend nhận
đúng body `{"email":"...","password":"..."}`. Bắt request thật qua proxy, so với request **cùng
endpoint, cùng body** nhưng gọi từ app Flutter gốc (đã biết chạy đúng):

| | App Studiop (lỗi) | App Flutter gốc (đúng) |
|---|---|---|
| Body | `{"email":"...","password":"..."}` | **giống hệt** |
| `Content-Type` | `application/x-www-form-urlencoded` | `application/json` |

**Phương pháp debug:** khi 2 request cùng gọi 1 endpoint, cùng body, nhưng 1 cái lỗi 1 cái đúng —
so sánh **từng header** giữa 2 request thật (không đoán) để cô lập chính xác biến số khác nhau.
Ở đây chỉ có đúng 1 khác biệt có ý nghĩa: `Content-Type`.

**Nguyên nhân gốc:** backend đọc `Content-Type: application/x-www-form-urlencoded` nên cố parse
body như dạng `key=value&key2=value2`, không phải JSON — dù body thực chất là JSON hợp lệ. Kiểm
tra `NetworkClient.makeURLRequest()`: **không có dòng nào set `Content-Type`** cho bất kỳ request
nào — bug ảnh hưởng **toàn bộ** POST request trong app (login, register, mọi User endpoint...),
không riêng gì login.

```swift
// Thiếu — mọi request có JSON body đều bị thiếu Content-Type
urlRequest.httpBody = request.body
urlRequest.setValue(currentLanguageCode(), forHTTPHeaderField: "lang")
// (không có Content-Type ở đây)

// Sửa — set Content-Type cho mọi request có body, đặt TRƯỚC khi áp headers do caller cung cấp
// (để caller vẫn override được nếu cần, ví dụ multipart upload sau này)
if request.body != nil {
    urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
}
for (field, value) in request.headers {
    urlRequest.setValue(value, forHTTPHeaderField: field)
}
```

**Bài học:** `httpBody` chứa đúng JSON không có nghĩa backend sẽ parse đúng — HTTP dựa vào
`Content-Type` để biết cách **diễn giải** body, không tự suy luận từ nội dung. Đây chính xác là
rủi ro Sprint 3's QA report đã cảnh báo trước ("DTO field names là best guess, cần xác nhận với
backend thật ở Sprint 4") — nhưng hoá ra vấn đề thật không nằm ở field name, mà ở tầng thấp hơn
(Core/NetworkClient), một lớp mà 16 domain sau này đều dùng chung — sửa 1 chỗ, khỏi phải sửa lại
ở từng RepositoryImpl.

---

## 15. `DecodingError` bắn ra khi wrapper key sai — và tại sao message lại chung chung

Sau khi sửa Content-Type, login vẫn lỗi — nhưng lần này UI báo **"The data couldn't be read
because it is missing."**, dù backend trả `200` với response đầy đủ, hợp lệ. So sánh response
thật với DTO đang giả định:

```swift
// Data/Auth/DTOs/AuthSessionResponseDTO.swift — Sprint 3's best guess
struct AuthSessionResponseDTO: Decodable {
    let token: String
    let user: UserDTO   // <- tìm key "user" ở top-level
}
```

Response thật: `{"status": 1, "code": "U200", "msg": "...", "data": {...}, "token": "..."}` —
**không hề có key `"user"`** ở top-level, user object nằm dưới key **`"data"`**.
`JSONDecoder` không tìm thấy `"user"` → ném `DecodingError.keyNotFound` → khi code bắt lỗi generic
(`catch { errorMessage = error.localizedDescription }`, xem `LoginViewModel.login()`), Swift/
Foundation bridge `DecodingError` sang `NSError` và trả về một câu **rất chung chung** — không nói
thẳng "thiếu key nào" — nên debug phải quay lại nhìn thẳng vào response JSON thật, không thể chỉ
đọc message lỗi mà đoán ra nguyên nhân.

**Phát hiện thêm, quan trọng hơn:** cả response thành công (`status: 1`) lẫn response thất bại
trước đó (`status: 0`, `"Please enter your Email."`) đều là **HTTP 200** — xác nhận backend này
dùng field `status`/`msg` trong body để báo thành công/thất bại thật, **không dùng HTTP status
code**. Đây chính xác là rủi ro đã bàn ở mục 2 (ai bắt lỗi ẩn trong response) — giờ có bằng chứng
thật để tổng quát hoá, không còn chỉ là lý thuyết:

```swift
// NetworkClient.swift — thêm 1 check tổng quát, cùng chỗ với containsInvalidTokenMessage
// nhưng KHÔNG clear Keychain (lỗi nghiệp vụ thường không phải do session hỏng)
private func businessFailureMessage(in data: Data) -> String? {
    guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
          let status = json["status"] as? Int, status == 0,
          let message = json["msg"] as? String
    else { return nil }
    return message
}
```

Và để message thật của backend (`msg`) hiển thị đúng lên UI thay vì text lỗi Swift chung chung,
`NetworkError` giờ conform `LocalizedError`:

```swift
extension NetworkError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .apiError(let message): return message   // dùng thẳng msg backend, không tự chế
        ...
        }
    }
}
```

**Test hồi quy quan trọng nhất:** dùng **verbatim response JSON thật** bạn vừa capture được làm
fixture test (`loginDecodesARealCapturedSuccessResponse`) — không phải JSON tự bịa gần giống, mà
copy y nguyên response server trả về. Đây là cách chắc chắn nhất để test không "tự lừa mình" bằng
fixture sai lệch so với thực tế.

**Việc CHƯA xác nhận, cố tình để ngỏ:** `/users/info` có dùng chung envelope `{data: ...}` này
không? Chưa có bằng chứng thật (chưa capture response `/users/info` thật) nên `UserRepositoryImpl`
giữ nguyên cách decode cũ (top-level trực tiếp) — đúng nguyên tắc CLAUDE.md "không đoán field khi
chưa có xác nhận", dù rất có khả năng nó cũng theo cùng convention.

---

## 16. Xác nhận 2 lần độc lập → nâng "best guess" thành "convention chung", và generic wrapper tránh lặp code

Sau khi login thành công (mục 15), gọi tiếp `fetchUserInfo()` vẫn lỗi y hệt — dù response trả về
`200` với dữ liệu đầy đủ, hợp lệ:

```json
{"status": 1, "msg": "Get info Success.", "data": {"id": 14915, "id_encode": 2079435752, ...}}
```

`UserRepositoryImpl.fetchUserInfo()` lúc đó vẫn decode `UserDTO` **trực tiếp** ở top-level (giả
định gốc từ Sprint 3, đã bị chính mục 15 nghi ngờ nhưng chưa sửa vì thiếu bằng chứng). Giờ có
response thật thứ 2 — xác nhận **cùng envelope `{status, msg, data}`** như `/users/login`.

**Bài học về mức độ tin cậy:** 1 lần xác nhận thật = sửa đúng chỗ đó, nhưng vẫn ghi rõ "chưa chắc
áp dụng chỗ khác" (đúng tinh thần CLAUDE.md — không lan rộng một guess). **2 lần xác nhận độc lập,
cùng domain, cùng backend** = đủ tự tin nâng cấp từ "guess riêng lẻ" thành "convention chung" của
cả API — lúc này việc áp dụng suy luận đó sang các endpoint anh em cùng domain (`changeUserInfo`,
`changeUserProfile`) là hợp lý, miễn là **ghi rõ ràng** endpoint nào đã có bằng chứng thật, endpoint
nào chỉ suy luận theo (để người sau biết đâu là sự thật đã kiểm chứng, đâu là suy luận hợp lý chưa
test).

**Tránh lặp code khi pattern lặp lại ≥ 3 lần:** thay vì copy-paste `try JSONDecoder().decode(...).data`
ở cả 3 hàm (`fetchUserInfo`, `changeUserInfo`, `changeUserProfile`), tạo 1 generic wrapper dùng
chung:

```swift
struct DataResponseDTO<T: Decodable>: Decodable {
    let data: T
}

// Dùng lại ở bất kỳ đâu cần unwrap "data"
try JSONDecoder().decode(DataResponseDTO<UserDTO>.self, from: data).data.toDomain()
```

Đây **không phải** abstraction "phòng hờ tương lai" (thứ nên tránh) — đây là DRY hoá 1 pattern
**đã lặp lại thật, 3 lần, ngay bây giờ**, với bằng chứng cụ thể, không phải đoán trước nhu cầu.

---

## 17. Validate field (email/username) đúng chuẩn Clean Architecture — rule thuần ở Domain, enforce ở 2 nơi, text hiển thị tách riêng, tái dùng qua 1 component

Câu hỏi ban đầu: validate email/username "đúng chuẩn" nghĩa là gì trong kiến trúc 4 tầng của
project? Trả lời qua 4 quyết định gắn chặt với nhau, không tách rời được:

**a) Rule thuần (không I/O) → sống ở Domain, KHÔNG cần `@Dependency`:**

```swift
// Domain/Auth/Validation/AuthFieldValidator.swift
enum AuthValidationError: Error, Equatable {
    case emptyEmail
    case invalidEmailFormat
}

enum AuthFieldValidator {
    static func validateEmail(_ email: String) -> AuthValidationError? { ... }
}
```
Khác với `AuthRepository` (protocol + `DependencyKey`, vì cần swap real/mock) — validate không bao
giờ cần "bản giả", input/output luôn cố định theo cùng 1 rule, nên chỉ cần `enum` namespace tĩnh,
không DI, không giữ state.

**b) Enforce ở CẢ UseCase lẫn ViewModel — không phải chỉ 1 nơi:**

```swift
// Domain/Auth/UseCases/LoginUseCase.swift — enforcement thật, độc lập Presentation nào gọi vào
func callAsFunction(email: String, password: String) async throws -> AuthSession {
    if let error = AuthFieldValidator.validateEmail(email) { throw error }
    return try await repository.login(email: email, password: password)
}
```
Nếu chỉ validate ở ViewModel, một caller khác (unit test gọi thẳng UseCase, hay một Presentation
khác sau này) sẽ lọt qua rule hoàn toàn. Validate ở ViewModel (gọi lại đúng hàm này) chỉ để có phản
hồi UI tức thời khi gõ — không phải nơi thực sự đảm bảo tính đúng đắn.

**c) Domain error chỉ giữ định danh (case), KHÔNG giữ text hiển thị:**

```swift
// Features/Auth/AuthValidationError+Localized.swift — Presentation, không phải Domain
extension AuthValidationError {
    var localizedMessage: String {
        switch self {
        case .emptyEmail: String(localized: "auth.error.emptyEmail", defaultValue: "Vui lòng nhập email")
        case .invalidEmailFormat: String(localized: "auth.error.invalidEmailFormat", defaultValue: "Email không đúng định dạng")
        }
    }
}
```
Domain không biết người dùng đang xem ngôn ngữ nào — đó là việc của Presentation (String Catalog
`.xcstrings`, tự động qua `String(localized:defaultValue:)`). Có cân nhắc nhưng **quyết định không
làm**: đổi `email: String` thành Value Object (`EmailAddress` với `init(_:) throws`) — bị loại vì
SwiftUI `TextField` bắt buộc bind tới một `String` sống trong lúc gõ dở (chưa hợp lệ), và đổi kiểu
sẽ kéo theo sửa `User` Entity + DTO khắp Data layer chỉ để giải quyết vấn đề đang ở quy mô 2-3 form.

**d) Scale lên nhiều field mà không nhân đôi property — gộp `value` + `error` làm một, tái dùng qua
1 component:**

```swift
// Features/Shared/ValidatedField.swift
struct ValidatedField<Value: Equatable>: Equatable {
    var value: Value
    var error: String?
}
```
```swift
// Features/Shared/ValidatedTextField.swift — validator là closure trả String? (đã dịch sẵn)
ValidatedTextField(title: "Email", field: $viewModel.email) { value in
    AuthFieldValidator.validateEmail(value)?.localizedMessage
}
.keyboardType(.emailAddress)   // vẫn "xuyên" xuống TextField bên trong component
```
`.keyboardType`/`.disabled`/`.autocorrectionDisabled` đặt trên `ValidatedTextField` (custom View)
vẫn tới được `TextField` lồng bên trong — vì các modifier này set **environment value**, thứ tự
động lan xuống mọi view con trong `body`, không gắn riêng với chính view bị gọi trực tiếp.

**Bài học:** một validate "đúng chuẩn" không nằm gọn trong 1 file — nó là sự **phân công đúng vai
trò cho từng tầng**: Domain giữ *luật* (thuần, không phụ thuộc gì), UseCase *thực thi luật* (bất kể
ai gọi vào), Presentation giữ *cách hiển thị* (ngôn ngữ, phản hồi UI) và *tái sử dụng* (1 component
chung khi số field tăng lên). Không tầng nào được ôm việc của tầng khác — kể cả khi gộp lại "cho
gọn" có vẻ tiện hơn trong ngắn hạn.

---

## Bảng tổng hợp nhanh

| Khái niệm | File tham chiếu |
|---|---|
| DataSource gộp vào RepositoryImpl khi chỉ có 1 nguồn dữ liệu | `docs/architecture.md` (Network/Firebase/Ably convention) |
| Lỗi ẩn trong response 200 được bắt ở Core, không phải Data | `Core/NetworkClient.swift` (`containsInvalidTokenMessage`) |
| `@Observable` + `@Dependency` xung đột — inject qua constructor | `Features/Auth/ViewModel/LoginViewModel.swift`, `Features/Auth/View/LoginView.swift` |
| ViewModel nên phụ thuộc UseCase, không phải Repository | `Features/Auth/ViewModel/LoginViewModel.swift` (composition ở `LoginView.onAppear`) |
| Swift Testing (`Testing`/`@Test`/`#expect`), không phải `XCTest` | `studiopTests/Auth/LoginViewModelTests.swift` |
| `@ObservationIgnored` chỉ cần cho `var`, không cần cho `let` | `Features/Auth/ViewModel/LoginViewModel.swift` |
| `@MainActor` đảm bảo resume sau `await` vẫn ở main thread | `Features/Auth/ViewModel/LoginViewModel.swift`, `Features/AppState.swift` |
| `@Bindable` cần khi KHÔNG có sẵn `$` (không phải `@State`/`@Binding`); thừa nếu đã có | `Features/Auth/View/LoginView.swift` |
| `body` chạy trước `.onAppear`/`.task`; né Optional bằng `init` + `_property = State(initialValue:)` | `Features/Auth/View/LoginView.swift` |
| `@State`/property nội bộ nên `private`; `private` không cản trở `init` cùng type | `Features/Auth/View/LoginView.swift` |
| `@Environment` tránh prop drilling, nhưng không đọc được trong `init` | `studiopApp.swift` (`RootView`) |
| Property wrapper sinh 3 thứ: `x` (wrappedValue), `$x` (projectedValue), `_x` (wrapper instance) | `Features/Auth/View/LoginView.swift` (`_viewModel`) |
| Local env không push git — `#filePath` + file gitignore, không sửa `.pbxproj` | `Core/AppEnvironment.swift` (`local-environment.json`) |
| Thiếu `Content-Type: application/json` khiến backend parse sai JSON body — so sánh request thật để debug | `Core/NetworkClient.swift` |
| `DecodingError.keyNotFound` do sai wrapper key; backend báo lỗi qua `status/msg` trên HTTP 200, không qua status code | `Data/Auth/DTOs/AuthSessionResponseDTO.swift`, `Core/NetworkClient.swift` |
| 2 lần xác nhận độc lập → nâng "guess" thành convention chung; generic `DataResponseDTO<T>` tránh lặp code | `Data/Auth/DTOs/DataResponseDTO.swift`, `UserRepositoryImpl.swift` |
| Validate field: Domain giữ rule thuần + định danh lỗi; enforce ở cả UseCase lẫn ViewModel; text hiển thị + tái dùng (`ValidatedField`/`ValidatedTextField`) thuộc Presentation | `Domain/Auth/Validation/AuthFieldValidator.swift`, `Features/Auth/AuthValidationError+Localized.swift`, `Features/Shared/ValidatedField.swift`, `Features/Shared/ValidatedTextField.swift` |
