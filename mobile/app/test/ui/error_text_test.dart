import 'package:flutter/material.dart';

import 'package:app/l10n/l10n.dart';
import 'package:app/ui/error.dart';
import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('offline display text is the no-internet message', (tester) async {
    final error = AppError('Network error', type: .network);

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(builder: (context) => Text(error.text(isOffline: true, l10n: context.l10n))),
      ),
    );

    expect(find.text('No internet connection'), findsOneWidget);
    expect(error.type, AppErrorType.network);
  });

  testWidgets('typed errors use localized copy, not the transport message', (tester) async {
    final error = AppError('Server busy. Try again later', type: .serverBusy);

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ru'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(builder: (context) => Text(error.text(isOffline: false, l10n: context.l10n))),
      ),
    );

    expect(find.text('Сервер перегружен. Попробуйте позже'), findsOneWidget);
    expect(find.text('Server busy. Try again later'), findsNothing);
  });

  testWidgets('untyped errors keep their message', (tester) async {
    final error = AppError('Something odd');

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(builder: (context) => Text(error.text(isOffline: false, l10n: context.l10n))),
      ),
    );

    expect(find.text('Something odd'), findsOneWidget);
  });
}
