# Startup

Process kickoff and leave-splash.

## Pipeline

1. `main` — `configureDependencies()`, then logging and analytics, then `StartAppBootstrapUseCase`. `AppConfig` is resolved from `--flavor` / `appFlavor` via DI.
2. Bootstrap repo — `start` resolves reachability and returns that same future on later calls. There is no session to restore.
3. `runApp` → `/launch` — Launch calls `LaunchRouterGate.completeLaunch` (awaits `start` + min splash).
4. Gate — `notifyListeners` → redirect leaves `/launch` for `/characters`.

## Ownership

- `main` owns process kickoff (`StartAppBootstrapUseCase`).
- The gate owns leave-splash (`completeLaunch`); do not call it from data / bootstrap.
