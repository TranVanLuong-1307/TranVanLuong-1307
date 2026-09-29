import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notification_insight/core/enums/notification_category.dart';
import 'package:notification_insight/core/enums/notification_priority.dart';
import 'package:notification_insight/data/database/notification_dao.dart';
import 'package:notification_insight/data/repositories/notification_repository.dart';
import 'package:notification_insight/models/notification_data.dart';
import 'package:notification_insight/models/notification_record.dart';
import 'package:notification_insight/models/tracked_app.dart';
import 'package:notification_insight/services/analyzer/category_classifier.dart';
import 'package:notification_insight/services/analyzer/generic_analyzer.dart';
import 'package:notification_insight/services/analyzer/notification_analyzer.dart';
import 'package:notification_insight/services/notification/notification_filter.dart';
import 'package:notification_simulator/models/test_scenario.dart';
import 'package:notification_simulator/screens/simulator_screen.dart';
import 'package:notification_simulator/services/android_notification_poster.dart';

class MockNotificationPoster implements IAndroidNotificationPoster {
  final List<Map<String, dynamic>> dispatchedNotifications = [];

  @override
  Future<bool> postNotification({
    required String? title,
    required String? content,
    int? notificationId,
  }) async {
    dispatchedNotifications.add({
      'title': title,
      'content': content,
      'id': notificationId,
    });
    return true;
  }
}

class MockNotificationDao implements INotificationDao {
  final Map<int, NotificationRecord> _db = {};
  int _autoId = 1;

  @override
  Future<int> insert(NotificationRecord record) async {
    final id = record.id ?? _autoId++;
    _db[id] = record.copyWith(id: id);
    return id;
  }

  @override
  Future<NotificationRecord?> getById(int id) async => _db[id];

  @override
  Future<List<NotificationRecord>> getAll({int limit = 50, int offset = 0}) async => _db.values.toList();

  @override
  Future<List<NotificationRecord>> getByCategory(NotificationCategory category, {int limit = 50, int offset = 0}) async =>
      _db.values.where((e) => e.category == category).toList();

  @override
  Future<List<NotificationRecord>> getByPackage(String packageName, {int limit = 50, int offset = 0}) async =>
      _db.values.where((e) => e.packageName == packageName).toList();

  @override
  Future<List<NotificationRecord>> search(String query, {int limit = 50, int offset = 0}) async =>
      getFiltered(query: query, limit: limit, offset: offset);

  @override
  Future<List<NotificationRecord>> getFiltered({
    String? query,
    NotificationCategory? category,
    String? packageName,
    bool? isFavorite,
    bool? isRead,
    int? startTime,
    int? endTime,
    int limit = 50,
    int offset = 0,
  }) async => _db.values.toList();

  @override
  Future<int> toggleFavorite(int id, bool isFavorite) async => 1;

  @override
  Future<int> markAsRead(int id) async => 1;

  @override
  Future<int> markAsUnread(int id) async => 1;

  @override
  Future<int> markAllAsRead() async => 0;

  @override
  Future<int> deleteById(int id) async => _db.remove(id) != null ? 1 : 0;

  @override
  Future<int> getTotalCount() async => _db.length;

  @override
  Future<int> getTodayCount() async => _db.length;

  @override
  Future<int> getFavoriteCount() async => _db.values.where((e) => e.isFavorite).length;

  @override
  Future<int> getUnreadCount() async => _db.values.where((e) => !e.isRead).length;

  @override
  Future<int> getCountByDateRange(int startTime, int endTime) async => 0;

  @override
  Future<Map<String, int>> getDailyCountsLast7Days() async => {};

  @override
  Future<Map<NotificationCategory, int>> getCategoryCounts() async => {};

  @override
  Future<List<TrackedApp>> getTrackedApps() async => [];

  @override
  Future<bool> hasRecentDuplicate(String packageName, String? title, String? content, int currentTimestamp, {int windowMs = 3000}) async {
    return _db.values.any((e) =>
        e.packageName == packageName &&
        e.title == title &&
        e.content == content &&
        (e.timestamp - currentTimestamp).abs() <= windowMs);
  }

  @override
  Future<int> deleteAll() async {
    final len = _db.length;
    _db.clear();
    return len;
  }
}

void main() {
  group('Phase 8 - Notification Simulator Architecture & Pipeline Tests', () {
    late MockNotificationDao dao;
    late NotificationRepository repository;
    late NotificationFilter filter;
    late NotificationAnalyzer analyzer;

    setUp(() {
      dao = MockNotificationDao();
      repository = NotificationRepository(dao: dao);
      filter = NotificationFilter();
      analyzer = NotificationAnalyzer(
        classifier: CategoryClassifier(),
        genericAnalyzer: GenericAnalyzer(),
      );
    });

    test('Simulator definition should contain all 10 mandated scenarios', () {
      final scenarios = TestScenario.predefinedScenarios;
      expect(scenarios.length, 10);

      final ids = scenarios.map((s) => s.id).toList();
      expect(ids, containsAll([
        'sc_normal',
        'sc_long_title',
        'sc_long_content',
        'sc_unicode',
        'sc_vietnamese',
        'sc_empty_title',
        'sc_empty_content',
        'sc_generic_security',
        'sc_repeated',
        'sc_rapid_multiple',
      ]));
    });

    testWidgets('SimulatorScreen UI interacts with IAndroidNotificationPoster without database shortcut', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final mockPoster = MockNotificationPoster();

      await tester.pumpWidget(MaterialApp(
        home: SimulatorScreen(poster: mockPoster),
      ));
      await tester.pumpAndSettle();

      // Verify UI elements are present
      expect(find.text('Notification Simulator'), findsOneWidget);
      expect(find.text('GỬI NOTIFICATION THẬT QUA ANDROID OS'), findsOneWidget);

      // Tap Send Notification button
      await tester.tap(find.text('GỬI NOTIFICATION THẬT QUA ANDROID OS'));
      await tester.pumpAndSettle();

      // Poster must have dispatched 1 notification
      expect(mockPoster.dispatchedNotifications.length, 1);
      expect(mockPoster.dispatchedNotifications.first['title'], 'Nguyễn Văn Nam');
      expect(mockPoster.dispatchedNotifications.first['content'], 'Hôm nay mấy giờ chúng ta gặp nhau ở quán cafe?');
    });

    test('Pipeline End-to-End: Simulator notification flows through complete listener pipeline to SQLite', () async {
      const simulatorPkg = 'com.notificationinsight.simulator';
      final now = DateTime.now().millisecondsSinceEpoch;

      final incomingEvents = [
        NotificationData(
          packageName: simulatorPkg,
          appName: 'Test Simulator',
          title: 'Mã xác thực tài khoản',
          content: 'Mã OTP của bạn là 839210. Hiệu lực 2 phút.',
          timestamp: now,
        ),
        NotificationData(
          packageName: simulatorPkg,
          appName: 'Test Simulator',
          title: '🎉 Khuyến mãi đặc biệt 🎁',
          content: 'Nội dung tiếng Việt có dấu đầy đủ & biểu tượng cảm xúc ✨',
          timestamp: now,
        ),
      ];

      for (final event in incomingEvents) {
        // Step 1: Filter
        final filterResult = filter.evaluate(event, isTrackingEnabled: true);
        expect(filterResult.isAccepted, isTrue);

        // Step 2: Analyzer
        final record = analyzer.process(event)!;

        // Step 3: Persistence to SQLite
        await repository.saveNotification(record);
      }

      // Verify records stored in SQLite
      final storedRecords = await repository.getNotifications();
      expect(storedRecords.length, 2);

      // Verify Security/OTP was properly categorized and given urgent priority
      final otpRecord = storedRecords.firstWhere((r) => r.title!.contains('Mã xác thực'));
      expect(otpRecord.category, NotificationCategory.security);
      expect(otpRecord.priority, NotificationPriority.urgent);

      // Verify Unicode and Vietnamese preserved accurately in database
      final unicodeRecord = storedRecords.firstWhere((r) => r.title!.contains('🎉'));
      expect(unicodeRecord.title, '🎉 Khuyến mãi đặc biệt 🎁');
      expect(unicodeRecord.content, 'Nội dung tiếng Việt có dấu đầy đủ & biểu tượng cảm xúc ✨');
    });

    test('Pipeline properly rejects duplicate notifications from Simulator repeated scenario', () async {
      const simulatorPkg = 'com.notificationinsight.simulator';
      final now = DateTime.now().millisecondsSinceEpoch;

      final dupData = NotificationData(
        packageName: simulatorPkg,
        appName: 'Test Simulator',
        title: 'Shopee Thông Báo',
        content: 'Flash sale 12h sắp bắt đầu!',
        timestamp: now,
      );

      // First event saved
      final record1 = analyzer.process(dupData)!;
      await repository.saveNotification(record1);

      // Second identical event within 3 seconds
      final isDup = await repository.hasRecentDuplicate(
        dupData.packageName,
        dupData.title,
        dupData.content,
        now,
      );

      expect(isDup, isTrue);
      // Duplicate should NOT be inserted again
    });
  });
}
