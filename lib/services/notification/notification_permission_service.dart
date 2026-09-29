import 'dart:io';
import 'package:flutter/services.dart';
import 'package:notification_listener_service/notification_listener_service.dart';
import '../../core/utils/app_logger.dart';

abstract class INotificationPermissionService {
  Future<bool> isPermissionGranted();
  Future<bool> requestPermission();
  Future<bool> refreshPermissionStatus();
}

class NotificationPermissionService implements INotificationPermissionService {
  static const String _tag = 'NotificationPermissionService';

  @override
  Future<bool> isPermissionGranted() async {
    if (!Platform.isAndroid) {
      AppLogger.warn(_tag, 'Notification listener is only available on Android platform.');
      return false;
    }

    try {
      final granted = await NotificationListenerService.isPermissionGranted();
      AppLogger.debug(_tag, 'isPermissionGranted check result: $granted');
      return granted;
    } on PlatformException catch (e) {
      AppLogger.error(_tag, 'PlatformException while checking permission', e.message);
      return false;
    } catch (e) {
      AppLogger.error(_tag, 'Unexpected error while checking permission', e);
      return false;
    }
  }

  @override
  Future<bool> requestPermission() async {
    if (!Platform.isAndroid) {
      AppLogger.warn(_tag, 'Requesting permission ignored: Non-Android platform.');
      return false;
    }

    try {
      AppLogger.info(_tag, 'Requesting Notification Access permission from Android OS...');
      final result = await NotificationListenerService.requestPermission();
      AppLogger.info(_tag, 'requestPermission completed with result: $result');
      return result;
    } on PlatformException catch (e) {
      AppLogger.error(_tag, 'PlatformException while requesting permission', e.message);
      return false;
    } catch (e) {
      AppLogger.error(_tag, 'Unexpected error while requesting permission', e);
      return false;
    }
  }

  @override
  Future<bool> refreshPermissionStatus() async {
    return await isPermissionGranted();
  }
}
