import '../core/enums/notification_category.dart';
import '../core/enums/notification_priority.dart';

class NotificationRecord {
  final int? id;
  final String packageName;
  final String appName;
  final String? title;
  final String? content;
  final NotificationCategory category;
  final NotificationPriority priority;
  final int timestamp;
  final bool isRead;
  final bool isFavorite;
  final int createdAt;

  const NotificationRecord({
    this.id,
    required this.packageName,
    required this.appName,
    this.title,
    this.content,
    required this.category,
    this.priority = NotificationPriority.normal,
    required this.timestamp,
    this.isRead = false,
    this.isFavorite = false,
    required this.createdAt,
  });

  DateTime get dateTime => DateTime.fromMillisecondsSinceEpoch(timestamp);
  DateTime get createdDateTime => DateTime.fromMillisecondsSinceEpoch(createdAt);

  NotificationRecord copyWith({
    int? id,
    String? packageName,
    String? appName,
    String? title,
    String? content,
    NotificationCategory? category,
    NotificationPriority? priority,
    int? timestamp,
    bool? isRead,
    bool? isFavorite,
    int? createdAt,
  }) {
    return NotificationRecord(
      id: id ?? this.id,
      packageName: packageName ?? this.packageName,
      appName: appName ?? this.appName,
      title: title ?? this.title,
      content: content ?? this.content,
      category: category ?? this.category,
      priority: priority ?? this.priority,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      isFavorite: isFavorite ?? this.isFavorite,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'packageName': packageName,
      'appName': appName,
      'title': title,
      'content': content,
      'category': category.name,
      'priority': priority.name,
      'timestamp': timestamp,
      'isRead': isRead ? 1 : 0,
      'isFavorite': isFavorite ? 1 : 0,
      'createdAt': createdAt,
    };
  }

  factory NotificationRecord.fromMap(Map<String, dynamic> map) {
    return NotificationRecord(
      id: map['id'] as int?,
      packageName: map['packageName'] as String? ?? '',
      appName: map['appName'] as String? ?? 'Unknown App',
      title: map['title'] as String?,
      content: map['content'] as String?,
      category: NotificationCategory.fromString(map['category'] as String?),
      priority: NotificationPriority.fromString(map['priority'] as String?),
      timestamp: map['timestamp'] as int? ?? DateTime.now().millisecondsSinceEpoch,
      isRead: (map['isRead'] as int? ?? 0) == 1,
      isFavorite: (map['isFavorite'] as int? ?? 0) == 1,
      createdAt: map['createdAt'] as int? ?? DateTime.now().millisecondsSinceEpoch,
    );
  }

  @override
  String toString() {
    return 'NotificationRecord(id: $id, app: $appName, title: $title, category: ${category.name})';
  }
}
