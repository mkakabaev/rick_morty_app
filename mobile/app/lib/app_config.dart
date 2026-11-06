import 'package:flutter/services.dart';

import 'package:app/di/di.dart';
import 'package:core/core.dart';

enum Flavor {
  dev,
  stage,
  prod;

  /// Used when the build was started without `--flavor` (for example a plain `flutter run`).
  static const Flavor fallback = .dev;

  /// Resolves [name] (the `--flavor` value) to a [Flavor], or [fallback] when it is missing or unknown.
  static Flavor fromName(String? name) => Flavor.values.byNameOrNull(name) ?? fallback;
}

class AppConfig {
  final Flavor flavor;
  final String title;
  final String apiBaseUrl;

  const AppConfig({required this.flavor, required this.title, required this.apiBaseUrl});

  factory AppConfig.fromFlavor(Flavor flavor) {
    return AppConfig(
      flavor: flavor,
      title: switch (flavor) {
        .dev => 'Rick and Morty App Dev',
        .stage => 'Rick and Morty App Stage',
        .prod => 'Rick and Morty App',
      },
      apiBaseUrl: 'https://rickandmortyapi.com/api',
    );
  }

  AppConfig copyWith({Flavor? flavor, String? title, String? apiBaseUrl}) =>
      AppConfig(flavor: flavor ?? this.flavor, title: title ?? this.title, apiBaseUrl: apiBaseUrl ?? this.apiBaseUrl);
}

@module
abstract class AppConfigModule {
  @lazySingleton
  AppConfig appConfig() {
    final flavor = Flavor.fromName(appFlavor);
    if (flavor.name != appFlavor) {
      AppLog.error(
        StateError('Unknown flavor "$appFlavor"'),
        StackTrace.current,
        message: 'Falling back to the "${flavor.name}" flavor',
      );
    }
    return AppConfig.fromFlavor(flavor);
  }
}
