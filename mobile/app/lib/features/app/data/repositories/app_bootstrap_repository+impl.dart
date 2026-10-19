import 'package:app/di/di.dart';
import 'package:app/services/reachability/reachability_service.dart';

import '../../domain/repositories/app_bootstrap_repository.dart';

@LazySingleton(as: AppBootstrapRepository)
class AppBootstrapRepositoryImpl implements AppBootstrapRepository {
  final ReachabilityService _reachability;
  Future<void>? _started;

  AppBootstrapRepositoryImpl(this._reachability);

  @override
  Future<void> start() => _started ??= _bootstrap();

  Future<void> _bootstrap() async {
    await _reachability.ready;
  }
}
