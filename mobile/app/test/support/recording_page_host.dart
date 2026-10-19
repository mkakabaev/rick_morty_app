import 'package:core/core.dart';

import 'package:app/ui/ui.dart';

class RecordingPageHost implements PageHost {
  final errors = <RickMortyError>[];
  final shownOffline = <bool>[];
  var hideErrorCount = 0;
  bool isTopmostValue = true;

  @override
  void showError(RickMortyError error, {bool isOffline = false}) {
    errors.add(error);
    shownOffline.add(isOffline);
  }

  @override
  void hideErrors() => hideErrorCount++;

  @override
  bool get isTopmost => isTopmostValue;

  @override
  void dropFocus() {}
}
