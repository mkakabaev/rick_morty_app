import 'dart:async';

import 'package:app/features/reachability/data/repositories/reachability_repository_impl.dart';
import 'package:app/features/reachability/domain/entities/reachability.dart';
import 'package:app/services/reachability/reachability_service.dart';
import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('maps the current service status and later changes', () async {
    final service = _Service(false);
    final repository = ReachabilityRepositoryImpl(service);
    addTearDown(repository.dispose);

    expect(repository.observe().value, Reachability.offline);

    service.emit(true);
    await Future<void>.delayed(Duration.zero);

    expect(repository.observe().value, Reachability.online);
  });

  test('stays online until the service reports a status', () async {
    final service = _Service(null);
    final repository = ReachabilityRepositoryImpl(service);
    addTearDown(repository.dispose);

    expect(repository.observe().value, Reachability.online);

    service.emit(false);
    await Future<void>.delayed(Duration.zero);

    expect(repository.observe().value, Reachability.offline);
  });
}

class _Service implements ReachabilityService {
  final BehaviorSubject<bool> _status;
  final _changes = StreamController<bool>.broadcast();

  _Service(bool? initial) : _status = BehaviorSubject<bool>(sync: true) {
    if (initial != null) {
      _status.add(initial);
    }
  }

  @override
  ValueStream<bool> get status => _status;

  @override
  Stream<bool> get changes => _changes.stream;

  @override
  Future<void> get ready => Future<void>.value();

  void emit(bool isOnline) {
    _status.add(isOnline);
    _changes.add(isOnline);
  }
}
