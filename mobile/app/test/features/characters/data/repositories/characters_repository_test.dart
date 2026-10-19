import 'dart:async';

import 'package:app/features/characters/data/repositories/characters_repository+impl.dart';
import 'package:app/features/characters/domain/entities/character.dart';
import 'package:app/features/characters/domain/entities/character_id.dart';
import 'package:app/services/api_client/api_client.dart';
import 'package:app/services/api_client/dtos/character.dart';
import 'package:app/services/reachability/reachability_service.dart';
import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('maps a character page', () async {
    final repository = CharactersRepositoryImpl(
      _FakeApi(
        Result.value(
          const CharactersResponseDto(
            info: CharacterResponsePageInfoDto(count: 1, pages: 2, next: 'https://example/next', prev: null),
            results: [
              CharacterDto(
                id: 1,
                name: 'Rick Sanchez',
                status: 'Alive',
                species: 'Human',
                image: 'https://example/rick.png',
                origin: CharacterPlaceDto(name: 'Earth (C-137)'),
                location: CharacterPlaceDto(name: 'Citadel of Ricks'),
              ),
            ],
          ),
        ),
      ),
      _Reachability(),
    );

    final result = await repository.search(name: ' Rick ', page: 1);

    final page = result.requiredValue;
    expect(page.hasMore, isTrue);
    expect(page.items.single.name, 'Rick Sanchez');
    expect(page.items.single.status, 'Alive');
    expect(page.items.single.species, 'Human');
    expect(page.items.single.imageUrl, 'https://example/rick.png');
    expect(page.items.single.origin, 'Earth (C-137)');
    expect(page.items.single.location, 'Citadel of Ricks');
  });

  test('maps notFound to an empty page', () async {
    final repository = CharactersRepositoryImpl(
      _FakeApi(Result.error(RickMortyError('There is nothing here', type: .notFound))),
      _Reachability(),
    );

    final result = await repository.search(name: 'zzz', page: 3);

    final page = result.requiredValue;
    expect(page.items, isEmpty);
    expect(page.hasMore, isFalse);
    expect(page.page, 3);
  });

  test('fetches a missing character on observe and then serves the cache', () async {
    const dto = CharacterDto(
      id: 2,
      name: 'Morty Smith',
      status: 'Alive',
      species: 'Human',
      image: 'https://example/morty.png',
      origin: CharacterPlaceDto(name: 'Earth'),
      location: CharacterPlaceDto(name: 'Earth'),
    );
    final api = _FakeCharacterApi(Result.value(dto));
    final repository = CharactersRepositoryImpl(api, _Reachability());

    final first = <ValueState<Character>>[];
    final firstSubscription = repository.character(const CharacterId.fromInt(2)).listen(first.add);
    await pumpEventQueue();

    expect(api.characterFetches, 1);
    expect(first.last.requiredValue.name, 'Morty Smith');
    expect(first.last.requiredValue.origin, 'Earth');
    expect(first.last.requiredValue.location, 'Earth');

    final second = <ValueState<Character>>[];
    final secondSubscription = repository.character(const CharacterId.fromInt(2)).listen(second.add);
    await pumpEventQueue();

    expect(api.characterFetches, 1);
    expect(second.single.requiredValue.id, const CharacterId.fromInt(2));

    await repository.reloadCharacter(const CharacterId.fromInt(2));
    expect(api.characterFetches, 2);
    expect(repository.character(const CharacterId.fromInt(2)).value.requiredValue.name, 'Morty Smith');

    await firstSubscription.cancel();
    await secondSubscription.cancel();
  });

  test('keeps a failed observe empty until reload succeeds', () async {
    const dto = CharacterDto(
      id: 2,
      name: 'Morty Smith',
      status: 'Alive',
      species: 'Human',
      image: 'https://example/morty.png',
      origin: CharacterPlaceDto(name: 'Earth'),
      location: CharacterPlaceDto(name: 'Earth'),
    );
    final api = _FakeCharacterApi(Result.error(RickMortyError('offline')));
    final repository = CharactersRepositoryImpl(api, _Reachability());
    final states = <ValueState<Character>>[];
    final subscription = repository.character(const CharacterId.fromInt(2)).listen(states.add);
    await pumpEventQueue();

    expect(states.last, isA<ValueStateLoadFailed<Character>>());
    expect(states.last.error?.message, 'offline');
    expect(states.last.value, isNull);

    api.character = Result.value(dto);
    await repository.reloadCharacter(const CharacterId.fromInt(2));

    expect(api.characterFetches, 2);
    expect(repository.character(const CharacterId.fromInt(2)).value.requiredValue.name, 'Morty Smith');
    await subscription.cancel();
  });

  test('search fills the cache so observe does not fetch', () async {
    final api = _FakeApi(
      Result.value(
        const CharactersResponseDto(
          info: CharacterResponsePageInfoDto(count: 1, pages: 1, next: null, prev: null),
          results: [
            CharacterDto(
              id: 1,
              name: 'Rick Sanchez',
              status: 'Alive',
              species: 'Human',
              image: 'https://example/rick.png',
              origin: CharacterPlaceDto(name: 'Earth (C-137)'),
              location: CharacterPlaceDto(name: 'Citadel of Ricks'),
            ),
          ],
        ),
      ),
    );
    final repository = CharactersRepositoryImpl(api, _Reachability());

    await repository.search(name: 'Rick', page: 1);
    final states = <ValueState<Character>>[];
    final subscription = repository.character(const CharacterId.fromInt(1)).listen(states.add);
    await pumpEventQueue();

    expect(api.characterFetches, 0);
    expect(states.single.requiredValue.name, 'Rick Sanchez');
    expect(states.single, isA<ValueStateLoaded<Character>>());
    await subscription.cancel();
  });

  test('reloads subscribed characters without data when reachability becomes online', () async {
    const dto = CharacterDto(
      id: 2,
      name: 'Morty Smith',
      status: 'Alive',
      species: 'Human',
      image: 'https://example/morty.png',
      origin: CharacterPlaceDto(name: 'Earth'),
      location: CharacterPlaceDto(name: 'Earth'),
    );
    final api = _FakeCharacterApi(Result.error(RickMortyError('offline')));
    final reachability = _Reachability();
    final repository = CharactersRepositoryImpl(api, reachability);
    final states = <ValueState<Character>>[];
    final subscription = repository.character(const CharacterId.fromInt(2)).listen(states.add);
    await pumpEventQueue();

    expect(api.characterFetches, 1);
    expect(states.last.value, isNull);

    api.character = Result.value(dto);
    reachability.emit(.offline);
    await pumpEventQueue();
    expect(api.characterFetches, 1);

    reachability.emit(.online);
    await pumpEventQueue();

    expect(api.characterFetches, 2);
    expect(states.last.requiredValue.name, 'Morty Smith');
    await subscription.cancel();
  });

  test('leaves loaded and unsubscribed characters alone when reachability becomes online', () async {
    final api = _FakeCharacterApi(Result.error(RickMortyError('offline')));
    final reachability = _Reachability();
    final repository = CharactersRepositoryImpl(api, reachability);

    await repository.reloadCharacter(const CharacterId.fromInt(2));
    expect(api.characterFetches, 1);

    final loaded = _FakeCharacterApi(
      Result.value(
        const CharacterDto(
          id: 1,
          name: 'Rick Sanchez',
          status: 'Alive',
          species: 'Human',
          image: 'https://example/rick.png',
          origin: CharacterPlaceDto(name: 'Earth'),
          location: CharacterPlaceDto(name: 'Earth'),
        ),
      ),
    );
    final loadedRepository = CharactersRepositoryImpl(loaded, reachability);
    final subscription = loadedRepository.character(const CharacterId.fromInt(1)).listen((_) {});
    await pumpEventQueue();
    expect(loaded.characterFetches, 1);

    reachability.emit(.online);
    await pumpEventQueue();

    expect(api.characterFetches, 1);
    expect(loaded.characterFetches, 1);
    await subscription.cancel();
  });
}

class _Reachability implements ReachabilityService {
  final _status = BehaviorSubject<Reachability>.seeded(.offline);
  final _changes = StreamController<Reachability>.broadcast();

  @override
  ValueStream<Reachability> get status => _status;

  @override
  Stream<Reachability> get changes => _changes.stream;

  @override
  Future<void> get ready => Future.value();

  void emit(Reachability value) {
    _status.add(value);
    _changes.add(value);
  }
}

class _FakeApi implements ApiClient {
  final Result<CharactersResponseDto> _page;
  var characterFetches = 0;

  _FakeApi(this._page);

  @override
  FutureResult<CharactersResponseDto> getCharacters({required int page, String? name}) async => _page;

  @override
  FutureResult<CharacterDto> getCharacter(int id) async {
    characterFetches++;
    throw StateError('getCharacter was not stubbed');
  }
}

class _FakeCharacterApi implements ApiClient {
  Result<CharacterDto> character;
  var characterFetches = 0;

  _FakeCharacterApi(this.character);

  @override
  FutureResult<CharactersResponseDto> getCharacters({required int page, String? name}) {
    throw StateError('getCharacters was not stubbed');
  }

  @override
  FutureResult<CharacterDto> getCharacter(int id) async {
    characterFetches++;
    return character;
  }
}
