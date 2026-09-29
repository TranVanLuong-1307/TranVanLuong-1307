enum SimulatorCategoryType {
  messaging('Tin nhắn (Messaging)'),
  email('Email'),
  finance('Tài chính (Finance)'),
  shopping('Mua sắm (Shopping)'),
  delivery('Giao vận (Delivery)'),
  security('Bảo mật (Security)'),
  system('Hệ thống (System)'),
  generic('Thông thường (Generic)');

  final String displayName;
  const SimulatorCategoryType(this.displayName);
}

class TestScenario {
  final String id;
  final String name;
  final String description;
  final String defaultTitle;
  final String defaultContent;
  final SimulatorCategoryType categoryType;

  const TestScenario({
    required this.id,
    required this.name,
    required this.description,
    required this.defaultTitle,
    required this.defaultContent,
    required this.categoryType,
  });

  static const List<TestScenario> predefinedScenarios = [
    // 1. Normal notification
    TestScenario(
      id: 'sc_normal',
      name: '1. Normal Notification',
      description: 'Thông báo bình thường từ ứng dụng tin nhắn với nội dung ngắn gọn',
      defaultTitle: 'Nguyễn Văn Nam',
      defaultContent: 'Hôm nay mấy giờ chúng ta gặp nhau ở quán cafe?',
      categoryType: SimulatorCategoryType.messaging,
    ),

    // 2. Long title
    TestScenario(
      id: 'sc_long_title',
      name: '2. Long Title',
      description: 'Tiêu đề rất dài vượt quá độ rộng chuẩn của Notification Drawer',
      defaultTitle: 'THÔNG BÁO QUAN TRỌNG VỀ VIỆC CẬP NHẬT HỆ THỐNG GIAO DỊCH TÀI CHÍNH TOÀN QUỐC NĂM 2026',
      defaultContent: 'Hệ thống sẽ tạm dừng để bảo trì định kỳ từ 0h00 đến 4h00 sáng mai.',
      categoryType: SimulatorCategoryType.system,
    ),

    // 3. Long content
    TestScenario(
      id: 'sc_long_content',
      name: '3. Long Content',
      description: 'Nội dung thông báo dài nhiều dòng thử thách tính năng mở rộng BigTextStyle',
      defaultTitle: 'Chi tiết biên lai mua sắm',
      defaultContent: 'Đơn hàng #SPX891011 đã được thanh toán 1.250.000đ. '
          'Danh sách sản phẩm gồm 3 món: Tai nghe không dây Bluetooth, Cáp sạc nhanh Type-C 65W, Ốp lưng silicon. '
          'Dự kiến giao hàng vào ngày mai. Vui lòng giữ máy để nhân viên giao hàng liên hệ khi tới địa chỉ.',
      categoryType: SimulatorCategoryType.shopping,
    ),

    // 4. Unicode & Emoji
    TestScenario(
      id: 'sc_unicode',
      name: '4. Unicode & Emoji',
      description: 'Ký tự Unicode phức tạp, ký hiệu biểu tượng cảm xúc và icon đặc biệt',
      defaultTitle: '🎉 Chúc mừng sinh nhật! 🎂✨',
      defaultContent: 'Nhận ngay voucher ưu đãi 50% 🎁 dành riêng cho bạn hôm nay! 🔥 Mã: HAPPY2026',
      categoryType: SimulatorCategoryType.generic,
    ),

    // 5. Vietnamese Accented
    TestScenario(
      id: 'sc_vietnamese',
      name: '5. Tiếng Việt đầy đủ dấu',
      description: 'Chuỗi tiếng Việt phức tạp với nhiều phụ âm và dấu thanh tiếng Việt',
      defaultTitle: 'Biến động số dư tài khoản',
      defaultContent: 'Tài khoản 0123456789 tại VCB vừa được cộng +5.500.000đ. Số dư hiện tại: 18.250.000 VND. Nội dung: Chuyển tiền lương tháng.',
      categoryType: SimulatorCategoryType.finance,
    ),

    // 6. Empty Title
    TestScenario(
      id: 'sc_empty_title',
      name: '6. Empty Title',
      description: 'Tiêu đề rỗng/null, chỉ có phần nội dung thông báo',
      defaultTitle: '',
      defaultContent: 'Shipper đã lấy hàng thành công và đang trên đường giao tới bạn.',
      categoryType: SimulatorCategoryType.delivery,
    ),

    // 7. Empty Content
    TestScenario(
      id: 'sc_empty_content',
      name: '7. Empty Content',
      description: 'Nội dung rỗng/null, chỉ có phần tiêu đề thông báo',
      defaultTitle: 'Bạn có một cuộc gọi nhỡ từ số 0987654321',
      defaultContent: '',
      categoryType: SimulatorCategoryType.generic,
    ),

    // 8. Generic / System Alert
    TestScenario(
      id: 'sc_generic_security',
      name: '8. Security & OTP',
      description: 'Cảnh báo bảo mật khẩn cấp và mã OTP gửi tới người dùng',
      defaultTitle: 'Mã xác thực tài khoản',
      defaultContent: 'Mã OTP của bạn là 839210. Tuyệt đối không chia sẻ mã này cho bất kỳ ai kể cả nhân viên ngân hàng.',
      categoryType: SimulatorCategoryType.security,
    ),

    // 9. Repeated Notification
    TestScenario(
      id: 'sc_repeated',
      name: '9. Repeated Notifications',
      description: 'Kịch bản gửi 2 thông báo có nội dung giống hệt nhau để kiểm tra bộ lọc duplicate',
      defaultTitle: 'Shopee Thông Báo',
      defaultContent: 'Flash sale 12h sắp bắt đầu! Hàng ngàn mã giảm giá 50k đang chờ bạn.',
      categoryType: SimulatorCategoryType.shopping,
    ),

    // 10. Rapid Multiple Notifications
    TestScenario(
      id: 'sc_rapid_multiple',
      name: '10. Multiple Rapid Notifications',
      description: 'Gửi 5 thông báo liên tiếp với tốc độ cao để kiểm tra độ ổn định của pipeline',
      defaultTitle: 'Tin nhắn nhóm công việc',
      defaultContent: 'Cập nhật tiến độ dự án Notification Insight sprint 2',
      categoryType: SimulatorCategoryType.messaging,
    ),
  ];
}
