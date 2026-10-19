import 'package:app/di/di.dart';

import '../repositories/app_bootstrap_repository.dart';

@injectable
class StartAppBootstrapUseCase {
  final AppBootstrapRepository _repository;

  const StartAppBootstrapUseCase(this._repository);

  Future<void> call() => _repository.start();
}
