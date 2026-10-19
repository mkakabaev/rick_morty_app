import 'package:core/core.dart';

import 'package:app/di/di.dart';

import '../entities/character_page.dart';
import '../repositories/characters_repository.dart';

@injectable
class SearchCharactersUseCase {
  final CharactersRepository _repository;

  const SearchCharactersUseCase(this._repository);

  FutureResult<CharacterPage> call({String? name, required int page}) => _repository.search(name: name, page: page);
}
