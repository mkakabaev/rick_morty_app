import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';

import 'package:app/ui/ui.dart' show NavPresentation, NavTransition;
import 'package:go_router/go_router.dart';

import 'route_extra.dart';

class NavTransitionPage<T> extends Page<T> {
  /// Builds a page using [routePresentation] defaults, overridden by [AppRouteExtra] on [state.extra].
  factory NavTransitionPage(GoRouterState state, Widget child, NavPresentation routePresentation) {
    final extra = AppRouteExtra.from(state.extra);
    final effectivePresentation = routePresentation.copyWith(
      transition: extra?.transition,
      fullscreenDialog: extra?.fullscreenDialog,
    );
    return NavTransitionPage._(
      key: state.pageKey,
      child: child,
      transition: effectivePresentation.transition,
      fullscreenDialog: effectivePresentation.fullscreenDialog,
    );
  }

  const NavTransitionPage._({required this.child, required this.transition, required this.fullscreenDialog, super.key});

  final Widget child;
  final NavTransition transition;
  final bool fullscreenDialog;

  @override
  Route<T> createRoute(BuildContext context) => _TransitionPageRoute<T>(this);
}

///
/// mixed with MaterialRouteTransitionMixin for 1) the default transition2, 2) be supported by native Material routes
///
class _TransitionPageRoute<T> extends PageRoute<T> with MaterialRouteTransitionMixin<T> {
  _TransitionPageRoute(NavTransitionPage<T> page) : super(settings: page, fullscreenDialog: page.fullscreenDialog);

  NavTransition? _effectiveBackTransition;
  NavTransition get _transition => _page.transition;
  NavTransitionPage<T> get _page => settings as NavTransitionPage<T>;

  @override
  bool get barrierDismissible => false;

  @override
  Duration get transitionDuration => switch (_transition) {
    .defaultTransition => super.transitionDuration,
    .fade || .flip => const Duration(milliseconds: 300),
    .launchFade => const Duration(milliseconds: 600),
  };

  @override
  Duration get reverseTransitionDuration => switch (_transition) {
    .defaultTransition => super.reverseTransitionDuration,
    .fade || .flip => const Duration(milliseconds: 300),
    .launchFade => const Duration(milliseconds: 600),
  };

  @override
  bool get maintainState => true;

  @override
  Widget buildContent(BuildContext context) => throw UnimplementedError('Should not be called');

  @override
  Widget buildPage(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation) =>
      Semantics(scopesRoute: true, explicitChildNodes: true, child: _page.child);

  @override
  // ... dynamic came from the super class
  // ignore: avoid-dynamic
  bool canTransitionTo(TransitionRoute<dynamic> nextRoute) {
    if (nextRoute is _TransitionPageRoute) {
      switch (nextRoute._transition) {
        case .flip || .fade || .launchFade:
          _effectiveBackTransition = nextRoute._transition;
          return true;

        case .defaultTransition:
          break;
      }
      return !nextRoute.fullscreenDialog;
    }

    return super.canTransitionTo(nextRoute);
  }

  Widget _buildFadeTransition(Animation<double> animation, Widget child, [bool isBack = false]) {
    if (isBack) {
      return FadeTransition(
        opacity: Tween(begin: 1.0, end: 0.0).animate(CurvedAnimation(parent: animation, curve: Curves.linear)),
        child: child,
      );
    }
    return FadeTransition(
      opacity: CurveTween(curve: Curves.linear).animate(animation),
      child: child,
    );
  }

  Widget _buildFlipTransition(BuildContext context, Animation<double> animation, Widget child, [bool isBack = false]) {
    const tilt = 0.001;
    const curve = Curves.easeOut;
    final deepness = (MediaQuery.sizeOf(context).width * 0.75).clamp(50.0, 400.0);

    if (isBack) {
      return MatrixTransition(
        animation: CurvedAnimation(
          parent: animation,
          curve: Interval(0.0, 0.5, curve: curve.flipped),
        ),
        child: child,
        onTransform: (double value) {
          final angle = lerpDouble(0.0, pi / 2, value) ?? 0.0;
          final translate = lerpDouble(0.0, deepness, value) ?? 0.0;
          return Matrix4.identity()
            ..setEntry(3, 2, tilt)
            ..translateByDouble(0.0, 0.0, translate, 1.0)
            ..rotateY(angle);
        },
      );
    }
    return MatrixTransition(
      animation: CurvedAnimation(
        parent: animation,
        curve: const Interval(0.5, 1.0, curve: curve),
      ),
      child: child,
      onTransform: (double value) {
        final angle = lerpDouble(pi / 2, 0.0, value) ?? 0.0;
        final translate = lerpDouble(-deepness, 0.0, value) ?? 0.0;
        return Matrix4.identity()
          ..setEntry(3, 2, -tilt)
          ..translateByDouble(0.0, 0.0, translate, 1.0)
          ..rotateY(angle);
      },
    );
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    switch (_effectiveBackTransition) {
      case .flip:
        return _buildFlipTransition(context, secondaryAnimation, child, true);

      case .fade:
        return _buildFadeTransition(secondaryAnimation, child, true);

      // Keep the page underneath opaque so the navigator background does not show through.
      case .launchFade:
        return child;

      case null || .defaultTransition:
        break;
    }

    switch (_transition) {
      case .flip:
        return _buildFlipTransition(context, animation, child);

      case .fade || .launchFade:
        return _buildFadeTransition(animation, child);

      case .defaultTransition:
        return super.buildTransitions(context, animation, secondaryAnimation, child);
    }
  }
}
