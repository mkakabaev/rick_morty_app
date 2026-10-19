import 'dart:async';

import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app/features/reachability/data/repositories/reachability_repository+impl.dart';
import 'package:app/features/reachability/domain/entities/reachability.dart';
import 'package:app/services/reachability/reachability_service.dart' as connectivity;

void main() {
  test('maps the current service status and later changes', () async {
    final service = _Service(connectivity.Reachability.offline);
    final repository = ReachabilityRepositoryImpl(service);
    addTearDown(repository.dispose);

    expect(repository.observe().value, Reachability.offline);

    service.emit(connectivity.Reachability.online);
    await Future<void>.delayed(Duration.zero);

    expect(repository.observe().value, Reachability.online);
  });

  test('stays online until the service reports a status', () async {
    final service = _Service(null);
    final repository = ReachabilityRepositoryImpl(service);
    addTearDown(repository.dispose);

    expect(repository.observe().value, Reachability.online);

    service.emit(connectivity.Reachability.offline);
    await Future<void>.delayed(Duration.zero);

    expect(repository.observe().value, Reachability.offline);
  });
}

class _Service implements connectivity.ReachabilityService {
  final BehaviorSubject<connectivity.Reachability> _status;
  final _changes = StreamController<connectivity.Reachability>.broadcast();

  _Service(connectivity.Reachability? initial) : _status = BehaviorSubject<connectivity.Reachability>(sync: true) {
    if (initial != null) {
      _status.add(initial);
    }
  }

  @override
  ValueStream<connectivity.Reachability> get status => _status;

  @override
  Stream<connectivity.Reachability> get changes => _changes.stream;

  @override
  Future<void> get ready => Future<void>.value();

  void emit(connectivity.Reachability value) {
    _status.add(value);
    _changes.add(value);
  }
}
