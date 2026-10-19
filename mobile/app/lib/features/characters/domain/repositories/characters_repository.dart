import 'package:core/core.dart';

import '../entities/character.dart';
import '../entities/character_id.dart';
import '../entities/character_page.dart';

abstract interface class CharactersRepository {
  FutureResult<CharacterPage> search({String? name, required int page});

  ValueStream<ValueState<Character>> character(CharacterId id);

  Future<ValueState<Character>> reloadCharacter(CharacterId id);
}
