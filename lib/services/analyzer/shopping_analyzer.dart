import '../../core/enums/notification_category.dart';
import '../../core/enums/notification_priority.dart';
import '../../core/utils/app_name_resolver.dart';
import '../../core/utils/text_normalizer.dart';
import '../../models/notification_data.dart';
import '../../models/notification_record.dart';

abstract class IShoppingAnalyzer {
  NotificationRecord analyze(NotificationData data);
  String? extractOrderId(String? text);
}

class ShoppingAnalyzer implements IShoppingAnalyzer {
  // Regex to extract real order identifier like "#123", "#SPX123456", "Đơn hàng #12345", "đơn hàng 892341"
  static final RegExp _orderIdRegex = RegExp(
    r'(?:#|(?:đơn|don)\s+(?:hàng|hang)\s+#?)([a-zA-Z0-9_-]{3,20})',
    caseSensitive: false,
  );

  @override
  String? extractOrderId(String? text) {
    if (text == null || text.trim().isEmpty) return null;
    return TextNormalizer.extractFirstMatch(text, _orderIdRegex, group: 1);
  }

  @override
  NotificationRecord analyze(NotificationData data) {
    final combined = '${data.title ?? ''} ${data.content ?? ''}'.trim();
    final orderId = extractOrderId(combined);

    // If an order ID exists or is a confirmed order, normal priority; promotional sales are low priority
    final priority = (orderId != null || TextNormalizer.containsAny(combined, ['xac nhan don hang', 'dat hang thanh cong']))
        ? NotificationPriority.normal
        : NotificationPriority.low;

    return NotificationRecord(
      packageName: data.packageName,
      appName: data.appName ?? AppNameResolver.resolve(data.packageName),
      title: data.title,
      content: data.content,
      category: NotificationCategory.shopping,
      priority: priority,
      timestamp: data.timestamp,
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );
  }
}
