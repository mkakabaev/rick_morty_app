import 'dart:async';

import 'package:flutter/material.dart';

import 'package:app/ui/ui.dart' show NavPresentation, NavTransition;
import 'package:go_router/go_router.dart';

import 'route_extra.dart';
import 'router.dart';
import 'transition_page.dart';

export 'package:app/ui/ui.dart' show NavPresentation, NavTransition;
export 'route_extra.dart' show AppRouteExtra;

class AppRoute extends GoRoute {
  final NavPresentation presentation;
  final bool trackAnalytics;

  AppRoute({
    required String name,
    required super.path,
    required GoRouterWidgetBuilder builder,
    super.routes,
    super.redirect,
    this.presentation = const NavPresentation(),
    this.trackAnalytics = true,
  }) : super(
         name: name,
         builder: builder,
         pageBuilder: (context, state) => NavTransitionPage(state, builder(context, state), presentation),
       );

  @override
  String get name {
    final name = super.name;
    if (name == null) {
      throw Exception('AppRoute name is null');
    }
    return name;
  }

  @protected
  void performGo({
    Map<String, String> pathParameters = const <String, String>{},
    Map<String, String> queryParameters = const <String, String>{},
    NavTransition? transition,
    bool? fullscreenDialog,
    Object? data,
  }) {
    router.goNamed(
      name,
      pathParameters: pathParameters,
      queryParameters: queryParameters,
      extra: _extra(transition: transition, fullscreenDialog: fullscreenDialog, data: data),
    );
  }

  @protected
  void performPush({
    Map<String, String> pathParameters = const <String, String>{},
    Map<String, String> queryParameters = const <String, String>{},
    NavTransition? transition,
    bool? fullscreenDialog,
    Object? data,
  }) {
    final location = router.namedLocation(name, pathParameters: pathParameters, queryParameters: queryParameters);
    final target = router.configuration.findMatch(Uri.parse(location));
    if (pushReentersShell(router.routerDelegate.currentConfiguration, target)) {
      // The shell is already under another pushed page. Pushing into it again
      // builds a second shell page with the same key and the navigator asserts.
      router.onException(uri: Uri.parse(location));
      return;
    }

    unawaited(
      router.pushNamed(
        name,
        pathParameters: pathParameters,
        queryParameters: queryParameters,
        extra: _extra(transition: transition, fullscreenDialog: fullscreenDialog, data: data),
      ),
    );
  }

  Object? _extra({NavTransition? transition, bool? fullscreenDialog, Object? data}) {
    if (transition == null && fullscreenDialog == null && data == null) {
      return null;
    }
    return AppRouteExtra(transition: transition, fullscreenDialog: fullscreenDialog, data: data);
  }

  @protected
  AppRouter get router => AppRouter.instance;
}

/// Whether [target] would place a shell page on the root navigator while that
/// same shell is already underneath the current page.
///
/// Pushing a shell route while that same shell is already underneath the current page
/// builds a second shell page with the same key.
@visibleForTesting
bool pushReentersShell(RouteMatchList current, RouteMatchList target) {
  if (target.isError || target.matches.isEmpty || current.matches.isEmpty) {
    return false;
  }
  final incoming = target.matches.last;
  if (incoming is! ShellRouteMatch) {
    return false;
  }
  if (current.matches.last.route == incoming.route) {
    return false;
  }
  return current.matches.any((match) => match.route == incoming.route);
}

///
/// A common way to add direct parameterless go() navigation. Add this mixin to your AppRoute's descendants
///
mixin ParameterlessRoute on AppRoute {
  void go({NavTransition? transition, bool? fullscreenDialog}) =>
      performGo(transition: transition, fullscreenDialog: fullscreenDialog);
}
