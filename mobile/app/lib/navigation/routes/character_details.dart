import 'package:app/di/di.dart';
import 'package:app/features/characters/characters.dart';
import 'package:app/features/characters/characters_ui.dart';

import '../route.dart';

const _characterIdKey = 'characterId';

@lazySingleton
class CharacterDetailsRoute extends RickMortyRoute {
  CharacterDetailsRoute()
    : super(
        name: 'CharacterDetailsRoute',
        path: ':$_characterIdKey',
        builder: (_, state) => CharacterDetailsPage(
          id: CharacterId.fromWire(int.tryParse(state.pathParameters[_characterIdKey] ?? "?") ?? -1),
        ),
      );

  void push(CharacterId id) => performPush(pathParameters: {_characterIdKey: '${id.toWire}'});
}
