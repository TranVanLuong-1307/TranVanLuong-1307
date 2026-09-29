import 'package:flutter_test/flutter_test.dart';
import 'package:notification_insight/core/constants/app_constants.dart';
import 'package:notification_insight/core/enums/notification_category.dart';
import 'package:notification_insight/core/enums/notification_priority.dart';
import 'package:notification_insight/data/database/notification_dao.dart';
import 'package:notification_insight/data/repositories/notification_repository.dart';
import 'package:notification_insight/models/notification_record.dart';
import 'package:notification_insight/models/tracked_app.dart';
import 'package:notification_insight/providers/settings_provider.dart';
import 'package:notification_insight/services/notification/notification_permission_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockPermissionService implements INotificationPermissionService {
  bool granted;
  MockPermissionService({this.granted = false});

  @override
  Future<bool> isPermissionGranted() async => granted;

  @override
  Future<bool> requestPermission() async {
    granted = true;
    return true;
  }

  @override
  Future<bool> refreshPermissionStatus() async => granted;
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
  Future<Map<NotificationCategory, int>> getCategoryCounts() async {
    final map = <NotificationCategory, int>{};
    for (final cat in NotificationCategory.values) {
      map[cat] = _db.values.where((e) => e.category == cat).length;
    }
    return map;
  }

  @override
  Future<List<TrackedApp>> getTrackedApps() async => [];

  @override
  Future<bool> hasRecentDuplicate(String packageName, String? title, String? content, int currentTimestamp, {int windowMs = 3000}) async => false;

  @override
  Future<int> deleteAll() async {
    final len = _db.length;
    _db.clear();
    return len;
  }
}

void main() {
  group('Phase 7 - Settings, Permission & Data Management Tests', () {
    late MockNotificationDao dao;
    late NotificationRepository repository;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      dao = MockNotificationDao();
      repository = NotificationRepository(dao: dao);
    });

    test('SettingsProvider should initialize with defaults and load from SharedPreferences', () async {
      final mockPermission = MockPermissionService(granted: true);
      final provider = SettingsProvider(permissionService: mockPermission);

      await provider.initSettings();

      expect(provider.isTrackingEnabled, isTrue);
      expect(provider.isPermissionGranted, isTrue);
      expect(provider.isLoading, isFalse);
    });

    test('Tracking state toggle should persist across simulated app restart', () async {
      final mockPermission = MockPermissionService(granted: true);
      final provider = SettingsProvider(permissionService: mockPermission);

      await provider.initSettings();
      expect(provider.isTrackingEnabled, isTrue);

      // User turns tracking OFF
      await provider.setTrackingEnabled(false);
      expect(provider.isTrackingEnabled, isFalse);

      // Verify stored in SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool(AppConstants.keyTrackingEnabled), isFalse);

      // Simulate App Restart with a new provider instance
      final restartedProvider = SettingsProvider(permissionService: mockPermission);
      await restartedProvider.initSettings();

      // Must restore false from SharedPreferences
      expect(restartedProvider.isTrackingEnabled, isFalse);
    });

    test('Permission status check and request updates state dynamically', () async {
      final mockPermission = MockPermissionService(granted: false);
      final provider = SettingsProvider(permissionService: mockPermission);

      await provider.initSettings();
      expect(provider.isPermissionGranted, isFalse);

      // User grants permission in settings
      final granted = await provider.requestPermission();
      expect(granted, isTrue);
      expect(provider.isPermissionGranted, isTrue);

      // Subsequent check maintains granted
      await provider.checkPermission();
      expect(provider.isPermissionGranted, isTrue);
    });

    test('Clear All Data must remove all records from SQLite and reset all counts to 0', () async {
      final now = DateTime.now().millisecondsSinceEpoch;

      // Seed 2 real records
      await repository.saveNotification(NotificationRecord(
        packageName: 'com.zing.zalo',
        appName: 'Zalo',
        title: 'Tin nhắn',
        content: 'Nội dung',
        category: NotificationCategory.messaging,
        priority: NotificationPriority.normal,
        isRead: false,
        isFavorite: true,
        timestamp: now,
        createdAt: now,
      ));

      await repository.saveNotification(NotificationRecord(
        packageName: 'com.shopee.vn',
        appName: 'Shopee',
        title: 'Đơn hàng',
        content: 'Đang giao',
        category: NotificationCategory.shopping,
        priority: NotificationPriority.normal,
        isRead: true,
        isFavorite: false,
        timestamp: now,
        createdAt: now,
      ));

      expect(await repository.getTotalCount(), 2);
      expect(await repository.getFavoriteCount(), 1);

      // Execute clear all notifications
      final cleared = await repository.clearAllNotifications();
      expect(cleared, isTrue);

      // Verify all counts and lists are completely reset
      expect(await repository.getTotalCount(), 0);
      expect(await repository.getTodayCount(), 0);
      expect(await repository.getFavoriteCount(), 0);
      expect(await repository.getUnreadCount(), 0);
      expect(await repository.getNotifications(), isEmpty);
      expect(await repository.getTrackedApps(), isEmpty);

      final catCounts = await repository.getCategoryCounts();
      for (final cat in NotificationCategory.values) {
        expect(catCounts[cat], 0);
      }
    });
  });
}
