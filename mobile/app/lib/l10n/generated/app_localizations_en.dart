// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Rick and Morty App';

  @override
  String get characters => 'R & M Characters';

  @override
  String get searchCharacters => 'Search by name';

  @override
  String get noCharacters => 'No characters found';

  @override
  String noCharactersMatch(String query) {
    return 'No characters match \"$query\"';
  }

  @override
  String get clearSearch => 'Clear search';

  @override
  String get characterStatus => 'Status';

  @override
  String get species => 'Species';

  @override
  String get origin => 'Origin';

  @override
  String get location => 'Location';

  @override
  String get somethingWentWrong => 'Something went wrong';

  @override
  String get retry => 'Retry';

  @override
  String get oops => 'Oops!';

  @override
  String unableToOpen(String uri) {
    return 'Unable to open $uri';
  }

  @override
  String get goHome => 'Go home';

  @override
  String get noInternet => 'No internet connection';

  @override
  String get imageNotFound => 'Image not found';

  @override
  String get imageNotLoaded => 'Couldn\'t load image';
}
