---
name: review-clean-architecture
description: Reviews this Flutter app against its feature-module Clean Architecture. Use when the user asks to inspect or review architecture, CA, layering, feature barrels, use cases vs repositories, or the app against its architecture.
---

# Review against this app's CA

1. Read [Clean architecture](/mobile/app/docs/clean-architecture.md) and use **only** that checklist.
2. Trace public barrels (`foo.dart`), UI barrels (`foo_ui.dart`), and imports across presentation / domain / data / `lib/services/` / `packages/core/`.
3. Separate module-boundary breaks from hygiene.
