# Ghi chú học tập — Sprint 7 (Store/Catalog, Cart/Checkout)

Tài liệu tổng hợp các kiến thức Swift/iOS **mới** học được khi triển khai Store/Catalog +
Cart/Checkout (F-017 → F-022) và senior-skill add-on (so sánh tải ảnh GCD vs TaskGroup/actor). Nối
tiếp [docs/learning-notes-sprint-006.md](learning-notes-sprint-006.md) — không lặp lại kiến thức
đã học ở đó (đặc biệt `@MainActor`/`nonisolated`, Keychain, protocol abstraction để test).

---

## 1. `DispatchSemaphore`-gated GCD vs `TaskGroup`/actor — cùng một bài toán, hai cách giải hoàn toàn khác tư duy

`Core/GCDImageDownloader.swift` (chỉ để so sánh, không ship) vs `Core/ImageLoading.swift`'s
`ImageCache` (bản ship thật) — cùng giải bài "tải N ảnh đồng thời, giới hạn số lượng cùng lúc":

```swift
// GCD: chặn (block) một luồng nền bằng semaphore.wait(), cần DispatchGroup riêng để biết khi nào xong
semaphore.wait()
queue.async {
    defer { semaphore.signal(); group.leave() }
    let data = try? Data(contentsOf: url)   // đồng bộ, tự chặn luồng
}
group.wait()

// async/await: không chặn luồng nào cả (suspend thay vì block), TaskGroup tự biết khi nào xong
await withTaskGroup(of: Void.self) { group in
    for url in urls { group.addTask { _ = try? await self.image(for: url) } }
}   // return tự động khi mọi child task xong -- không cần primitive đếm riêng
```

**Bài học:** `DispatchSemaphore.wait()` thực sự **chặn (block)** luồng gọi nó — đây là lý do GCD
version bắt buộc chạy trên hàng đợi nền (`queue`), không bao giờ được gọi trên main thread.
`async/await` **không chặn** luồng nào — nó *suspend* (tạm dừng), nhường luồng cho việc khác, rồi
resume khi sẵn sàng. Đây là khác biệt cốt lõi, không chỉ là "cú pháp mới cho cùng một cơ chế cũ".

---

## 2. `actor` khử trùng lặp request đang chạy — không chỉ là "cache có khoá"

```swift
actor ImageCache {
    private var cache: [URL: UIImage] = [:]
    private var inFlightTasks: [URL: Task<UIImage, Error>] = [:]

    func image(for url: URL) async throws -> UIImage {
        if let cached = cache[url] { return cached }
        if let existingTask = inFlightTasks[url] { return try await existingTask.value }  // <-- điểm hay
        let task = Task<UIImage, Error> { /* download */ }
        inFlightTasks[url] = task
        ...
    }
}
```

Nếu 2 nơi trong app (ví dụ Storefront grid và Product detail carousel) cùng lúc xin tải **cùng một
URL** trước khi cache có sẵn, không có `inFlightTasks` thì cả hai sẽ tự tải riêng — lãng phí băng
thông, và có thể ra 2 lần network y hệt nhau. Lưu **chính cái `Task` đang chạy** (không chỉ kết quả
cuối) cho phép lệnh gọi thứ hai `await` lên cùng `Task` đó thay vì tự tạo request mới.

**Bài học:** với một cache dùng chung nhiều nơi gọi đồng thời, khử trùng lặp không chỉ là "kiểm tra
cache có sẵn chưa" — còn phải kiểm tra "có request nào **đang chạy dở** cho key này không", vì cache
"đã có" và cache "đang được lấy" là hai trạng thái khác nhau. `actor` làm việc này an toàn tự nhiên
vì mọi truy cập vào `inFlightTasks`/`cache` đều tuần tự hoá.

---

## 3. Không phải mọi backend endpoint cùng domain đều cùng một cách encode body

`docs/api-reference.md` ghi rõ `/stores/checkout/{create,get,process}` nhận **FormData**, trong khi
mọi endpoint khác của cùng backend (kể cả các endpoint khác trong `StoreRepository`) đều JSON.
`NetworkRequest`/`NetworkClient` (Core, xây từ Sprint 1) trước đó **hardcode** luôn
`Content-Type: application/json` cho mọi request có body — phải mở rộng thêm một field
`bodyEncoding` để phản ánh đúng sự khác biệt này:

```swift
enum BodyEncoding: Equatable { case json, formURLEncoded }
var bodyEncoding: BodyEncoding = .json   // mặc định giữ nguyên hành vi cũ, additive
```

**Bài học:** đừng giả định "cùng 1 backend thì mọi endpoint đều encode giống nhau" chỉ vì phần lớn
đã như vậy — tài liệu ghi rõ ngoại lệ thì phải tôn trọng ngoại lệ đó, kể cả khi nó buộc phải mở rộng
một phần Core đã ổn định từ 6 sprint trước. Mở rộng kiểu additive (giá trị mặc định giữ nguyên hành
vi cũ) là cách an toàn để làm việc này mà không phá vỡ mọi call site đang có.

---

## 4. `navigationDestination(item:)` đòi `Hashable`, không chỉ `Identifiable`

```swift
.navigationDestination(item: $checkoutSession) { session in
    CheckoutView(session: session)
}
// error: 'CheckoutSession' phải conform 'Hashable'
```

`CheckoutSession` trước đó chỉ có `Equatable, Identifiable, Sendable` — tưởng vậy là đủ cho
`item:` (vì logic thì chỉ cần biết "có giá trị hay không" để quyết định push màn hình), nhưng API
thật của SwiftUI đòi `Hashable` (để nó tự quản lý danh tính trong navigation stack nội bộ).

**Bài học:** khi một API SwiftUI có nhiều overload gần giống nhau (`navigationDestination(isPresented:)`
vs `navigationDestination(item:)`), đừng đoán protocol yêu cầu dựa theo suy luận logic — cứ thử biên
dịch, để compiler chỉ đúng constraint còn thiếu, rồi thêm conformance đó (thường chỉ là thêm 1 từ
khoá vào danh sách protocol, không đổi hành vi gì khác).

---

## 5. Domain (kiến trúc) và Feature (trải nghiệm người dùng) không phải lúc nào cũng cùng một ranh giới

`StudioRepository` (protocol) nằm ở `Domain/Live/` — vì "Studio" gắn với domain live-streaming
trong thiết kế Sprint 2 (16 domain dịch thẳng từ `docs/api-reference.md`). Nhưng tính năng người
dùng thấy được (F-020, "theo dõi shop yêu thích") lại thuộc nhóm **Store/Catalog** theo
`docs/features.md` — nên Presentation của nó nằm ở `Features/Commerce/Favorites/`, không phải
`Features/Live/`.

**Bài học:** ranh giới Domain (theo cấu trúc API/nghiệp vụ backend) và ranh giới Feature/Presentation
(theo cách người dùng trải nghiệm màn hình) **không bắt buộc phải trùng nhau** — một tính năng hoàn
toàn có thể "vay mượn" Repository từ một domain khác. Đây không phải lỗi kiến trúc, chỉ là một điểm
cần ghi chú lại (như dev_report đã làm) để người đọc sau không ngạc nhiên khi thấy import chéo
domain.

---

## 6. Debounce tìm kiếm bằng `Task` + `Task.sleep` + huỷ `Task` cũ — không cần `Combine`

```swift
private var autocompleteTask: Task<Void, Never>?

private func scheduleAutocomplete() {
    autocompleteTask?.cancel()                        // huỷ lần gõ phím trước
    let currentQuery = query
    autocompleteTask = Task {
        try? await Task.sleep(nanoseconds: 300_000_000)   // đợi 300ms
        guard !Task.isCancelled else { return }           // nếu bị huỷ (gõ tiếp) thì dừng, không search
        await runSearch(currentQuery)
    }
}
```

**Bài học:** debounce theo kiểu Combine (`.debounce(for:scheduler:)`) không phải cách duy nhất —
với Swift Concurrency thuần, "huỷ Task cũ mỗi lần có sự kiện mới, Task mới tự chờ rồi tự kiểm tra
`Task.isCancelled`" đạt cùng hiệu quả mà không cần thêm dependency Combine, và dễ đọc tuyến tính hơn
so với chuỗi operator.

---

## Bảng tổng hợp nhanh

| Khái niệm | File tham chiếu |
|---|---|
| `DispatchSemaphore` (block luồng) vs `async/await` (suspend, không block) cho cùng bài toán tải ảnh đồng thời | `studiop/Core/GCDImageDownloader.swift`, `studiop/Core/ImageLoading.swift` |
| `actor` khử trùng lặp request đang chạy bằng cách lưu chính `Task`, không chỉ kết quả | `studiop/Core/ImageLoading.swift` (`inFlightTasks`) |
| Mở rộng `NetworkRequest` thêm `bodyEncoding` vì không phải mọi endpoint cùng backend đều JSON | `studiop/Core/NetworkRequest.swift`, `studiop/Core/NetworkClient.swift` |
| `navigationDestination(item:)` đòi `Hashable`, không chỉ `Identifiable` | `studiop/Domain/Commerce/Entities/CheckoutSession.swift` |
| Ranh giới Domain (theo backend) và ranh giới Feature (theo UX) có thể lệch nhau, đó không phải lỗi | `studiop/Domain/Live/Repositories/StudioRepository.swift`, `studiop/Features/Commerce/Favorites/` |
| Debounce bằng huỷ `Task` cũ + `Task.sleep` + `Task.isCancelled`, không cần Combine | `studiop/Features/Commerce/Search/SearchViewModel.swift` |
