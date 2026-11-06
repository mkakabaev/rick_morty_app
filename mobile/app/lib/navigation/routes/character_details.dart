import 'package:app/di/di.dart';
import 'package:app/features/characters/characters.dart';
import 'package:app/features/characters/characters_ui.dart';

import '../route.dart';

const _characterIdKey = 'characterId';

@lazySingleton
class CharacterDetailsRoute extends AppRoute {
  CharacterDetailsRoute()
    : super(
        name: 'CharacterDetailsRoute',
        // Digits only. Anything else does not match this route and lands on `/404`
        // through `onException`, instead of requesting `/character/-1`.
        path: ':$_characterIdKey(\\d+)',
        builder: (_, state) =>
            CharacterDetailsPage(id: CharacterId.fromWire(int.parse(state.pathParameters[_characterIdKey] ?? ''))),
      );

  void push(CharacterId id) => performPush(pathParameters: {_characterIdKey: '${id.toWire}'});
}
