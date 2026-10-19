import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'package:app/l10n/l10n.dart';

import '../error.dart';

abstract interface class PageHost {
  void showError(RickMortyError error, {bool isOffline = false});
  void hideErrors();
  bool get isTopmost;
  void dropFocus();
}

class DefaultPageHost implements PageHost {
  final BuildContext _context;

  const DefaultPageHost(this._context);

  @override
  void showError(RickMortyError error, {bool isOffline = false}) {
    _invokeWhenReady(() {
      // make optional?
      if (!isTopmost) {
        return;
      }

      final theme = Theme.of(_context);
      final message = error.text(isOffline: isOffline, l10n: _context.l10n);
      final _ = ScaffoldMessenger.maybeOf(_context)?.showSnackBar(
        SnackBar(
          content: Text(message, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onError)),
          backgroundColor: theme.colorScheme.error,
        ),
      );
    });
  }

  @override
  void hideErrors() {
    _invokeWhenReady(() {
      ScaffoldMessenger.maybeOf(_context)?.hideCurrentSnackBar();
    });
  }

  @override
  bool get isTopmost {
    if (_context.mounted && ModalRoute.of(_context)?.isCurrent == true) {
      return true;
    }
    return false;
  }

  @override
  void dropFocus() {
    FocusManager.instance.primaryFocus?.unfocus();
  }

  /// [ScaffoldMessenger], [Theme], [ModalRoute], and localizations register an inherited dependency.
  /// That is illegal until [State.initState] has finished, which is still in progress
  /// while the frame is building. Defer those calls to the end of the frame.
  void _invokeWhenReady(VoidCallback action) {
    if (!_context.mounted) {
      return;
    }

    if (SchedulerBinding.instance.schedulerPhase == SchedulerPhase.persistentCallbacks) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_context.mounted) {
          return;
        }
        action();
      });
      return;
    }

    action();
  }
}

/// Exposes the current page's [PageHost] to descendant widgets.
class PageHostScope extends InheritedWidget {
  static PageHost of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<PageHostScope>();
    if (scope == null) {
      throw FlutterError('PageHostScope.of() called with no PageHostScope ancestor.');
    }
    return scope.host;
  }

  final PageHost host;

  const PageHostScope({super.key, required this.host, required super.child});

  @override
  bool updateShouldNotify(PageHostScope oldWidget) => host != oldWidget.host;
}
