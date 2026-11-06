import 'dart:convert';

import 'package:app/ui/ui.dart' show NavTransition;

/// GoRouter `state.extra` payload: optional presentation overrides + optional data.
///
/// Null [transition] / [fullscreenDialog] mean "keep the route's [NavPresentation]".
class AppRouteExtra {
  final NavTransition? transition;
  final bool? fullscreenDialog;
  final Object? data;

  const AppRouteExtra({this.transition, this.fullscreenDialog, this.data});

  static AppRouteExtra? from(Object? extra) => extra is AppRouteExtra ? extra : null;
}

/// Stub codec so GoRouter does not warn about complex [AppRouteExtra] extras.
///
/// Serialization is a no-op; extras are in-memory only.
final class AppRouteExtraCodec extends Codec<Object?, Object?> {
  const AppRouteExtraCodec();

  @override
  Converter<Object?, Object?> get decoder => const _NoOpExtraConverter();

  @override
  Converter<Object?, Object?> get encoder => const _NoOpExtraConverter();
}

final class _NoOpExtraConverter extends Converter<Object?, Object?> {
  const _NoOpExtraConverter();

  @override
  Object? convert(Object? input) => null;
}
