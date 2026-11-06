import 'logging.dart';
import 'tags.dart';

extension AppEnumByName<T extends Enum> on Iterable<T> {
  /// Like [EnumByName.byName], but returns `null` when [name] is null or unknown.
  T? byNameOrNull(String? name) {
    if (name != null) {
      for (final value in this) {
        if (value.name == name) {
          return value;
        }
      }
    }
    return null;
  }
}

/// Simple elapsed-time logger. Starts on construction; call [stop] once.
class AppStopwatch with Loggable {
  final _sw = Stopwatch()..start();

  AppStopwatch({required Tags parentTags}) : logTags = parentTags + '⏱️';

  @override
  final Tags logTags;

  void stop(String label) {
    _sw.stop();
    log('$label: elapsed ${_formatWithGroupSeparators(_sw.elapsedMicroseconds)} µs');
  }

  static final _groupSepRegExp = RegExp(r'(\d)(?=(\d{3})+(?!\d))');
  String _formatWithGroupSeparators(int value) => value.toString().replaceAllMapped(_groupSepRegExp, (m) => '${m[1]},');
}
