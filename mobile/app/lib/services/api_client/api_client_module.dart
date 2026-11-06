import 'package:app/app_config.dart';
import 'package:app/di/di.dart';

import 'api_client.dart';
import 'rest_api_client.dart';

@module
abstract class ApiClientModule {
  @lazySingleton
  ApiClient apiClient(AppConfig config) => RestApiClient(endpoint: config.apiBaseUrl);
}
