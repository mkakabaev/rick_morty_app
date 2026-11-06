import 'package:flutter/foundation.dart';

import 'package:app/navigation/routes/characters.dart';
import 'package:app/ui/ui.dart';
import 'package:equatable/equatable.dart';

@immutable
final class BadRoutePageBlocState extends Equatable {
  const BadRoutePageBlocState();

  @override
  List<Object> get props => [];
}

class BadRoutePageBloc extends PageBloc<BadRoutePageBlocState> {
  final CharactersRoute _charactersRoute;

  factory BadRoutePageBloc(PageHost pageHost, {required CharactersRoute charactersRoute}) {
    return BadRoutePageBloc._(const BadRoutePageBlocState(), pageHost, charactersRoute);
  }

  BadRoutePageBloc._(super.initialState, super.pageHost, this._charactersRoute);

  void goHome() {
    _charactersRoute.go();
  }
}
