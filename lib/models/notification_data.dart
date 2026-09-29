class NotificationData {
  final String packageName;
  final String? appName;
  final String? title;
  final String? content;
  final int timestamp;
  final int? rawId;
  final bool isRemoved;
  final bool isOngoing;
  final bool canReply;
  final bool hasExtraPicture;
  final Map<String, dynamic> extraMetadata;

  const NotificationData({
    required this.packageName,
    this.appName,
    this.title,
    this.content,
    required this.timestamp,
    this.rawId,
    this.isRemoved = false,
    this.isOngoing = false,
    this.canReply = false,
    this.hasExtraPicture = false,
    this.extraMetadata = const {},
  });

  /// Check if the notification has no readable text content
  bool get isEmpty =>
      (title == null || title!.trim().isEmpty) &&
      (content == null || content!.trim().isEmpty);

  /// Check if the notification represents an active, readable notification
  bool get isValidToProcess => !isRemoved && !isEmpty;

  @override
  String toString() {
    return 'NotificationData(pkg: $packageName, title: $title, content: $content, time: $timestamp, removed: $isRemoved)';
  }
}
