# Rick and Morty

Sample Flutter app for browsing and searching characters from the [Rick and Morty API](https://rickandmortyapi.com/documentation). Paginated catalog, name search, and a details screen that preserves list state on back.

https://github.com/user-attachments/assets/386b2efb-de33-4c80-89cc-e4789ebbbe3f

## What it demonstrates

**Feature-first Clean Architecture (FFCA) without feature packages.** Same module rules as a multi-package FFCA app (public API = entities + use cases; repositories private; cross-feature code depends on use cases, never another feature’s repository) — different packaging.

| | This app (folders) | Multi-package FFCA |
|---|---|---|
| Feature boundary | Folders under `mobile/app/lib/features/` + selective barrels (`foo.dart` / `foo_ui.dart`) | One pub package per feature under `mobile/packages/features/` |
| Enforcement | Convention and barrel exports | Pub package resolution (`resolution: workspace`) — illegal imports fail at resolve |
| Workspace | No Dart workspace; app is one package | Pub workspace: app + shared kits + every feature package |
| Shared kits | Mostly inside the app (`lib/ui/`, `lib/services/`, …); only a small path-dependent `core` kernel | Separate shared packages outside the app |
| Feature DI | App composition root registers everything | Each feature ships a `di/` injectable micro-package; app links modules |
| Cost | Fewer packages and less pub/DI wiring | Stronger isolation; more ceremony |

This sample is small enough that the folder layout keeps the CA shape without a workspace, per-feature packages, or kit/DI micro-package wiring. Multi-package FFCA pays that cost for hard boundaries and reusable kits; here the tradeoff favors a single app package. Details and the review checklist: [Clean Architecture](mobile/app/docs/clean-architecture.md).

**Screen state: `PageBloc` + page widget + `PageHost`.** Each screen is a `PageState` that owns a page-scoped `PageBloc` (Cubit). The page builds from bloc state; the bloc talks to the UI through `PageHost` (snackbars / host-level errors) instead of reaching into widgets.

**Dio + Retrofit; JSON (de)serialization on long-lived isolates (not `compute()` per call).** Encode/decode runs on shared `Worker` isolates reused across requests.

**Unreliable networking.** Reachability drives auto-update / resume when the device comes back online. HTTP `429` is retried for API calls and for image downloads before surfacing a busy-server error.

## Stack

Flutter / Dart. Screen state — `flutter_bloc`. Navigation — `go_router`. DI — `get_it` + `injectable`.

HTTP — `dio`, `retrofit`, `json_serializable`. Images — `cached_network_image` + `flutter_cache_manager`. Reachability — `connectivity_plus`. Also: `rxdart`, `equatable`.

## Run

```sh
cd mobile/app
flutter pub get
flutter run --flavor dev
```

Flavors are `dev`, `stage`, and `prod` (see `flavorizr.yaml`). A build started without `--flavor` falls back to `dev`. The Flutter version is pinned in `mobile/app/.fvmrc`; with [FVM](https://fvm.app) installed, prefix commands with `fvm`.

## Checks

```sh
cd mobile/app
flutter analyze && flutter test
cd ../packages/core && dart analyze && dart test
```

The same steps run in CI (`.github/workflows/ci.yml`), together with `mobile/scripts/format.zsh --check`.

## Docs

- [Clean Architecture](mobile/app/docs/clean-architecture.md) — also the source of truth and review checklist for the [review-clean-architecture](.cursor/skills/review-clean-architecture/SKILL.md) skill
- [Navigation](mobile/app/docs/navigation.md)
- [Startup](mobile/app/docs/startup.md)
- [HTTP client](mobile/app/docs/backend-client.md)
