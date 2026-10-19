import 'package:flutter/material.dart';

import 'package:core/core.dart';

import '../../../../domain/entities/character.dart';

import 'character_tile.dart';
import 'characters_list_footer.dart';

class CharacterList extends StatefulWidget {
  final List<Character> items;
  final bool showFooter;
  final String query;
  final bool isLoadingMore;
  final RickMortyError? moreError;
  final bool isOffline;
  final int resultsGeneration;
  final RefreshCallback onRefresh;
  final VoidCallback onLoadMore;
  final ValueChanged<Character> onCharacterTap;
  final ValueChanged<ScrollPosition> onScroll;

  const CharacterList({
    super.key,
    required this.items,
    required this.showFooter,
    required this.query,
    required this.isLoadingMore,
    required this.moreError,
    required this.isOffline,
    required this.resultsGeneration,
    required this.onRefresh,
    required this.onLoadMore,
    required this.onCharacterTap,
    required this.onScroll,
  });

  @override
  State<CharacterList> createState() => _CharacterListState();
}

class _CharacterListState extends State<CharacterList> {
  static RegExp? _patternFor(String query) {
    final needle = query.trim();
    if (needle.isEmpty) {
      return null;
    }
    return RegExp(RegExp.escape(needle), caseSensitive: false, unicode: true);
  }

  final _controller = ScrollController(keepScrollOffset: false);
  late final RegExp? _highlight = _patternFor(widget.query);
  var _jumpScheduled = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_handleScroll);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(CharacterList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.resultsGeneration != oldWidget.resultsGeneration) {
      _jumpToTop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final CharacterList(
      :items,
      :showFooter,
      :moreError,
      :isOffline,
      :isLoadingMore,
      :onLoadMore,
      :onCharacterTap,
      :onScroll,
      :onRefresh,
    ) = widget;

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.builder(
        controller: _controller,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: .fromLTRB(0, 8, 0, bottomInset + 8),
        itemCount: items.length + (showFooter ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= items.length) {
            return CharacterListFooter(
              error: moreError,
              isOffline: isOffline,
              isLoading: isLoadingMore,
              onRetry: onLoadMore,
            );
          }

          final character = items[index];
          return CharacterTile(
            key: ValueKey(character.id),
            character: character,
            highlight: _highlight,
            isOffline: isOffline,
            onTap: onCharacterTap,
          );
        },
      ),
    );
  }

  void _jumpToTop() {
    if (_jumpScheduled) {
      return;
    }
    _jumpScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _jumpScheduled = false;
      if (!mounted) {
        return;
      }
      if (!_controller.hasClients) {
        _jumpToTop();
        return;
      }
      if (_controller.offset != 0) {
        _controller.jumpTo(0);
      }
    });
  }

  void _handleScroll() {
    if (!_controller.hasClients) {
      return;
    }
    widget.onScroll(_controller.position);
  }
}
