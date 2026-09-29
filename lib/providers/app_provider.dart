import 'package:flutter/foundation.dart';
import '../../data/repositories/notification_repository.dart';
import '../../models/tracked_app.dart';

class AppProvider extends ChangeNotifier {
  final INotificationRepository _repository;

  List<TrackedApp> _trackedApps = [];
  bool _isLoading = false;

  AppProvider({INotificationRepository? repository})
      : _repository = repository ?? NotificationRepository();

  List<TrackedApp> get trackedApps => _trackedApps;
  bool get isLoading => _isLoading;

  Future<void> loadTrackedApps() async {
    _isLoading = true;
    notifyListeners();

    try {
      _trackedApps = await _repository.getTrackedApps();
    } catch (_) {
      _trackedApps = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  int get totalAppsCount => _trackedApps.length;
}
