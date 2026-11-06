import 'dart:developer' as developer;

import 'package:meta/meta.dart';

/// A destination for events produced by [Analytics].
abstract interface class AnalyticsProvider {
  void track(String name, {Map<String, Object?> properties});

  void identify(String userId, {Map<String, Object?> traits});

  void screen(String name, {Map<String, Object?> properties});

  void reset();
}

/// Static fan-out analytics API with ambient [context] merged into [track].
abstract final class Analytics {
  static final _providers = <AnalyticsProvider>[];

  static void addProvider(AnalyticsProvider provider) => _providers.add(provider);

  /// Ambient context merged into every [track] (call-site keys win).
  /// Updated by [screen]; cleared by [reset].
  static Map<String, Object?> _context = {};

  static void track(String name, {Map<String, Object?> properties = const {}}) {
    final merged = {..._context, ...properties};
    for (final provider in _providers) {
      provider.track(name, properties: merged);
    }
  }

  static void identify(String userId, {Map<String, Object?> traits = const {}}) {
    for (final provider in _providers) {
      provider.identify(userId, traits: traits);
    }
  }

  /// Sets ambient [context] to `{screen: name, ...properties}`, then fans out.
  static void screen(String name, {Map<String, Object?> properties = const {}}) {
    _context = {'screen': name, ...properties};
    for (final provider in _providers) {
      provider.screen(name, properties: properties);
    }
  }

  static void reset() {
    _context = {};
    for (final provider in _providers) {
      provider.reset();
    }
  }
}

@visibleForTesting
extension AnalyticsTesting on Analytics {
  static List<AnalyticsProvider> get providers => Analytics._providers;
  static set providers(List<AnalyticsProvider> value) => Analytics._providers
    ..clear()
    ..addAll(value);

  static Map<String, Object?> get context => Analytics._context;
  static set context(Map<String, Object?> value) => Analytics._context = value;
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
