class AppConstants {
  AppConstants._();

  static const String appName = 'Notification Insight';
  static const String appVersion = '1.0.0';

  // Database
  static const String dbName = 'notification_insight.db';
  static const int dbVersion = 1;
  static const String tableNotifications = 'notifications';

  // SharedPreferences keys
  static const String keyTrackingEnabled = 'tracking_enabled';
  static const String keyFilterEmptyNotifications = 'filter_empty_notifications';
  static const String keyPrivacyMode = 'privacy_mode_enabled';

  // Default limits
  static const int defaultPageSize = 50;
  static const int recentNotificationsLimit = 5;
}
