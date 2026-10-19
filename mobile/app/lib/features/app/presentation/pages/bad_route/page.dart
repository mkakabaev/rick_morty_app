import 'package:flutter/material.dart';

import 'package:app/l10n/l10n.dart';
import 'package:app/ui/ui.dart';
import 'bloc.dart';

class BadRoutePage extends StatefulWidget {
  final Uri uri;

  const BadRoutePage({required this.uri, super.key});

  @override
  State createState() => _BadRoutePageState();
}

class _BadRoutePageState extends PageState<BadRoutePage, BadRoutePageBloc, BadRoutePageBlocState> {
  @override
  BadRoutePageBloc createBloc() => .new(host);

  @override
  Widget buildPage(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.oops)),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.unableToOpen(widget.uri.toString()), textAlign: TextAlign.center),
            const SizedBox(height: 20),
            Button(title: l10n.goHome, onTap: bloc.goHome),
          ],
        ),
      ),
    );
  }
}
