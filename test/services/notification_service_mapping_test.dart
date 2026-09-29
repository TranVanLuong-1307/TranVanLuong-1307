import 'package:flutter_test/flutter_test.dart';
import 'package:notification_insight/core/utils/app_name_resolver.dart';
import 'package:notification_insight/models/notification_data.dart';
import 'package:notification_insight/services/analyzer/notification_analyzer.dart';

void main() {
  group('Notification Event Mapping & Edge Cases Tests', () {
    late NotificationAnalyzer analyzer;

    setUp(() {
      analyzer = NotificationAnalyzer();
    });

    test('should resolve readable app name for known packages without guessing', () {
      expect(AppNameResolver.resolve('com.google.android.gm'), 'Gmail');
      expect(AppNameResolver.resolve('com.zing.zalo'), 'Zalo');
      expect(AppNameResolver.resolve('com.facebook.orca'), 'Messenger');
      expect(AppNameResolver.resolve('com.vcb.digibank'), 'VCB Digibank');
      expect(AppNameResolver.resolve('com.shopee.vn'), 'Shopee');
      expect(AppNameResolver.resolve('com.grabtaxi.passenger'), 'Grab');
    });

    test('should fallback safely for unknown or null package names', () {
      expect(AppNameResolver.resolve(null), 'Ứng dụng không xác định');
      expect(AppNameResolver.resolve(''), 'Ứng dụng không xác định');
      expect(AppNameResolver.resolve('com.custom.app'), 'App');
    });

    test('should handle null title gracefully when content is present', () {
      const data = NotificationData(
        packageName: 'com.zing.zalo',
        title: null,
        content: 'Bạn có một tin nhắn mới từ Lan',
        timestamp: 1712049200000,
      );

      final record = analyzer.process(data);
      expect(record, isNotNull);
      expect(record!.title, isNull);
      expect(record.content, 'Bạn có một tin nhắn mới từ Lan');
      expect(record.appName, 'Zalo');
    });

    test('should handle null content gracefully when title is present', () {
      const data = NotificationData(
        packageName: 'com.shopee.vn',
        title: 'Đơn hàng đang giao',
        content: null,
        timestamp: 1712049200000,
      );

      final record = analyzer.process(data);
      expect(record, isNotNull);
      expect(record!.title, 'Đơn hàng đang giao');
      expect(record.content, isNull);
      expect(record.appName, 'Shopee');
    });

    test('should preserve Unicode Vietnamese characters accurately', () {
      const complexText = 'Số dư tài khoản 123456789 thay đổi: +1.500.000đ. Cảm ơn quý khách đã sử dụng dịch vụ!';
      const data = NotificationData(
        packageName: 'com.vcb.digibank',
        title: 'Biến động số dư',
        content: complexText,
        timestamp: 1712049200000,
      );

      final record = analyzer.process(data);
      expect(record, isNotNull);
      expect(record!.content, complexText);
    });
  });
}
