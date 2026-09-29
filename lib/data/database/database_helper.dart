import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../../core/constants/app_constants.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB(AppConstants.dbName);
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: AppConstants.dbVersion,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE ${AppConstants.tableNotifications} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        packageName TEXT NOT NULL,
        appName TEXT NOT NULL,
        title TEXT,
        content TEXT,
        category TEXT NOT NULL,
        priority TEXT NOT NULL,
        timestamp INTEGER NOT NULL,
        isRead INTEGER NOT NULL DEFAULT 0,
        isFavorite INTEGER NOT NULL DEFAULT 0,
        createdAt INTEGER NOT NULL
      )
    ''');

    // Create indexes for faster filtering and sorting
    await db.execute(
      'CREATE INDEX idx_notifications_timestamp ON ${AppConstants.tableNotifications} (timestamp DESC)',
    );
    await db.execute(
      'CREATE INDEX idx_notifications_category ON ${AppConstants.tableNotifications} (category)',
    );
    await db.execute(
      'CREATE INDEX idx_notifications_package ON ${AppConstants.tableNotifications} (packageName)',
    );
  }

  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}
