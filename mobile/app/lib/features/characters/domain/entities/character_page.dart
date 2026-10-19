import 'package:equatable/equatable.dart';

import 'character.dart';

class CharacterPage extends Equatable {
  final List<Character> items;
  final int page;
  final bool hasMore;

  const CharacterPage({required this.items, required this.page, required this.hasMore});

  @override
  List<Object> get props => [items, page, hasMore];
}
