class TrackedApp {
  final String packageName;
  final String appName;
  final int notificationCount;
  final int lastTimestamp;
  final bool isTrackingEnabled;

  const TrackedApp({
    required this.packageName,
    required this.appName,
    this.notificationCount = 0,
    required this.lastTimestamp,
    this.isTrackingEnabled = true,
  });

  DateTime get lastReceivedTime =>
      DateTime.fromMillisecondsSinceEpoch(lastTimestamp);

  TrackedApp copyWith({
    String? packageName,
    String? appName,
    int? notificationCount,
    int? lastTimestamp,
    bool? isTrackingEnabled,
  }) {
    return TrackedApp(
      packageName: packageName ?? this.packageName,
      appName: appName ?? this.appName,
      notificationCount: notificationCount ?? this.notificationCount,
      lastTimestamp: lastTimestamp ?? this.lastTimestamp,
      isTrackingEnabled: isTrackingEnabled ?? this.isTrackingEnabled,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'packageName': packageName,
      'appName': appName,
      'notificationCount': notificationCount,
      'lastTimestamp': lastTimestamp,
      'isTrackingEnabled': isTrackingEnabled ? 1 : 0,
    };
  }

  factory TrackedApp.fromMap(Map<String, dynamic> map) {
    return TrackedApp(
      packageName: map['packageName'] as String? ?? '',
      appName: map['appName'] as String? ?? 'Unknown App',
      notificationCount: map['notificationCount'] as int? ?? 0,
      lastTimestamp: map['lastTimestamp'] as int? ?? 0,
      isTrackingEnabled: (map['isTrackingEnabled'] as int? ?? 1) == 1,
    );
  }
}
