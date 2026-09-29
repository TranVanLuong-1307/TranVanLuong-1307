# 📱 NOTIFICATION INSIGHT
> **Đồ án môn học:** Lập trình Di động (Mobile Programming)  
> **Trường:** Đại học Công nghệ TP.HCM (HUTECH)  
> **Ứng dụng:** Quản lý, Phân loại và Thống kê Thông báo Thông minh trên Android  

---

## 👥 THÀNH VIÊN NHÓM
| STT | Họ và Tên | Mã số sinh viên (MSSV) | Vai trò / Nhiệm vụ |
|:---:|:---|:---:|:---|
| 1 | [Họ tên thành viên 1] | [MSSV 1] | Trưởng nhóm / Fullstack Pipeline |
| 2 | [Trần Văn Lượng ] | [2380601307] | Member | Database |

---

## 📖 GIỚI THIỆU ĐỀ TÀI
**Notification Insight** là ứng dụng Android giúp người dùng giải quyết bài toán "quá tải thông báo" (notification overload). Ứng dụng tự động lắng nghe, phân loại và lưu trữ lịch sử thông báo 100% cục bộ trên thiết bị (On-Device SQLite), đồng thời cung cấp Dashboard thống kê trực quan giúp người dùng theo dõi thói quen sử dụng điện thoại mà không lo lộ lọt dữ liệu riêng tư.

### 🌟 Tính năng nổi bật:
- 🔔 **Lắng nghe thông báo 24/7:** Bắt sự kiện thông báo thời gian thực qua `NotificationListenerService` của Android.
- 🧠 **Phân loại thông minh (Rule-Based):** Phân loại tự động 11 danh mục (Tài chính, OTP/Bảo mật, Tin nhắn, Mua sắm, Giao hàng, Mạng xã hội, Hệ thống...).
- 🔍 **Trích xuất dữ liệu tự động:** Bóc tách mã OTP 4–8 số, biến động số dư ngân hàng (+/- VNĐ), mã đơn hàng.
- 📊 **Thống kê trực quan (Dashboard):** Biểu đồ tròn Donut phân bố danh mục và biểu đồ cột tần suất nhận thông báo 7 ngày (sử dụng thư viện `fl_chart`).
- 🛡️ **Bảo mật tuyệt đối:** Hoàn toàn offline, không gửi dữ liệu ra máy chủ bên ngoài.
- 🧪 **Bộ giả lập tích hợp (Simulator):** Cho phép test các kịch bản nhận thông báo dồn dập (Burst test) ngay trong app.

---

## 🛠️ CÔNG NGHỆ CHÍNH (TECH STACK)
- **Framework:** Flutter SDK >= 3.12 (Dart 3)
- **Android Native:** `NotificationListenerService` (Java/Kotlin) giao tiếp với Flutter qua Event Channel
- **Cơ sở dữ liệu:** SQLite (`sqflite`) theo kiến trúc Repository & DAO Pattern
- **Quản lý trạng thái:** `Provider`
- **Biểu đồ:** `fl_chart`
- **Độ ổn định:** Đạt chuẩn `flutter analyze: 0 issues` và `flutter test: 69/69 passed`.

---

## 🚀 HƯỚNG DẪN CÀI ĐẶT & CHẠY ỨNG DỤNG (DOCUMENT)

### CÁCH 1: Chạy trực tiếp từ Mã nguồn Git (Dành cho Lập trình viên / Giảng viên)

#### 1. Yêu cầu môi trường (Prerequisites)
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (Khuyến nghị phiên bản >= 3.12.0)
- [Android Studio](https://developer.android.com/studio) với Android SDK Platform 34 hoặc 35
- Thiết bị thật Android (hoặc máy ảo Android Emulator) chạy Android 8.0 trở lên

#### 2. Các bước khởi chạy
```bash
# Bước 1: Clone mã nguồn từ GitHub
git clone https://github.com/[your-username]/App_notification.git

# Bước 2: Di chuyển vào thư mục dự án
cd App_notification

# Bước 3: Cài đặt các thư viện phụ thuộc
flutter pub get

# Bước 4: Kiểm tra tính toàn vẹn của mã nguồn (Tùy chọn)
flutter test

# Bước 5: Kết nối điện thoại và chạy ứng dụng
flutter run
```

---

### CÁCH 2: Cài đặt nhanh bằng File APK Release (Dành cho Người dùng cuối)

Nhóm đã đóng gói sẵn các file APK Release tại thư mục `build/app/outputs/flutter-apk/`:

1. **Tải file APK:**
   - **Bản tối ưu nhẹ nhất (17.8 MB - Khuyên dùng):** `app-arm64-v8a-release.apk` (Tương thích với 99% smartphone Android hiện nay).
   - **Bản đầy đủ (49.6 MB):** `app-release.apk` (Tương thích mọi kiến trúc chip).
2. **Cài đặt lên điện thoại:**
   - Chép file APK vào điện thoại (hoặc gửi qua Zalo/Drive).
   - Mở file trên điện thoại và chọn **Cài đặt** (Cho phép cài đặt từ nguồn này).

---

## ⚠️ HƯỚNG DẪN CẤP QUYỀN TRUY CẬP THÔNG BÁO (BẮT BUỘC)

Vì ứng dụng cần đọc thông báo để phân loại, bạn cần cấp quyền **Truy cập thông báo (Notification Access)**.

### 🔴 Lưu ý quan trọng trên Android 13, 14, 15:
Khi cài đặt file APK từ bên ngoài, Android kích hoạt cơ chế bảo mật **"Cài đặt bị hạn chế" (Restricted Settings)** khiến nút gạt cấp quyền bị mờ đi. Bạn hãy làm theo 3 bước sau để mở khóa:

1. Vào **Cài đặt (Settings)** điện thoại ➔ **Ứng dụng (Apps)**.
2. Tìm và chọn ứng dụng **Notification Insight**.
3. Bấm vào biểu tượng **dấu 3 chấm (⋮)** ở góc trên bên phải màn hình ➔ chọn **"Cho phép cài đặt bị hạn chế" (Allow restricted settings)** và xác nhận bằng vân tay/mã pin.
4. Mở lại ứng dụng **Notification Insight** và bật công tắc cấp quyền thông báo như bình thường.

---

## 🧪 KIỂM THỬ ĐỘ ỔN ĐỊNH (TESTING)
Dự án được viết bộ kiểm thử tự động toàn diện bao gồm:
- **Unit Tests:** Kiểm tra bộ phân loại `CategoryClassifier`, bộ lọc `NotificationFilter`, trích xuất OTP & số tiền.
- **Pipeline Tests:** Kiểm thử luồng dữ liệu khép kín từ Listener đến SQLite Database.
- **Stability & Edge Cases:** Kiểm thử chống trùng lặp thông báo, chống spam sạc pin và kiểm tra memory leak khi dispose.

Chạy lệnh kiểm thử:
```bash
flutter test
```
*Kết quả: 69/69 test cases Passed.*
