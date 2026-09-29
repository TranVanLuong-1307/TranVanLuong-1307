import '../../core/enums/notification_category.dart';
import '../../core/utils/app_logger.dart';
import '../../models/notification_data.dart';
import '../../models/notification_record.dart';
import 'category_classifier.dart';
import 'finance_analyzer.dart';
import 'generic_analyzer.dart';
import 'messaging_analyzer.dart';
import 'shopping_analyzer.dart';

abstract class INotificationAnalyzer {
  NotificationRecord? process(NotificationData data);
}

class NotificationAnalyzer implements INotificationAnalyzer {
  static const String _tag = 'NotificationAnalyzer';

  final ICategoryClassifier _classifier;
  final IFinanceAnalyzer _financeAnalyzer;
  final IShoppingAnalyzer _shoppingAnalyzer;
  final IMessagingAnalyzer _messagingAnalyzer;
  final IGenericAnalyzer _genericAnalyzer;

  NotificationAnalyzer({
    ICategoryClassifier? classifier,
    IFinanceAnalyzer? financeAnalyzer,
    IShoppingAnalyzer? shoppingAnalyzer,
    IMessagingAnalyzer? messagingAnalyzer,
    IGenericAnalyzer? genericAnalyzer,
  })  : _classifier = classifier ?? CategoryClassifier(),
        _financeAnalyzer = financeAnalyzer ?? FinanceAnalyzer(),
        _shoppingAnalyzer = shoppingAnalyzer ?? ShoppingAnalyzer(),
        _messagingAnalyzer = messagingAnalyzer ?? MessagingAnalyzer(),
        _genericAnalyzer = genericAnalyzer ?? GenericAnalyzer();

  @override
  NotificationRecord? process(NotificationData data) {
    if (data.isEmpty) {
      AppLogger.debug(_tag, 'Cannot process notification with empty title & content.');
      return null;
    }

    final category = _classifier.classify(data);
    NotificationRecord record;

    switch (category) {
      case NotificationCategory.finance:
        record = _financeAnalyzer.analyze(data);
        break;
      case NotificationCategory.shopping:
        record = _shoppingAnalyzer.analyze(data);
        break;
      case NotificationCategory.messaging:
        record = _messagingAnalyzer.analyze(data);
        break;
      default:
        record = _genericAnalyzer.analyze(data, category);
        break;
    }

    AppLogger.info(
      _tag,
      'Classification completed: pkg="${record.packageName}", app="${record.appName}", '
      'category=${record.category.displayName}, priority=${record.priority.displayName}',
    );

    return record;
  }
}
