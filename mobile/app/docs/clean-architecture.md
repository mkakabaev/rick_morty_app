# Clean Architecture — this app

This app uses **one** architecture: features are modules. A feature’s public API is the entities + use cases other modules need. Repositories are private to the module.

```txt
feature public API  =  exported entities + use cases  (foo.dart)   // selective
feature UI          =  pages + optional widgets       (foo_ui.dart)
feature private     =  repository interfaces, impls, feature DTOs, unexported domain
```

Inside a feature the folders are still `presentation` → use cases → own repository → `data` → `services`. That is how the module is built, not a second set of cross-feature rules.

## Folders

| Place | Role |
|---|---|
| `lib/features/{name}/domain/` | Entities, repository **interfaces**, use cases |
| `lib/features/{name}/data/` | Repository impls, feature-local DTOs |
| `lib/features/{name}/presentation/` | `Page` + `PageBloc` (Cubit) |
| `lib/features/{name}/{name}.dart` | Public API: entities + use cases other modules need (selective; not “export everything”) |
| `lib/features/{name}/{name}_ui.dart` | Pages, and optionally that feature’s shared widgets. Not blocs or routes |
| `lib/ui/` | Shared widgets, `PageState` / `PageBloc` / `PageHost`, `NavPresentation` / `NavTransition`, `AppImage` / `ImageCacheScope` |
| `lib/navigation/` | GoRouter composition: `AppRoute` / `AppRouter` ports, launch gate, `NavTransitionPage`, screen analytics |
| `lib/services/` | HTTP, images, connectivity. DTOs and service primitives, not feature entities |
| `lib/di/` | GetIt + injectable. Composition root |
| Packages workspace `core/` | Dart kernel: `Result`, `AppError`, `ValueState`, `Worker`, `Tags` / `Loggable` / `AppLog`, `Analytics`. No Flutter |

## Reachability as a feature

`lib/services/reachability/` is only the connectivity primitive (`ReachabilityService`: online as `bool`). Online/offline as product state lives in `features/reachability/`: a domain entity, repository, and `ObserveReachabilityUseCase`. Presentation and domain take that use case (and entity), not the service — same cross-feature rule as everywhere else. Feature data (including other features’ data) may still depend on `ReachabilityService`; the reachability feature maps the bool onto the domain entity. Presentation and domain never import `connectivity_plus` or `ReachabilityService`.

The service stays in `lib/services/` rather than under `features/reachability/data/` on purpose. Several features’ data layers need the raw link signal (characters reload-on-online, app bootstrap waits on `ready`), the same way they use `ApiClient` or `ImageService`. Putting connectivity inside the reachability feature would either export a private data source or force every consumer through that feature’s use cases. This monolith keeps shared wire primitives in `lib/services/`; the feature owns product `Reachability` for presentation/domain.

## Allowed dependencies

| From | May use | Must not use |
|---|---|---|
| Presentation | Own use cases + entities, other features’ **public barrels**, other features’ `*_ui.dart` **widgets**, `lib/ui`, `core`, route objects under `lib/navigation/routes/` and `LaunchRouterGate` (injected via `createBloc()`) | `data/`, `services/` internals, other features’ **pages**, the rest of `lib/navigation/` (`AppRouter`, `createAppRouter`) |
| Domain | `core`, Flutter, other features’ **entities** | `data/`, `services/`, GetIt lookups, pages, other features’ repositories |
| Data | Own domain, `services`, other features’ **use cases + entities** | Other features’ repositories, other features’ `*_ui.dart`, GetIt **lookups** in the constructor body |
| Services | `core`, DTO types | Feature entities, use cases, pages |
| `core` package | Dart + async/rxdart/equatable | Flutter, `app/`, GetIt |

Cross-feature **yes**: a repository constructor that takes another feature’s use case.  
Cross-feature **no**: a repository constructor that takes another feature’s repository.

A 1-line use case is the stable port, not wasted ceremony.

Use-case filenames describe the operation without a redundant `_use_case`
suffix (for example, `search_characters.dart`); class names retain the `UseCase` suffix
(for example, `SearchCharactersUseCase`).

Name use cases that return live streams `Observe…UseCase` (for example,
`ObserveReachabilityUseCase` and `ObserveCharacterUseCase`) and keep the
operation behind `call()`. Reserve `Get…UseCase` for one-time reads. Do not use
`$` suffixes or generic names such as `getStream()`.

Prefer one typed stream for cohesive state, such as `Reachability`, over one
observer per field. One-shot reads and reloads stay explicit operations, such
as `SearchCharactersUseCase` and `ReloadCharacterUseCase`.

## Pages and `*_ui.dart`

Pages live in the feature (`presentation/pages/`). That colocation is the structure; the second barrel is a Dart visibility workaround, not a second module.

- `{name}.dart` — module API: export only entities/use cases other modules import. Intra-feature types stay unexported. No widgets.
- `{name}_ui.dart` — pages, and optionally widgets that belong to this feature. Do not export `PageBloc`s or routes.
- Other features’ presentation may import `*_ui.dart` for **widgets**, not to construct or navigate to another feature’s page.
- Pages do not import other features’ **pages**. Navigate with route objects (`lib/navigation/routes/…`).
- App-wide kit (`PageState`, buttons, `NavPresentation`, `AppImage`, …) stays in `lib/ui/`. Feature-specific widgets may live on `*_ui.dart`.
- `AppImage` takes a `cacheManager`. The root `App` widget wraps the tree in `ImageCacheScope` from `ImageService`; widgets read it with `ImageCacheScope.of(context)`. UI does not resolve `ImageService` via GetIt.

The barrel is a convention. The real rule is pages don’t import pages.

## DI

- GetIt lives at the **composition root**: `main`, `navigation/router.dart`, `createBloc()`, injectable constructors.
- Repositories and use cases: constructor injection. Do not `getIt<T>()` inside a repository body.
- Page blocs are **not** registered; `PageState.createBloc()` constructs them (page-scoped). **Require** constructor injection of use cases and routes from that factory — do not call `getIt` inside the `PageBloc`. Resolve with `getIt` only in `createBloc()`.
- Routes as GetIt lazy singletons are the navigation port for now (owned by `lib/navigation/`).

## Mapping

Map HTTP DTOs and service primitives to entities in **feature data**, not in `lib/services`. Wire DTOs and service types do not import feature types.

## Result

`FutureResult<T>` is `Future<Result<T>>`. Loaders **complete** with `Result.error(...)`. Never `FutureResult.error` (that is `Future.error` and skips `ValueStateLoadFailed`).

## Review checklist

1. Does a domain/data file import `*_ui.dart` or a barrel that exports pages?
2. Does feature P import feature Q’s **repository**? (illegal)
3. Does feature P import feature Q’s **use case**? (legal; prefer constructor injection)
4. Does `lib/services/` import feature entities or mapping extensions onto them?
5. Is GetIt used inside a repository body instead of a constructor parameter?
6. Leftovers (stub / commented-out use cases, etc) may be hygiene warnings only — not CA.
7. Does `*_ui.dart` export blocs or routes? (pages and feature widgets are fine)
8. Does a page import another feature’s **page**? (illegal; navigate via routes. Importing `*_ui.dart` for widgets is fine)
9. Does a `PageBloc` call `getIt` for use cases or routes? (illegal; inject via `createBloc()`. Resolving in `createBloc()` is required)

These are **not** violations: data or presentation calling another feature’s use case; 1-line use cases; `createBloc()` resolving use cases / routes with `getIt` and passing them into the bloc; domain use cases importing `di.dart` only for `@injectable`; domain importing Flutter or `core`; a public barrel that omits entities/use cases only used inside the feature.
