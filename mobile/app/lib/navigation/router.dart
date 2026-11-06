import 'package:flutter/material.dart';

import 'package:go_router/go_router.dart';

import 'route_extra.dart';

class AppRouter extends GoRouter {
  static AppRouter? _instance;

  static AppRouter get instance {
    final instance = _instance;
    if (instance == null) {
      throw Exception('AppRouter not initialized');
    }
    return instance;
  }

  final void Function({required Uri uri}) onException;

  AppRouter.createApp({
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
         extraCodec: const AppRouteExtraCodec(),
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
