enum NotificationPriority {
  low,
  normal,
  high,
  urgent;

  String get displayName {
    switch (this) {
      case NotificationPriority.low:
        return 'Thấp';
      case NotificationPriority.normal:
        return 'Bình thường';
      case NotificationPriority.high:
        return 'Cao';
      case NotificationPriority.urgent:
        return 'Khẩn cấp';
    }
  }

  static NotificationPriority fromString(String? name) {
    if (name == null) return NotificationPriority.normal;
    return NotificationPriority.values.firstWhere(
      (p) => p.name.toLowerCase() == name.toLowerCase(),
      orElse: () => NotificationPriority.normal,
    );
  }
}
