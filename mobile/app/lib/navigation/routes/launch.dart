import 'package:app/di/di.dart';
import 'package:app/features/app/app_ui.dart';

import '../route.dart';

@lazySingleton
class LaunchRoute extends RickMortyRoute {
  LaunchRoute()
    : super(name: 'LaunchRoute', path: '/launch', trackAnalytics: false, builder: (_, _) => const LaunchPage());
}
