import 'package:app/ui/ui.dart';
import 'package:core/core.dart';

class RecordingPageHost implements PageHost {
  final errors = <AppError>[];
  final shownOffline = <bool>[];
  var hideErrorCount = 0;
  bool isTopmostValue = true;

  @override
  void showError(AppError error, {bool isOffline = false}) {
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
