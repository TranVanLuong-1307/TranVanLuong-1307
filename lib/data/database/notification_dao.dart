import 'package:sqflite/sqflite.dart';
import '../../core/constants/app_constants.dart';
import '../../core/enums/notification_category.dart';
import '../../models/notification_record.dart';
import '../../models/tracked_app.dart';
import 'database_helper.dart';

abstract class INotificationDao {
  Future<int> insert(NotificationRecord record);
  Future<NotificationRecord?> getById(int id);
  Future<List<NotificationRecord>> getAll({int limit = 50, int offset = 0});
  Future<List<NotificationRecord>> getByCategory(NotificationCategory category, {int limit = 50, int offset = 0});
  Future<List<NotificationRecord>> getByPackage(String packageName, {int limit = 50, int offset = 0});
  Future<List<NotificationRecord>> search(String query, {int limit = 50, int offset = 0});
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
  });
  Future<int> toggleFavorite(int id, bool isFavorite);
  Future<int> markAsRead(int id);
  Future<int> markAsUnread(int id);
  Future<int> markAllAsRead();
  Future<int> deleteById(int id);
  Future<int> getTotalCount();
  Future<int> getTodayCount();
  Future<int> getFavoriteCount();
  Future<int> getUnreadCount();
  Future<int> getCountByDateRange(int startTime, int endTime);
  Future<Map<String, int>> getDailyCountsLast7Days();
  Future<Map<NotificationCategory, int>> getCategoryCounts();
  Future<List<TrackedApp>> getTrackedApps();
  Future<bool> hasRecentDuplicate(String packageName, String? title, String? content, int currentTimestamp, {int windowMs = 3000});
  Future<int> deleteAll();
}

class NotificationDao implements INotificationDao {
  final DatabaseHelper _dbHelper;

  NotificationDao({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  Future<Database> get _db async => await _dbHelper.database;

  @override
  Future<int> insert(NotificationRecord record) async {
    final db = await _db;
    return await db.insert(
      AppConstants.tableNotifications,
      record.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<NotificationRecord?> getById(int id) async {
    final db = await _db;
    final results = await db.query(
      AppConstants.tableNotifications,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (results.isNotEmpty) {
      return NotificationRecord.fromMap(results.first);
    }
    return null;
  }

  @override
  Future<List<NotificationRecord>> getAll({int limit = 50, int offset = 0}) async {
    final db = await _db;
    final results = await db.query(
      AppConstants.tableNotifications,
      orderBy: 'timestamp DESC',
      limit: limit,
      offset: offset,
    );
    return results.map((m) => NotificationRecord.fromMap(m)).toList();
  }

  @override
  Future<List<NotificationRecord>> getByCategory(
    NotificationCategory category, {
    int limit = 50,
    int offset = 0,
  }) async {
    final db = await _db;
    final results = await db.query(
      AppConstants.tableNotifications,
      where: 'category = ?',
      whereArgs: [category.name],
      orderBy: 'timestamp DESC',
      limit: limit,
      offset: offset,
    );
    return results.map((m) => NotificationRecord.fromMap(m)).toList();
  }

  @override
  Future<List<NotificationRecord>> getByPackage(
    String packageName, {
    int limit = 50,
    int offset = 0,
  }) async {
    final db = await _db;
    final results = await db.query(
      AppConstants.tableNotifications,
      where: 'packageName = ?',
      whereArgs: [packageName],
      orderBy: 'timestamp DESC',
      limit: limit,
      offset: offset,
    );
    return results.map((m) => NotificationRecord.fromMap(m)).toList();
  }

  @override
  Future<List<NotificationRecord>> search(
    String query, {
    int limit = 50,
    int offset = 0,
  }) async {
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
    final db = await _db;
    final whereClauses = <String>[];
    final whereArgs = <dynamic>[];

    // Search query on title, content, appName, packageName
    if (query != null && query.trim().isNotEmpty) {
      final pattern = '%${query.trim()}%';
      whereClauses.add('(title LIKE ? OR content LIKE ? OR appName LIKE ? OR packageName LIKE ?)');
      whereArgs.addAll([pattern, pattern, pattern, pattern]);
    }

    // Category filter
    if (category != null) {
      whereClauses.add('category = ?');
      whereArgs.add(category.name);
    }

    // Package name filter
    if (packageName != null && packageName.trim().isNotEmpty) {
      whereClauses.add('packageName = ?');
      whereArgs.add(packageName.trim());
    }

    // Favorite filter
    if (isFavorite != null) {
      whereClauses.add('isFavorite = ?');
      whereArgs.add(isFavorite ? 1 : 0);
    }

    // Read/Unread filter
    if (isRead != null) {
      whereClauses.add('isRead = ?');
      whereArgs.add(isRead ? 1 : 0);
    }

    // Date range filter
    if (startTime != null) {
      whereClauses.add('timestamp >= ?');
      whereArgs.add(startTime);
    }
    if (endTime != null) {
      whereClauses.add('timestamp <= ?');
      whereArgs.add(endTime);
    }

    final whereString = whereClauses.isNotEmpty ? whereClauses.join(' AND ') : null;

    final results = await db.query(
      AppConstants.tableNotifications,
      where: whereString,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: 'timestamp DESC',
      limit: limit,
      offset: offset,
    );

    return results.map((m) => NotificationRecord.fromMap(m)).toList();
  }

  @override
  Future<int> toggleFavorite(int id, bool isFavorite) async {
    final db = await _db;
    return await db.update(
      AppConstants.tableNotifications,
      {'isFavorite': isFavorite ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<int> markAsRead(int id) async {
    final db = await _db;
    return await db.update(
      AppConstants.tableNotifications,
      {'isRead': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<int> markAsUnread(int id) async {
    final db = await _db;
    return await db.update(
      AppConstants.tableNotifications,
      {'isRead': 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<int> markAllAsRead() async {
    final db = await _db;
    return await db.update(
      AppConstants.tableNotifications,
      {'isRead': 1},
      where: 'isRead = 0',
    );
  }

  @override
  Future<int> deleteById(int id) async {
    final db = await _db;
    return await db.delete(
      AppConstants.tableNotifications,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<int> getTotalCount() async {
    final db = await _db;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM ${AppConstants.tableNotifications}');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  @override
  Future<int> getTodayCount() async {
    final db = await _db;
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day).millisecondsSinceEpoch;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM ${AppConstants.tableNotifications} WHERE timestamp >= ?',
      [startOfDay],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  @override
  Future<int> getFavoriteCount() async {
    final db = await _db;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM ${AppConstants.tableNotifications} WHERE isFavorite = 1',
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  @override
  Future<int> getUnreadCount() async {
    final db = await _db;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM ${AppConstants.tableNotifications} WHERE isRead = 0',
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  @override
  Future<int> getCountByDateRange(int startTime, int endTime) async {
    final db = await _db;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM ${AppConstants.tableNotifications} WHERE timestamp >= ? AND timestamp <= ?',
      [startTime, endTime],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  @override
  Future<Map<String, int>> getDailyCountsLast7Days() async {
    final db = await _db;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final Map<String, int> dailyCounts = {};
    for (int i = 6; i >= 0; i--) {
      final date = today.subtract(Duration(days: i));
      final dateKey = '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      dailyCounts[dateKey] = 0;
    }

    final sevenDaysAgoMs = today.subtract(const Duration(days: 6)).millisecondsSinceEpoch;
    final results = await db.rawQuery('''
      SELECT date(timestamp / 1000, 'unixepoch', 'localtime') as day, COUNT(*) as count
      FROM ${AppConstants.tableNotifications}
      WHERE timestamp >= ?
      GROUP BY day
    ''', [sevenDaysAgoMs]);

    for (final row in results) {
      final day = row['day'] as String?;
      final count = row['count'] as int? ?? 0;
      if (day != null && dailyCounts.containsKey(day)) {
        dailyCounts[day] = count;
      }
    }

    return dailyCounts;
  }

  @override
  Future<Map<NotificationCategory, int>> getCategoryCounts() async {
    final db = await _db;
    final results = await db.rawQuery(
      'SELECT category, COUNT(*) as count FROM ${AppConstants.tableNotifications} GROUP BY category',
    );

    final map = <NotificationCategory, int>{};
    // Initialize all 11 categories with 0 by default
    for (final cat in NotificationCategory.values) {
      map[cat] = 0;
    }

    for (final row in results) {
      final cat = NotificationCategory.fromString(row['category'] as String?);
      map[cat] = row['count'] as int? ?? 0;
    }
    return map;
  }

  @override
  Future<List<TrackedApp>> getTrackedApps() async {
    final db = await _db;
    final results = await db.rawQuery('''
      SELECT packageName, appName, COUNT(*) as count, MAX(timestamp) as lastTime
      FROM ${AppConstants.tableNotifications}
      GROUP BY packageName
      ORDER BY count DESC
    ''');

    return results.map((row) {
      return TrackedApp(
        packageName: row['packageName'] as String? ?? '',
        appName: row['appName'] as String? ?? 'App',
        notificationCount: row['count'] as int? ?? 0,
        lastTimestamp: row['lastTime'] as int? ?? 0,
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
    final db = await _db;
    final minTime = currentTimestamp - windowMs;
    final maxTime = currentTimestamp + windowMs;

    String whereClause = 'packageName = ? AND timestamp >= ? AND timestamp <= ?';
    List<dynamic> whereArgs = [packageName, minTime, maxTime];

    if (title != null) {
      whereClause += ' AND title = ?';
      whereArgs.add(title);
    } else {
      whereClause += ' AND title IS NULL';
    }

    if (content != null) {
      whereClause += ' AND content = ?';
      whereArgs.add(content);
    } else {
      whereClause += ' AND content IS NULL';
    }

    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM ${AppConstants.tableNotifications} WHERE $whereClause',
      whereArgs,
    );

    final count = Sqflite.firstIntValue(result) ?? 0;
    return count > 0;
  }

  @override
  Future<int> deleteAll() async {
    final db = await _db;
    return await db.delete(AppConstants.tableNotifications);
  }
}
