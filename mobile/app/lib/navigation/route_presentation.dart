/// Built-in page transitions for [RickMortyTransitionPage].
enum RickMortyRouteTransition { defaultTransition, fade, launchFade, flip }

/// Presentation defaults for a route (also used when redirects cannot pass [MyRouteExtra]).
class RickMortyRoutePresentation {
  final RickMortyRouteTransition transition;
  final bool fullscreenDialog;

  const RickMortyRoutePresentation({
    this.transition = RickMortyRouteTransition.defaultTransition,
    this.fullscreenDialog = false,
  });

  RickMortyRoutePresentation copyWith({RickMortyRouteTransition? transition, bool? fullscreenDialog}) =>
      RickMortyRoutePresentation(
        transition: transition ?? this.transition,
        fullscreenDialog: fullscreenDialog ?? this.fullscreenDialog,
      );
}
