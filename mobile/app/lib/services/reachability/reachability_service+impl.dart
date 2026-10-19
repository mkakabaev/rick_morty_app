import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

import 'package:app/di/di.dart';
import 'package:core/core.dart';

import 'reachability_service.dart';

typedef ConnectivityResults = List<ConnectivityResult>;

@LazySingleton(as: ReachabilityService)
class ReachabilityServiceImpl implements ReachabilityService {
  final BehaviorSubject<Reachability> _status = BehaviorSubject();
  final PublishSubject<Reachability> _changes = PublishSubject();
  final Stream<ConnectivityResults> _connectivityChanges;
  final Future<ConnectivityResults> Function() _checkConnectivity;
  final _ready = Completer<void>();
  StreamSubscription<ConnectivityResults>? _subscription;
  var _streamReported = false;
  var _disposed = false;

  @override
  ValueStream<Reachability> get status => _status;

  @override
  Stream<Reachability> get changes => _changes;

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

  Future<void> _readCurrent() async {
    final results = await _checkConnectivity();
    if (!_streamReported) {
      _emit(_reachabilityFor(results));
    }
  }

  void _onConnectivity(ConnectivityResults results) {
    _streamReported = true;
    _emit(_reachabilityFor(results));
  }

  void _emit(Reachability value) {
    final changed = _status.hasValue && _status.value != value;
    _status.addDistinct(value);
    if (changed) {
      _changes.add(value);
    }
    _completeReady();
  }

  Reachability _reachabilityFor(ConnectivityResults results) {
    if (results.any((result) => result != .none)) {
      return .online;
    }
    return .offline;
  }
}
