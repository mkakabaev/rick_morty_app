import 'package:flutter/material.dart';

import 'package:app/di/di.dart';
import 'package:app/features/reachability/reachability.dart';
import 'package:app/l10n/l10n.dart';
import 'package:app/ui/ui.dart';
import 'package:core/core.dart';

import '../../../domain/entities/character.dart';
import '../../../domain/use_cases/search_characters.dart';

import 'bloc.dart';
import 'widgets/characters_list.dart';
import 'widgets/search_field.dart';
import 'widgets/no_characters_found.dart';
import 'widgets/scroll_shadow.dart';

class CharactersPage extends StatefulWidget {
  const CharactersPage({super.key});

  @override
  State createState() => _CharactersPageState();
}

class _CharactersPageState extends PageState<CharactersPage, CharactersPageBloc, CharactersPageBlocState> {
  final _queryController = TextEditingController();
  var _contentScrolled = false;
  final _loadMoreMarker = _LoadMoreMarker();
  final _resultsIdentity = _ResultsIdentity();

  @override
  CharactersPageBloc createBloc() => .new(
    host,
    searchCharacters: getIt<SearchCharactersUseCase>(),
    observeReachability: getIt<ObserveReachabilityUseCase>(),
  );

  @override
  bool get useBlocSelectors => true;

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  @override
  Widget buildPage(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.characters), notificationPredicate: (_) => false),
      body: Column(
        children: [
          blocSelector(
            selector: (state) => state.query,
            builder: (context, query) => CharacterSearchField(
              controller: _queryController,
              query: query,
              onChanged: bloc.search,
              onClear: _clearQuery,
              onTapOutside: host.dropFocus,
            ),
          ),

          blocSelector(
            selector: (state) => state.showLinearProgress,
            builder: (context, showLinearProgress) => SizedBox(
              height: 3,
              child: showLinearProgress ? const LinearProgressIndicator(minHeight: 3) : const SizedBox.shrink(),
            ),
          ),

          Expanded(
            child: Stack(
              children: [
                NotificationListener<UserScrollNotification>(
                  onNotification: _dismissKeyboard,
                  child: _buildBody(context),
                ),
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: blocSelector(
                    selector: (state) => state.itemCount > 0,
                    builder: (_, hasItems) => ScrollShadow(opacity: _contentScrolled && hasItems ? 1 : 0),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void didBlocChange(BuildContext context, CharactersPageBlocState blocState) {
    _loadMoreMarker.update(blocState);

    if (_resultsIdentity.update(blocState) && _contentScrolled) {
      setState(() => _contentScrolled = false);
    }
  }

  Widget _buildBody(BuildContext _) {
    return blocSelector(
      selector: (state) => (
        state.characters,
        state.showFooter,
        state.query,
        state.isLoadingMore,
        state.moreError,
        state.isOffline,
        state.resultsGeneration,
      ),
      builder: (context, selected) {
        final (characters, showFooter, query, isLoadingMore, moreError, isOffline, resultsGeneration) = selected;

        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          layoutBuilder: _charactersBodyLayout,
          transitionBuilder: _charactersBodyFade,
          child: _bodyContent(
            characters: characters,
            showFooter: showFooter,
            query: query,
            isLoadingMore: isLoadingMore,
            moreError: moreError,
            isOffline: isOffline,
            resultsGeneration: resultsGeneration,
          ),
        );
      },
    );
  }

  static Widget _charactersBodyLayout(Widget? currentChild, List<Widget> previousChildren) {
    return Stack(fit: .expand, children: [...previousChildren, ?currentChild]);
  }

  static Widget _charactersBodyFade(Widget child, Animation<double> animation) {
    return FadeTransition(
      opacity: animation,
      child: ListenableBuilder(
        listenable: animation,
        builder: (context, child) => IgnorePointer(ignoring: animation.status == .reverse, child: child),
        child: child,
      ),
    );
  }

  Widget _bodyContent({
    required ValueState<List<Character>> characters,
    required bool showFooter,
    required String query,
    required bool isLoadingMore,
    required RickMortyError? moreError,
    required bool isOffline,
    required int resultsGeneration,
  }) {
    // Has a content
    final items = characters.value;
    if (items != null) {
      if (items.isEmpty) {
        return NoCharactersFound(
          key: _resultsIdentity.key,
          query: query,
          onClear: _clearQuery,
          onRefresh: bloc.refresh,
        );
      }

      return CharacterList(
        key: _resultsIdentity.key,
        items: items,
        showFooter: showFooter,
        query: query,
        isLoadingMore: isLoadingMore,
        moreError: moreError,
        isOffline: isOffline,
        resultsGeneration: resultsGeneration,
        onRefresh: bloc.refresh,
        onLoadMore: bloc.loadMore,
        onCharacterTap: bloc.openCharacterDetails,
        onScroll: _onResultsScroll,
      );
    }

    // Has an error
    final error = characters.error;
    if (error != null) {
      return ErrorPlate(key: const ValueKey("error"), error: error, isOffline: isOffline, onRetry: bloc.retry);
    }

    // Is loading
    return const LoadingPlate(key: ValueKey("loading"));
  }

  void _clearQuery() {
    host.dropFocus();

    if (_queryController.text.isNotEmpty) {
      _queryController.clear();
      bloc.clearSearch();
    }
  }

  bool _dismissKeyboard(UserScrollNotification notification) {
    host.dropFocus();
    return false;
  }

  void _onResultsScroll(ScrollPosition position) {
    final contentScrolled = position.pixels > 0;
    if (contentScrolled != _contentScrolled) {
      setState(() => _contentScrolled = contentScrolled);
    }

    if (_loadMoreMarker.shouldLoadMore(position)) {
      bloc.loadMore();
    }
  }
}

class _ResultsIdentity {
  var _generation = -1;
  var _query = '';
  var _itemCount = 0;

  /// Updates the switcher identity when a new first page arrives.
  /// Appending a page keeps the previous query and count so the list does not crossfade.
  bool update(CharactersPageBlocState state) {
    if (state.resultsGeneration == _generation || state.characters.value == null) {
      return false;
    }

    final changed = _query != state.query || _itemCount != state.itemCount;
    _generation = state.resultsGeneration;
    _query = state.query;
    _itemCount = state.itemCount;
    return changed;
  }

  Key get key => ValueKey(("items", _query, _itemCount));
}

/// Keeps the next page from loading twice before layout grows the scroll extent.
///
/// A load-more error blocks another automatic fetch. The block clears once the user
/// scrolls up until the end is more than half a viewport, plus a few pixels, away.
class _LoadMoreMarker {
  static const _releaseSlack = 24.0;

  var _generation = 0;
  var _itemCount = 0;
  double? _maxScrollExtent;
  var _errorLatched = false;
  var _blocked = false;

  void update(CharactersPageBlocState state) {
    final itemCount = state.itemCount;
    if (state.isRefreshing || itemCount < _itemCount || state.resultsGeneration != _generation) {
      _maxScrollExtent = null;
      _errorLatched = false;
      _blocked = false;
    }
    _itemCount = itemCount;
    _generation = state.resultsGeneration;
    if (state.moreError != null) {
      if (!_errorLatched) {
        _errorLatched = true;
        _blocked = true;
      }
    } else {
      _errorLatched = false;
      _blocked = false;
    }
  }

  bool shouldLoadMore(ScrollPosition position) {
    final maxScrollExtent = position.maxScrollExtent;
    final halfViewport = position.viewportDimension / 2;
    final distanceFromEnd = maxScrollExtent - position.pixels;

    if (_blocked) {
      if (distanceFromEnd < halfViewport + _releaseSlack) {
        return false;
      }
      _blocked = false;
      _maxScrollExtent = null;
    }

    if (distanceFromEnd > halfViewport) {
      return false;
    }

    final seen = _maxScrollExtent;
    if (seen != null && maxScrollExtent <= seen) {
      return false;
    }
    _maxScrollExtent = maxScrollExtent;
    return true;
  }
}
