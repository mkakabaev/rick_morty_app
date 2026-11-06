import 'dart:async';

import 'package:app/features/app/data/repositories/app_bootstrap_repository_impl.dart';
import 'package:app/services/reachability/reachability_service.dart';
import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('start returns one future and waits until reachability has a status', () async {
    final reachability = _Reachability();
    final repository = AppBootstrapRepositoryImpl(reachability);
    final first = repository.start();
    final second = repository.start();

    expect(identical(first, second), isTrue);

    var started = false;
    unawaited(() async {
      await first;
      started = true;
    }());
    await Future<void>.delayed(Duration.zero);
    expect(started, isFalse);

    reachability.finish();
    await first;
    expect(started, isTrue);
  });
}

class _Reachability implements ReachabilityService {
  final _ready = Completer<void>();
  final _status = BehaviorSubject<bool>();

  @override
  ValueStream<bool> get status => _status;

  @override
  Stream<bool> get changes => const Stream.empty();

  @override
  Future<void> get ready => _ready.future;

  void finish() {
    _status.add(true);
    _ready.complete();
  }
}
