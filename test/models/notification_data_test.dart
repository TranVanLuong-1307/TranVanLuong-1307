import 'package:flutter_test/flutter_test.dart';
import 'package:notification_insight/models/notification_data.dart';

void main() {
  group('NotificationData Model Tests', () {
    test('isEmpty should return true when both title and content are null or whitespace', () {
      const dataNull = NotificationData(
        packageName: 'com.test',
        timestamp: 1000,
      );
      expect(dataNull.isEmpty, true);

      const dataEmpty = NotificationData(
        packageName: 'com.test',
        title: '   ',
        content: '',
        timestamp: 1000,
      );
      expect(dataEmpty.isEmpty, true);
    });

    test('isEmpty should return false when title or content has text', () {
      const dataWithTitle = NotificationData(
        packageName: 'com.test',
        title: 'Hello',
        timestamp: 1000,
      );
      expect(dataWithTitle.isEmpty, false);

      const dataWithContent = NotificationData(
        packageName: 'com.test',
        content: 'World',
        timestamp: 1000,
      );
      expect(dataWithContent.isEmpty, false);
    });
  });
}
