import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

import 'package:app/features/reachability/reachability.dart';
import 'package:app/ui/ui.dart';
import 'package:core/core.dart';

import '../../../domain/entities/character.dart';
import '../../../domain/entities/character_id.dart';
import '../../../domain/use_cases/observe_character.dart';
import '../../../domain/use_cases/reload_character.dart';

@immutable
final class CharacterDetailsPageBlocState extends Equatable {
  final CharacterId characterId;
  final ValueState<Character> character;
  final bool isOffline;

  const CharacterDetailsPageBlocState({
    required this.characterId,
    required this.isOffline,
    this.character = const ValueState.empty(),
  });

  CharacterDetailsPageBlocState copyWith({ValueState<Character>? character, bool? isOffline}) {
    return CharacterDetailsPageBlocState(
      characterId: characterId,
      character: character ?? this.character,
      isOffline: isOffline ?? this.isOffline,
    );
  }

  @override
  List<Object?> get props => [characterId, character, isOffline];
}

class CharacterDetailsPageBloc extends PageBloc<CharacterDetailsPageBlocState> {
  final ReloadCharacterUseCase _reloadCharacter;

  StreamSubscription<ValueState<Character>>? _characterSubscription;
  StreamSubscription<Reachability>? _reachabilitySubscription;

  factory CharacterDetailsPageBloc(
    PageHost pageHost, {
    required CharacterId characterId,
    required ObserveCharacterUseCase observeCharacter,
    required ReloadCharacterUseCase reloadCharacter,
    required ObserveReachabilityUseCase observeReachability,
  }) {
    final stream = observeCharacter(characterId);
    final reachability = observeReachability();
    final initialState = CharacterDetailsPageBlocState(
      characterId: characterId,
      character: stream.value,
      isOffline: reachability.value.isOffline,
    );

    return CharacterDetailsPageBloc._(initialState, pageHost, stream, reachability, reloadCharacter);
  }

  CharacterDetailsPageBloc._(
    super.initialState,
    super.pageHost,
    ValueStream<ValueState<Character>> characterStream,
    ValueStream<Reachability> reachability,
    this._reloadCharacter,
  ) {
    _characterSubscription = characterStream.listen((ch) {
      final error = ch.error;
      if (error != null && ch.hasValue) {
        pageHost.showError(error, isOffline: state.isOffline);
      }
      emitSafe(state.copyWith(character: ch));
    });

    _reachabilitySubscription = reachability.listen((value) {
      emitSafe(state.copyWith(isOffline: value.isOffline));
    });
  }

  @override
  Future<void> close() {
    unawaited(_characterSubscription?.cancel());
    unawaited(_reachabilitySubscription?.cancel());
    return super.close();
  }

  Future<void> reload() async {
    pageHost.hideErrors();
    await _reloadCharacter(state.characterId);
  }
}
