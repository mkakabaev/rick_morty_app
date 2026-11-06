import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:app/navigation/launch_router_gate.dart';
import 'package:app/ui/ui.dart';
import 'package:equatable/equatable.dart';

@immutable
final class LaunchPageBlocState extends Equatable {
  const LaunchPageBlocState();

  @override
  List<Object> get props => [];
}

class LaunchPageBloc extends PageBloc<LaunchPageBlocState> {
  factory LaunchPageBloc(PageHost pageHost, {required LaunchRouterGate launchRouterGate}) {
    return LaunchPageBloc._(const LaunchPageBlocState(), pageHost, launchRouterGate);
  }

  LaunchPageBloc._(super.initialState, super.pageHost, LaunchRouterGate launchRouterGate) {
    unawaited(launchRouterGate.completeLaunch());
  }
}
