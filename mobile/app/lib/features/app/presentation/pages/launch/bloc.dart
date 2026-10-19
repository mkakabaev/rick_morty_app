import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

import 'package:app/di/di.dart';
import 'package:app/navigation/launch_router_gate.dart';
import 'package:app/ui/ui.dart';

@immutable
final class LaunchPageBlocState extends Equatable {
  const LaunchPageBlocState();

  @override
  List<Object> get props => [];
}

class LaunchPageBloc extends PageBloc<LaunchPageBlocState> {
  factory LaunchPageBloc(PageHost pageHost) {
    return LaunchPageBloc._(const LaunchPageBlocState(), pageHost);
  }

  LaunchPageBloc._(super.initialState, super.pageHost) {
    unawaited(getIt<LaunchRouterGate>().completeLaunch());
  }
}
