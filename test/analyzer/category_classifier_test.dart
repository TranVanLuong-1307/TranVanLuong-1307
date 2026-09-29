import 'package:flutter_test/flutter_test.dart';
import 'package:notification_insight/core/enums/notification_category.dart';
import 'package:notification_insight/models/notification_data.dart';
import 'package:notification_insight/services/analyzer/category_classifier.dart';

void main() {
  group('CategoryClassifier Tests', () {
    late CategoryClassifier classifier;

    setUp(() {
      classifier = CategoryClassifier();
    });

    test('should classify as FINANCE when content has currency or payment keywords', () {
      const data = NotificationData(
        packageName: 'com.momo',
        title: 'Nhận tiền',
        content: 'Bạn nhận được 200.000đ từ Nguyễn Văn A',
        timestamp: 1000,
      );
      final result = classifier.classify(data);
      expect(result, NotificationCategory.finance);
    });

    test('should classify as DELIVERY when content has delivery status keywords', () {
      const data = NotificationData(
        packageName: 'com.delivery.app',
        title: 'ShopeeFood',
        content: 'Đơn hàng đang được giao tới bạn',
        timestamp: 1000,
      );
      final result = classifier.classify(data);
      expect(result, NotificationCategory.delivery);
    });

    test('should classify as EMAIL when package or content is email related', () {
      const data = NotificationData(
        packageName: 'com.google.android.gm',
        title: 'Gmail',
        content: 'Bạn nhận được email mới từ đối tác',
        timestamp: 1000,
      );
      final result = classifier.classify(data);
      expect(result, NotificationCategory.email);
    });

    test('should classify as SECURITY when OTP is present', () {
      const data = NotificationData(
        packageName: 'com.bank.service',
        title: 'Xác thực',
        content: 'Mã OTP của bạn là 849201. Không chia sẻ mã này.',
        timestamp: 1000,
      );
      final result = classifier.classify(data);
      expect(result, NotificationCategory.security);
    });

    test('should classify as MESSAGING when chat/message keywords or apps are present', () {
      const data = NotificationData(
        packageName: 'com.zing.zalo',
        title: 'Zalo',
        content: 'Nguyễn Văn A đã gửi tin nhắn cho bạn',
        timestamp: 1000,
      );
      final result = classifier.classify(data);
      expect(result, NotificationCategory.messaging);
    });

    test('should fallback to OTHER when no keywords or known package matched', () {
      const data = NotificationData(
        packageName: 'com.random.unrecognized.app',
        title: 'Hello',
        content: 'Lorem ipsum dolor sit amet',
        timestamp: 1000,
      );
      final result = classifier.classify(data);
      expect(result, NotificationCategory.other);
    });
  });
}
