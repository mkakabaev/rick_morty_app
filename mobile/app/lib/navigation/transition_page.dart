import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'route_extra.dart';
import 'route_presentation.dart';

class RickMortyTransitionPage<T> extends Page<T> {
  /// Builds a page using [routePresentation] defaults, overridden by [RickMortyRouteExtra] on [state.extra].
  factory RickMortyTransitionPage(GoRouterState state, Widget child, RickMortyRoutePresentation routePresentation) {
    final extra = RickMortyRouteExtra.from(state.extra);
    final effectivePresentation = routePresentation.copyWith(
      transition: extra?.transition,
      fullscreenDialog: extra?.fullscreenDialog,
    );
    return RickMortyTransitionPage._(
      key: state.pageKey,
      child: child,
      transition: effectivePresentation.transition,
      fullscreenDialog: effectivePresentation.fullscreenDialog,
    );
  }

  const RickMortyTransitionPage._({
    required this.child,
    required this.transition,
    required this.fullscreenDialog,
    super.key,
  });

  final Widget child;
  final RickMortyRouteTransition transition;
  final bool fullscreenDialog;

  @override
  Route<T> createRoute(BuildContext context) => _RickMortyTransitionPageRoute<T>(this);
}

///
/// mixed with MaterialRouteTransitionMixin for 1) the default transition2, 2) be supported by native Material routes
///
class _RickMortyTransitionPageRoute<T> extends PageRoute<T> with MaterialRouteTransitionMixin<T> {
  static const _baseTransitionDuration = Duration(milliseconds: 300);

  _RickMortyTransitionPageRoute(RickMortyTransitionPage<T> page)
    : super(settings: page, fullscreenDialog: page.fullscreenDialog);

  RickMortyRouteTransition? _effectiveBackTransition;
  RickMortyRouteTransition get _transition => _page.transition;
  RickMortyTransitionPage<T> get _page => settings as RickMortyTransitionPage<T>;

  @override
  bool get barrierDismissible => false;

  @override
  Duration get transitionDuration => switch (_transition) {
    .launchFade => _baseTransitionDuration * 2,
    .defaultTransition || .fade || .flip => _baseTransitionDuration,
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
    if (nextRoute is _RickMortyTransitionPageRoute) {
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
