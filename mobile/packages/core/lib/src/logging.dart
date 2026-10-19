import 'dart:developer' as developer;

enum LogLevel { all, errors, nothing }

/// [developer.log] level used for records that carry an [error]. Matches `Level.SEVERE`.
const int logErrorLevel = 1000;

/// A destination for messages produced by [LoggerObject].
abstract interface class LogOutput {
  void write(String message, {Object? error, StackTrace? stackTrace});
}

/// Default output: [developer.log].
final class DeveloperLogOutput implements LogOutput {
  const DeveloperLogOutput();

  @override
  void write(String message, {Object? error, StackTrace? stackTrace}) {
    developer.log(message, error: error, stackTrace: stackTrace, level: error == null ? 0 : logErrorLevel);
  }
}

mixin LoggerObject {
  /// Destinations that every [LoggerObject] writes to. Empty until the app attaches outputs.
  // ignore: avoid-global-state
  static List<LogOutput> outputs = [];

  LogLevel get logLevel => LogLevel.all;

  String get logName;

  void log(String s, {Object? error, StackTrace? stackTrace}) {
    if (logLevel == LogLevel.nothing) {
      return;
    }
    if (logLevel == LogLevel.errors && error == null) {
      return;
    }

    final buffer = StringBuffer();
    final t = DateTime.now();
    buffer.write('[');
    buffer.write(t.hour.toString().padLeft(2, '0'));
    buffer.write(':');
    buffer.write(t.minute.toString().padLeft(2, '0'));
    buffer.write(':');
    buffer.write(t.second.toString().padLeft(2, '0'));
    buffer.write('.');
    buffer.write(t.millisecond.toString().padLeft(3, '0'));
    buffer.write('] ');
    buffer.write(logName);
    buffer.write(': ');
    buffer.write(s);
    final message = buffer.toString();
    for (final output in LoggerObject.outputs) {
      output.write(message, error: error, stackTrace: stackTrace);
    }
  }
}

final class _RootLogger with LoggerObject {
  @override
  String get logName => 'App';

  const _RootLogger();
}

/// Root logger for failures that have no owning [LoggerObject].
abstract final class AppLog {
  /// Records [error] and [stackTrace] through [LoggerObject.outputs].
  static void error(Object error, StackTrace stackTrace, {String message = 'Uncaught'}) {
    const _RootLogger().log(message, error: error, stackTrace: stackTrace);
  }
}
