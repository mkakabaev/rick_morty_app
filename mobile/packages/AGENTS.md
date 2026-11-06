# Packages

`core/` is the Dart kernel (`Result`, `AppError`, `ValueState`, `Worker`, `CWValue`, `Tags` / `Loggable` / `AppLog`, `Analytics`). No Flutter. Register log outputs with `AppLog.addOutput` and analytics destinations with `Analytics.addProvider`.

`analysis_options/` holds the shared analyzer configuration.

App architecture lives under `mobile/app/`: [Clean architecture](/mobile/app/docs/clean-architecture.md).
