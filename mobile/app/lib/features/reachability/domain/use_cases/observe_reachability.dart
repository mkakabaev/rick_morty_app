import 'package:core/core.dart';

import 'package:app/di/di.dart';

import '../entities/reachability.dart';
import '../repositories/reachability_repository.dart';

@injectable
class ObserveReachabilityUseCase {
  final ReachabilityRepository _repository;

  const ObserveReachabilityUseCase(this._repository);

  ValueStream<Reachability> call() => _repository.observe();
}
