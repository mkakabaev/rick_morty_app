// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes

import 'package:app/app_config.dart' as _i433;
import 'package:app/features/app/app.dart' as _i901;
import 'package:app/features/app/data/repositories/app_bootstrap_repository+impl.dart'
    as _i519;
import 'package:app/features/app/domain/repositories/app_bootstrap_repository.dart'
    as _i816;
import 'package:app/features/app/domain/use_cases/start_app_bootstrap.dart'
    as _i62;
import 'package:app/features/characters/data/repositories/characters_repository+impl.dart'
    as _i500;
import 'package:app/features/characters/domain/repositories/characters_repository.dart'
    as _i575;
import 'package:app/features/characters/domain/use_cases/observe_character.dart'
    as _i1035;
import 'package:app/features/characters/domain/use_cases/reload_character.dart'
    as _i553;
import 'package:app/features/characters/domain/use_cases/search_characters.dart'
    as _i47;
import 'package:app/features/reachability/data/repositories/reachability_repository+impl.dart'
    as _i44;
import 'package:app/features/reachability/domain/repositories/reachability_repository.dart'
    as _i1022;
import 'package:app/features/reachability/domain/use_cases/observe_reachability.dart'
    as _i423;
import 'package:app/navigation/launch_router_gate.dart' as _i730;
import 'package:app/navigation/routes/bad_route_page.dart' as _i328;
import 'package:app/navigation/routes/character_details.dart' as _i71;
import 'package:app/navigation/routes/characters.dart' as _i400;
import 'package:app/navigation/routes/launch.dart' as _i867;
import 'package:app/services/api_client/api_client.dart' as _i595;
import 'package:app/services/api_client/api_client_module.dart' as _i440;
import 'package:app/services/image_service/image_service+impl.dart' as _i41;
import 'package:app/services/image_service/image_service.dart' as _i666;
import 'package:app/services/reachability/reachability_service+impl.dart'
    as _i410;
import 'package:app/services/reachability/reachability_service.dart' as _i959;
import 'package:get_it/get_it.dart' as _i174;
import 'package:injectable/injectable.dart' as _i526;

extension GetItInjectableX on _i174.GetIt {
  // initializes the registration of main-scope dependencies inside of GetIt
  _i174.GetIt init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) {
    final gh = _i526.GetItHelper(this, environment, environmentFilter);
    final appConfigModule = _$AppConfigModule();
    final apiClientModule = _$ApiClientModule();
    gh.lazySingleton<_i433.AppConfig>(() => appConfigModule.appConfig());
    gh.lazySingleton<_i328.BadRoutePageRoute>(() => _i328.BadRoutePageRoute());
    gh.lazySingleton<_i71.CharacterDetailsRoute>(
      () => _i71.CharacterDetailsRoute(),
    );
    gh.lazySingleton<_i867.LaunchRoute>(() => _i867.LaunchRoute());
    gh.lazySingleton<_i666.ImageService>(() => _i41.ImageServiceImpl());
    gh.lazySingleton<_i400.CharactersRoute>(
      () => _i400.CharactersRoute(gh<_i71.CharacterDetailsRoute>()),
    );
    gh.lazySingleton<_i959.ReachabilityService>(
      () => _i410.ReachabilityServiceImpl(),
    );
    gh.lazySingleton<_i816.AppBootstrapRepository>(
      () => _i519.AppBootstrapRepositoryImpl(gh<_i959.ReachabilityService>()),
    );
    gh.lazySingleton<_i1022.ReachabilityRepository>(
      () => _i44.ReachabilityRepositoryImpl(gh<_i959.ReachabilityService>()),
    );
    gh.lazySingleton<_i595.ApiClient>(
      () => apiClientModule.apiClient(gh<_i433.AppConfig>()),
    );
    gh.factory<_i423.ObserveReachabilityUseCase>(
      () =>
          _i423.ObserveReachabilityUseCase(gh<_i1022.ReachabilityRepository>()),
    );
    gh.factory<_i62.StartAppBootstrapUseCase>(
      () => _i62.StartAppBootstrapUseCase(gh<_i816.AppBootstrapRepository>()),
    );
    gh.lazySingleton<_i575.CharactersRepository>(
      () => _i500.CharactersRepositoryImpl(
        gh<_i595.ApiClient>(),
        gh<_i959.ReachabilityService>(),
      ),
    );
    gh.factory<_i1035.ObserveCharacterUseCase>(
      () => _i1035.ObserveCharacterUseCase(gh<_i575.CharactersRepository>()),
    );
    gh.factory<_i553.ReloadCharacterUseCase>(
      () => _i553.ReloadCharacterUseCase(gh<_i575.CharactersRepository>()),
    );
    gh.factory<_i47.SearchCharactersUseCase>(
      () => _i47.SearchCharactersUseCase(gh<_i575.CharactersRepository>()),
    );
    gh.lazySingleton<_i730.LaunchRouterGate>(
      () => _i730.LaunchRouterGate(
        gh<_i901.StartAppBootstrapUseCase>(),
        gh<_i867.LaunchRoute>(),
        gh<_i400.CharactersRoute>(),
        gh<_i328.BadRoutePageRoute>(),
      ),
    );
    return this;
  }
}

class _$AppConfigModule extends _i433.AppConfigModule {}

class _$ApiClientModule extends _i440.ApiClientModule {}
