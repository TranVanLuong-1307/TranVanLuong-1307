import 'package:flutter_test/flutter_test.dart';
import 'package:notification_insight/core/enums/notification_category.dart';
import 'package:notification_insight/core/enums/notification_priority.dart';
import 'package:notification_insight/data/database/notification_dao.dart';
import 'package:notification_insight/data/repositories/notification_repository.dart';
import 'package:notification_insight/models/notification_record.dart';
import 'package:notification_insight/models/tracked_app.dart';

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
  Future<List<NotificationRecord>> getAll({int limit = 50, int offset = 0}) async {
    final list = _db.values.toList()..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return list.skip(offset).take(limit).toList();
  }

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
    var list = _db.values.where((e) {
      if (category != null && e.category != category) return false;
      if (packageName != null && e.packageName != packageName) return false;
      if (isFavorite != null && e.isFavorite != isFavorite) return false;
      if (isRead != null && e.isRead != isRead) return false;
      if (startTime != null && e.timestamp < startTime) return false;
      if (endTime != null && e.timestamp > endTime) return false;
      return true;
    }).toList();
    list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return list.skip(offset).take(limit).toList();
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
  Future<int> getTodayCount() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day).millisecondsSinceEpoch;
    return _db.values.where((e) => e.timestamp >= startOfDay).length;
  }

  @override
  Future<int> getFavoriteCount() async => _db.values.where((e) => e.isFavorite).length;

  @override
  Future<int> getUnreadCount() async => _db.values.where((e) => !e.isRead).length;

  @override
  Future<int> getCountByDateRange(int startTime, int endTime) async =>
      _db.values.where((e) => e.timestamp >= startTime && e.timestamp <= endTime).length;

  @override
  Future<Map<String, int>> getDailyCountsLast7Days() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final map = <String, int>{};
    for (int i = 6; i >= 0; i--) {
      final date = today.subtract(Duration(days: i));
      final key = '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      map[key] = 0;
    }
    for (final rec in _db.values) {
      final d = DateTime.fromMillisecondsSinceEpoch(rec.timestamp);
      final key = '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
      if (map.containsKey(key)) {
        map[key] = (map[key] ?? 0) + 1;
      }
    }
    return map;
  }

  @override
  Future<Map<NotificationCategory, int>> getCategoryCounts() async {
    final map = <NotificationCategory, int>{};
    for (final cat in NotificationCategory.values) {
      map[cat] = _db.values.where((e) => e.category == cat).length;
    }
    return map;
  }

  @override
  Future<List<TrackedApp>> getTrackedApps() async {
    final map = <String, List<NotificationRecord>>{};
    for (final rec in _db.values) {
      map.putIfAbsent(rec.packageName, () => []).add(rec);
    }
    return map.entries.map((entry) {
      return TrackedApp(
        packageName: entry.key,
        appName: entry.value.first.appName,
        notificationCount: entry.value.length,
        lastTimestamp: entry.value.map((e) => e.timestamp).reduce((a, b) => a > b ? a : b),
      );
    }).toList();
  }

  @override
  Future<bool> hasRecentDuplicate(
    String packageName,
    String? title,
    String? content,
    int currentTimestamp, {
    int windowMs = 3000,
  }) async {
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
  group('Phase 6 - Dashboard & Statistics SQLite Tests', () {
    late MockNotificationDao dao;
    late NotificationRepository repository;

    setUp(() {
      dao = MockNotificationDao();
      repository = NotificationRepository(dao: dao);
    });

    test('Empty database should return all 0 metrics and empty list (NO fake data)', () async {
      final total = await repository.getTotalCount();
      final today = await repository.getTodayCount();
      final fav = await repository.getFavoriteCount();
      final unread = await repository.getUnreadCount();
      final catCounts = await repository.getCategoryCounts();
      final dailyCounts = await repository.getDailyCountsLast7Days();
      final recent = await repository.getNotifications(limit: 5);

      expect(total, 0);
      expect(today, 0);
      expect(fav, 0);
      expect(unread, 0);
      expect(recent, isEmpty);

      // All 11 categories must exist and have count 0
      expect(catCounts.length, NotificationCategory.values.length);
      for (final cat in NotificationCategory.values) {
        expect(catCounts[cat], 0);
      }

      // Last 7 days must exist and have count 0
      expect(dailyCounts.length, 7);
      for (final count in dailyCounts.values) {
        expect(count, 0);
      }
    });

    test('Dashboard metrics should compute accurately from real stored records', () async {
      final now = DateTime.now();
      final todayMs = now.millisecondsSinceEpoch;
      final yesterdayMs = now.subtract(const Duration(days: 1)).millisecondsSinceEpoch;

      // Insert 1 unread today favorite finance
      await repository.saveNotification(NotificationRecord(
        packageName: 'com.vcb.digibank',
        appName: 'VCB Digibank',
        title: 'Biến động số dư',
        content: '+2.000.000đ',
        category: NotificationCategory.finance,
        priority: NotificationPriority.high,
        isRead: false,
        isFavorite: true,
        timestamp: todayMs,
        createdAt: todayMs,
      ));

      // Insert 1 read today non-favorite messaging
      await repository.saveNotification(NotificationRecord(
        packageName: 'com.zing.zalo',
        appName: 'Zalo',
        title: 'Bạn bè',
        content: 'Alo bạn ơi',
        category: NotificationCategory.messaging,
        priority: NotificationPriority.normal,
        isRead: true,
        isFavorite: false,
        timestamp: todayMs,
        createdAt: todayMs,
      ));

      // Insert 1 unread yesterday shopping
      await repository.saveNotification(NotificationRecord(
        packageName: 'com.shopee.vn',
        appName: 'Shopee',
        title: 'Đơn hàng #1234',
        content: 'Đang giao',
        category: NotificationCategory.shopping,
        priority: NotificationPriority.normal,
        isRead: false,
        isFavorite: false,
        timestamp: yesterdayMs,
        createdAt: yesterdayMs,
      ));

      final total = await repository.getTotalCount();
      final today = await repository.getTodayCount();
      final fav = await repository.getFavoriteCount();
      final unread = await repository.getUnreadCount();
      final apps = await repository.getTrackedApps();
      final catCounts = await repository.getCategoryCounts();
      final dailyCounts = await repository.getDailyCountsLast7Days();

      expect(total, 3);
      expect(today, 2);
      expect(fav, 1);
      expect(unread, 2);
      expect(apps.length, 3);

      expect(catCounts[NotificationCategory.finance], 1);
      expect(catCounts[NotificationCategory.messaging], 1);
      expect(catCounts[NotificationCategory.shopping], 1);
      expect(catCounts[NotificationCategory.security], 0);

      // Time statistics last 7 days must sum to total records within the window
      final totalIn7Days = dailyCounts.values.fold<int>(0, (sum, count) => sum + count);
      expect(totalIn7Days, 3);
    });

    test('Date filtering and date range count query', () async {
      final now = DateTime.now();
      final t1 = now.subtract(const Duration(hours: 10)).millisecondsSinceEpoch;
      final t2 = now.subtract(const Duration(hours: 2)).millisecondsSinceEpoch;
      final t3 = now.subtract(const Duration(days: 3)).millisecondsSinceEpoch;

      await repository.saveNotification(NotificationRecord(
        packageName: 'com.app.one',
        appName: 'App One',
        title: 'T1',
        content: 'C1',
        category: NotificationCategory.general,
        priority: NotificationPriority.normal,
        timestamp: t1,
        createdAt: t1,
      ));

      await repository.saveNotification(NotificationRecord(
        packageName: 'com.app.two',
        appName: 'App Two',
        title: 'T2',
        content: 'C2',
        category: NotificationCategory.general,
        priority: NotificationPriority.normal,
        timestamp: t2,
        createdAt: t2,
      ));

      await repository.saveNotification(NotificationRecord(
        packageName: 'com.app.three',
        appName: 'App Three',
        title: 'T3',
        content: 'C3',
        category: NotificationCategory.general,
        priority: NotificationPriority.normal,
        timestamp: t3,
        createdAt: t3,
      ));

      // Range covering only t1 and t2 (today last 12 hours)
      final startRange = now.subtract(const Duration(hours: 12)).millisecondsSinceEpoch;
      final endRange = now.millisecondsSinceEpoch;

      final rangeCount = await repository.getCountByDateRange(startRange, endRange);
      expect(rangeCount, 2);

      final filtered = await repository.getFilteredNotifications(startTime: startRange, endTime: endRange);
      expect(filtered.length, 2);
      expect(filtered.map((e) => e.title), containsAll(['T1', 'T2']));
    });
  });
}
