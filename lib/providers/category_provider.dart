import 'package:flutter/foundation.dart';
import '../../core/enums/notification_category.dart';
import '../../data/repositories/notification_repository.dart';

class CategoryProvider extends ChangeNotifier {
  final INotificationRepository _repository;

  Map<NotificationCategory, int> _categoryCounts = {};
  bool _isLoading = false;

  CategoryProvider({INotificationRepository? repository})
      : _repository = repository ?? NotificationRepository();

  Map<NotificationCategory, int> get categoryCounts => _categoryCounts;
  bool get isLoading => _isLoading;

  Future<void> loadCategoryStats() async {
    _isLoading = true;
    notifyListeners();

    try {
      _categoryCounts = await _repository.getCategoryCounts();
    } catch (_) {
      _categoryCounts = {};
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  int getCount(NotificationCategory category) {
    return _categoryCounts[category] ?? 0;
  }
}
