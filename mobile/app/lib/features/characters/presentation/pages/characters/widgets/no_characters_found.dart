import 'package:app/l10n/l10n.dart';
import 'package:app/ui/ui.dart';
import 'package:flutter/material.dart';

class NoCharactersFound extends StatelessWidget {
  final String query;
  final VoidCallback onClear;
  final Future<void> Function() onRefresh;

  const NoCharactersFound({super.key, required this.query, required this.onClear, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final trimmed = query.trim();
    final hasQuery = trimmed.isNotEmpty;
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.only(bottom: bottomInset),
            children: [
              ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight - bottomInset),
                child: Column(
                  spacing: 4,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        hasQuery ? l10n.noCharactersMatch(trimmed) : l10n.noCharacters,
                        style: theme.textTheme.titleMedium,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    if (hasQuery) Button.secondary(title: l10n.clearSearch, onTap: onClear),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
