import 'package:app/di/di.dart';
import 'package:app/features/app/app_ui.dart';

import '../route.dart';

@lazySingleton
class BadRoutePageRoute extends RickMortyRoute {
  BadRoutePageRoute()
    : super(
        name: 'BadRoutePageRoute',
        path: '/404',
        builder: (_, state) => BadRoutePage(uri: RickMortyRouteExtra.from(state.extra)?.data as Uri? ?? state.uri),
      );

  void go({required Uri uri}) => performGo(data: uri);
}
