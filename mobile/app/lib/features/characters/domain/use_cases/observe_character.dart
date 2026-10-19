import 'package:core/core.dart';

import 'package:app/di/di.dart';

import '../entities/character.dart';
import '../entities/character_id.dart';
import '../repositories/characters_repository.dart';

@injectable
class ObserveCharacterUseCase {
  final CharactersRepository _repository;

  const ObserveCharacterUseCase(this._repository);

  ValueStream<ValueState<Character>> call(CharacterId id) => _repository.character(id);
}
