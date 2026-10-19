import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'route_extra.dart';

class RickMortyRouter extends GoRouter {
  static late RickMortyRouter? _instance;

  static RickMortyRouter get instance {
    final instance = _instance;
    if (instance == null) {
      throw Exception('MyGoRouter not initialized');
    }
    return instance;
  }

  final void Function({required Uri uri}) onException;

  RickMortyRouter.createApp({
    required this.onException,
    required List<RouteBase> routes,
    required super.initialLocation,
    super.debugLogDiagnostics = false,
    super.refreshListenable,
    GoRouterRedirect? redirect,
  }) : super.routingConfig(
         onException: (_, state, _) => onException(uri: state.uri),
         routingConfig: ValueNotifier(
           RoutingConfig(routes: routes, redirect: redirect ?? (_, _) => null, redirectLimit: 5),
         ),
         extraCodec: const RickMortyRouteExtraCodec(),
         overridePlatformDefaultLocation: true,
       ) {
    _instance = this;
  }

  /// Clears the installed router so tests can create a fresh instance.
  @visibleForTesting
  static void debugReset() {
    _instance = null;
  }
}
