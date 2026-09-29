import 'dart:async';
import 'package:notification_listener_service/notification_event.dart';
import 'package:notification_listener_service/notification_listener_service.dart';
import '../../core/utils/app_logger.dart';
import '../../models/notification_data.dart';

abstract class INotificationService {
  Stream<NotificationData> get notificationStream;
  bool get isListening;
  void startListening();
  void stopListening();
  void dispose();
}

class NotificationService implements INotificationService {
  static const String _tag = 'NotificationService';

  final _controller = StreamController<NotificationData>.broadcast();
  StreamSubscription<ServiceNotificationEvent>? _subscription;
  bool _isListening = false;

  @override
  Stream<NotificationData> get notificationStream => _controller.stream;

  @override
  bool get isListening => _isListening;

  @override
  void startListening() {
    if (_isListening) {
      AppLogger.debug(_tag, 'startListening called but service is already listening. Skipping.');
      return;
    }

    try {
      AppLogger.info(_tag, 'Subscribing to NotificationListenerService.notificationsStream...');

      _subscription = NotificationListenerService.notificationsStream.listen(
        (event) {
          _handleRawEvent(event);
        },
        onError: (error) {
          AppLogger.error(_tag, 'Stream error from NotificationListenerService', error);
        },
        onDone: () {
          AppLogger.info(_tag, 'Notification stream has finished/closed.');
          _isListening = false;
        },
        cancelOnError: false,
      );

      _isListening = true;
      AppLogger.info(_tag, 'Notification listener successfully started and active.');
    } catch (e) {
      AppLogger.error(_tag, 'Failed to initialize notificationsStream', e);
      _isListening = false;
    }
  }

  void _handleRawEvent(ServiceNotificationEvent event) {
    try {
      // Diagnostic log in development mode
      AppLogger.debug(
        _tag,
        'Incoming Raw Event: id=${event.id}, pkg="${event.packageName}", '
        'title="${event.title}", removed=${event.hasRemoved}, postTime=${event.timestamp}',
      );

      // Mapping with safe fallbacks
      final safePackage = event.packageName.trim().isNotEmpty
          ? event.packageName.trim()
          : 'unknown';

      final safeTitle = event.title.trim().isNotEmpty
          ? event.title.trim()
          : null;

      final safeContent = event.content.trim().isNotEmpty
          ? event.content.trim()
          : null;

      // Captured time: if Android postTime <= 0, capture device current time
      final capturedTime = event.timestamp > 0
          ? event.timestamp
          : DateTime.now().millisecondsSinceEpoch;

      final data = NotificationData(
        packageName: safePackage,
        title: safeTitle,
        content: safeContent,
        timestamp: capturedTime,
        rawId: event.id,
        isRemoved: event.hasRemoved,
        isOngoing: event.onGoing,
        canReply: event.canReply,
        hasExtraPicture: event.haveExtraPicture,
      );

      _controller.add(data);
    } catch (e) {
      AppLogger.error(_tag, 'Error mapping raw event to NotificationData', e);
    }
  }

  @override
  void stopListening() {
    if (!_isListening) return;

    AppLogger.info(_tag, 'Stopping notification listener...');
    _subscription?.cancel();
    _subscription = null;
    _isListening = false;
  }

  @override
  void dispose() {
    stopListening();
    _controller.close();
    AppLogger.debug(_tag, 'NotificationService disposed.');
  }
}
