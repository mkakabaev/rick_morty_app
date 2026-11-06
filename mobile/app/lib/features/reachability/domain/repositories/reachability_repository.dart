import 'package:core/core.dart';

import '../entities/reachability.dart';

abstract interface class ReachabilityRepository {
  ValueStream<Reachability> observe();
}
