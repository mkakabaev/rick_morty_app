import 'package:app/di/di.dart';
import 'package:app/features/characters/characters_ui.dart';

import '../route.dart';

import 'character_details.dart';

@lazySingleton
class CharactersRoute extends RickMortyRoute with RickMortyRouteNoParamGo {
  CharactersRoute(CharacterDetailsRoute detailsRoute)
    : super(
        name: 'CharactersRoute',
        path: '/characters',
        presentation: const RickMortyRoutePresentation(transition: .launchFade),
        builder: (_, _) => const CharactersPage(),
        routes: [detailsRoute],
      );
}
