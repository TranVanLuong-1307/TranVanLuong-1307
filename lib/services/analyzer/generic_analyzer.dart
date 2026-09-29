import '../../core/enums/notification_category.dart';
import '../../core/enums/notification_priority.dart';
import '../../core/utils/app_name_resolver.dart';
import '../../core/utils/text_normalizer.dart';
import '../../models/notification_data.dart';
import '../../models/notification_record.dart';

abstract class IGenericAnalyzer {
  NotificationRecord analyze(NotificationData data, NotificationCategory category);
  String? extractOtpCode(String? text);
}

class GenericAnalyzer implements IGenericAnalyzer {
  // Regex extracting real OTP 4 to 8 digits following security keywords
  static final RegExp _otpCodeRegex = RegExp(
    r'(?:otp|xac\s+thuc|code|mat\s+khau)[^\d]*(\d{4,8})\b',
    caseSensitive: false,
  );

  @override
  String? extractOtpCode(String? text) {
    if (text == null || text.trim().isEmpty) return null;
    return TextNormalizer.extractFirstMatch(text, _otpCodeRegex, group: 1);
  }

  @override
  NotificationRecord analyze(NotificationData data, NotificationCategory category) {
    NotificationPriority priority = NotificationPriority.normal;

    switch (category) {
      case NotificationCategory.security:
        priority = NotificationPriority.urgent;
        break;
      case NotificationCategory.delivery:
        // Delivery alerts during active shipment are high priority
        priority = NotificationPriority.normal;
        break;
      case NotificationCategory.email:
        priority = NotificationPriority.normal;
        break;
      case NotificationCategory.system:
        final combined = '${data.title ?? ''} ${data.content ?? ''}';
        if (TextNormalizer.containsAny(combined, ['pin yeu', 'low battery', 'canh bao'])) {
          priority = NotificationPriority.high;
        } else {
          priority = NotificationPriority.normal;
        }
        break;
      case NotificationCategory.social:
      case NotificationCategory.entertainment:
        priority = NotificationPriority.low;
        break;
      case NotificationCategory.general:
      case NotificationCategory.other:
        priority = NotificationPriority.normal;
        break;
      default:
        priority = NotificationPriority.normal;
        break;
    }

    return NotificationRecord(
      packageName: data.packageName,
      appName: data.appName ?? AppNameResolver.resolve(data.packageName),
      title: data.title,
      content: data.content,
      category: category,
      priority: priority,
      timestamp: data.timestamp,
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );
  }
}
