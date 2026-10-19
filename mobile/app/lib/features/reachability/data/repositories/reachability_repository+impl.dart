import 'dart:async';

import 'package:app/di/di.dart';
import 'package:app/services/reachability/reachability_service.dart' as service;
import 'package:core/core.dart';

import '../../domain/entities/reachability.dart';
import '../../domain/repositories/reachability_repository.dart';

@LazySingleton(as: ReachabilityRepository)
class ReachabilityRepositoryImpl implements ReachabilityRepository {
  final BehaviorSubject<Reachability> _status;
  late final StreamSubscription<service.Reachability> _subscription;

  ReachabilityRepositoryImpl(service.ReachabilityService service)
    : _status = BehaviorSubject.seeded(_initial(service)) {
    _subscription = service.status.listen((value) {
      _status.addDistinct(_map(value));
    });
  }

  Future<void> dispose() async {
    await _subscription.cancel();
    await _status.close();
  }

  @override
  ValueStream<Reachability> observe() => _status.stream;

  static Reachability _initial(service.ReachabilityService service) {
    if (!service.status.hasValue) {
      return .online;
    }
    return _map(service.status.value);
  }

  static Reachability _map(service.Reachability value) {
    return switch (value) {
      service.Reachability.online => .online,
      service.Reachability.offline => .offline,
    };
  }
}
