import 'dart:async';

import 'package:app/di/di.dart';
import 'package:app/services/api_client/api_client.dart';
import 'package:app/services/api_client/dtos/character.dart';
import 'package:app/services/reachability/reachability_service.dart';
import 'package:core/core.dart';

import '../../domain/entities/character.dart';
import '../../domain/entities/character_id.dart';
import '../../domain/entities/character_page.dart';
import '../../domain/repositories/characters_repository.dart';

@LazySingleton(as: CharactersRepository)
class CharactersRepositoryImpl implements CharactersRepository {
  final ApiClient _apiClient;
  final _characters = <CharacterId, ValueStateHost<Character>>{};
  late final StreamSubscription<Reachability> _reachabilityChanges;

  CharactersRepositoryImpl(this._apiClient, ReachabilityService reachability) {
    _reachabilityChanges = reachability.changes.listen(_onReachability);
  }

  Future<void> dispose() async {
    await _reachabilityChanges.cancel();
  }

  @override
  FutureResult<CharacterPage> search({String? name, required int page}) async {
    final trimmed = name?.trim() ?? '';
    final query = trimmed.isEmpty ? null : trimmed;

    final result = await _apiClient.getCharacters(page: page, name: query);

    if (result.isError) {
      if (result.requiredError.type == .notFound) {
        return Result.value(CharacterPage(items: const [], page: page, hasMore: false));
      }
      return Result.error(result.requiredError);
    }

    final dto = result.requiredValue;
    final items = dto.results.map((item) => _characterFromDto(item)).toList();
    for (final character in items) {
      _remember(character);
    }
    return Result.value(CharacterPage(page: page, hasMore: dto.info.next != null, items: items));
  }

  @override
  ValueStream<ValueState<Character>> character(CharacterId id) => _host(id).valueStream;

  @override
  Future<ValueState<Character>> reloadCharacter(CharacterId id) => _host(id).reload();

  ValueStateHost<Character> _host(CharacterId id) {
    return _characters.putIfAbsent(id, () => ValueStateHost(loader: () => _loadCharacter(id)));
  }

  void _remember(Character character) {
    final current = _characters[character.id];
    if (current == null) {
      _characters[character.id] = ValueStateHost(loader: () => _loadCharacter(character.id), seed: character);
      return;
    }
    if (current.valueStream.value.isLoading) {
      return;
    }
    current.updateLoaded(character);
  }

  void _onReachability(Reachability reachability) {
    if (reachability != .online) {
      return;
    }
    for (final host in _characters.values) {
      host.reloadIfSubscribedWithoutValue();
    }
  }

  FutureResult<Character> _loadCharacter(CharacterId id) async {
    try {
      final result = await _apiClient.getCharacter(id.toWire);
      if (result.isError) {
        return Result.error(result.requiredError);
      }
      return Result.value(_characterFromDto(result.requiredValue));
    } catch (e) {
      return Result.error(RickMortyError.from(e));
    }
  }
}

Character _characterFromDto(CharacterDto dto) {
  return Character(
    id: CharacterId.fromWire(dto.id),
    name: dto.name,
    status: dto.status,
    species: dto.species,
    imageUrl: dto.image,
    origin: dto.origin.name,
    location: dto.location.name,
  );
}
