import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app/services/reachability/reachability_service+impl.dart';
import 'package:app/services/reachability/reachability_service.dart';

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

    final seen = <Reachability>[];
    final transitions = service.changes.listen(seen.add);
    addTearDown(transitions.cancel);

    await service.ready;
    expect(service.status.value, Reachability.offline);
    await Future<void>.delayed(Duration.zero);
    expect(seen, isEmpty);

    interfaces = [ConnectivityResult.wifi];
    changes.add([ConnectivityResult.wifi]);
    await _until(() => service.status.value == .online);
    await Future<void>.delayed(Duration.zero);
    expect(seen, [Reachability.online]);

    changes.add([ConnectivityResult.none]);
    await _until(() => service.status.value == .offline);
    await Future<void>.delayed(Duration.zero);
    expect(seen, [Reachability.online, Reachability.offline]);
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

    expect(service.status.value, Reachability.online);
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
