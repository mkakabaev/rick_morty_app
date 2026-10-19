import 'package:core/core.dart';

import 'package:app/di/di.dart';

import '../entities/character.dart';
import '../entities/character_id.dart';
import '../repositories/characters_repository.dart';

@injectable
class ReloadCharacterUseCase {
  final CharactersRepository _repository;

  const ReloadCharacterUseCase(this._repository);

  Future<ValueState<Character>> call(CharacterId id) => _repository.reloadCharacter(id);
}
