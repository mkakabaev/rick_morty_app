import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:app/di/di.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:core/core.dart';

import 'reachability_service.dart';

typedef ConnectivityResults = List<ConnectivityResult>;

@LazySingleton(as: ReachabilityService)
class ReachabilityServiceImpl with Loggable implements ReachabilityService {
  final BehaviorSubject<bool> _status = BehaviorSubject();
  final PublishSubject<bool> _changes = PublishSubject();
  final Stream<ConnectivityResults> _connectivityChanges;
  final Future<ConnectivityResults> Function() _checkConnectivity;
  final _ready = Completer<void>();
  StreamSubscription<ConnectivityResults>? _subscription;
  var _streamReported = false;
  var _disposed = false;

  @override
  final Tags logTags = const Tags('ReachabilityService');

  @override
  ValueStream<bool> get status => _status;

  @override
  Stream<bool> get changes => _changes;

  @override
  Future<void> get ready => _ready.future;

  ReachabilityServiceImpl._({
    required Stream<ConnectivityResults> connectivityChanges,
    required Future<ConnectivityResults> Function() checkConnectivity,
  }) : _connectivityChanges = connectivityChanges,
       _checkConnectivity = checkConnectivity {
    _subscription = _connectivityChanges.listen(_onConnectivity);
    unawaited(_readCurrent());
  }

  factory ReachabilityServiceImpl() {
    final connectivity = Connectivity();
    return ReachabilityServiceImpl._(
      connectivityChanges: connectivity.onConnectivityChanged,
      checkConnectivity: connectivity.checkConnectivity,
    );
  }

  @visibleForTesting
  ReachabilityServiceImpl.forTest({
    required Stream<ConnectivityResults> connectivityChanges,
    required Future<ConnectivityResults> Function() checkConnectivity,
  }) : this._(connectivityChanges: connectivityChanges, checkConnectivity: checkConnectivity);

  @visibleForTesting
  void dispose() {
    if (_disposed) {
      return;
    }
    _disposed = true;
    _completeReady();
    unawaited(_subscription?.cancel());
    unawaited(_status.close());
    unawaited(_changes.close());
    _subscription = null;
  }

  void _completeReady() {
    if (!_ready.isCompleted) {
      _ready.complete();
    }
  }

  /// Reads the current interfaces once. A failed read must not leave [ready]
  /// pending (bootstrap awaits it), so it is reported as online and logged.
  Future<void> _readCurrent() async {
    bool isOnline;
    try {
      isOnline = _isOnline(await _checkConnectivity());
    } catch (error, stackTrace) {
      log('Connectivity read failed, assuming online', error: error, stackTrace: stackTrace);
      isOnline = true;
    }
    if (_disposed || _streamReported) {
      return;
    }
    _emit(isOnline);
  }

  void _onConnectivity(ConnectivityResults results) {
    _streamReported = true;
    _emit(_isOnline(results));
  }

  void _emit(bool isOnline) {
    final changed = _status.hasValue && _status.value != isOnline;
    _status.addDistinct(isOnline);
    if (changed) {
      _changes.add(isOnline);
    }
    _completeReady();
  }

  bool _isOnline(ConnectivityResults results) {
    return results.any((result) => result != .none);
  }
}
