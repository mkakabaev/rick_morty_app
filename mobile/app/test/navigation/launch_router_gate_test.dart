import 'dart:async';

import 'package:flutter/material.dart';

import 'package:app/features/app/domain/repositories/app_bootstrap_repository.dart';
import 'package:app/features/app/domain/use_cases/start_app_bootstrap.dart';
import 'package:app/navigation/launch_router_gate.dart';
import 'package:app/navigation/routes/bad_route_page.dart';
import 'package:app/navigation/routes/character_details.dart';
import 'package:app/navigation/routes/characters.dart';
import 'package:app/navigation/routes/launch.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  late _Bootstrap bootstrap;
  late LaunchRouterGate gate;
  late GoRouter router;
  late LaunchRoute launch;
  late CharactersRoute characters;
  late BadRoutePageRoute badRoute;

  setUp(() {
    bootstrap = _Bootstrap();
    launch = LaunchRoute();
    characters = CharactersRoute(CharacterDetailsRoute());
    badRoute = BadRoutePageRoute();
    gate = LaunchRouterGate(StartAppBootstrapUseCase(bootstrap), launch, characters, badRoute);
    router = GoRouter(initialLocation: launch.path, routes: [launch, characters, badRoute]);
    addTearDown(router.dispose);
    addTearDown(gate.dispose);
  });

  GoRouterState stateAt(String location) => GoRouterState(
    router.configuration,
    uri: Uri.parse(location),
    matchedLocation: location,
    fullPath: location,
    pathParameters: const {},
    pageKey: ValueKey(location),
  );

  testWidgets('before launch completes every location except /404 is sent to /launch', (tester) async {
    final context = await _context(tester);

    expect(gate.redirect(context, stateAt(launch.path)), isNull);
    expect(gate.redirect(context, stateAt(characters.path)), launch.path);
    expect(gate.redirect(context, stateAt('${characters.path}/1')), launch.path);
    expect(gate.redirect(context, stateAt(badRoute.path)), isNull);
  });

  testWidgets('completeLaunch waits for bootstrap, then notifies and leaves /launch', (tester) async {
    final context = await _context(tester);
    var notifications = 0;
    gate.addListener(() => notifications += 1);

    // testWidgets runs on a fake clock: timers and microtasks advance on pump(), not on await.
    var completed = false;
    unawaited(() async {
      await gate.completeLaunch(minSplash: Duration.zero);
      completed = true;
    }());
    await tester.pump(const Duration(milliseconds: 1));
    expect(completed, isFalse);
    expect(notifications, 0);
    expect(gate.redirect(context, stateAt(characters.path)), launch.path);

    bootstrap.finish();
    await tester.pump(const Duration(milliseconds: 1));

    expect(completed, isTrue);
    expect(notifications, 1);
    expect(gate.redirect(context, stateAt(launch.path)), characters.path);
    expect(gate.redirect(context, stateAt(characters.path)), isNull);
    expect(gate.redirect(context, stateAt(badRoute.path)), isNull);
  });

  testWidgets('completeLaunch is idempotent', (tester) async {
    await _context(tester);
    var notifications = 0;
    gate.addListener(() => notifications += 1);

    var completions = 0;
    Future<void> trackLaunch() async {
      await gate.completeLaunch(minSplash: Duration.zero);
      completions += 1;
    }

    unawaited(trackLaunch());
    unawaited(trackLaunch());
    bootstrap.finish();
    await tester.pump(const Duration(milliseconds: 1));
    unawaited(trackLaunch());
    await tester.pump(const Duration(milliseconds: 1));

    expect(completions, 3);
    expect(bootstrap.starts, 1);
    expect(notifications, 1);
  });
}

Future<BuildContext> _context(WidgetTester tester) async {
  late BuildContext captured;
  await tester.pumpWidget(
    Builder(
      builder: (context) {
        captured = context;
        return const SizedBox.shrink();
      },
    ),
  );
  return captured;
}

class _Bootstrap implements AppBootstrapRepository {
  // Created on first use so it belongs to the test's fake-async zone, not the setUp zone.
  Completer<void>? _started;
  var starts = 0;

  @override
  Future<void> start() {
    starts += 1;
    return (_started ??= Completer<void>()).future;
  }

  void finish() {
    final started = _started;
    if (started != null && !started.isCompleted) {
      started.complete();
    }
  }
}
