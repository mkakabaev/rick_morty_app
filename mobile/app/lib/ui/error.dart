import 'dart:async';

import 'package:flutter/material.dart';

import 'package:app/l10n/l10n.dart';
import 'package:core/core.dart';

import 'buttons.dart';

extension RickMortyErrorText on RickMortyError {
  String text({required bool isOffline, required AppLocalizations l10n}) {
    if (isOffline) {
      return l10n.noInternet;
    }
    return message;
  }
}

class ErrorPlate extends StatelessWidget {
  final FutureOr<void> Function() onRetry;
  final RickMortyError error;
  final bool isOffline;
  final bool adjustForAppBar;

  const ErrorPlate({
    super.key,
    required this.onRetry,
    required this.error,
    required this.isOffline,
    this.adjustForAppBar = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    String title = l10n.somethingWentWrong;
    String? message = error.message;
    var canRetry = true;

    // Some errors are self explanatory, so we can show a simple message
    if (isOffline) {
      title = error.text(isOffline: true, l10n: l10n);
      message = null;
      canRetry = false;
    } else {
      switch (error.type) {
        case .notFound:
          title = error.message;
          message = null;
          canRetry = false;
        default:
          break;
      }
    }

    return Padding(
      padding: const EdgeInsets.all(30),
      child: SizedBox(
        width: .infinity,
        child: Column(
          spacing: 4,
          mainAxisAlignment: .center,
          children: [
            Text(title, style: theme.textTheme.headlineMedium, textAlign: TextAlign.center),

            if (message != null)
              Text(
                message,
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.secondary),
                textAlign: TextAlign.center,
              ),

            if (canRetry)
              Padding(
                padding: const .only(top: 4),
                child: Button.secondary(title: l10n.retry, onTap: onRetry),
              ),

            if (adjustForAppBar) const SizedBox(height: kToolbarHeight),
          ],
        ),
      ),
    );
  }
}
