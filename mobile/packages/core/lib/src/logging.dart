import 'dart:developer' as developer;

import 'package:meta/meta.dart';

import 'tags.dart';

enum LogLevel { all, errors, nothing }

/// A destination for messages produced by [Loggable].
abstract interface class LogOutput {
  void write(String message, {Object? error, StackTrace? stackTrace});
}

final class DeveloperLogOutput implements LogOutput {
  const DeveloperLogOutput();

  // [developer.log] level used for records that carry an [error]. Matches `Level.SEVERE`.
  static const int _logErrorLevel = 1000;

  @override
  void write(String message, {Object? error, StackTrace? stackTrace}) {
    developer.log(message, error: error, stackTrace: stackTrace, level: error == null ? 0 : _logErrorLevel);
  }
}

mixin Loggable {
  LogLevel get logLevel => LogLevel.all;

  Tags get logTags;

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
    buffer.write(']');

    final tags = logTags.toString();
    if (tags.isNotEmpty) {
      buffer.write(' ');
      buffer.write(tags);
      buffer.write(': ');
    } else {
      buffer.write(' ');
    }

    buffer.write(s);
    final message = buffer.toString();
    for (final output in AppLog._outputs) {
      output.write(message, error: error, stackTrace: stackTrace);
    }
  }
}

final class _RootLogger with Loggable {
  @override
  Tags get logTags => const Tags('App');

  const _RootLogger();
}

/// Global logging entry points and destinations shared by every [Loggable].
abstract final class AppLog {
  static final _outputs = <LogOutput>[];

  static void addOutput(LogOutput output) => _outputs.add(output);

  static void error(Object error, StackTrace stackTrace, {required String message}) {
    const _RootLogger().log(message, error: error, stackTrace: stackTrace);
  }
}

@visibleForTesting
extension AppLogTesting on AppLog {
  static List<LogOutput> get outputs => AppLog._outputs;

  static set outputs(List<LogOutput> value) => AppLog._outputs
    ..clear()
    ..addAll(value);
}
