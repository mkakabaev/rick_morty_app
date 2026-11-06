import 'package:app/di/di.dart';
import 'package:app/features/characters/characters_ui.dart';

import '../route.dart';

import 'character_details.dart';

@lazySingleton
class CharactersRoute extends AppRoute with ParameterlessRoute {
  CharactersRoute(CharacterDetailsRoute detailsRoute)
    : super(
        name: 'CharactersRoute',
        path: '/characters',
        presentation: const NavPresentation(transition: .launchFade),
        builder: (_, _) => const CharactersPage(),
        routes: [detailsRoute],
      );
}
