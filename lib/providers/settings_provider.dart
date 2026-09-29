import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/app_logger.dart';
import '../../services/notification/notification_permission_service.dart';

class SettingsProvider extends ChangeNotifier {
  static const String _tag = 'SettingsProvider';
  final INotificationPermissionService _permissionService;

  bool _isPermissionGranted = false;
  bool _isTrackingEnabled = true;
  bool _isDarkMode = false;
  bool _isLoading = false;
  String? _errorMessage;

  SettingsProvider({
    INotificationPermissionService? permissionService,
  }) : _permissionService = permissionService ?? NotificationPermissionService();

  bool get isPermissionGranted => _isPermissionGranted;
  bool get isTrackingEnabled => _isTrackingEnabled;
  bool get isDarkMode => _isDarkMode;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> initSettings() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      _isTrackingEnabled = prefs.getBool(AppConstants.keyTrackingEnabled) ?? true;
      _isPermissionGranted = await _permissionService.isPermissionGranted();
      AppLogger.info(_tag, 'Settings initialized: tracking=$_isTrackingEnabled, permission=$_isPermissionGranted');
    } catch (e) {
      _errorMessage = 'Không thể tải cài đặt: $e';
      AppLogger.error(_tag, 'Failed to initialize settings', e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> checkPermission() async {
    try {
      final granted = await _permissionService.isPermissionGranted();
      if (_isPermissionGranted != granted) {
        _isPermissionGranted = granted;
        AppLogger.info(_tag, 'Permission status updated on check: $_isPermissionGranted');
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = 'Lỗi kiểm tra quyền: $e';
      AppLogger.error(_tag, 'Error checking permission', e);
      notifyListeners();
    }
  }

  Future<bool> requestPermission() async {
    try {
      final granted = await _permissionService.requestPermission();
      _isPermissionGranted = granted;
      notifyListeners();
      return granted;
    } catch (e) {
      _errorMessage = 'Lỗi yêu cầu quyền truy cập thông báo: $e';
      AppLogger.error(_tag, 'Error requesting permission', e);
      notifyListeners();
      return false;
    }
  }

  Future<void> setTrackingEnabled(bool enabled) async {
    _isTrackingEnabled = enabled;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(AppConstants.keyTrackingEnabled, enabled);
      AppLogger.info(_tag, 'Tracking state saved to SharedPreferences: $enabled');
    } catch (e) {
      _errorMessage = 'Không thể lưu trạng thái theo dõi: $e';
      AppLogger.error(_tag, 'Failed to save tracking preference', e);
      notifyListeners();
    }
  }

  void toggleTheme(bool isDark) {
    _isDarkMode = isDark;
    notifyListeners();
  }
}
