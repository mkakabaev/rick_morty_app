import 'package:core/core.dart';

import 'dtos/character.dart';
import 'dtos/characters.dart';

export 'dtos/characters.dart';

abstract interface class ApiClient {
  FutureResult<CharactersResponseDto> getCharacters({required int page, String? name});
  FutureResult<CharacterDto> getCharacter(int id);
}
