/// Built-in page transitions for [NavTransitionPage].
enum NavTransition { defaultTransition, fade, launchFade, flip }

/// Presentation defaults for a route (also used when redirects cannot pass [AppRouteExtra]).
class NavPresentation {
  final NavTransition transition;
  final bool fullscreenDialog;

  const NavPresentation({this.transition = NavTransition.defaultTransition, this.fullscreenDialog = false});

  NavPresentation copyWith({NavTransition? transition, bool? fullscreenDialog}) => NavPresentation(
    transition: transition ?? this.transition,
    fullscreenDialog: fullscreenDialog ?? this.fullscreenDialog,
  );
}
