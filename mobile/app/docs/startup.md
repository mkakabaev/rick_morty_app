# Startup

Process kickoff and leave-splash.

## Pipeline

1. `main` — `AppLog.addOutput` / `Analytics.addProvider`, then `configureDependencies()`, then `StartAppBootstrapUseCase`. `AppConfig` is resolved from `--flavor` / `appFlavor` via DI; a missing or unknown flavor falls back to `Flavor.fallback` (`dev`) and is logged. Root widget is `App`.
2. Bootstrap repo — `start` resolves reachability and returns that same future on later calls. There is no session to restore. `ReachabilityService.ready` completes even when the platform read fails (it then reports online), so bootstrap cannot hang the splash.
3. `runApp` → `/launch` — Launch calls `LaunchRouterGate.completeLaunch` (awaits `start` + min splash).
4. Gate — `notifyListeners` → redirect leaves `/launch` for `/characters`.

## Ownership

- `main` owns process kickoff (`StartAppBootstrapUseCase`).
- The gate owns leave-splash (`completeLaunch`); do not call it from data / bootstrap.
