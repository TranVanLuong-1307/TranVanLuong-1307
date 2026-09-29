import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:notification_insight/core/enums/notification_category.dart';
import 'package:notification_insight/data/repositories/notification_repository.dart';
import 'package:notification_insight/models/notification_data.dart';
import 'package:notification_insight/models/notification_record.dart';
import 'package:notification_insight/models/tracked_app.dart';
import 'package:notification_insight/providers/notification_provider.dart';
import 'package:notification_insight/services/analyzer/notification_analyzer.dart';
import 'package:notification_insight/services/notification/notification_filter.dart';
import 'package:notification_insight/services/notification/notification_service.dart';

class MockNotificationService implements INotificationService {
  final _controller = StreamController<NotificationData>.broadcast();
  bool _listening = false;

  @override
  Stream<NotificationData> get notificationStream => _controller.stream;

  @override
  bool get isListening => _listening;

  @override
  void startListening() {
    _listening = true;
  }

  @override
  void stopListening() {
    _listening = false;
  }

  @override
  void dispose() {
    _controller.close();
  }

  void emit(NotificationData data) {
    _controller.add(data);
  }
}

class InMemoryRepository implements INotificationRepository {
  final List<NotificationRecord> storage = [];

  @override
  Future<int> saveNotification(NotificationRecord record) async {
    final newId = storage.length + 1;
    final saved = record.copyWith(id: newId);
    storage.insert(0, saved);
    return newId;
  }

  @override
  Future<List<NotificationRecord>> getNotifications({int limit = 50, int offset = 0}) async {
    return List.from(storage);
  }

  @override
  Future<List<NotificationRecord>> getByCategory(NotificationCategory category, {int limit = 50, int offset = 0}) async {
    return storage.where((e) => e.category == category).toList();
  }

  @override
  Future<List<NotificationRecord>> getByPackage(String packageName, {int limit = 50, int offset = 0}) async {
    return storage.where((e) => e.packageName == packageName).toList();
  }

  @override
  Future<List<NotificationRecord>> searchNotifications(String query, {int limit = 50, int offset = 0}) async {
    return storage.where((e) => (e.title ?? '').contains(query)).toList();
  }

  @override
  Future<NotificationRecord?> getNotificationById(int id) async {
    final list = storage.where((e) => e.id == id).toList();
    return list.isNotEmpty ? list.first : null;
  }

  @override
  Future<List<NotificationRecord>> getFilteredNotifications({
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
    return storage.where((e) {
      if (category != null && e.category != category) return false;
      if (packageName != null && e.packageName != packageName) return false;
      if (isFavorite != null && e.isFavorite != isFavorite) return false;
      if (isRead != null && e.isRead != isRead) return false;
      if (query != null && query.isNotEmpty) {
        final q = query.toLowerCase();
        final m1 = e.title?.toLowerCase().contains(q) ?? false;
        final m2 = e.content?.toLowerCase().contains(q) ?? false;
        if (!m1 && !m2) return false;
      }
      return true;
    }).skip(offset).take(limit).toList();
  }

  @override
  Future<bool> markAsUnread(int id) async => true;

  @override
  Future<int> markAllAsRead() async {
    int count = 0;
    for (int i = 0; i < storage.length; i++) {
      if (!storage[i].isRead) {
        storage[i] = storage[i].copyWith(isRead: true);
        count++;
      }
    }
    return count;
  }

  @override
  Future<bool> deleteNotification(int id) async {
    final initial = storage.length;
    storage.removeWhere((e) => e.id == id);
    return storage.length < initial;
  }

  @override
  Future<int> getUnreadCount() async => storage.where((e) => !e.isRead).length;

  @override
  Future<bool> toggleFavorite(int id, bool isFavorite) async => true;

  @override
  Future<bool> markAsRead(int id) async => true;

  @override
  Future<int> getTotalCount() async => storage.length;

  @override
  Future<int> getTodayCount() async => storage.length;

  @override
  Future<int> getFavoriteCount() async => 0;

  @override
  Future<int> getCountByDateRange(int startTime, int endTime) async => 0;

  @override
  Future<Map<String, int>> getDailyCountsLast7Days() async => {};

  @override
  Future<Map<NotificationCategory, int>> getCategoryCounts() async => {};

  @override
  Future<List<TrackedApp>> getTrackedApps() async => [];

  @override
  Future<bool> hasRecentDuplicate(
    String packageName,
    String? title,
    String? content,
    int currentTimestamp, {
    int windowMs = 3000,
  }) async {
    return storage.any((e) =>
      e.packageName == packageName &&
      e.title == title &&
      e.content == content &&
      (e.timestamp - currentTimestamp).abs() <= windowMs
    );
  }

  @override
  Future<bool> clearAllNotifications() async {
    storage.clear();
    return true;
  }
}

void main() {
  group('Real Notification Ingestion Pipeline End-to-End Tests', () {
    late MockNotificationService mockService;
    late InMemoryRepository repo;
    late NotificationFilter filter;
    late NotificationAnalyzer analyzer;
    late NotificationProvider provider;

    setUp(() {
      mockService = MockNotificationService();
      repo = InMemoryRepository();
      filter = NotificationFilter();
      analyzer = NotificationAnalyzer();

      provider = NotificationProvider(
        repository: repo,
        notificationService: mockService,
        filter: filter,
        analyzer: analyzer,
      );
    });

    tearDown(() {
      provider.dispose();
    });

    test('valid incoming notification should flow end-to-end and update provider state', () async {
      provider.startNotificationPipeline(isTrackingEnabled: true);

      const incoming = NotificationData(
        packageName: 'com.vcb.digibank',
        title: 'Biến động số dư',
        content: 'Bạn nhận được 200.000đ từ NGUYEN VAN A',
        timestamp: 1712049200000,
      );

      mockService.emit(incoming);

      // Wait a microtask tick for async pipeline processing
      await Future.delayed(const Duration(milliseconds: 50));

      expect(repo.storage.length, 1);
      expect(provider.notifications.length, 1);
      expect(provider.totalCount, 1);

      final record = provider.notifications.first;
      expect(record.appName, 'VCB Digibank');
      expect(record.category, NotificationCategory.finance);
      expect(record.content, 'Bạn nhận được 200.000đ từ NGUYEN VAN A');
    });

    test('removed event should be filtered out and NOT persisted to database', () async {
      provider.startNotificationPipeline(isTrackingEnabled: true);

      const removedEvent = NotificationData(
        packageName: 'com.zing.zalo',
        title: 'Zalo',
        content: 'Tin nhắn đã thu hồi',
        timestamp: 1712049200000,
        isRemoved: true,
      );

      mockService.emit(removedEvent);
      await Future.delayed(const Duration(milliseconds: 50));

      expect(repo.storage.length, 0);
      expect(provider.notifications.length, 0);
    });

    test('duplicate notification within time window should NOT create duplicate record', () async {
      provider.startNotificationPipeline(isTrackingEnabled: true);

      const firstNotification = NotificationData(
        packageName: 'com.shopee.vn',
        title: 'Shopee',
        content: 'Đơn hàng đang được giao',
        timestamp: 1712049200000,
      );

      // Emit first time
      mockService.emit(firstNotification);
      await Future.delayed(const Duration(milliseconds: 50));
      expect(repo.storage.length, 1);

      // Emit duplicate event 500ms later (e.g., Android re-broadcast)
      const duplicateNotification = NotificationData(
        packageName: 'com.shopee.vn',
        title: 'Shopee',
        content: 'Đơn hàng đang được giao',
        timestamp: 1712049200500,
      );

      mockService.emit(duplicateNotification);
      await Future.delayed(const Duration(milliseconds: 50));

      // Should still be only 1 record!
      expect(repo.storage.length, 1);
      expect(provider.notifications.length, 1);
    });

    test('incoming notifications should be ignored when tracking is disabled', () async {
      provider.startNotificationPipeline(isTrackingEnabled: false);

      const incoming = NotificationData(
        packageName: 'com.google.android.gm',
        title: 'Email mới',
        content: 'Chào bạn',
        timestamp: 1712049200000,
      );

      mockService.emit(incoming);
      await Future.delayed(const Duration(milliseconds: 50));

      expect(repo.storage.length, 0);
      expect(provider.notifications.length, 0);
    });
  });
}
