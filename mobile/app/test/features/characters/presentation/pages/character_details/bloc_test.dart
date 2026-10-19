import 'package:app/services/api_client/dtos/character.dart';
import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app/features/characters/data/repositories/characters_repository+impl.dart';
import 'package:app/features/characters/domain/entities/character_id.dart';
import 'package:app/features/characters/domain/use_cases/observe_character.dart';
import 'package:app/features/characters/domain/use_cases/reload_character.dart';
import 'package:app/features/characters/presentation/pages/character_details/bloc.dart';
import 'package:app/features/reachability/domain/entities/reachability.dart';
import 'package:app/features/reachability/domain/repositories/reachability_repository.dart';
import 'package:app/features/reachability/domain/use_cases/observe_reachability.dart';
import 'package:app/services/api_client/api_client.dart';
import 'package:app/services/reachability/reachability_service.dart' as connectivity;

import '../../../../../support/recording_page_host.dart';

void main() {
  test('shows a cached character immediately and does not fetch', () async {
    final api = _Api(Result.value(_dto('Rick Sanchez')));
    final repository = CharactersRepositoryImpl(api, _Reachability());
    await repository.search(name: 'Rick', page: 1);

    final bloc = _bloc(repository);
    addTearDown(bloc.close);

    expect(bloc.state.character.requiredValue.name, 'Rick C-137');
    expect(api.fetches, 0);
  });

  test('subscribes to the cached character and reloads only when asked', () async {
    final api = _Api(Result.value(_dto('Rick Sanchez')));
    final repository = CharactersRepositoryImpl(api, _Reachability());
    final host = RecordingPageHost();
    final bloc = _bloc(repository, host);
    addTearDown(bloc.close);

    await pumpEventQueue();
    expect(bloc.state.character.requiredValue.name, 'Rick Sanchez');
    expect(api.fetches, 1);

    await repository.search(name: 'Rick', page: 1);
    await pumpEventQueue();
    expect(repository.character(const CharacterId.fromInt(1)).value.requiredValue.name, 'Rick C-137');
    expect(bloc.state.character.requiredValue.name, 'Rick C-137');
    expect(api.fetches, 1);

    api.character = Result.error(RickMortyError('offline'));
    await bloc.reload();

    expect(api.fetches, 2);
    expect(host.hideErrorCount, 1);
    expect(host.errors.single.message, 'offline');
    expect(host.shownOffline, [false]);
    expect(bloc.state.character.requiredValue.name, 'Rick C-137');
  });
}

CharacterDetailsPageBloc _bloc(CharactersRepositoryImpl repository, [RecordingPageHost? host]) {
  return CharacterDetailsPageBloc(
    host ?? RecordingPageHost(),
    characterId: const CharacterId.fromInt(1),
    observeCharacter: ObserveCharacterUseCase(repository),
    reloadCharacter: ReloadCharacterUseCase(repository),
    observeReachability: _onlineReachability(),
  );
}

ObserveReachabilityUseCase _onlineReachability() {
  final status = BehaviorSubject<Reachability>.seeded(.online);
  addTearDown(status.close);
  return ObserveReachabilityUseCase(_ReachabilityRepository(status));
}

CharacterDto _dto(String name) {
  return CharacterDto(
    id: 1,
    name: name,
    status: 'Alive',
    species: 'Human',
    image: 'https://example/rick.png',
    origin: const CharacterPlaceDto(name: 'Earth'),
    location: const CharacterPlaceDto(name: 'Citadel'),
  );
}

class _ReachabilityRepository implements ReachabilityRepository {
  final BehaviorSubject<Reachability> _status;

  _ReachabilityRepository(this._status);

  @override
  ValueStream<Reachability> observe() => _status.stream;
}

class _Reachability implements connectivity.ReachabilityService {
  @override
  ValueStream<connectivity.Reachability> get status => BehaviorSubject<connectivity.Reachability>();

  @override
  Stream<connectivity.Reachability> get changes => const Stream.empty();

  @override
  Future<void> get ready => Future.value();
}

class _Api implements ApiClient {
  Result<CharacterDto> character;
  var fetches = 0;

  _Api(this.character);

  @override
  FutureResult<CharactersResponseDto> getCharacters({required int page, String? name}) async {
    return Result.value(
      CharactersResponseDto(
        info: const CharacterResponsePageInfoDto(count: 1, pages: 1, next: null, prev: null),
        results: [_dto('Rick C-137')],
      ),
    );
  }

  @override
  FutureResult<CharacterDto> getCharacter(int id) async {
    fetches++;
    return character;
  }
}
