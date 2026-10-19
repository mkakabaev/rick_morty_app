import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app/l10n/l10n.dart';
import 'package:app/ui/error.dart';

void main() {
  testWidgets('offline display text is the no-internet message', (tester) async {
    final error = RickMortyError('Network error', type: .network);

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(builder: (context) => Text(error.text(isOffline: true, l10n: context.l10n))),
      ),
    );

    expect(find.text('No internet connection'), findsOneWidget);
    expect(error.type, RickMortyErrorType.network);
  });

  testWidgets('online display text keeps the error message', (tester) async {
    final error = RickMortyError('Network error', type: .network);

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(builder: (context) => Text(error.text(isOffline: false, l10n: context.l10n))),
      ),
    );

    expect(find.text('Network error'), findsOneWidget);
  });
}
