import 'dart:async';
import 'dart:isolate';

import 'package:core/core.dart';
import 'package:test/test.dart';

void main() {
  late List<LogOutput> previousOutputs;

  setUp(() {
    previousOutputs = LoggerObject.outputs;
  });

  tearDown(() {
    LoggerObject.outputs = previousOutputs;
  });

  test('handler errors stay on the future and are not logged as isolate failures', () async {
    final output = _RecordingOutput();
    LoggerObject.outputs = [output];

    final worker = await Worker.spawn(name: 'handler-errors');
    addTearDown(worker.close);

    await expectLater(worker.process(_ThrowRequest()), throwsA(isA<StateError>()));
    expect(output.messages, isEmpty);
    expect(await worker.process(_ValueRequest(7)), 7);
  });

  test('uncaught isolate errors fail in-flight work, are logged, and the worker restarts', () async {
    final output = _RecordingOutput();
    LoggerObject.outputs = [output];

    final worker = await Worker.spawn(name: 'uncaught');
    addTearDown(worker.close);

    await expectLater(worker.process(_HangAndBoom()).timeout(const Duration(seconds: 5)), throwsA(isA<RemoteError>()));
    expect(output.messages, isNotEmpty);
    expect(output.messages.single.$1, contains('uncaught isolate'));
    expect(output.messages.single.$2, isA<RemoteError>());
    expect(output.messages.single.$3, isNotNull);

    expect(await worker.process(_ValueRequest(3)), 3);
  });

  test('close cancels in-flight work and rejects later work', () async {
    final output = _RecordingOutput();
    LoggerObject.outputs = [output];

    final worker = await Worker.spawn(name: 'close-inflight');
    final pending = worker.process(_HangRequest());
    await _waitUntil(() => worker.activeRequests == 1);

    worker.close();
    worker.close();

    await expectLater(pending, throwsA(isA<StateError>().having((error) => error.message, 'message', 'Closed')));
    expect(worker.activeRequests, 0);
    expect(output.messages, isEmpty);
    await expectLater(worker.process(_ValueRequest(1)), throwsA(isA<StateError>()));
  });

  test('a request that cannot be sent fails that call and leaves the worker usable', () async {
    final worker = await Worker.spawn(name: 'unsendable');
    addTearDown(worker.close);

    final port = ReceivePort();
    addTearDown(port.close);

    await expectLater(worker.process(_UnsendableRequest(port)), throwsA(isA<ArgumentError>()));
    expect(worker.activeRequests, 0);
    expect(await worker.process(_ValueRequest(4)), 4);
  });

  test('handlers run on the named isolate and return data, including null', () async {
    final worker = await Worker.spawn(name: 'echo');
    addTearDown(worker.close);

    expect(await worker.process(_EchoRequest('ok')), 'ok');
    expect(await worker.process(_EchoRequest(null)), isNull);
    expect(await worker.process(_DebugNameRequest()), 'echo');
  });

  test('a synchronous handler failure stays on that future', () async {
    final worker = await Worker.spawn(name: 'sync-throw');
    addTearDown(worker.close);

    await expectLater(
      worker.process(_SyncThrowRequest()),
      throwsA(isA<StateError>().having((e) => e.message, 'message', 'sync')),
    );
    expect(worker.activeRequests, 0);
    expect(await worker.process(_ValueRequest(1)), 1);
  });

  test('handler failures keep the worker stack and do not cancel a sibling', () async {
    final worker = await Worker.spawn(name: 'sibling');
    addTearDown(worker.close);

    final failing = worker.process(_ThrowRequest());
    final sibling = worker.process(_ValueRequest(5));

    try {
      await failing;
      fail('expected StateError');
    } on StateError catch (error, stackTrace) {
      expect(error.message, 'nope');
      expect('$stackTrace', contains('_ThrowRequest.handler'));
    }
    expect(await sibling, 5);
    expect(worker.activeRequests, 0);
  });

  test('async handlers overlap, and the busiest overlap is remembered until restart', () async {
    final worker = await Worker.spawn(name: 'overlap');
    addTearDown(worker.close);

    final order = <int>[];
    Future<int> complete(int milliseconds) async {
      final value = await worker.process(_DelayRequest(milliseconds));
      order.add(value);
      return value;
    }

    final slow = complete(80);
    final fast = complete(10);
    await _waitUntil(() => worker.activeRequests == 2);

    expect(worker.maxActiveRequests, 2);
    await Future.wait([slow, fast]);
    expect(order, [10, 80]);
    expect(worker.activeRequests, 0);
    expect(worker.maxActiveRequests, 2);

    await expectLater(worker.process(_HangAndBoom()).timeout(const Duration(seconds: 5)), throwsA(isA<RemoteError>()));
    expect(worker.maxActiveRequests, 0);
    expect(await worker.process(_ValueRequest(1)), 1);
    expect(worker.maxActiveRequests, 1);
  });

  test('a record result is delivered as a value', () async {
    final worker = await Worker.spawn(name: 'record');
    addTearDown(worker.close);

    final (value, stackTrace) = await worker.process(_RecordRequest());
    expect(value, 4);
    expect(stackTrace, isA<StackTrace>());
  });

  test('a result that cannot be sent fails that call and leaves the worker usable', () async {
    final worker = await Worker.spawn(name: 'unsendable-result');
    addTearDown(worker.close);

    await expectLater(worker.process(_UnsendableResultRequest()), throwsA(isA<ArgumentError>()));
    expect(worker.activeRequests, 0);
    expect(await worker.process(_ValueRequest(2)), 2);
  });

  test('an exception that cannot be sent comes back as a remote error', () async {
    final output = _RecordingOutput();
    LoggerObject.outputs = [output];

    final worker = await Worker.spawn(name: 'unsendable-error');
    addTearDown(worker.close);

    await expectLater(
      worker.process(_ThrowUnsendableRequest()),
      throwsA(isA<RemoteError>().having((error) => '$error', 'text', contains('ReceivePort'))),
    );
    expect(output.messages, isEmpty);
    expect(worker.activeRequests, 0);
    expect(await worker.process(_ValueRequest(8)), 8);
  });

  test('the same request can run again after it finishes, but not while it is running', () async {
    final worker = await Worker.spawn(name: 'reuse');
    addTearDown(worker.close);

    final request = _ValueRequest(6);
    expect(await worker.process(request), 6);
    expect(await worker.process(request), 6);

    final hanging = _HangRequest();
    final pending = worker.process(hanging);
    await _waitUntil(() => worker.activeRequests == 1);

    await expectLater(
      worker.process(hanging),
      throwsA(isA<StateError>().having((error) => error.message, 'message', 'Request is already running')),
    );
    expect(worker.activeRequests, 1);
    expect(worker.maxActiveRequests, 1);

    worker.close();
    await expectLater(pending, throwsA(isA<StateError>().having((error) => error.message, 'message', 'Closed')));
  });

  test('close cancels every in-flight request', () async {
    final worker = await Worker.spawn(name: 'close-many');
    final first = worker.process(_HangRequest());
    final second = worker.process(_HangRequest());
    await _waitUntil(() => worker.activeRequests == 2);

    worker.close();

    await expectLater(first, throwsA(isA<StateError>().having((error) => error.message, 'message', 'Closed')));
    await expectLater(second, throwsA(isA<StateError>().having((error) => error.message, 'message', 'Closed')));
    expect(worker.activeRequests, 0);
    expect(worker.maxActiveRequests, 0);
  });

  test('killing the isolate fails in-flight work, is logged, and the worker restarts', () async {
    final output = _RecordingOutput();
    LoggerObject.outputs = [output];

    final worker = await Worker.spawn(name: 'killed');
    addTearDown(worker.close);

    final hanging = worker.process(_HangRequest());
    await _waitUntil(() => worker.activeRequests == 1);
    final killed = worker.process(_KillRequest());
    final results = Future.wait([
      expectLater(killed, throwsA(isA<StateError>().having((error) => error.message, 'message', 'Isolate exited'))),
      expectLater(hanging, throwsA(isA<StateError>().having((error) => error.message, 'message', 'Isolate exited'))),
    ]);

    await results;
    expect(output.messages.single.$1, contains('killed isolate: unexpected exit'));
    expect(output.messages.single.$2, isA<StateError>());
    expect(worker.activeRequests, 0);

    expect(await worker.process(_ValueRequest(9)), 9);
  });

  test('workers do not share an event loop', () async {
    final spinning = await Worker.spawn(name: 'spin');
    final other = await Worker.spawn(name: 'other');
    addTearDown(spinning.close);
    addTearDown(other.close);

    final ping = ReceivePort();
    addTearDown(ping.close);
    final started = Completer<void>();
    ping.listen((_) {
      if (!started.isCompleted) {
        started.complete();
      }
    });

    final slow = spinning.process(_SpinRequest(ping.sendPort));
    await started.future.timeout(const Duration(seconds: 5));

    final elapsed = Stopwatch()..start();
    expect(await other.process(_ValueRequest(9)), 9);
    expect(elapsed.elapsed, lessThan(const Duration(milliseconds: 200)));
    expect(await slow, 1);
  });
}

final class _RecordingOutput implements LogOutput {
  final messages = <(String, Object?, StackTrace?)>[];

  @override
  void write(String message, {Object? error, StackTrace? stackTrace}) {
    messages.add((message, error, stackTrace));
  }
}

final class _ValueRequest extends WorkerRequest<int, int> {
  _ValueRequest(int value) : super(data: value);

  @override
  Future<int> handler() async {
    return data;
  }
}

final class _ThrowRequest extends WorkerRequest<int, int> {
  _ThrowRequest() : super(data: 0);

  @override
  Future<int> handler() async {
    throw StateError('nope');
  }
}

final class _HangAndBoom extends WorkerRequest<int, int> {
  _HangAndBoom() : super(data: 0);

  @override
  Future<int> handler() {
    unawaited(Future<void>.error(StateError('boom')));
    return Completer<int>().future;
  }
}

final class _HangRequest extends WorkerRequest<int, int> {
  _HangRequest() : super(data: 0);

  @override
  Future<int> handler() => Completer<int>().future;
}

final class _UnsendableRequest extends WorkerRequest<ReceivePort, int> {
  _UnsendableRequest(ReceivePort port) : super(data: port);

  @override
  Future<int> handler() async => 0;
}

final class _EchoRequest extends WorkerRequest<String?, String?> {
  _EchoRequest(String? value) : super(data: value);

  @override
  Future<String?> handler() async => data;
}

final class _DebugNameRequest extends WorkerRequest<int, String> {
  _DebugNameRequest() : super(data: 0);

  @override
  Future<String> handler() async => Isolate.current.debugName ?? '';
}

final class _SyncThrowRequest extends WorkerRequest<int, int> {
  _SyncThrowRequest() : super(data: 0);

  @override
  Future<int> handler() {
    throw StateError('sync');
  }
}

final class _DelayRequest extends WorkerRequest<int, int> {
  _DelayRequest(int milliseconds) : super(data: milliseconds);

  @override
  Future<int> handler() async {
    await Future<void>.delayed(Duration(milliseconds: data));
    return data;
  }
}

final class _RecordRequest extends WorkerRequest<int, (int, StackTrace)> {
  _RecordRequest() : super(data: 4);

  @override
  Future<(int, StackTrace)> handler() async => (data, StackTrace.current);
}

final class _UnsendableResultRequest extends WorkerRequest<int, Object> {
  _UnsendableResultRequest() : super(data: 0);

  @override
  Future<Object> handler() async => ReceivePort();
}

final class _ThrowUnsendableRequest extends WorkerRequest<int, int> {
  _ThrowUnsendableRequest() : super(data: 0);

  @override
  Future<int> handler() async {
    throw ReceivePort();
  }
}

final class _KillRequest extends WorkerRequest<int, int> {
  _KillRequest() : super(data: 0);

  @override
  Future<int> handler() async {
    Isolate.current.kill(priority: Isolate.immediate);
    return 0;
  }
}

final class _SpinRequest extends WorkerRequest<SendPort, int> {
  _SpinRequest(SendPort ping) : super(data: ping);

  @override
  Future<int> handler() async {
    data.send(true);
    final watch = Stopwatch()..start();
    while (watch.elapsedMilliseconds < 400) {}
    return 1;
  }
}

Future<void> _waitUntil(bool Function() predicate) async {
  final deadline = DateTime.now().add(const Duration(seconds: 5));
  while (!predicate()) {
    if (DateTime.now().isAfter(deadline)) {
      fail('timed out waiting for worker');
    }
    await Future<void>.delayed(const Duration(milliseconds: 1));
  }
}
