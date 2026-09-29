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
  Future<NotificationRecord?> getById(int id) async {
    return _db[id];
  }

  @override
  Future<List<NotificationRecord>> getAll({int limit = 50, int offset = 0}) async {
    final list = _db.values.toList()..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return list.skip(offset).take(limit).toList();
  }

  @override
  Future<List<NotificationRecord>> getByCategory(NotificationCategory category, {int limit = 50, int offset = 0}) async {
    return _db.values.where((e) => e.category == category).toList();
  }

  @override
  Future<List<NotificationRecord>> getByPackage(String packageName, {int limit = 50, int offset = 0}) async {
    return _db.values.where((e) => e.packageName == packageName).toList();
  }

  @override
  Future<List<NotificationRecord>> search(String query, {int limit = 50, int offset = 0}) async {
    return getFiltered(query: query, limit: limit, offset: offset);
  }

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
  Future<int> deleteById(int id) async {
    return _db.remove(id) != null ? 1 : 0;
  }

  @override
  Future<int> getTotalCount() async => _db.length;

  @override
  Future<int> getTodayCount() async => _db.length;

  @override
  Future<int> getFavoriteCount() async => _db.values.where((e) => e.isFavorite).length;

  @override
  Future<int> getUnreadCount() async => _db.values.where((e) => !e.isRead).length;

  @override
  Future<Map<NotificationCategory, int>> getCategoryCounts() async {
    final map = <NotificationCategory, int>{};
    for (final cat in NotificationCategory.values) {
      map[cat] = _db.values.where((e) => e.category == cat).length;
    }
    return map;
  }

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
      (e.timestamp - currentTimestamp).abs() <= windowMs
    );
  }

  @override
  Future<int> deleteAll() async {
    final count = _db.length;
    _db.clear();
    return count;
  }
}

void main() {
  group('NotificationRepository Persistence & Query Tests (Phase 4 & 5)', () {
    late MockNotificationDao dao;
    late NotificationRepository repository;

    setUp(() {
      dao = MockNotificationDao();
      repository = NotificationRepository(dao: dao);
    });

    test('saveNotification, getById, markRead, toggleFavorite and delete', () async {
      const record = NotificationRecord(
        packageName: 'com.vcb.digibank',
        appName: 'VCB Digibank',
        title: 'Biến động số dư',
        content: 'Bạn nhận được 200.000đ',
        category: NotificationCategory.finance,
        priority: NotificationPriority.high,
        timestamp: 1712049200000,
        isRead: false,
        isFavorite: false,
        createdAt: 1712049200000,
      );

      final id = await repository.saveNotification(record);
      expect(id, isPositive);

      final fetched = await repository.getNotificationById(id);
      expect(fetched, isNotNull);
      expect(fetched!.title, 'Biến động số dư');
      expect(fetched.isRead, false);

      // Mark as read
      await repository.markAsRead(id);
      final readItem = await repository.getNotificationById(id);
      expect(readItem!.isRead, true);

      // Mark as unread
      await repository.markAsUnread(id);
      final unreadItem = await repository.getNotificationById(id);
      expect(unreadItem!.isRead, false);

      // Toggle favorite
      await repository.toggleFavorite(id, true);
      final favItem = await repository.getNotificationById(id);
      expect(favItem!.isFavorite, true);

      // Delete notification
      final deleted = await repository.deleteNotification(id);
      expect(deleted, true);
      expect(await repository.getNotificationById(id), isNull);
    });

    test('getFilteredNotifications handles multi-criteria SQL filters correctly', () async {
      await repository.saveNotification(const NotificationRecord(
        packageName: 'com.google.android.gm',
        appName: 'Gmail',
        title: 'Chào mừng thành viên mới',
        content: 'Chào bạn, chúc một ngày tốt lành',
        category: NotificationCategory.email,
        priority: NotificationPriority.normal,
        timestamp: 1000,
        isRead: true,
        isFavorite: false,
        createdAt: 1000,
      ));

      await repository.saveNotification(const NotificationRecord(
        packageName: 'com.shopee.vn',
        appName: 'Shopee',
        title: 'Voucher 50K đang chờ bạn',
        content: 'Dùng ngay kẻo hết hạn',
        category: NotificationCategory.shopping,
        priority: NotificationPriority.low,
        timestamp: 2000,
        isRead: false,
        isFavorite: true,
        createdAt: 2000,
      ));

      // Filter by category
      final emailOnly = await repository.getFilteredNotifications(category: NotificationCategory.email);
      expect(emailOnly.length, 1);
      expect(emailOnly.first.appName, 'Gmail');

      // Filter by favorite
      final favOnly = await repository.getFilteredNotifications(isFavorite: true);
      expect(favOnly.length, 1);
      expect(favOnly.first.appName, 'Shopee');

      // Filter by unread
      final unreadOnly = await repository.getFilteredNotifications(isRead: false);
      expect(unreadOnly.length, 1);
      expect(unreadOnly.first.appName, 'Shopee');

      // Filter by search query
      final searchResult = await repository.getFilteredNotifications(query: 'voucher');
      expect(searchResult.length, 1);
      expect(searchResult.first.appName, 'Shopee');

      // Combined filter: email + isFavorite: true -> should be empty
      final combinedEmpty = await repository.getFilteredNotifications(
        category: NotificationCategory.email,
        isFavorite: true,
      );
      expect(combinedEmpty.isEmpty, true);
    });

    test('getCategoryCounts aggregates counts for all 11 categories without fabrication', () async {
      await repository.saveNotification(const NotificationRecord(
        packageName: 'com.zing.zalo',
        appName: 'Zalo',
        title: 'Tin nhắn',
        content: 'Alo',
        category: NotificationCategory.messaging,
        timestamp: 1000,
        createdAt: 1000,
      ));

      final counts = await repository.getCategoryCounts();
      expect(counts.length, 11);
      expect(counts[NotificationCategory.messaging], 1);
      expect(counts[NotificationCategory.finance], 0);
      expect(counts[NotificationCategory.delivery], 0);
    });
  });
}
