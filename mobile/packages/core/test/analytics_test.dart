import 'package:core/core.dart';
import 'package:test/test.dart';

void main() {
  late List<AnalyticsProvider> previousProviders;
  late Map<String, Object?> previousContext;

  setUp(() {
    previousProviders = Analytics.providers;
    previousContext = Analytics.context;
    Analytics.providers = [];
    Analytics.context = {};
  });

  tearDown(() {
    Analytics.providers = previousProviders;
    Analytics.context = previousContext;
  });

  test('fans out track, identify, screen, and reset to every provider', () {
    final first = _RecordingProvider();
    final second = _RecordingProvider();
    Analytics.providers = [first, second];

    Analytics.track('clicked', properties: {'button': 'ok'});
    Analytics.identify('user-1', traits: {'plan': 'pro'});
    Analytics.screen('PostsRoute', properties: {'path': '/posts'});
    Analytics.reset();

    for (final provider in [first, second]) {
      expect(provider.tracks, hasLength(1));
      expect(provider.tracks.single.$1, 'clicked');
      expect(provider.tracks.single.$2, equals({'button': 'ok'}));

      expect(provider.identifies, hasLength(1));
      expect(provider.identifies.single.$1, 'user-1');
      expect(provider.identifies.single.$2, equals({'plan': 'pro'}));

      expect(provider.screens, hasLength(1));
      expect(provider.screens.single.$1, 'PostsRoute');
      expect(provider.screens.single.$2, equals({'path': '/posts'}));

      expect(provider.resets, 1);
    }
  });

  test('screen sets ambient context merged into later track calls', () {
    final provider = _RecordingProvider();
    Analytics.providers = [provider];

    Analytics.screen('PostsRoute', properties: {'path': '/posts', 'tab': 0});
    expect(Analytics.context, equals({'screen': 'PostsRoute', 'path': '/posts', 'tab': 0}));

    Analytics.track('clicked', properties: {'button': 'ok'});
    expect(provider.tracks.single.$1, 'clicked');
    expect(provider.tracks.single.$2, equals({'screen': 'PostsRoute', 'path': '/posts', 'tab': 0, 'button': 'ok'}));
  });

  test('track call-site properties win over ambient context', () {
    final provider = _RecordingProvider();
    Analytics.providers = [provider];

    Analytics.screen('PostsRoute', properties: {'path': '/posts'});
    Analytics.track('clicked', properties: {'path': '/override'});

    expect(provider.tracks.single.$2, equals({'screen': 'PostsRoute', 'path': '/override'}));
  });

  test('reset clears ambient context', () {
    final provider = _RecordingProvider();
    Analytics.providers = [provider];

    Analytics.screen('PostsRoute', properties: {'path': '/posts'});
    Analytics.reset();

    expect(Analytics.context, isEmpty);
    Analytics.track('after_reset');
    expect(provider.tracks.single.$1, 'after_reset');
    expect(provider.tracks.single.$2, isEmpty);
  });
}

final class _RecordingProvider implements AnalyticsProvider {
  final tracks = <(String, Map<String, Object?>)>[];
  final identifies = <(String, Map<String, Object?>)>[];
  final screens = <(String, Map<String, Object?>)>[];
  var resets = 0;

  @override
  void track(String name, {Map<String, Object?> properties = const {}}) {
    tracks.add((name, Map.of(properties)));
  }

  @override
  void identify(String userId, {Map<String, Object?> traits = const {}}) {
    identifies.add((userId, Map.of(traits)));
  }

  @override
  void screen(String name, {Map<String, Object?> properties = const {}}) {
    screens.add((name, Map.of(properties)));
  }

  @override
  void reset() {
    resets++;
  }
}
