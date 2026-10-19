import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

import 'package:app/di/di.dart';
import 'package:app/navigation/routes/characters.dart';
import 'package:app/ui/ui.dart';

@immutable
final class BadRoutePageBlocState extends Equatable {
  const BadRoutePageBlocState();

  @override
  List<Object> get props => [];
}

class BadRoutePageBloc extends PageBloc<BadRoutePageBlocState> {
  factory BadRoutePageBloc(PageHost pageHost) {
    return BadRoutePageBloc._(const BadRoutePageBlocState(), pageHost);
  }

  BadRoutePageBloc._(super.initialState, super.pageHost);

  void goHome() {
    getIt<CharactersRoute>().go();
  }
}
