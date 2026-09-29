import '../../core/enums/notification_category.dart';
import '../../core/enums/notification_priority.dart';
import '../../core/utils/app_name_resolver.dart';
import '../../core/utils/text_normalizer.dart';
import '../../models/notification_data.dart';
import '../../models/notification_record.dart';

abstract class IMessagingAnalyzer {
  NotificationRecord analyze(NotificationData data);
  String? extractSender(String? title, String? content);
}

class MessagingAnalyzer implements IMessagingAnalyzer {
  // Regex to extract sender name before a colon or phrase
  static final RegExp _senderColonRegex = RegExp(r'^([^:\n]{1,30}):', caseSensitive: false);
  static final RegExp _senderSentRegex = RegExp(r'^([^:\n]{1,30})\s+(?:đã gửi|da gui|sent you)', caseSensitive: false);

  @override
  String? extractSender(String? title, String? content) {
    if (title != null && title.trim().isNotEmpty) {
      // Often title in messaging apps is the sender's contact name
      final colonMatch = TextNormalizer.extractFirstMatch(title, _senderColonRegex, group: 1);
      if (colonMatch != null) return colonMatch;

      final sentMatch = TextNormalizer.extractFirstMatch(title, _senderSentRegex, group: 1);
      if (sentMatch != null) return sentMatch;

      // If title is just a person's name (short and doesn't contain app generic keywords)
      if (title.length <= 30 && !TextNormalizer.containsAny(title, ['zalo', 'messenger', 'tin nhan', 'message'])) {
        return title.trim();
      }
    }

    if (content != null && content.trim().isNotEmpty) {
      final colonMatch = TextNormalizer.extractFirstMatch(content, _senderColonRegex, group: 1);
      if (colonMatch != null) return colonMatch;

      final sentMatch = TextNormalizer.extractFirstMatch(content, _senderSentRegex, group: 1);
      if (sentMatch != null) return sentMatch;
    }

    return null;
  }

  @override
  NotificationRecord analyze(NotificationData data) {
    return NotificationRecord(
      packageName: data.packageName,
      appName: data.appName ?? AppNameResolver.resolve(data.packageName),
      title: data.title,
      content: data.content,
      category: NotificationCategory.messaging,
      priority: NotificationPriority.normal,
      timestamp: data.timestamp,
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );
  }
}
