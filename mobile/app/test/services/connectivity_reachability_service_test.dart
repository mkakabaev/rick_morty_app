import 'dart:async';

import 'package:app/services/reachability/reachability_service_impl.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('follows the network interface', () async {
    final changes = StreamController<ConnectivityResults>();
    var interfaces = <ConnectivityResult>[ConnectivityResult.none];
    final service = ReachabilityServiceImpl.forTest(
      connectivityChanges: changes.stream,
      checkConnectivity: () async => interfaces,
    );
    addTearDown(service.dispose);
    addTearDown(changes.close);

    final seen = <bool>[];
    final transitions = service.changes.listen(seen.add);
    addTearDown(transitions.cancel);

    await service.ready;
    expect(service.status.value, isFalse);
    await Future<void>.delayed(Duration.zero);
    expect(seen, isEmpty);

    interfaces = [ConnectivityResult.wifi];
    changes.add([ConnectivityResult.wifi]);
    await _until(() => service.status.value);
    await Future<void>.delayed(Duration.zero);
    expect(seen, [true]);

    changes.add([ConnectivityResult.none]);
    await _until(() => !service.status.value);
    await Future<void>.delayed(Duration.zero);
    expect(seen, [true, false]);
  });

  test('a failed startup read still completes ready and assumes online', () async {
    final changes = StreamController<ConnectivityResults>();
    final service = ReachabilityServiceImpl.forTest(
      connectivityChanges: changes.stream,
      checkConnectivity: () async => throw StateError('plugin missing'),
    );
    addTearDown(service.dispose);
    addTearDown(changes.close);

    await service.ready.timeout(const Duration(seconds: 2));

    expect(service.status.value, isTrue);

    changes.add([ConnectivityResult.none]);
    await _until(() => !service.status.value);
  });

  test('keeps a connectivity event that arrives during the startup read', () async {
    final changes = StreamController<ConnectivityResults>();
    final started = Completer<void>();
    final release = Completer<void>();
    final interfaces = <ConnectivityResult>[ConnectivityResult.none];
    final service = ReachabilityServiceImpl.forTest(
      connectivityChanges: changes.stream,
      checkConnectivity: () async {
        if (!started.isCompleted) {
          started.complete();
        }
        await release.future;
        return interfaces;
      },
    );
    addTearDown(service.dispose);
    addTearDown(changes.close);

    await started.future;
    changes.add([ConnectivityResult.wifi]);
    await service.ready;

    release.complete();
    await Future<void>.delayed(Duration.zero);

    expect(service.status.value, isTrue);
  });
}

Future<void> _until(bool Function() done) async {
  final deadline = DateTime.now().add(const Duration(seconds: 2));
  while (!done()) {
    if (DateTime.now().isAfter(deadline)) {
      fail('condition was not met');
    }
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
}
