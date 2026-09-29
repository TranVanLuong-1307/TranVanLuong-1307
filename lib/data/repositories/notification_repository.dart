import '../../core/enums/notification_category.dart';
import '../../core/utils/app_logger.dart';
import '../../models/notification_record.dart';
import '../../models/tracked_app.dart';
import '../database/notification_dao.dart';

abstract class INotificationRepository {
  Future<int> saveNotification(NotificationRecord record);
  Future<NotificationRecord?> getNotificationById(int id);
  Future<List<NotificationRecord>> getNotifications({int limit = 50, int offset = 0});
  Future<List<NotificationRecord>> getByCategory(NotificationCategory category, {int limit = 50, int offset = 0});
  Future<List<NotificationRecord>> getByPackage(String packageName, {int limit = 50, int offset = 0});
  Future<List<NotificationRecord>> searchNotifications(String query, {int limit = 50, int offset = 0});
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
  });
  Future<bool> toggleFavorite(int id, bool isFavorite);
  Future<bool> markAsRead(int id);
  Future<bool> markAsUnread(int id);
  Future<int> markAllAsRead();
  Future<bool> deleteNotification(int id);
  Future<int> getTotalCount();
  Future<int> getTodayCount();
  Future<int> getFavoriteCount();
  Future<int> getUnreadCount();
  Future<int> getCountByDateRange(int startTime, int endTime);
  Future<Map<String, int>> getDailyCountsLast7Days();
  Future<Map<NotificationCategory, int>> getCategoryCounts();
  Future<List<TrackedApp>> getTrackedApps();
  Future<bool> hasRecentDuplicate(String packageName, String? title, String? content, int currentTimestamp, {int windowMs = 3000});
  Future<bool> clearAllNotifications();
}

class NotificationRepository implements INotificationRepository {
  static const String _tag = 'NotificationRepository';
  final INotificationDao _dao;

  NotificationRepository({INotificationDao? dao})
      : _dao = dao ?? NotificationDao();

  @override
  Future<int> saveNotification(NotificationRecord record) async {
    final id = await _dao.insert(record);
    AppLogger.info(_tag, 'Notification saved successfully with SQLite rowId=$id (pkg=${record.packageName})');
    return id;
  }

  @override
  Future<NotificationRecord?> getNotificationById(int id) async {
    return await _dao.getById(id);
  }

  @override
  Future<List<NotificationRecord>> getNotifications({int limit = 50, int offset = 0}) async {
    return await _dao.getAll(limit: limit, offset: offset);
  }

  @override
  Future<List<NotificationRecord>> getByCategory(
    NotificationCategory category, {
    int limit = 50,
    int offset = 0,
  }) async {
    return await _dao.getByCategory(category, limit: limit, offset: offset);
  }

  @override
  Future<List<NotificationRecord>> getByPackage(
    String packageName, {
    int limit = 50,
    int offset = 0,
  }) async {
    return await _dao.getByPackage(packageName, limit: limit, offset: offset);
  }

  @override
  Future<List<NotificationRecord>> searchNotifications(
    String query, {
    int limit = 50,
    int offset = 0,
  }) async {
    return await _dao.search(query, limit: limit, offset: offset);
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
    return await _dao.getFiltered(
      query: query,
      category: category,
      packageName: packageName,
      isFavorite: isFavorite,
      isRead: isRead,
      startTime: startTime,
      endTime: endTime,
      limit: limit,
      offset: offset,
    );
  }

  @override
  Future<bool> toggleFavorite(int id, bool isFavorite) async {
    final rows = await _dao.toggleFavorite(id, isFavorite);
    AppLogger.debug(_tag, 'Toggled favorite for id=$id -> isFavorite=$isFavorite');
    return rows > 0;
  }

  @override
  Future<bool> markAsRead(int id) async {
    final rows = await _dao.markAsRead(id);
    AppLogger.debug(_tag, 'Marked as read for id=$id');
    return rows > 0;
  }

  @override
  Future<bool> markAsUnread(int id) async {
    final rows = await _dao.markAsUnread(id);
    AppLogger.debug(_tag, 'Marked as unread for id=$id');
    return rows > 0;
  }

  @override
  Future<int> markAllAsRead() async {
    final rows = await _dao.markAllAsRead();
    AppLogger.info(_tag, 'Marked all notifications as read ($rows updated).');
    return rows;
  }

  @override
  Future<bool> deleteNotification(int id) async {
    final rows = await _dao.deleteById(id);
    AppLogger.info(_tag, 'Deleted notification id=$id');
    return rows > 0;
  }

  @override
  Future<int> getTotalCount() async {
    return await _dao.getTotalCount();
  }

  @override
  Future<int> getTodayCount() async {
    return await _dao.getTodayCount();
  }

  @override
  Future<int> getFavoriteCount() async {
    return await _dao.getFavoriteCount();
  }

  @override
  Future<int> getUnreadCount() async {
    return await _dao.getUnreadCount();
  }

  @override
  Future<int> getCountByDateRange(int startTime, int endTime) async {
    return await _dao.getCountByDateRange(startTime, endTime);
  }

  @override
  Future<Map<String, int>> getDailyCountsLast7Days() async {
    return await _dao.getDailyCountsLast7Days();
  }

  @override
  Future<Map<NotificationCategory, int>> getCategoryCounts() async {
    return await _dao.getCategoryCounts();
  }

  @override
  Future<List<TrackedApp>> getTrackedApps() async {
    return await _dao.getTrackedApps();
  }

  @override
  Future<bool> hasRecentDuplicate(
    String packageName,
    String? title,
    String? content,
    int currentTimestamp, {
    int windowMs = 3000,
  }) async {
    final isDup = await _dao.hasRecentDuplicate(
      packageName,
      title,
      content,
      currentTimestamp,
      windowMs: windowMs,
    );
    if (isDup) {
      AppLogger.debug(_tag, 'Duplicate notification detected for $packageName within ${windowMs}ms window. Skipping save.');
    }
    return isDup;
  }

  @override
  Future<bool> clearAllNotifications() async {
    final rows = await _dao.deleteAll();
    AppLogger.info(_tag, 'Cleared all notifications from database ($rows rows removed).');
    return rows >= 0;
  }
}
