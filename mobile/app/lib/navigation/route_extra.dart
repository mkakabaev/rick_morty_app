import 'dart:convert';

import 'route_presentation.dart';

/// GoRouter `state.extra` payload: optional presentation overrides + optional data.
///
/// Null [transition] / [fullscreenDialog] mean "keep the route's [RickMortyRoutePresentation]".
class RickMortyRouteExtra {
  final RickMortyRouteTransition? transition;
  final bool? fullscreenDialog;
  final Object? data;

  const RickMortyRouteExtra({this.transition, this.fullscreenDialog, this.data});

  static RickMortyRouteExtra? from(Object? extra) => extra is RickMortyRouteExtra ? extra : null;
}

/// Stub codec so GoRouter does not warn about complex [RickMortyRouteExtra] extras.
///
/// Serialization is a no-op; extras are in-memory only.
final class RickMortyRouteExtraCodec extends Codec<Object?, Object?> {
  const RickMortyRouteExtraCodec();

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
