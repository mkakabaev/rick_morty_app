import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:app/features/reachability/reachability.dart';
import 'package:app/navigation/routes/character_details.dart';
import 'package:app/ui/ui.dart';
import 'package:core/core.dart';
import 'package:equatable/equatable.dart';
import 'package:rxdart/rxdart.dart';

import '../../../domain/entities/character.dart';
import '../../../domain/use_cases/search_characters.dart';

enum CharactersListLoadingKind { firstPage, morePage, refresh }

@immutable
final class CharactersPageBlocState extends Equatable {
  final String query;
  final bool hasMore;
  final int resultsGeneration;
  final int pagesLoaded;
  final ValueState<List<Character>> characters;
  final CharactersListLoadingKind loadingKind;
  final bool isOffline;

  const CharactersPageBlocState({
    required this.query,
    required this.hasMore,
    required this.resultsGeneration,
    required this.pagesLoaded,
    required this.characters,
    required this.loadingKind,
    required this.isOffline,
  });

  CharactersPageBlocState copyWith({
    String? query,
    bool? hasMore,
    int? resultsGeneration,
    int? pagesLoaded,
    ValueState<List<Character>>? characters,
    CharactersListLoadingKind? loadingKind,
    bool? isOffline,
  }) => CharactersPageBlocState(
    query: query ?? this.query,
    hasMore: hasMore ?? this.hasMore,
    resultsGeneration: resultsGeneration ?? this.resultsGeneration,
    pagesLoaded: pagesLoaded ?? this.pagesLoaded,
    characters: characters ?? this.characters,
    loadingKind: loadingKind ?? this.loadingKind,
    isOffline: isOffline ?? this.isOffline,
  );

  @override
  List<Object?> get props => [query, hasMore, resultsGeneration, pagesLoaded, characters, loadingKind, isOffline];

  bool get isRefreshing => characters.isLoading && characters.hasValue && loadingKind == .refresh;
  bool get showLinearProgress => characters.isLoading && characters.hasValue && loadingKind == .firstPage;
  bool get showFooter => hasMore;
  bool get isLoadingMore => characters.isLoading && loadingKind == .morePage;
  AppError? get moreError => loadingKind == .morePage ? characters.error : null;
  int get itemCount => characters.value?.length ?? 0;
  bool get _canLoadMore => hasMore && !isLoadingMore;
}

@visibleForTesting
extension CharactersPageBlocStateTest on CharactersPageBlocState {
  Iterable<String>? characterNames() => characters.value?.map((item) => item.name);
  String? singleCharacterName() => characters.value?.single.name;
  String? charactersErrorMessage() => characters.error?.message;
  bool hasSettledItemCount(int count) => characters.hasValue && itemCount == count && !isRefreshing;
}

class CharactersPageBloc extends PageBloc<CharactersPageBlocState> with Loggable {
  final SearchCharactersUseCase _searchCharacters;
  final CharacterDetailsRoute _characterDetailsRoute;
  final _queryQueue = PublishSubject<String>();
  late final StreamSubscription<void> _debouncedQueries;
  late final StreamSubscription<Reachability> _reachability;
  var _generation = 0;

  @override
  final Tags logTags = const Tags('CharactersPage.Bloc');

  factory CharactersPageBloc(
    PageHost pageHost, {
    required SearchCharactersUseCase searchCharacters,
    required ObserveReachabilityUseCase observeReachability,
    required CharacterDetailsRoute characterDetailsRoute,
  }) {
    final reachability = observeReachability();
    final initialState = CharactersPageBlocState(
      query: '',
      hasMore: false,
      resultsGeneration: 0,
      pagesLoaded: 0,
      characters: const ValueState.empty(),
      loadingKind: .firstPage,
      isOffline: reachability.value.isOffline,
    );

    return CharactersPageBloc._(initialState, pageHost, searchCharacters, characterDetailsRoute, reachability);
  }

  CharactersPageBloc._(
    super.initialState,
    super.pageHost,
    this._searchCharacters,
    this._characterDetailsRoute,
    ValueStream<Reachability> reachability,
  ) {
    _debouncedQueries = _queryQueue.debounceTime(const Duration(milliseconds: 300)).listen((query) {
      // [state.query] is the active query (settled or in-flight), set when a load starts.
      if (query != state.query) {
        unawaited(_loadFirstPage(query: query));
      } else if (state.characters.isLoadFailed) {
        // Same query after a failure retries that failure (page 1 or load-more), same as
        // coming back online.
        _retryFailedLoad();
      }
    });
    _reachability = reachability.listen(_onReachability);
    unawaited(_loadFirstPage(query: ''));
  }

  @override
  Future<void> close() async {
    await _debouncedQueries.cancel();
    await _reachability.cancel();
    await _queryQueue.close();
    await super.close();
  }

  void search(String query) => _queryQueue.add(query.trim());

  void retry() => unawaited(_loadFirstPage(query: state.query));

  void clearSearch() => unawaited(_loadFirstPage(query: '', fromScratch: true));

  Future<void> refresh() => _loadFirstPage(query: state.query, kind: .refresh);

  Future<void> _loadFirstPage({
    required String query,
    CharactersListLoadingKind kind = .firstPage,
    bool fromScratch = false,
  }) async {
    // Keep non-empty rows visible while a new query loads. An empty previous page must not
    // stay on screen — [state.query] updates immediately, so the empty plate would briefly
    // claim "no matches" for the new text before results arrive.
    final keepRows = !fromScratch && state.characters.value?.isNotEmpty == true;
    _startLoading(
      state.copyWith(
        characters: keepRows ? state.characters.startLoading() : const ValueState.loading(null),
        pagesLoaded: fromScratch ? 0 : state.pagesLoaded,
        query: query,
        loadingKind: kind,
        hasMore: false,
      ),
    );

    final generation = ++_generation;
    final result = await _searchCharacters(name: query, page: 1);
    if (generation != _generation || isClosed) {
      return;
    }

    if (result.isError) {
      final error = result.requiredError;
      _failLoading(state.copyWith(characters: ValueState.loadFailed(error, null)));
      return;
    }

    final page = result.requiredValue;
    _completeLoading(
      state.copyWith(
        hasMore: page.hasMore,
        resultsGeneration: state.resultsGeneration + 1,
        pagesLoaded: page.page,
        characters: ValueState.loaded(page.items),
      ),
    );
  }

  void loadMore() {
    unawaited(loadMoreAsync());
  }

  @visibleForTesting
  Future<void> loadMoreAsync() async {
    if (!state._canLoadMore) {
      return;
    }

    _startLoading(state.copyWith(characters: state.characters.startLoading(), loadingKind: .morePage));

    final generation = _generation;
    final result = await _searchCharacters(name: state.query, page: state.pagesLoaded + 1);
    if (generation != _generation || isClosed) {
      return;
    }

    if (result.isError) {
      final error = result.requiredError;
      pageHost.showError(error, isOffline: state.isOffline);
      _failLoading(state.copyWith(characters: state.characters.endLoadingWithError(error)));
      return;
    }

    final page = result.requiredValue;
    _completeLoading(
      state.copyWith(
        characters: state.characters.endLoadingWithValue([...?state.characters.value, ...page.items]),
        pagesLoaded: page.page,
        hasMore: page.hasMore,
      ),
    );
  }

  void _startLoading(CharactersPageBlocState state) {
    log("Query '${state.query}' started for page: ${state.pagesLoaded + 1}...");
    emitSafe(state);
  }

  void _failLoading(CharactersPageBlocState state) {
    log("Query '${state.query}' failed (page: ${state.pagesLoaded + 1}, ${state.characters.error?.message})");
    emitSafe(state);
  }

  void _completeLoading(CharactersPageBlocState state) {
    log(
      "Query '${state.query}' loaded (page: ${state.pagesLoaded}, items: ${state.itemCount}, "
      "hasMore: ${state.hasMore}, generation: ${state.resultsGeneration})",
    );
    emitSafe(state);
  }

  void _onReachability(Reachability reachability) {
    final wasOffline = state.isOffline;
    final isOffline = reachability.isOffline;
    emitSafe(state.copyWith(isOffline: isOffline));
    if (wasOffline && !isOffline) {
      _retryFailedLoad();
    }
  }

  void _retryFailedLoad() {
    if (state.characters.isLoadFailed) {
      switch (state.loadingKind) {
        case .firstPage:
        case .refresh:
          retry();

        case .morePage:
          loadMore();
      }
    }
  }

  void openCharacterDetails(Character character) {
    pageHost.dropFocus();
    _characterDetailsRoute.push(character.id);
  }
}
