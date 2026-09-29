import 'package:flutter_test/flutter_test.dart';
import 'package:notification_insight/core/enums/notification_category.dart';
import 'package:notification_insight/core/enums/notification_priority.dart';
import 'package:notification_insight/models/notification_record.dart';

void main() {
  group('NotificationRecord Model Tests', () {
    test('toMap and fromMap should correctly serialize and deserialize', () {
      final now = DateTime.now().millisecondsSinceEpoch;
      final record = NotificationRecord(
        id: 1,
        packageName: 'com.vcb.digibank',
        appName: 'VCB Digibank',
        title: 'Biến động số dư',
        content: 'Số dư TK thay đổi +500.000 VND',
        category: NotificationCategory.finance,
        priority: NotificationPriority.high,
        timestamp: now,
        isRead: false,
        isFavorite: true,
        createdAt: now,
      );

      final map = record.toMap();
      final fromMap = NotificationRecord.fromMap(map);

      expect(fromMap.id, record.id);
      expect(fromMap.packageName, record.packageName);
      expect(fromMap.appName, record.appName);
      expect(fromMap.title, record.title);
      expect(fromMap.content, record.content);
      expect(fromMap.category, NotificationCategory.finance);
      expect(fromMap.priority, NotificationPriority.high);
      expect(fromMap.isFavorite, true);
      expect(fromMap.isRead, false);
      expect(fromMap.timestamp, record.timestamp);
    });

    test('copyWith should create modified instance without mutating original', () {
      const record = NotificationRecord(
        id: 1,
        packageName: 'com.zing.zalo',
        appName: 'Zalo',
        title: 'Tin nhắn mới',
        content: 'Alo bạn ơi',
        category: NotificationCategory.messaging,
        timestamp: 1000,
        createdAt: 1000,
      );

      final updated = record.copyWith(isFavorite: true, isRead: true);

      expect(record.isFavorite, false);
      expect(record.isRead, false);
      expect(updated.isFavorite, true);
      expect(updated.isRead, true);
      expect(updated.title, 'Tin nhắn mới');
    });

    test('fromMap should handle missing or null fields gracefully', () {
      final record = NotificationRecord.fromMap({});

      expect(record.packageName, '');
      expect(record.appName, 'Unknown App');
      expect(record.title, null);
      expect(record.content, null);
      expect(record.category, NotificationCategory.other);
      expect(record.priority, NotificationPriority.normal);
      expect(record.isRead, false);
      expect(record.isFavorite, false);
    });
  });
}
