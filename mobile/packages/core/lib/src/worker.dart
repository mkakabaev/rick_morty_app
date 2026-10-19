import 'dart:async';
import 'dart:isolate';
import 'dart:math';

import 'logging.dart';

/// A message handled on a [Worker] isolate.
///
/// [id] is fixed for this instance. A worker may run each instance only once
/// at a time; after that call finishes, the same instance can be sent again.
abstract class WorkerRequest<M extends Object?, R extends Object?> {
  static var _lastRequestId = 0;

  final int id;
  final M data;

  WorkerRequest({required this.data}) : id = _lastRequestId += 1;

  Future<R> handler();
}

/// Runs [WorkerRequest]s on one background isolate.
///
/// The request is the message, so it and every field it closes over must be
/// sendable. Handlers share that isolate's event loop: synchronous work in
/// [WorkerRequest.handler] does not run on extra cores.
///
/// [close] cancels in-flight work and kills the isolate.
class Worker {
  static Future<Worker> spawn({required String name}) async {
    final worker = Worker._(name);
    await worker._ensureStarted();
    return worker;
  }

  final String _name;
  bool _isClosed = false;
  bool _isAlive = false;
  Future<void>? _startFuture;
  _WorkerSpawn? _spawn;

  int get activeRequests => _spawn?.activeRequests ?? 0;
  int get maxActiveRequests => _spawn?.maxActiveRequests ?? 0;

  Worker._(this._name);

  void close() {
    if (_isClosed) {
      return;
    }
    _isClosed = true;

    final spawn = _spawn;
    if (spawn != null) {
      spawn.clean(error: _Err(StateError('Closed')));
      spawn.kill();
      _detachSpawn(spawn);
    }
  }

  Future<R> process<M, R>(WorkerRequest<M, R> request) async {
    _ensureNonClosed();
    await _ensureStarted();
    _ensureNonClosed();

    final spawn = _spawn;
    if (spawn == null) {
      throw StateError('Worker is not running');
    }
    return spawn.process(request);
  }

  void _ensureNonClosed() {
    if (_isClosed) {
      throw StateError('Closed');
    }
  }

  Future<void> _ensureStarted() {
    _ensureNonClosed();

    if (_isAlive) {
      return Future<void>.value();
    }

    return _startFuture ??= _start();
  }

  Future<void> _start() async {
    final spawn = _WorkerSpawn(_name);
    _spawn = spawn;

    try {
      await spawn.bootstrap(
        isClosed: () => _isClosed,
        onError: (_, _) => _detachSpawn(spawn),
        onExit: () => _detachSpawn(spawn),
      );
      _isAlive = true;
    } catch (error, stackTrace) {
      _detachSpawn(spawn);

      if (_isClosed) {
        return;
      }

      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  void _detachSpawn(_WorkerSpawn spawn) {
    if (!identical(_spawn, spawn)) {
      return;
    }
    _isAlive = false;
    _startFuture = null;
    _spawn = null;
  }
}

final class _WorkerSpawn {
  static void _startRemoteIsolate(SendPort sendPort) {
    final receivePort = ReceivePort();
    sendPort.send(receivePort.sendPort);

    receivePort.listen((Object? message) {
      _processMessage(sendPort, message as WorkerRequest);
    });
  }

  static void _processMessage(SendPort sendPort, WorkerRequest request) async {
    try {
      final result = await request.handler();
      sendPort.send((request.id, result));
    } catch (e, st) {
      // Same isolate group: send the thrown object and its stack. Not every
      // exception is sendable (native resources, some closures) — RemoteError
      // keeps the stack as a string in that case.
      try {
        sendPort.send((request.id, e, st));
      } catch (_) {
        try {
          sendPort.send((request.id, RemoteError('$e', '$st'), StackTrace.fromString('$st')));
        } catch (sendError, sendStack) {
          Error.throwWithStackTrace(sendError, sendStack);
        }
      }
    }
  }

  final String _name;
  final _requests = <int, Completer<Object?>>{};
  final _errorPort = ReceivePort();
  final _exitPort = ReceivePort();
  ReceivePort? _responsesPort;
  SendPort? _commands;
  Isolate? isolate;
  bool _fatalErrorReported = false;
  bool _isCleaned = false;
  int _maxActiveRequests = 0;
  Completer<(ReceivePort, SendPort)>? _connection;

  int get activeRequests => _requests.length;
  int get maxActiveRequests => _maxActiveRequests;

  _WorkerSpawn(this._name);

  Future<R> process<M, R>(WorkerRequest<M, R> request) async {
    final commands = _commands;
    if (commands == null) {
      throw StateError('Worker is not running');
    }

    if (_requests.containsKey(request.id)) {
      throw StateError('Request is already running');
    }

    final completer = Completer<Object?>();
    // Delivery is asynchronous, so the reply cannot arrive before the completer
    // is registered. Registering after send keeps a rejected payload out of the map.
    try {
      commands.send(request);
    } catch (error, stackTrace) {
      Error.throwWithStackTrace(error, stackTrace);
    }
    _requests[request.id] = completer;
    _maxActiveRequests = max(_maxActiveRequests, _requests.length);
    return await completer.future as R;
  }

  Future<void> bootstrap({
    required bool Function() isClosed,
    required void Function(Object error, StackTrace stackTrace) onError,
    required void Function() onExit,
  }) async {
    final connection = _connection = Completer<(ReceivePort, SendPort)>();
    // clean() may complete this before bootstrap is awaiting it.
    connection.future.ignore();

    _errorPort.listen((Object? message) {
      if (_fatalErrorReported) {
        return;
      }
      _fatalErrorReported = true;
      final err = _decodeIsolateError(message);
      // Fail waiters before onError detaches this spawn. Completers can resume
      // callers immediately, and those callers must observe a worker that can be restarted.
      clean(error: err, logMessage: 'unhandled error');
      onError(err.error, err.stackTrace);
    });

    _exitPort.listen((Object? _) {
      // A fatal error terminates the isolate too, and this event can be queued
      // ahead of the error event. Handle exit on a later turn so the original
      // error is still the one waiters and the log observe.
      unawaited(
        Future<void>(() {
          if (_isCleaned || _fatalErrorReported) {
            return;
          }
          clean(error: _Err(StateError('Isolate exited')), logMessage: 'unexpected exit');
          onExit();
        }),
      );
    });

    final initPort = RawReceivePort();
    initPort.handler = (Object? initialMessage) {
      if (connection.isCompleted) {
        _closeRawQuietly(initPort);
        return;
      }
      final commandPort = initialMessage as SendPort;
      connection.complete((ReceivePort.fromRawReceivePort(initPort), commandPort));
    };

    try {
      isolate = await Isolate.spawn(
        _startRemoteIsolate,
        initPort.sendPort,
        debugName: _name,
        onError: _errorPort.sendPort,
        onExit: _exitPort.sendPort,
      );

      final (receivePort, sendPort) = await connection.future;
      if (_isCleaned || isClosed()) {
        receivePort.close();
        throw StateError(isClosed() ? 'Closed' : '$_name isolate exited');
      }
      _responsesPort = receivePort;
      _commands = sendPort;
      _listenResponses(receivePort);
    } catch (error, stackTrace) {
      kill();
      clean(error: _Err(error, stackTrace));
      _closeRawQuietly(initPort);
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  void clean({required _Err error, String? logMessage}) {
    if (_isCleaned) {
      return;
    }
    _isCleaned = true;
    _commands = null;

    if (logMessage != null) {
      AppLog.error(error.error, error.stackTrace, message: '$_name isolate: $logMessage');
    }

    _closeQuietly(_responsesPort);
    _closeQuietly(_errorPort);
    _closeQuietly(_exitPort);

    _failRequests(error);

    // Unblock a handshake that is still waiting. A later failure cannot replace
    // this once the completer is done, so callers pass the real error in.
    final connection = _connection;
    if (connection != null && !connection.isCompleted) {
      error.applyToCompleter(connection);
    }
  }

  void _failRequests(_Err error) {
    final pending = _requests.values.toList();
    _requests.clear();
    for (final completer in pending) {
      if (!completer.isCompleted) {
        error.applyToCompleter(completer);
      }
    }
  }

  void _listenResponses(ReceivePort receivePort) {
    receivePort.listen((message) {
      switch (message) {
        // ignore: avoid-unrelated-type-assertions
        case (int id, Object? error, StackTrace stackTrace):
          final completer = _requests.remove(id);
          if (completer != null && !completer.isCompleted) {
            completer.completeError(error ?? StateError('$_name isolate failed'), stackTrace);
          }
        // ignore: avoid-unrelated-type-assertions
        case (int id, Object? value):
          final completer = _requests.remove(id);
          if (completer != null && !completer.isCompleted) {
            completer.complete(value);
          }
        default:
          final error = StateError('Unexpected worker message: $message');
          AppLog.error(error, StackTrace.current, message: '$_name isolate');
      }
    });
  }

  void kill() {
    isolate?.kill(priority: Isolate.immediate);
  }

  _Err _decodeIsolateError(Object? message) {
    // Isolate error is a list of two elements: the error and the stack trace.
    // https://api.dart.dev/dart-isolate/Isolate/addErrorListener.html
    if (message is List && message.length == 2) {
      final [errorText, stackText] = message;
      return _Err(RemoteError("$errorText", "$stackText"), StackTrace.fromString("$stackText"));
    }

    return _Err(StateError('Isolate error: $message'));
  }

  void _closeQuietly(ReceivePort? port) {
    try {
      port?.close();
    } on StateError {
      // Shutdown or an earlier failure already closed this port.
    }
  }

  void _closeRawQuietly(RawReceivePort port) {
    try {
      port.close();
    } on StateError {
      // The handshake port was already transferred or closed.
    }
  }
}

final class _Err {
  final Object error;
  final StackTrace stackTrace;

  _Err(this.error, [StackTrace? stackTrace]) : stackTrace = stackTrace ?? StackTrace.current;

  void applyToCompleter(Completer<Object?> completer) {
    completer.completeError(error, stackTrace);
  }
}
