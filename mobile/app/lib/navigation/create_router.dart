import 'package:app/di/di.dart';

import 'analytics_navigation_tracker.dart';
import 'launch_router_gate.dart';
import 'router.dart';
import 'routes/bad_route_page.dart';
import 'routes/characters.dart';
import 'routes/launch.dart';

RickMortyRouter createAppRouter() {
  final launchGate = getIt<LaunchRouterGate>();
  final badRoute = getIt<BadRoutePageRoute>();

  final router = RickMortyRouter.createApp(
    onException: ({required Uri uri}) => badRoute.go(uri: uri),
    debugLogDiagnostics: true,
    initialLocation: getIt<LaunchRoute>().path,
    refreshListenable: launchGate,
    redirect: launchGate.redirect,
    routes: [getIt<LaunchRoute>(), getIt<CharactersRoute>(), badRoute],
  );
  AnalyticsNavigationTracker(router).start();
  return router;
}
