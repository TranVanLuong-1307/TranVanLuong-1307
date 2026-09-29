import '../../core/enums/notification_category.dart';
import '../../core/enums/notification_priority.dart';
import '../../core/utils/app_name_resolver.dart';
import '../../core/utils/text_normalizer.dart';
import '../../models/notification_data.dart';
import '../../models/notification_record.dart';

abstract class IFinanceAnalyzer {
  NotificationRecord analyze(NotificationData data);
  String? extractAmount(String? text);
}

class FinanceAnalyzer implements IFinanceAnalyzer {
  // Regex to extract amount from Vietnamese financial notifications:
  // e.g. "200.000đ", "+500,000 VND", "1.500.000 d", "$25.50"
  // Regex to extract amount from financial notifications:
  // Supports both prefix ($25.50) and suffix (500.000đ, 200,000 VND, 1.500.000 d)
  static final RegExp _amountRegex = RegExp(
    r'(?:[\$€£¥]\s*[+-]?\s*\d{1,3}(?:[.,]\d{3})*(?:[.,]\d+)?|[+-]?\s*\d{1,3}(?:[.,]\d{3})*(?:[.,]\d+)?\s*(?:đ|vnd|dong|usd|\$))',
    caseSensitive: false,
  );

  @override
  String? extractAmount(String? text) {
    if (text == null || text.trim().isEmpty) return null;
    return TextNormalizer.extractFirstMatch(text, _amountRegex, group: 0)?.trim();
  }

  @override
  NotificationRecord analyze(NotificationData data) {
    final combined = '${data.title ?? ''} ${data.content ?? ''}'.trim();
    final amount = extractAmount(combined);

    // Financial balance fluctuations or payments are high priority; generic ads are normal
    final priority = (amount != null || TextNormalizer.containsAny(combined, ['bien dong', 'so du', 'chuyen khoan', 'giao dich']))
        ? NotificationPriority.high
        : NotificationPriority.normal;

    return NotificationRecord(
      packageName: data.packageName,
      appName: data.appName ?? AppNameResolver.resolve(data.packageName),
      title: data.title,
      content: data.content,
      category: NotificationCategory.finance,
      priority: priority,
      timestamp: data.timestamp,
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );
  }
}
