import 'package:core/core.dart';

enum Reachability {
  online,
  offline;

  bool get isOnline => this == .online;
  bool get isOffline => this == .offline;
}

abstract interface class ReachabilityService {
  ValueStream<Reachability> get status;

  /// Reachability transitions after [status] has a value.
  ///
  /// Does not replay the current [status].
  Stream<Reachability> get changes;

  /// Completes once [status] has its first online or offline value.
  Future<void> get ready;
}

extension ReachabilityServiceExt on ReachabilityService {
  bool get isOnline => status.value.isOnline;
  bool get isOffline => status.value.isOffline;
}
