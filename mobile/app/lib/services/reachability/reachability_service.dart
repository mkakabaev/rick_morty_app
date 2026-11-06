import 'package:core/core.dart';

abstract interface class ReachabilityService {
  /// Whether any network interface is up.
  ValueStream<bool> get status;

  /// Reachability transitions after [status] has a value.
  ///
  /// Does not replay the current [status]. `true` is online.
  Stream<bool> get changes;

  /// Completes once [status] has its first value.
  Future<void> get ready;
}
