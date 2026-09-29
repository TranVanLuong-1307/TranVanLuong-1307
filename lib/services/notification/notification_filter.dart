import '../../core/utils/app_logger.dart';
import '../../core/utils/text_normalizer.dart';
import '../../models/notification_data.dart';

class FilterResult {
  final bool isAccepted;
  final String reason;

  const FilterResult({required this.isAccepted, required this.reason});

  static const FilterResult accepted = FilterResult(isAccepted: true, reason: 'Accepted');
  static const FilterResult trackingDisabled = FilterResult(isAccepted: false, reason: 'Tracking is disabled by user');
  static const FilterResult removedEvent = FilterResult(isAccepted: false, reason: 'Event represents a removed/dismissed notification');
  static const FilterResult emptyData = FilterResult(isAccepted: false, reason: 'Notification title and content are both empty');
  static const FilterResult selfApp = FilterResult(isAccepted: false, reason: 'Self notification originating from Notification Insight itself');
  static const FilterResult systemOngoing = FilterResult(
    isAccepted: false,
    reason: 'Ongoing system/hardware status notification (charging, USB debugging, etc.)',
  );
}

abstract class INotificationFilter {
  FilterResult evaluate(NotificationData data, {bool isTrackingEnabled = true});
  bool shouldProcess(NotificationData data, {bool isTrackingEnabled = true});
}

class NotificationFilter implements INotificationFilter {
  static const String _tag = 'NotificationFilter';
  static const String _selfPackage = 'com.notificationinsight.notification_insight';

  static const Set<String> _systemPackages = {
    'android',
    'com.android.systemui',
    'com.google.android.systemui',
  };

  static const List<String> _hardwareStatusKeywords = [
    'charging',
    'cable charging',
    'fast charging',
    'super fast charging',
    'slow charging',
    'wireless charging',
    'fully charged',
    'battery full',
    'dang sac',
    'sac pin',
    'sac nhanh',
    'sac khong day',
    'da sac day',
    'pin day',
    'usb debugging',
    'go loi usb',
    'usb connected',
    'ket noi usb',
    'charging connected device',
    'dang sac thiet bi',
    'usb for file transfer',
    'truyen file qua usb',
  ];

  @override
  FilterResult evaluate(NotificationData data, {bool isTrackingEnabled = true}) {
    // 1. Check user tracking toggle
    if (!isTrackingEnabled) {
      AppLogger.debug(_tag, 'Filter rejected: Tracking is disabled');
      return FilterResult.trackingDisabled;
    }

    // 2. Reject removed/dismissed events
    if (data.isRemoved) {
      AppLogger.debug(_tag, 'Filter rejected: Dismissed event for pkg: ${data.packageName}');
      return FilterResult.removedEvent;
    }

    // 3. Reject notifications with no readable text
    if (data.isEmpty) {
      AppLogger.debug(_tag, 'Filter rejected: Empty notification from pkg: ${data.packageName}');
      return FilterResult.emptyData;
    }

    // 4. Reject notifications from this app itself to avoid infinite feedback loop
    if (data.packageName == _selfPackage) {
      AppLogger.debug(_tag, 'Filter rejected: Self notification from $_selfPackage');
      return FilterResult.selfApp;
    }

    // 5. Reject ongoing system & hardware status notifications (charging, USB debugging, etc.)
    final pkg = data.packageName.toLowerCase();
    final isSystemPackage = _systemPackages.contains(pkg) || pkg == 'android';
    final combinedText = '${data.title ?? ''} ${data.content ?? ''}';

    if (isSystemPackage) {
      // Reject ongoing notifications from Android / SystemUI
      if (data.isOngoing) {
        AppLogger.debug(_tag, 'Filter rejected: Ongoing system notification from $pkg');
        return FilterResult.systemOngoing;
      }

      // Reject hardware status updates (charging, battery full, USB debugging)
      if (TextNormalizer.containsAny(combinedText, _hardwareStatusKeywords)) {
        AppLogger.debug(_tag, 'Filter rejected: System hardware/charging notification: "${data.title}"');
        return FilterResult.systemOngoing;
      }
    } else {
      // Non-system packages: reject if ongoing AND contains charging/battery status
      if (data.isOngoing && TextNormalizer.containsAny(combinedText, _hardwareStatusKeywords)) {
        AppLogger.debug(_tag, 'Filter rejected: Ongoing charging notification from $pkg');
        return FilterResult.systemOngoing;
      }
    }

    // Accept all valid notifications from all categories
    AppLogger.debug(_tag, 'Filter accepted: pkg=${data.packageName}, title="${data.title}"');
    return FilterResult.accepted;
  }

  @override
  bool shouldProcess(NotificationData data, {bool isTrackingEnabled = true}) {
    return evaluate(data, isTrackingEnabled: isTrackingEnabled).isAccepted;
  }
}
