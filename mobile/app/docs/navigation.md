# Navigation

GoRouter composition lives in `lib/navigation/`.

## Routes

| Route | Path | Role |
| --- | --- | --- |
| `LaunchRoute` | `/launch` | Splash. Redirects to the catalog when the launch gate is ready. `trackAnalytics` is off |
| `CharactersRoute` | `/characters` | Paged catalog. Stays on the stack under details |
| `CharacterDetailsRoute` | `/characters/:characterId` | Child of the catalog (`:characterId`). The page loads that id through `ObserveCharacterUseCase` |
| `BadRoutePageRoute` | `/404` | Unknown locations. Home calls `CharactersRoute.go()` |

`LaunchRouterGate` is the router's `refreshListenable` and `redirect`. Until launch completes, every location except `/404` stays on `/launch`.

Detail uses `push`, not `go`, so the catalog route, its bloc, the query, and the scroll position stay underneath. Pop returns to that same page. `onException` sends unknown locations to `/404`.

`AnalyticsNavigationTracker` reports `Analytics.screen` for routes with `trackAnalytics` (the default). It skips a repeat of the same route name and matched location.
