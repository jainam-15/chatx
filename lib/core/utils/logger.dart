import 'dart:developer' as dev;
import '../config/env.dart';

enum LogLevel {
  debug,
  info,
  warning,
  error,
}

class Logger {
  Logger._();

  static void log(
    LogLevel level,
    String tag,
    String message, [
    Object? error,
    StackTrace? stackTrace,
  ]) {
    if (!Env.isDebug && level == LogLevel.debug) return;

    final prefix = _getPrefix(level);
    final formattedMessage = '[$prefix][$tag] $message';

    if (error != null || stackTrace != null) {
      dev.log(
        formattedMessage,
        name: Env.appName,
        error: error,
        stackTrace: stackTrace,
        time: DateTime.now(),
      );
    } else {
      dev.log(
        formattedMessage,
        name: Env.appName,
        time: DateTime.now(),
      );
    }
  }

  static void debug(String tag, String message) {
    log(LogLevel.debug, tag, message);
  }

  static void info(String tag, String message) {
    log(LogLevel.info, tag, message);
  }

  static void warning(String tag, String message, [Object? error]) {
    log(LogLevel.warning, tag, message, error);
  }

  static void error(
    String tag,
    String message, [
    Object? error,
    StackTrace? stackTrace,
  ]) {
    log(LogLevel.error, tag, message, error, stackTrace);
  }

  static String _getPrefix(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return 'DEBUG ⚙️';
      case LogLevel.info:
        return 'INFO ℹ️';
      case LogLevel.warning:
        return 'WARN ⚠️';
      case LogLevel.error:
        return 'ERROR 🚨';
    }
  }
}
