import 'dart:developer' as developer;

/// A destination for events produced by [Analytics].
abstract interface class AnalyticsProvider {
  void track(String name, {Map<String, Object?> properties});

  void identify(String userId, {Map<String, Object?> traits});

  void screen(String name, {Map<String, Object?> properties});

  void reset();
}

/// Static fan-out analytics API with ambient [context] merged into [track].
final class Analytics {
  Analytics._();

  /// Destinations that every call fans out to. Empty until the app attaches providers.
  // ignore: avoid-global-state
  static List<AnalyticsProvider> providers = [];

  /// Ambient context merged into every [track] (call-site keys win).
  /// Updated by [screen]; cleared by [reset].
  // ignore: avoid-global-state
  static Map<String, Object?> context = {};

  static void track(String name, {Map<String, Object?> properties = const {}}) {
    final merged = {...context, ...properties};
    for (final provider in providers) {
      provider.track(name, properties: merged);
    }
  }

  static void identify(String userId, {Map<String, Object?> traits = const {}}) {
    for (final provider in providers) {
      provider.identify(userId, traits: traits);
    }
  }

  /// Sets ambient [context] to `{screen: name, ...properties}`, then fans out.
  static void screen(String name, {Map<String, Object?> properties = const {}}) {
    context = {'screen': name, ...properties};
    for (final provider in providers) {
      provider.screen(name, properties: properties);
    }
  }

  static void reset() {
    context = {};
    for (final provider in providers) {
      provider.reset();
    }
  }
}

/// Logs analytics calls via [developer.log].
final class LoggingAnalyticsProvider implements AnalyticsProvider {
  const LoggingAnalyticsProvider();

  static const _name = 'Analytics';

  @override
  void track(String name, {Map<String, Object?> properties = const {}}) {
    developer.log('track $name $properties', name: _name);
  }

  @override
  void identify(String userId, {Map<String, Object?> traits = const {}}) {
    developer.log('identify $userId $traits', name: _name);
  }

  @override
  void screen(String name, {Map<String, Object?> properties = const {}}) {
    developer.log('screen $name $properties', name: _name);
  }

  @override
  void reset() {
    developer.log('reset', name: _name);
  }
}
