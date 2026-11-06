import 'dart:async';

import 'package:app/features/characters/domain/entities/character.dart';
import 'package:app/features/characters/domain/entities/character_id.dart';
import 'package:app/features/characters/domain/entities/character_page.dart';
import 'package:app/features/characters/domain/repositories/characters_repository.dart';
import 'package:core/core.dart';

/// A [CharactersRepository] whose [search] calls are answered by the test, in order.
class ScriptedCharactersRepository implements CharactersRepository {
  final calls = <({String? name, int page})>[];
  final _pending = <Completer<Result<CharacterPage>>>[];

  int get pendingCount => _pending.length;

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
