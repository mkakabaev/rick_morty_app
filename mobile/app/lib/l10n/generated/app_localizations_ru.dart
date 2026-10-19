// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appTitle => 'Rick and Morty App';

  @override
  String get characters => 'R & M Персонажи';

  @override
  String get searchCharacters => 'Поиск по имени';

  @override
  String get noCharacters => 'Персонажи не найдены';

  @override
  String noCharactersMatch(String query) {
    return 'Нет персонажей по запросу «$query»';
  }

  @override
  String get clearSearch => 'Очистить поиск';

  @override
  String get characterStatus => 'Статус';

  @override
  String get species => 'Вид';

  @override
  String get origin => 'Происхождение';

  @override
  String get location => 'Локация';

  @override
  String get somethingWentWrong => 'Что-то пошло не так';

  @override
  String get retry => 'Повторить';

  @override
  String get oops => 'Упс!';

  @override
  String unableToOpen(String uri) {
    return 'Не удалось открыть $uri';
  }

  @override
  String get goHome => 'На главную';

  @override
  String get noInternet => 'Нет подключения к интернету';

  @override
  String get imageNotFound => 'Изображение не найдено';

  @override
  String get imageNotLoaded => 'Не удалось загрузить изображение';
}
