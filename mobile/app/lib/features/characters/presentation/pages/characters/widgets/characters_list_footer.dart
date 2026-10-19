import 'package:flutter/material.dart';

import 'package:app/l10n/l10n.dart';
import 'package:app/ui/ui.dart';
import 'package:core/core.dart';

class CharacterListFooter extends StatelessWidget {
  final RickMortyError? error;
  final bool isOffline;
  final bool isLoading;
  final VoidCallback onRetry;

  const CharacterListFooter({
    super.key,
    required this.error,
    required this.isOffline,
    required this.isLoading,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final error = this.error;
    if (error != null) {
      final l10n = context.l10n;
      return Padding(
        padding: const .all(16),
        child: Column(
          spacing: 4,
          children: [
            Text(
              error.text(isOffline: isOffline, l10n: l10n),
              textAlign: TextAlign.center,
            ),
            if (!isOffline) Button.secondary(title: l10n.retry, onTap: onRetry),
          ],
        ),
      );
    }
    if (isLoading) {
      return const Padding(
        padding: .all(16),
        child: Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 3))),
      );
    }
    return const SizedBox(height: 64);
  }
}
