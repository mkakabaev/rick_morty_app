import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app/l10n/l10n.dart';
import 'package:app/ui/page/page_host.dart';

void main() {
  testWidgets('hideErrors during initState does not look up ScaffoldMessenger yet', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: _HideOnInitPage()));

    expect(tester.takeException(), isNull);
  });

  testWidgets('showError during initState is shown after the frame', (tester) async {
    await tester.pumpWidget(_localizedApp(const _ShowOnInitPage()));
    expect(tester.takeException(), isNull);
    expect(find.text('boom'), findsNothing);

    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('boom'), findsOneWidget);
  });

  testWidgets('showError while offline shows the no-internet message', (tester) async {
    await tester.pumpWidget(_localizedApp(const _ShowOfflineOnInitPage()));
    await tester.pump();

    expect(find.text('No internet connection'), findsOneWidget);
    expect(find.text('Network error'), findsNothing);
  });

  testWidgets('hideErrors from a gesture hides the snackbar immediately', (tester) async {
    await tester.pumpWidget(_localizedApp(const _HideOnTapPage()));

    await tester.tap(find.text('show'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 750));
    expect(find.text('boom'), findsOneWidget);

    await tester.tap(find.text('hide'));
    await tester.pumpAndSettle();

    expect(find.text('boom'), findsNothing);
  });
}

Widget _localizedApp(Widget home) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: home,
  );
}

class _HideOnInitPage extends StatefulWidget {
  const _HideOnInitPage();

  @override
  State<_HideOnInitPage> createState() => _HideOnInitPageState();
}

class _HideOnInitPageState extends State<_HideOnInitPage> {
  @override
  void initState() {
    super.initState();
    DefaultPageHost(context).hideErrors();
  }

  @override
  Widget build(BuildContext context) => const Scaffold(body: SizedBox.shrink());
}

class _ShowOnInitPage extends StatefulWidget {
  const _ShowOnInitPage();

  @override
  State<_ShowOnInitPage> createState() => _ShowOnInitPageState();
}

class _ShowOnInitPageState extends State<_ShowOnInitPage> {
  @override
  void initState() {
    super.initState();
    DefaultPageHost(context).showError(RickMortyError('boom'));
  }

  @override
  Widget build(BuildContext context) => const Scaffold(body: SizedBox.shrink());
}

class _ShowOfflineOnInitPage extends StatefulWidget {
  const _ShowOfflineOnInitPage();

  @override
  State<_ShowOfflineOnInitPage> createState() => _ShowOfflineOnInitPageState();
}

class _ShowOfflineOnInitPageState extends State<_ShowOfflineOnInitPage> {
  @override
  void initState() {
    super.initState();
    DefaultPageHost(context).showError(RickMortyError('Network error', type: .network), isOffline: true);
  }

  @override
  Widget build(BuildContext context) => const Scaffold(body: SizedBox.shrink());
}

class _HideOnTapPage extends StatelessWidget {
  const _HideOnTapPage();

  @override
  Widget build(BuildContext context) {
    final host = DefaultPageHost(context);
    return Scaffold(
      body: Column(
        children: [
          TextButton(onPressed: () => host.showError(RickMortyError('boom')), child: const Text('show')),
          TextButton(onPressed: host.hideErrors, child: const Text('hide')),
        ],
      ),
    );
  }
}
