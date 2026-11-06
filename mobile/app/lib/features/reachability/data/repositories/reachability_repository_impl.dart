import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:app/di/di.dart';
import 'package:app/services/reachability/reachability_service.dart';
import 'package:core/core.dart';

import '../../domain/entities/reachability.dart';
import '../../domain/repositories/reachability_repository.dart';

@LazySingleton(as: ReachabilityRepository)
class ReachabilityRepositoryImpl implements ReachabilityRepository {
  final BehaviorSubject<Reachability> _status;
  late final StreamSubscription<bool> _subscription;

  ReachabilityRepositoryImpl(ReachabilityService service) : _status = BehaviorSubject.seeded(_initial(service)) {
    _subscription = service.status.listen((isOnline) {
      _status.addDistinct(_map(isOnline));
    });
  }

  @visibleForTesting
  Future<void> dispose() async {
    await _subscription.cancel();
    await _status.close();
  }

  @override
  ValueStream<Reachability> observe() => _status.stream;

  static Reachability _initial(ReachabilityService service) {
    if (!service.status.hasValue) {
      return .online;
    }
    return _map(service.status.value);
  }

  static Reachability _map(bool isOnline) {
    return isOnline ? .online : .offline;
  }
}
