import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'package:app/l10n/l10n.dart';
import 'package:app/navigation/create_router.dart';
import 'package:app/ui/ui.dart';

class RickMortyApp extends StatelessWidget {
  RickMortyApp({super.key});

  final _router = createAppRouter();

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      onGenerateTitle: (context) => context.l10n.appTitle,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: _router,
      darkTheme: applyAppColors(ThemeData.dark()),
      theme: applyAppColors(ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.purple))),
      themeMode: ThemeMode.system,
      scrollBehavior: const MaterialScrollBehavior().copyWith(
        dragDevices: PointerDeviceKind.values.toSet(),
        multitouchDragStrategy: .latestPointer,
      ),
    );
  }
}
