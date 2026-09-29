import 'package:flutter_test/flutter_test.dart';
import 'package:notification_insight/core/enums/notification_category.dart';
import 'package:notification_insight/core/enums/notification_priority.dart';
import 'package:notification_insight/data/repositories/notification_repository.dart';
import 'package:notification_insight/models/notification_record.dart';
import 'package:notification_insight/models/tracked_app.dart';
import 'package:notification_insight/providers/notification_provider.dart';

class FakeNotificationRepository implements INotificationRepository {
  final List<NotificationRecord> _items = [];

  FakeNotificationRepository(List<NotificationRecord> initial) {
    _items.addAll(initial);
  }

  @override
  Future<int> saveNotification(NotificationRecord record) async {
    _items.insert(0, record);
    return record.id ?? _items.length;
  }

  @override
  Future<NotificationRecord?> getNotificationById(int id) async {
    final list = _items.where((e) => e.id == id).toList();
    return list.isNotEmpty ? list.first : null;
  }

  @override
  Future<List<NotificationRecord>> getNotifications({int limit = 50, int offset = 0}) async {
    return List.from(_items);
  }

  @override
  Future<List<NotificationRecord>> getByCategory(NotificationCategory category, {int limit = 50, int offset = 0}) async {
    return _items.where((e) => e.category == category).toList();
  }

  @override
  Future<List<NotificationRecord>> getByPackage(String packageName, {int limit = 50, int offset = 0}) async {
    return _items.where((e) => e.packageName == packageName).toList();
  }

  @override
  Future<List<NotificationRecord>> searchNotifications(String query, {int limit = 50, int offset = 0}) async {
    final lower = query.toLowerCase();
    return _items.where((e) =>
      (e.title?.toLowerCase().contains(lower) ?? false) ||
      (e.content?.toLowerCase().contains(lower) ?? false) ||
      e.appName.toLowerCase().contains(lower) ||
      e.packageName.toLowerCase().contains(lower)
    ).toList();
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
    return _items.where((e) {
      if (category != null && e.category != category) return false;
      if (packageName != null && e.packageName != packageName) return false;
      if (isFavorite != null && e.isFavorite != isFavorite) return false;
      if (isRead != null && e.isRead != isRead) return false;
      if (query != null && query.isNotEmpty) {
        final q = query.toLowerCase();
        final m1 = e.title?.toLowerCase().contains(q) ?? false;
        final m2 = e.content?.toLowerCase().contains(q) ?? false;
        final m3 = e.appName.toLowerCase().contains(q);
        final m4 = e.packageName.toLowerCase().contains(q);
        if (!m1 && !m2 && !m3 && !m4) return false;
      }
      return true;
    }).toList();
  }

  @override
  Future<bool> toggleFavorite(int id, bool isFavorite) async {
    final idx = _items.indexWhere((e) => e.id == id);
    if (idx != -1) {
      _items[idx] = _items[idx].copyWith(isFavorite: isFavorite);
      return true;
    }
    return false;
  }

  @override
  Future<bool> markAsRead(int id) async {
    final idx = _items.indexWhere((e) => e.id == id);
    if (idx != -1) {
      _items[idx] = _items[idx].copyWith(isRead: true);
      return true;
    }
    return false;
  }

  @override
  Future<bool> markAsUnread(int id) async {
    final idx = _items.indexWhere((e) => e.id == id);
    if (idx != -1) {
      _items[idx] = _items[idx].copyWith(isRead: false);
      return true;
    }
    return false;
  }

  @override
  Future<int> markAllAsRead() async {
    int count = 0;
    for (int i = 0; i < _items.length; i++) {
      if (!_items[i].isRead) {
        _items[i] = _items[i].copyWith(isRead: true);
        count++;
      }
    }
    return count;
  }

  @override
  Future<bool> deleteNotification(int id) async {
    final initialLen = _items.length;
    _items.removeWhere((e) => e.id == id);
    return _items.length < initialLen;
  }

  @override
  Future<int> getTotalCount() async => _items.length;

  @override
  Future<int> getTodayCount() async => _items.length;

  @override
  Future<int> getFavoriteCount() async => _items.where((e) => e.isFavorite).length;

  @override
  Future<int> getUnreadCount() async => _items.where((e) => !e.isRead).length;

  @override
  Future<int> getCountByDateRange(int startTime, int endTime) async =>
      _items.where((e) => e.timestamp >= startTime && e.timestamp <= endTime).length;

  @override
  Future<Map<String, int>> getDailyCountsLast7Days() async => {};

  @override
  Future<Map<NotificationCategory, int>> getCategoryCounts() async {
    final map = <NotificationCategory, int>{};
    for (final cat in NotificationCategory.values) {
      map[cat] = _items.where((e) => e.category == cat).length;
    }
    return map;
  }

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
    return _items.any((e) =>
      e.packageName == packageName &&
      e.title == title &&
      e.content == content &&
      (e.timestamp - currentTimestamp).abs() <= windowMs
    );
  }

  @override
  Future<bool> clearAllNotifications() async {
    _items.clear();
    return true;
  }
}

void main() {
  group('NotificationProvider Tests', () {
    late FakeNotificationRepository fakeRepo;
    late NotificationProvider provider;

    final sampleRecords = [
      const NotificationRecord(
        id: 1,
        packageName: 'com.shopee.vn',
        appName: 'Shopee',
        title: 'Giao hàng',
        content: 'Đơn hàng đang đến',
        category: NotificationCategory.delivery,
        priority: NotificationPriority.normal,
        timestamp: 1000,
        isRead: false,
        isFavorite: false,
        createdAt: 1000,
      ),
      const NotificationRecord(
        id: 2,
        packageName: 'com.vcb.digibank',
        appName: 'VCB Digibank',
        title: 'Tài chính',
        content: 'Bạn nhận được 200.000đ',
        category: NotificationCategory.finance,
        priority: NotificationPriority.high,
        timestamp: 2000,
        isRead: true,
        isFavorite: true,
        createdAt: 2000,
      ),
    ];

    setUp(() {
      fakeRepo = FakeNotificationRepository(sampleRecords);
      provider = NotificationProvider(repository: fakeRepo);
    });

    test('loadNotifications should load all items and update metrics', () async {
      await provider.loadNotifications();

      expect(provider.notifications.length, 2);
      expect(provider.totalCount, 2);
      expect(provider.unreadCount, 1);
      expect(provider.favoriteCount, 1);
    });

    test('search should filter items matching query', () async {
      await provider.search('Shopee');

      expect(provider.notifications.length, 1);
      expect(provider.notifications.first.appName, 'Shopee');
    });

    test('search with no matching result should yield empty list without error', () async {
      await provider.search('xyzNonExistentQuery123');

      expect(provider.notifications.isEmpty, true);
    });

    test('filterByCategory should filter items by specific category', () async {
      await provider.filterByCategory(NotificationCategory.finance);

      expect(provider.notifications.length, 1);
      expect(provider.notifications.first.category, NotificationCategory.finance);
    });

    test('toggleFavorite should update favorite status in provider state and persist', () async {
      await provider.loadNotifications();
      final target = provider.notifications.first;
      expect(target.isFavorite, false);

      await provider.toggleFavorite(target);

      expect(provider.notifications.first.isFavorite, true);
    });

    test('toggleReadStatus should mark read and unread correctly', () async {
      await provider.loadNotifications();
      final unreadItem = provider.notifications.firstWhere((e) => !e.isRead);

      // Toggle to read
      await provider.toggleReadStatus(unreadItem);
      expect(provider.notifications.firstWhere((e) => e.id == unreadItem.id).isRead, true);

      // Toggle back to unread
      await provider.toggleReadStatus(provider.notifications.firstWhere((e) => e.id == unreadItem.id));
      expect(provider.notifications.firstWhere((e) => e.id == unreadItem.id).isRead, false);
    });

    test('markAllAsRead should update all unread notifications', () async {
      await provider.loadNotifications();
      expect(provider.unreadCount, 1);

      await provider.markAllAsRead();
      expect(provider.unreadCount, 0);
      expect(provider.notifications.every((e) => e.isRead), true);
    });

    test('deleteNotification should remove item from state and decrement total', () async {
      await provider.loadNotifications();
      expect(provider.totalCount, 2);

      final itemToDelete = provider.notifications.first;
      await provider.deleteNotification(itemToDelete);

      expect(provider.notifications.length, 1);
      expect(provider.notifications.any((e) => e.id == itemToDelete.id), false);
      expect(provider.totalCount, 1);
    });
  });
}
