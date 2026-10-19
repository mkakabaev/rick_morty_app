import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import 'package:app/di/di.dart';
import 'package:app/features/app/app.dart';

import 'routes/bad_route_page.dart';
import 'routes/characters.dart';
import 'routes/launch.dart';

/// Leaves the splash once bootstrap has finished, then sends `/launch` to the catalog.
@lazySingleton
class LaunchRouterGate extends ChangeNotifier {
  final StartAppBootstrapUseCase _startAppBootstrap;
  final LaunchRoute _launchRoute;
  final CharactersRoute _charactersRoute;
  final BadRoutePageRoute _badRoute;

  var _uiReady = false;
  Future<void>? _completeLaunchFuture;

  LaunchRouterGate(this._startAppBootstrap, this._launchRoute, this._charactersRoute, this._badRoute);

  /// Waits for bootstrap and [minSplash], then lets the router leave `/launch`.
  ///
  /// Safe to call more than once.
  Future<void> completeLaunch({Duration minSplash = const Duration(seconds: 2)}) {
    return _completeLaunchFuture ??= _completeLaunch(minSplash: minSplash);
  }

  Future<void> _completeLaunch({required Duration minSplash}) async {
    if (_uiReady) {
      return;
    }

    final splash = Future<void>.delayed(minSplash);
    await (_startAppBootstrap(), splash).wait;

    if (_uiReady) {
      return;
    }
    _uiReady = true;
    notifyListeners();
  }

  String? redirect(BuildContext _, GoRouterState state) {
    final location = state.matchedLocation;
    if (location == _badRoute.path) {
      return null;
    }
    if (!_uiReady) {
      if (location == _launchRoute.path) {
        return null;
      }
      return _launchRoute.path;
    }
    if (location == _launchRoute.path) {
      return _charactersRoute.path;
    }
    return null;
  }
}
