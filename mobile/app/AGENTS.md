# App

Architecture: features are modules. Public API = entities + use cases (`lib/features/foo/foo.dart`). Repositories are private.

- Cross-feature code depends on use cases, never on another feature’s repository. Data may constructor-inject those use cases.
- `foo_ui.dart` is pages, and optionally that feature’s shared widgets — not blocs or routes. `lib/navigation/` instantiates pages and owns the launch redirect; presentation imports route ports under `navigation/routes/`, not other features’ pages.
- Kernel primitives live in `packages/core/` (Dart-only, sibling under `mobile/`). Shared widgets live in `lib/ui/`.

Docs:

- Contract and review checklist: [Clean architecture](/mobile/app/docs/clean-architecture.md)
- Navigation: [Navigation](/mobile/app/docs/navigation.md)
- Startup: [Startup](/mobile/app/docs/startup.md)
- Backend client: [Backend client](/mobile/app/docs/backend-client.md)
