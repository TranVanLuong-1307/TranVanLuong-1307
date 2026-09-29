import 'package:flutter_test/flutter_test.dart';
import 'package:notification_insight/models/notification_data.dart';
import 'package:notification_insight/services/notification/notification_filter.dart';

void main() {
  group('NotificationFilter Unit Tests', () {
    late NotificationFilter filter;

  setUp(() {
    filter = NotificationFilter();
  });

  test('should reject notification when tracking is disabled', () {
    const data = NotificationData(
      packageName: 'com.google.android.gm',
      title: 'Email mới',
      content: 'Chào bạn',
      timestamp: 1000,
    );

    final result = filter.evaluate(data, isTrackingEnabled: false);
    expect(result.isAccepted, false);
    expect(result.reason, contains('Tracking is disabled'));
    expect(filter.shouldProcess(data, isTrackingEnabled: false), false);
  });

  test('should reject notification when isRemoved is true', () {
    const data = NotificationData(
      packageName: 'com.zing.zalo',
      title: 'Zalo',
      content: 'Tin nhắn',
      timestamp: 1000,
      isRemoved: true,
    );

    final result = filter.evaluate(data);
    expect(result.isAccepted, false);
    expect(result.reason, contains('removed/dismissed'));
  });

  test('should reject notification when both title and content are empty or whitespace', () {
    const data = NotificationData(
      packageName: 'com.shopee.vn',
      title: '   ',
      content: '',
      timestamp: 1000,
    );

    final result = filter.evaluate(data);
    expect(result.isAccepted, false);
    expect(result.reason, contains('empty'));
  });

  test('should reject notification originating from Notification Insight itself', () {
    const data = NotificationData(
      packageName: 'com.notificationinsight.notification_insight',
      title: 'Thông báo nội bộ',
      content: 'Nội dung',
      timestamp: 1000,
    );

    final result = filter.evaluate(data);
    expect(result.isAccepted, false);
    expect(result.reason, contains('Self notification'));
  });

  test('should accept valid notification with title and content from various apps', () {
    const apps = [
      'com.google.android.gm',
      'com.zing.zalo',
      'com.vcb.digibank',
      'com.shopee.vn',
      'com.grabtaxi.passenger',
      'com.android.systemui',
    ];

    for (final app in apps) {
      final data = NotificationData(
        packageName: app,
        title: 'Tiêu đề thông báo',
        content: 'Nội dung thông báo',
        timestamp: 1000,
      );

      final result = filter.evaluate(data);
      expect(result.isAccepted, true, reason: 'Failed for package $app');
    }
  });

  test('should reject ongoing notifications from system package', () {
    const data = NotificationData(
      packageName: 'com.android.systemui',
      title: 'Đang chạy trong nền',
      content: 'Chạm để xem chi tiết',
      timestamp: 1000,
      isOngoing: true,
    );

    final result = filter.evaluate(data);
    expect(result.isAccepted, false);
    expect(result.reason, contains('Ongoing system'));
  });

  test('should reject charging spam notifications from android/systemui', () {
    const testCases = [
      NotificationData(
        packageName: 'com.android.systemui',
        title: 'Cable charging: 28%',
        content: '1 h 15 m until full',
        timestamp: 1000,
      ),
      NotificationData(
        packageName: 'android',
        title: 'Hệ thống Android',
        content: 'Đang sạc thiết bị này qua USB',
        timestamp: 1000,
      ),
      NotificationData(
        packageName: 'com.android.systemui',
        title: 'Fast charging',
        content: '45 phút đến khi sạc đầy',
        timestamp: 1000,
      ),
      NotificationData(
        packageName: 'com.android.systemui',
        title: 'USB debugging connected',
        content: 'Tap to disable USB debugging',
        timestamp: 1000,
      ),
    ];

    for (final tc in testCases) {
      final result = filter.evaluate(tc);
      expect(result.isAccepted, false, reason: 'Should reject ${tc.title}');
    }
  });
  });
}
