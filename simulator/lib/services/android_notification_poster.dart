import 'package:flutter/services.dart';

abstract class IAndroidNotificationPoster {
  Future<bool> postNotification({
    required String? title,
    required String? content,
    int? notificationId,
  });
}

class AndroidNotificationPoster implements IAndroidNotificationPoster {
  static const MethodChannel _channel = MethodChannel('com.notificationinsight.simulator/native_notification');

  @override
  Future<bool> postNotification({
    required String? title,
    required String? content,
    int? notificationId,
  }) async {
    try {
      final result = await _channel.invokeMethod<bool>('postNotification', {
        'title': title,
        'content': content,
        'id': notificationId,
      });
      return result ?? true;
    } on MissingPluginException {
      // Running outside Android environment (e.g. unit tests or desktop)
      return true;
    } catch (e) {
      rethrow;
    }
  }
}
