import 'package:core/core.dart';
import 'package:go_router/go_router.dart';

import 'route.dart';

/// Reports GoRouter navigation as [Analytics.screen] events.
final class AnalyticsNavigationTracker {
  AnalyticsNavigationTracker(this._router);

  final GoRouter _router;
  String? _lastScreenKey;

  void start() {
    _router.routerDelegate.addListener(_onNavigation);
  }

  void stop() {
    _router.routerDelegate.removeListener(_onNavigation);
  }

  void _onNavigation() {
    // Avoid [GoRouter.state] — it uses [RouteMatchList.last], which throws while
    // matches are empty (startup) or a shell has no leaf yet.
    final configuration = _router.routerDelegate.currentConfiguration;
    final RouteMatch? leaf;
    try {
      leaf = configuration.lastOrNull;
    } on StateError {
      return;
    }
    if (leaf == null) {
      return;
    }

    final route = leaf.route;
    if (route is! RickMortyRoute || !route.trackAnalytics) {
      return;
    }

    final name = route.name;
    final key = '$name:${leaf.matchedLocation}';
    if (key == _lastScreenKey) {
      return;
    }
    _lastScreenKey = key;

    Analytics.screen(name, properties: {'path': leaf.matchedLocation, ...configuration.pathParameters});
  }
}
