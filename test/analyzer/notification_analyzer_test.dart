import 'package:flutter_test/flutter_test.dart';
import 'package:notification_insight/core/enums/notification_category.dart';
import 'package:notification_insight/core/enums/notification_priority.dart';
import 'package:notification_insight/models/notification_data.dart';
import 'package:notification_insight/services/analyzer/notification_analyzer.dart';

void main() {
  group('NotificationAnalyzer Pipeline Tests', () {
    late NotificationAnalyzer analyzer;

    setUp(() {
      analyzer = NotificationAnalyzer();
    });

    test('should return null when notification data is empty', () {
      const emptyData = NotificationData(
        packageName: 'com.test',
        title: '',
        content: null,
        timestamp: 1000,
      );
      final record = analyzer.process(emptyData);
      expect(record, isNull);
    });

    test('should process financial notification into NotificationRecord with high priority', () {
      const financeData = NotificationData(
        packageName: 'com.vcb.digibank',
        title: 'Biến động số dư',
        content: 'Bạn nhận được 200.000đ từ NGUYEN VAN A',
        timestamp: 1712049200000,
      );

      final record = analyzer.process(financeData);

      expect(record, isNotNull);
      expect(record!.category, NotificationCategory.finance);
      expect(record.priority, NotificationPriority.high);
      expect(record.packageName, 'com.vcb.digibank');
      expect(record.title, 'Biến động số dư');
      expect(record.content, 'Bạn nhận được 200.000đ từ NGUYEN VAN A');
    });

    test('should process security notification with urgent priority', () {
      const securityData = NotificationData(
        packageName: 'com.auth.app',
        title: 'Bảo mật',
        content: 'Mã xác thực của bạn là 123456',
        timestamp: 1712049200000,
      );

      final record = analyzer.process(securityData);

      expect(record, isNotNull);
      expect(record!.category, NotificationCategory.security);
      expect(record.priority, NotificationPriority.urgent);
    });
  });
}
