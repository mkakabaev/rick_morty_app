import 'package:core/core.dart';
import 'package:test/test.dart' hide Tags;

void main() {
  late List<LogOutput> previousOutputs;

  setUp(() {
    previousOutputs = AppLogTesting.outputs;
  });

  tearDown(() {
    AppLogTesting.outputs = previousOutputs;
  });

  test('writes the formatted line and error to every attached output', () {
    final first = _RecordingOutput();
    final second = _RecordingOutput();
    AppLogTesting.outputs = [first, second];

    final error = AppError('boom');
    const _Subject().log('hello', error: error);

    for (final output in [first, second]) {
      expect(output.messages, hasLength(1));
      expect(output.messages.single.$1, matches(r'^\[\d{2}:\d{2}:\d{2}\.\d{3}\] _LogSubject: hello$'));
      expect(output.messages.single.$2, same(error));
      expect(output.messages.single.$3, isNull);
    }
  });

  test('forwards the stack trace', () {
    final output = _RecordingOutput();
    AppLogTesting.outputs = [output];

    final error = StateError('boom');
    final stack = StackTrace.current;
    const _Subject().log('failed', error: error, stackTrace: stack);

    expect(output.messages.single.$2, same(error));
    expect(output.messages.single.$3, same(stack));
  });

  test('AppLog.error writes the error and stack through attached outputs', () {
    final output = _RecordingOutput();
    AppLogTesting.outputs = [output];

    final error = StateError('boom');
    final stack = StackTrace.current;
    AppLog.error(error, stack, message: 'Failed');

    expect(output.messages.single.$1, contains('App: Failed'));
    expect(output.messages.single.$2, same(error));
    expect(output.messages.single.$3, same(stack));
  });

  test('LogLevel.errors skips messages without an error', () {
    final output = _RecordingOutput();
    AppLogTesting.outputs = [output];

    const subject = _Subject(logLevel: LogLevel.errors);
    subject.log('ignored');
    subject.log('kept', error: AppError('x'));

    expect(output.messages, hasLength(1));
    expect(output.messages.single.$1, contains('kept'));
  });

  test('LogLevel.nothing drops every message', () {
    final output = _RecordingOutput();
    AppLogTesting.outputs = [output];

    const subject = _Subject(logLevel: LogLevel.nothing);
    subject.log('ignored');
    subject.log('also ignored', error: AppError('x'));

    expect(output.messages, isEmpty);
  });
}

final class _RecordingOutput implements LogOutput {
  final messages = <(String, Object?, StackTrace?)>[];

  @override
  void write(String message, {Object? error, StackTrace? stackTrace}) {
    messages.add((message, error, stackTrace));
  }
}

final class _Subject with Loggable {
  @override
  final LogLevel logLevel;

  @override
  Tags get logTags => const Tags('_LogSubject');

  const _Subject({this.logLevel = LogLevel.all});
}
