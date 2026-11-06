import 'dart:async';

import 'package:app/features/characters/domain/entities/character.dart';
import 'package:app/features/characters/domain/entities/character_id.dart';
import 'package:app/features/characters/domain/entities/character_page.dart';
import 'package:app/features/characters/domain/repositories/characters_repository.dart';
import 'package:app/features/characters/domain/use_cases/search_characters.dart';
import 'package:app/features/characters/presentation/pages/characters/bloc.dart';
import 'package:app/features/reachability/domain/entities/reachability.dart';
import 'package:app/features/reachability/domain/repositories/reachability_repository.dart';
import 'package:app/features/reachability/domain/use_cases/observe_reachability.dart';
import 'package:app/navigation/routes/character_details.dart';
import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../../support/recording_page_host.dart';

void main() {
  test('appends the next page and replaces items when the query changes', () async {
    final repository = _ScriptedRepository();
    final bloc = _bloc(repository);
    addTearDown(bloc.close);

    repository.complete(const CharacterPage(items: [_rick], page: 1, hasMore: true));
    await _until(() => bloc.state.itemCount == 1);

    final more = bloc.loadMoreAsync();
    repository.complete(const CharacterPage(items: [_morty], page: 2, hasMore: false));
    await more;

    expect(bloc.state.characterNames(), ['Rick Sanchez', 'Morty Smith']);
    expect(bloc.state.hasMore, isFalse);

    bloc.search('Mo');
    bloc.search('Morty');
    expect(bloc.state.characterNames(), ['Rick Sanchez', 'Morty Smith']);
    expect(bloc.state.isRefreshing, isFalse);
    await Future<void>.delayed(const Duration(milliseconds: 100));
    expect(bloc.state.isRefreshing, isFalse);
    expect(repository.calls.length, 2);

    await Future<void>.delayed(const Duration(milliseconds: 250));
    expect(bloc.state.showLinearProgress, isTrue);
    expect(bloc.state.characterNames(), ['Rick Sanchez', 'Morty Smith']);
    expect(repository.calls.length, 3);
    repository.complete(const CharacterPage(items: [_morty], page: 1, hasMore: false));
    await _until(() => bloc.state.hasSettledItemCount(1));

    expect(bloc.state.singleCharacterName(), 'Morty Smith');
    expect(repository.calls.last.name, 'Morty');
    expect(repository.calls.last.page, 1);
  });

  test('shortening a query that had no matches clears the empty plate while loading', () async {
    final repository = _ScriptedRepository();
    final bloc = _bloc(repository);
    addTearDown(bloc.close);

    repository.complete(const CharacterPage(items: [], page: 1, hasMore: false));
    await _until(() => bloc.state.hasSettledItemCount(0));
    expect(bloc.state.query, '');

    bloc.search('zz');
    await Future<void>.delayed(const Duration(milliseconds: 350));
    repository.complete(const CharacterPage(items: [], page: 1, hasMore: false));
    await _until(() => bloc.state.query == 'zz' && bloc.state.hasSettledItemCount(0));

    bloc.search('z');
    await Future<void>.delayed(const Duration(milliseconds: 350));

    expect(bloc.state.query, 'z');
    expect(bloc.state.characters.isLoading, isTrue);
    expect(bloc.state.characters.value, isNull);
    expect(bloc.state.showLinearProgress, isFalse);

    repository.complete(const CharacterPage(items: [_rick], page: 1, hasMore: false));
    await _until(() => bloc.state.hasSettledItemCount(1));
    expect(bloc.state.singleCharacterName(), 'Rick Sanchez');
  });

  test('the same query after a failed first page starts another load', () async {
    final repository = _ScriptedRepository();
    final bloc = _bloc(repository);
    addTearDown(bloc.close);

    repository.fail(AppError('server'));
    await _until(() => bloc.state.charactersErrorMessage() == 'server');
    expect(bloc.state.query, '');
    expect(repository.calls, hasLength(1));

    bloc.search('r');
    await Future<void>.delayed(const Duration(milliseconds: 350));
    expect(repository.calls, hasLength(2));
    repository.fail(AppError('server'));
    await _until(() => bloc.state.query == 'r' && bloc.state.characters.isLoadFailed);

    // Same string again after a failure must not be treated as a no-op.
    bloc.search('r');
    await Future<void>.delayed(const Duration(milliseconds: 350));
    expect(repository.calls, hasLength(3));
    expect(repository.calls.last.name, 'r');
  });

  test('the same query after a failed next page retries load more, not page 1', () async {
    final repository = _ScriptedRepository();
    final bloc = _bloc(repository);
    addTearDown(bloc.close);

    repository.complete(const CharacterPage(items: [_rick], page: 1, hasMore: true));
    await _until(() => bloc.state.itemCount == 1);

    final more = bloc.loadMoreAsync();
    repository.fail(AppError('timeout'));
    await more;
    expect(bloc.state.moreError?.message, 'timeout');
    expect(repository.calls, hasLength(2));

    bloc.search('');
    await Future<void>.delayed(const Duration(milliseconds: 350));
    expect(repository.calls, hasLength(3));
    expect(repository.calls.last, (name: '', page: 2));

    repository.complete(const CharacterPage(items: [_morty], page: 2, hasMore: false));
    await _until(() => bloc.state.hasSettledItemCount(2));

    expect(bloc.state.characterNames(), ['Rick Sanchez', 'Morty Smith']);
    expect(bloc.state.moreError, isNull);
  });

  test('clearing the field while a typed query is in flight reloads the unfiltered list', () async {
    final repository = _ScriptedRepository();
    final bloc = _bloc(repository);
    addTearDown(bloc.close);

    repository.complete(const CharacterPage(items: [_rick, _morty], page: 1, hasMore: false));
    await _until(() => bloc.state.itemCount == 2);

    bloc.search('r');
    await Future<void>.delayed(const Duration(milliseconds: 350));
    expect(repository.calls, hasLength(2));
    expect(repository.calls.last.name, 'r');

    // The user deletes the text before the 'r' request completes.
    bloc.search('');
    await Future<void>.delayed(const Duration(milliseconds: 350));
    expect(repository.calls, hasLength(3));
    expect(repository.calls.last.name, '');

    // The stale 'r' result is ignored; only the '' result is applied.
    repository.complete(const CharacterPage(items: [_rick], page: 1, hasMore: false));
    repository.complete(const CharacterPage(items: [_rick, _morty], page: 1, hasMore: false));
    await _until(() => bloc.state.hasSettledItemCount(2));

    expect(bloc.state.query, '');
    expect(bloc.state.characterNames(), ['Rick Sanchez', 'Morty Smith']);
  });

  test('reports a fetch failure through the page host and keeps loaded rows', () async {
    final host = RecordingPageHost();
    final repository = _ScriptedRepository();
    final bloc = _bloc(repository, host);
    addTearDown(bloc.close);

    repository.complete(const CharacterPage(items: [_rick], page: 1, hasMore: true));
    await _until(() => bloc.state.itemCount == 1);

    final more = bloc.loadMoreAsync();
    repository.fail(AppError('offline'));
    await more;

    expect(host.errors.single.message, 'offline');
    expect(host.shownOffline, [false]);
    expect(bloc.state.singleCharacterName(), 'Rick Sanchez');
    expect(bloc.state.charactersErrorMessage(), 'offline');
  });

  test('refresh keeps the current rows until the reload finishes', () async {
    final host = RecordingPageHost();
    final repository = _ScriptedRepository();
    final bloc = _bloc(repository, host);
    addTearDown(bloc.close);

    repository.complete(const CharacterPage(items: [_rick], page: 1, hasMore: false));
    await _until(() => bloc.state.itemCount == 1);

    final refresh = bloc.refresh();
    expect(bloc.state.isRefreshing, isTrue);
    expect(bloc.state.singleCharacterName(), 'Rick Sanchez');
    repository.fail(AppError('offline'));
    await refresh;

    expect(host.errors, isEmpty);
    expect(bloc.state.charactersErrorMessage(), 'offline');
    expect(bloc.state.itemCount, 0);
    expect(bloc.state.isRefreshing, isFalse);

    final again = bloc.refresh();
    repository.complete(const CharacterPage(items: [_morty], page: 1, hasMore: false));
    await again;

    expect(bloc.state.singleCharacterName(), 'Morty Smith');
    expect(bloc.state.isRefreshing, isFalse);
  });

  test('retries a failed first page when reachability returns', () async {
    final reachability = _Reachability(.offline);
    final repository = _ScriptedRepository();
    final bloc = _bloc(repository, null, reachability);
    addTearDown(bloc.close);

    repository.fail(AppError('server'));
    await _until(() => bloc.state.charactersErrorMessage() == 'server');
    expect(bloc.state.isOffline, isTrue);
    expect(repository.calls, hasLength(1));

    reachability.emit(.online);
    await _until(() => repository.calls.length == 2);

    expect(bloc.state.isOffline, isFalse);
    expect(repository.calls.last.page, 1);
    expect(repository.calls.last.name, '');
  });

  test('retries a failed next page when reachability returns', () async {
    final reachability = _Reachability(.online);
    final repository = _ScriptedRepository();
    final bloc = _bloc(repository, null, reachability);
    addTearDown(bloc.close);

    repository.complete(const CharacterPage(items: [_rick], page: 1, hasMore: true));
    await _until(() => bloc.state.itemCount == 1);

    final more = bloc.loadMoreAsync();
    repository.fail(AppError('timeout'));
    await more;
    expect(repository.calls, hasLength(2));

    reachability.emit(.offline);
    await _until(() => bloc.state.isOffline);
    expect(repository.calls, hasLength(2));

    reachability.emit(.online);
    await _until(() => repository.calls.length == 3);

    expect(repository.calls.last.page, 2);
    expect(repository.calls.last.name, '');
  });
}

CharactersPageBloc _bloc(_ScriptedRepository repository, [RecordingPageHost? host, _Reachability? reachability]) {
  final status = reachability ?? _Reachability(.online);
  addTearDown(status.dispose);
  return CharactersPageBloc(
    host ?? RecordingPageHost(),
    searchCharacters: SearchCharactersUseCase(repository),
    observeReachability: ObserveReachabilityUseCase(status),
    characterDetailsRoute: CharacterDetailsRoute(),
  );
}

Future<void> _until(bool Function() ready) async {
  for (var attempt = 0; attempt < 20 && !ready(); attempt += 1) {
    await Future<void>.delayed(Duration.zero);
  }
  expect(ready(), isTrue);
}

const _rick = Character(
  id: CharacterId.fromInt(1),
  name: 'Rick Sanchez',
  status: 'Alive',
  species: 'Human',
  imageUrl: 'https://example/rick.png',
  origin: 'Earth',
  location: 'Citadel',
);

const _morty = Character(
  id: CharacterId.fromInt(2),
  name: 'Morty Smith',
  status: 'Alive',
  species: 'Human',
  imageUrl: 'https://example/morty.png',
  origin: 'Earth',
  location: 'Earth',
);

class _Reachability implements ReachabilityRepository {
  final BehaviorSubject<Reachability> _status;

  _Reachability(Reachability initial) : _status = BehaviorSubject.seeded(initial, sync: true);

  @override
  ValueStream<Reachability> observe() => _status.stream;

  void emit(Reachability value) {
    _status.add(value);
  }

  Future<void> dispose() => _status.close();
}

class _ScriptedRepository implements CharactersRepository {
  final calls = <({String? name, int page})>[];
  final _pending = <Completer<Result<CharacterPage>>>[];

  @override
  FutureResult<CharacterPage> search({String? name, required int page}) {
    calls.add((name: name, page: page));
    final completer = Completer<Result<CharacterPage>>();
    _pending.add(completer);
    return completer.future;
  }

  void complete(CharacterPage page) {
    _pending.removeAt(0).complete(Result.value(page));
  }

  void fail(AppError error) {
    _pending.removeAt(0).complete(Result.error(error));
  }

  @override
  ValueStream<ValueState<Character>> character(CharacterId id) => throw UnimplementedError();

  @override
  Future<ValueState<Character>> reloadCharacter(CharacterId id) => throw UnimplementedError();
}
