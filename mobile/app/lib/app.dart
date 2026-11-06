import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'package:app/l10n/l10n.dart';
import 'package:app/navigation/create_router.dart';
import 'package:app/services/image_service/image_service.dart';
import 'package:app/ui/ui.dart';

import 'di/di.dart';

class App extends StatelessWidget {
  final _router = createAppRouter();
  final ImageService _imageService = getIt();

  App({super.key});

  @override
  Widget build(BuildContext context) {
    return ImageCacheScope(
      cacheManager: _imageService.cacheManager,
      child: MaterialApp.router(
        onGenerateTitle: (context) => context.l10n.appTitle,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: _router,
        darkTheme: applyAppColors(
          ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF808080),
              brightness: .dark,
              dynamicSchemeVariant: .monochrome,
            ),
          ),
        ),
        theme: applyAppColors(
          ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF808080), dynamicSchemeVariant: .monochrome),
          ),
        ),
        themeMode: ThemeMode.system,
        scrollBehavior: const MaterialScrollBehavior().copyWith(
          dragDevices: PointerDeviceKind.values.toSet(),
          multitouchDragStrategy: .latestPointer,
        ),
      ),
    );
  }
}
