# KẾ HOẠCH & DÀN Ý SLIDE THUYẾT TRÌNH ĐỒ ÁN
## ĐỀ TÀI: NOTIFICATION INSIGHT (ỨNG DỤNG QUẢN LÝ VÀ PHÂN TÍCH THÔNG BÁO ANDROID)
**Trường:** Đại học Công nghệ TP.HCM (HUTECH)  
**Môn học:** Lập trình Di động (Mobile Programming)  
**Thời lượng:** 15 – 20 phút (Bao gồm Demo và Q&A)

---

## I. PHÂN BỔ THỜI GIAN (TỔNG: 15 - 20 PHÚT)

| Phần | Nội dung | Thời lượng dự kiến | Người trình bày (gợi ý) |
|---|---|---|---|
| **Phần 1** | Đặt vấn đề, Giới thiệu ứng dụng & Mục tiêu | 2 – 3 phút | Thành viên 1 |
| **Phần 2** | Công nghệ sử dụng & Kiến trúc hệ thống | 3 – 4 phút | Thành viên 2 |
| **Phần 3** | **LIVE DEMO ỨNG DỤNG** (Quan trọng nhất) | 7 – 8 phút | Cả nhóm phối hợp |
| **Phần 4** | Hướng dẫn cài đặt (Git + APK) & Đóng gói | 2 phút | Thành viên 2 |
| **Phần 5** | Kết luận, Hướng phát triển & Hỏi đáp (Q&A) | 2 – 3 phút | Cả nhóm |

---

## II. CHI TIẾT NỘI DUNG TỪNG SLIDE (14 SLIDES CHUẨN)

### SLIDE 1: TRANG BÌA (Title Slide)
- **Tiêu đề lớn:** NOTIFICATION INSIGHT
- **Phụ đề:** Ứng dụng Quản lý, Phân loại và Thống kê Thông báo Thông minh trên Android
- **Thông tin môn học:** Báo cáo Bài tập vận dụng môn Lập trình Di động
- **Thông tin nhóm:**
  - Giảng viên hướng dẫn: [Tên Thầy/Cô]
  - Danh sách thành viên: [Họ tên 1 - MSSV], [Họ tên 2 - MSSV]...
- **Hình ảnh:** Icon ứng dụng chuông vàng Notification Insight + Mockup app.

---

### SLIDE 2: ĐẶT VẤN ĐỀ (Problem Statement)
- **Nội dung trên slide:**
  - Người dùng smartphone nhận **hàng trăm thông báo mỗi ngày** (Zalo, Messenger, Ngân hàng, Shopee, Hệ thống...).
  - **Tình trạng:** "Quá tải thông báo" (Notification Overload), dễ bỏ sót thông báo quan trọng (OTP ngân hàng, đơn hàng, tin nhắn khẩn cấp).
  - Thanh thông báo mặc định của Android: Bị trôi nhanh, lỡ bấm "Xóa tất cả" là mất hoàn toàn lịch sử.
  - Không có thống kê chi tiết thói quen sử dụng và phân bổ nguồn tin.
- **Lời thoại gợi ý (Script):**  
  *"Kính thưa Thầy/Cô và các bạn, mỗi ngày điện thoại chúng ta nhận vô số thông báo từ đủ mọi ứng dụng. Đôi khi chỉ một cú quẹt vô tình là toàn bộ mã OTP hay thông báo chuyển khoản biến mất. Chính vì vậy, nhóm em xây dựng Notification Insight để làm 'hộp đen' lưu trữ và phân tích thông minh cho điện thoại."*

---

### SLIDE 3: MỤC TIÊU & GIẢI PHÁP (Solution & Objectives)
- **Nội dung trên slide:**
  - **Ghi nhận tự động:** Lắng nghe thông báo thời gian thực 24/7 từ mọi ứng dụng.
  - **Phân loại thông minh (Rule-Based):** Tự động chia nhóm (Tài chính, Tin nhắn, Mua sắm, Bảo mật/OTP, Mạng xã hội, Hệ thống...).
  - **Bảo mật tuyệt đối (100% On-Device):** Lưu trữ SQLite cục bộ, không gửi dữ liệu ra máy chủ bên ngoài, đảm bảo an toàn thông tin cá nhân.
  - **Trực quan hóa dữ liệu:** Dashboard thống kê trực quan theo biểu đồ thời gian thực.

---

### SLIDE 4: CÔNG NGHỆ CHÍNH SỬ DỤNG (Core Technologies)
*(Theo đúng yêu cầu slide trong ảnh HUTECH: Giới thiệu công nghệ chính nhóm làm)*
- **Nội dung trên slide:**
  - **Flutter Framework & Dart 3:** Xây dựng giao diện đa nền tảng mượt mà, hiệu năng 60 FPS.
  - **Android Native NotificationListenerService:** Bắt trọn vẹn thông báo từ hệ điều hành Android qua Event Channel.
  - **SQLite (`sqflite`):** Hệ quản trị cơ sở dữ liệu quan hệ cục bộ, lưu trữ bền vững với Repository & DAO Pattern.
  - **Provider:** Quản lý trạng thái (State Management) reactive, tách bạch UI và Business Logic.
  - **FL Chart:** Thư viện vẽ biểu đồ phân tích (Donut Chart phân bổ danh mục & Bar Chart thống kê 7 ngày).

---

### SLIDE 5: KIẾN TRÚC HỆ THỐNG & PIPELINE XỬ LÝ (Architecture)
- **Nội dung trên slide:** Sơ đồ luồng xử lý thông báo khép kín:
  ```
  Android OS Notification
    ⬇ [NotificationListenerService]
  NotificationData (Raw Model)
    ⬇ [NotificationFilter] (Lọc bỏ rác, sự kiện gỡ bỏ, spam sạc pin)
    ⬇ [CategoryClassifier & Analyzer] (Phân loại danh mục & trích xuất dữ liệu)
  NotificationRecord (Processed Model)
    ⬇ [Repository & DAO]
  SQLite Local Database
    ⬇ [NotificationProvider]
  UI (Dashboard, Danh sách, Biểu đồ thống kê)
  ```
- **Điểm nhấn công nghệ:** Luồng xử lý hoàn toàn bất đồng bộ (Asynchronous Streams), không gây đơ lag giao diện người dùng.

---

### SLIDE 6: TÍNH NĂNG CHÍNH 1 – BỘ LỌC & PHÂN LOẠI THÔNG MINH
- **Nội dung trên slide:**
  - **Notification Filter:** Tự động loại bỏ thông báo rỗng, thông báo hủy, thông báo trạng thái phần cứng (như sạc pin, gỡ lỗi USB, kết nối mạng) để tránh làm bẩn database.
  - **Rule-Based Classifier:** Phân tích nội dung không dùng AI nặng nề, tốc độ mili-giây:
    - *Bảo mật / OTP:* Tự động nhận diện và trích xuất mã xác thực 4–8 số.
    - *Tài chính:* Nhận diện biến động số dư, số tiền giao dịch (+/- VNĐ).
    - *Mua sắm & Giao hàng:* Trích xuất mã vận đơn, trạng thái giao nhận.
    - *Tin nhắn:* Tách tên người gửi và nội dung tin nhắn.

---

### SLIDE 7: TÍNH NĂNG CHÍNH 2 – DASHBOARD & TRỰC QUAN HÓA
- **Nội dung trên slide:**
  - **5 Chỉ số thống kê tức thì:** Tổng thông báo, Hôm nay, Chưa đọc, Yêu thích (Quan trọng), Số ứng dụng.
  - **Biểu đồ Donut (Category Chart):** Phân tích tỷ trọng các danh mục thông báo theo thời gian thực từ SQLite.
  - **Biểu đồ Cột (7-Day Trends):** Theo dõi tần suất nhận thông báo trong 7 ngày gần nhất.
  - Tự động cập nhật khi có thông báo mới mà không cần F5 / tải lại trang.

---

### SLIDE 8: CÁC TÍNH NĂNG MỞ RỘNG (Extra Features)
- **Nội dung trên slide:**
  - **Tìm kiếm & Bộ lọc nâng cao:** Lọc theo danh mục, trạng thái đọc/chưa đọc, mức độ ưu tiên (Khẩn cấp, Cao, Bình thường).
  - **Đánh dấu thông báo yêu thích (Favorites):** Lưu giữ các thông báo quan trọng.
  - **Quản lý ứng dụng theo dõi (Tracked Apps):** Bật/tắt theo dõi từng app riêng biệt.
  - **Công cụ Giả lập nội bộ (Notification Simulator):** Hỗ trợ test và demo các kịch bản bão thông báo (burst) trực tiếp ngay trong app.
  - **Xóa / Quản lý bộ nhớ:** Cho phép dọn dẹp dữ liệu để giải phóng dung lượng.

---

### SLIDE 9: CHUẨN BỊ DEMO TRỰC TIẾP (Live Demo Introduction)
- **Nội dung trên slide:**
  - Thiết bị demo: Smartphone Android thật kết nối chiếu màn hình.
  - Các kịch bản demo:
    1. Cấp quyền Notification Access & Xử lý bảo mật Android 13+.
    2. Nhận thông báo thật từ bên ngoài (Tin nhắn, OTP, Mua sắm).
    3. Kiểm tra Dashboard nhảy số và vẽ biểu đồ tự động.
    4. Trích xuất chi tiết dữ liệu (Mã OTP, Số tiền).
    5. Giả lập kịch bản bão thông báo bằng Simulator.

---

### SLIDE 10: TÀI LIỆU CÀI ĐẶT & MÃ NGUỒN (Git + Installation)
*(Theo đúng yêu cầu slide trong ảnh HUTECH: Tài liệu hướng dẫn cài đặt Git + Document)*
- **Nội dung trên slide:**
  - **Mã nguồn Git:** [Link Github Repository của nhóm]
  - **Yêu cầu môi trường:** Flutter SDK >= 3.12, Android Studio, Android SDK 24+.
  - **Lệnh chạy từ source code:**
    ```bash
    git clone <repo-url>
    cd App_notification
    flutter pub get
    flutter run
    ```
  - **File cài đặt sẵn (APK Release):** Cung cấp sẵn file `app-arm64-v8a-release.apk` (17.8MB) và `app-release.apk` (49.6MB) trong thư mục `build/app/outputs/flutter-apk/` hoặc link Google Drive.

---

### SLIDE 11: LƯU Ý KHI CÀI ĐẶT TRÊN ANDROID 13 / 14 / 15
- **Nội dung trên slide:**
  - Cơ chế **"Restricted Settings" (Cài đặt bị hạn chế)** của Android đối với quyền `NotificationListenerService`.
  - Hướng dẫn 3 bước mở khóa:
    1. *Cài đặt máy ➜ Ứng dụng ➜ Chọn Notification Insight.*
    2. *Bấm dấu 3 chấm góc phải ➜ Chọn "Cho phép cài đặt bị hạn chế".*
    3. *Mở app và bật quyền Notification Access.*
  - Minh chứng cho thấy nhóm nghiên cứu sâu về cơ chế bảo mật hệ điều hành Android.

---

### SLIDE 12: ĐÁNH GIÁ ĐỘ ỔN ĐỊNH & KIỂM THỬ (Testing & Stability)
- **Nội dung trên slide:**
  - **Unit & Integration Tests:** Đạt **69/69 test cases PASS 100%**.
  - **Static Analysis:** `flutter analyze: 0 issues`.
  - **Xử lý triệt để các Edge Cases:**
    - Lọc bỏ spam sạc pin / kết nối USB khi cắm sạc.
    - Chống tràn giao diện (Overflow safe) trên mọi kích thước màn hình.
    - Cơ chế chống trùng lặp thông báo (Deduplication within 3s window).

---

### SLIDE 13: KẾT LUẬN & HƯỚNG PHÁT TRIỂN
- **Nội dung trên slide:**
  - **Kết quả đạt được:** Hoàn thành trọn vẹn pipeline lắng nghe, phân loại và thống kê thông báo với hiệu năng cao, bảo mật 100% offline.
  - **Hướng mở rộng tương lai:**
    - Export dữ liệu thông báo ra file Excel / CSV.
    - Nhắc nhở thông minh dựa trên thông báo (Ví dụ: Nhắc lịch hẹn từ tin nhắn).
    - Sao lưu mã hóa cục bộ (Encrypted Local Backup).

---

### SLIDE 14: LỜI CẢM ƠN & HỎI ĐÁP (Q&A)
- **Nội dung trên slide:**
  - "Cảm ơn Thầy/Cô và các bạn đã chú ý lắng nghe!"
  - Q&A: Sẵn sàng nhận câu hỏi từ Giảng viên.

---

## III. KỊCH BẢN DEMO THỰC TẾ CHI TIẾT (7 – 8 PHÚT)

1. **Bước 1 (1 phút) - Khởi động & Cấp quyền:**
   - Mở app lần đầu, cho Thầy/Cô xem màn hình yêu cầu cấp quyền `Notification Access`.
   - Bấm nút cấp quyền, chuyển sang Cài đặt Android và bật công tắc cho Notification Insight.

2. **Bước 2 (2 phút) - Thử nghiệm thông báo thật:**
   - Dùng một máy khác gửi tin nhắn Zalo / SMS hoặc nhận một thông báo ngân hàng / Shopee.
   - Cho Thầy/Cô thấy ngay lập tức trên app xuất hiện thông báo, kèm theo nhãn phân loại (Ví dụ: Tag xanh dương cho Tin nhắn, Tag đỏ cho OTP).
   - Nhấn vào xem chi tiết: Cho thấy mã OTP đã được highlight riêng biệt hoặc số tiền giao dịch được tách ra rõ ràng.

3. **Bước 3 (2 phút) - Trực quan hóa Dashboard:**
   - Chuyển về màn hình **Dashboard**:
   - Chỉ vào các thẻ: Tổng thông báo, Hôm nay, Chưa đọc.
   - Chỉ vào biểu đồ tròn **Phân bố theo danh mục**: Biểu đồ tự tính toán tỷ lệ % từ SQLite thật, không hề hardcode.

4. **Bước 4 (2 phút) - Sử dụng công cụ Simulator nội bộ:**
   - Mở màn hình **Cài đặt** ➜ mở **Bộ giả lập (Simulator)**.
   - Bấm gửi kịch bản "Bão thông báo" (Burst test 10 thông báo liên tục).
   - Quay lại màn hình thông báo: Tất cả đều được tiếp nhận mượt mà, không bị crash, không bị lag giao diện.

5. **Bước 5 (1 phút) - Tính năng phụ trợ:**
   - Thử tìm kiếm thông báo bằng thanh Search Bar.
   - Thử đánh dấu Yêu thích (Favorite) một thông báo quan trọng.
