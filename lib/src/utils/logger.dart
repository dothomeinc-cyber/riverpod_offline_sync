import 'package:flutter/foundation.dart';

class OfflineLogger {
  static bool isEnabled = false;

  static void log(String message, {String? tag}) {
    if (!isEnabled) return;
    final prefix = tag != null ? '[$tag]' : '[OfflineSync]';
    debugPrint('$prefix $message');
  }

  static void info(String message) {
    log(message, tag: 'INFO');
  }

  static void warning(String message) {
    log(message, tag: 'WARNING');
  }

  static void error(String message,
      {Object? error, StackTrace? stackTrace}) {
    log(message, tag: 'ERROR');
    if (error != null) debugPrint('Error: $error');
    if (stackTrace != null) {
      debugPrint('StackTrace: $stackTrace');
    }
  }

  static void debug(String message) {
    if (isEnabled) {
      log(message, tag: 'DEBUG');
    }
  }
}
