import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:notification_insight/core/enums/notification_category.dart';
import 'package:notification_insight/core/enums/notification_priority.dart';
import 'package:notification_insight/core/utils/app_name_resolver.dart';
import 'package:notification_insight/data/database/notification_dao.dart';
import 'package:notification_insight/data/repositories/notification_repository.dart';
import 'package:notification_insight/models/notification_data.dart';
import 'package:notification_insight/models/notification_record.dart';
import 'package:notification_insight/models/tracked_app.dart';
import 'package:notification_insight/providers/notification_provider.dart';
import 'package:notification_insight/services/analyzer/category_classifier.dart';
import 'package:notification_insight/services/analyzer/generic_analyzer.dart';
import 'package:notification_insight/services/analyzer/notification_analyzer.dart';
import 'package:notification_insight/services/notification/notification_filter.dart';
import 'package:notification_insight/services/notification/notification_service.dart';

class MockNotificationService implements INotificationService {
  final _controller = StreamController<NotificationData>.broadcast();
  bool _isListening = false;

  @override
  Stream<NotificationData> get notificationStream => _controller.stream;

  @override
  bool get isListening => _isListening;

  @override
  void startListening() {
    _isListening = true;
  }

  @override
  void stopListening() {
    _isListening = false;
  }

  @override
  void dispose() {
    _isListening = false;
    _controller.close();
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
  }) async {
    return _db.values.where((e) {
      if (category != null && e.category != category) return false;
      if (packageName != null && e.packageName != packageName) return false;
      if (isFavorite != null && e.isFavorite != isFavorite) return false;
      if (isRead != null && e.isRead != isRead) return false;
      return true;
    }).toList();
  }

  @override
  Future<int> toggleFavorite(int id, bool isFavorite) async {
    if (_db.containsKey(id)) {
      _db[id] = _db[id]!.copyWith(isFavorite: isFavorite);
      return 1;
    }
    return 0;
  }

  @override
  Future<int> markAsRead(int id) async {
    if (_db.containsKey(id)) {
      _db[id] = _db[id]!.copyWith(isRead: true);
      return 1;
    }
    return 0;
  }

  @override
  Future<int> markAsUnread(int id) async {
    if (_db.containsKey(id)) {
      _db[id] = _db[id]!.copyWith(isRead: false);
      return 1;
    }
    return 0;
  }

  @override
  Future<int> markAllAsRead() async {
    int count = 0;
    for (final id in _db.keys) {
      if (!_db[id]!.isRead) {
        _db[id] = _db[id]!.copyWith(isRead: true);
        count++;
      }
    }
    return count;
  }

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
  group('Phase 9 - Stability, Edge Cases & Hardening Tests', () {
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

    test('Edge Case: Null and empty titles/contents are handled safely without crashing', () {
      final now = DateTime.now().millisecondsSinceEpoch;

      // 1. Both title and content null/whitespace -> Filter REJECTS safely
      final emptyEvent = NotificationData(
        packageName: 'com.test.empty',
        title: '   ',
        content: null,
        timestamp: now,
      );
      final emptyResult = filter.evaluate(emptyEvent);
      expect(emptyResult.isAccepted, isFalse);

      // 2. Title present, content null -> Filter ACCEPTS, Analyzer processes
      final titleOnlyEvent = NotificationData(
        packageName: 'com.test.titleonly',
        title: 'Chỉ có tiêu đề thông báo',
        content: null,
        timestamp: now,
      );
      expect(filter.evaluate(titleOnlyEvent).isAccepted, isTrue);
      final titleRecord = analyzer.process(titleOnlyEvent);
      expect(titleRecord, isNotNull);
      expect(titleRecord!.title, 'Chỉ có tiêu đề thông báo');
      expect(titleRecord.content, isNull);

      // 3. Content present, title null -> Filter ACCEPTS, Analyzer processes
      final contentOnlyEvent = NotificationData(
        packageName: 'com.test.contentonly',
        title: null,
        content: 'Chỉ có nội dung văn bản',
        timestamp: now,
      );
      expect(filter.evaluate(contentOnlyEvent).isAccepted, isTrue);
      final contentRecord = analyzer.process(contentOnlyEvent);
      expect(contentRecord, isNotNull);
      expect(contentRecord!.title, isNull);
      expect(contentRecord.content, 'Chỉ có nội dung văn bản');
    });

    test('Edge Case: Extremely long content (5000 chars) is preserved completely without crashing', () async {
      final now = DateTime.now().millisecondsSinceEpoch;
      final longText = 'Nội dung rất dài ' * 300; // ~5100 chars

      final longEvent = NotificationData(
        packageName: 'com.news.daily',
        title: 'Bản tin đặc biệt',
        content: longText,
        timestamp: now,
      );

      final record = analyzer.process(longEvent)!;
      final savedId = await repository.saveNotification(record);

      final fetched = await repository.getNotificationById(savedId);
      expect(fetched, isNotNull);
      expect(fetched!.content!.length, longText.length);
      expect(fetched.content, longText);
    });

    test('Edge Case: SQL Injection patterns in title/content are safely stored and searched without syntax errors', () async {
      final now = DateTime.now().millisecondsSinceEpoch;
      const sqlPayload = "'; DROP TABLE notifications; -- ' OR '1'='1";

      final sqlEvent = NotificationData(
        packageName: 'com.security.probe',
        title: sqlPayload,
        content: "Nội dung kiểm tra injection: $sqlPayload",
        timestamp: now,
      );

      final record = analyzer.process(sqlEvent)!;
      final savedId = await repository.saveNotification(record);

      final fetched = await repository.getNotificationById(savedId);
      expect(fetched, isNotNull);
      expect(fetched!.title, sqlPayload);

      // Search using the dangerous payload
      final searchResults = await repository.searchNotifications(sqlPayload);
      expect(searchResults.length, 1);
      expect(searchResults.first.id, savedId);
    });

    test('Edge Case: Unknown package names resolve readable fallback safely', () {
      expect(AppNameResolver.resolve('com.example.completely.unknown.app'), 'App');
      expect(AppNameResolver.resolve(null), 'Ứng dụng không xác định');
      expect(AppNameResolver.resolve(''), 'Ứng dụng không xác định');
    });

    test('Hardening: Rapid burst of 20 notifications processed concurrently without loss', () async {
      final now = DateTime.now().millisecondsSinceEpoch;

      final futures = List.generate(20, (i) {
        final event = NotificationData(
          packageName: 'com.burst.app',
          title: 'Burst #$i',
          content: 'Nội dung burst số $i',
          timestamp: now + i,
        );
        final rec = analyzer.process(event)!;
        return repository.saveNotification(rec);
      });

      final ids = await Future.wait(futures);
      expect(ids.length, 20);

      final total = await repository.getTotalCount();
      expect(total, 20);
    });

    test('Hardening: Duplicate prevention rejects identical rapid messages', () async {
      final now = DateTime.now().millisecondsSinceEpoch;
      const pkg = 'com.shopee.vn';
      const title = 'Đồng giá 1k';
      const content = 'Vào mua ngay kẻo hết!';

      final record1 = NotificationRecord(
        packageName: pkg,
        appName: 'Shopee',
        title: title,
        content: content,
        category: NotificationCategory.shopping,
        priority: NotificationPriority.low,
        timestamp: now,
        createdAt: now,
      );

      await repository.saveNotification(record1);

      // Check if duplicate detection flags the identical second message
      final isDup = await repository.hasRecentDuplicate(pkg, title, content, now + 500, windowMs: 3000);
      expect(isDup, isTrue);

      // After 3500ms, should no longer be considered duplicate
      final isOldDup = await repository.hasRecentDuplicate(pkg, title, content, now + 3500, windowMs: 3000);
      expect(isOldDup, isFalse);
    });

    test('Provider Lifecycle: Start and dispose pipeline cancels stream subscription cleanly', () {
      final mockService = MockNotificationService();
      final provider = NotificationProvider(
        repository: repository,
        notificationService: mockService,
        filter: filter,
        analyzer: analyzer,
      );

      // Start listening
      provider.startNotificationPipeline(isTrackingEnabled: true);
      expect(provider.isListening, isTrue);

      // Re-calling start does not create duplicate subscriptions
      provider.startNotificationPipeline(isTrackingEnabled: true);
      expect(provider.isListening, isTrue);

      // Dispose cancels subscription and service
      provider.dispose();
      expect(provider.isListening, isFalse);
    });
  });
}
