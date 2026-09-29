import 'package:flutter/foundation.dart';

class AppLogger {
  AppLogger._();

  static bool isLoggingEnabled = kDebugMode;

  static void debug(String tag, String message) {
    if (isLoggingEnabled) {
      debugPrint('[$tag] $message');
    }
  }

  static void info(String tag, String message) {
    if (isLoggingEnabled) {
      debugPrint('ℹ️ [$tag] $message');
    }
  }

  static void warn(String tag, String message) {
    if (isLoggingEnabled) {
      debugPrint('⚠️ [$tag] $message');
    }
  }

  static void error(String tag, String message, [dynamic error]) {
    if (isLoggingEnabled) {
      debugPrint('❌ [$tag] $message ${error != null ? "($error)" : ""}');
    }
  }
}
