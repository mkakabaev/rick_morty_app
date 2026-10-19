import 'package:flutter/services.dart';

import 'package:app/di/di.dart';

enum Flavor { dev, stage, prod }

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
  AppConfig appConfig() => AppConfig.fromFlavor(Flavor.values.byName(appFlavor ?? '?'));
}
