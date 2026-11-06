import 'package:app/navigation/routes/character_details.dart';
import 'package:app/navigation/routes/characters.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  late GoRouter router;
  late CharactersRoute characters;

  setUp(() {
    characters = CharactersRoute(CharacterDetailsRoute());
    router = GoRouter(initialLocation: characters.path, routes: [characters]);
    addTearDown(router.dispose);
  });

  test('a numeric id matches the details route', () {
    final match = router.configuration.findMatch(Uri.parse('/characters/42'));

    expect(match.isError, isFalse);
    expect(match.pathParameters, {'characterId': '42'});
    expect(match.last.route, same(characters.routes.single));
  });

  test('a non-numeric id does not match, so it reaches onException instead of the API', () {
    for (final location in ['/characters/abc', '/characters/-1', '/characters/1.5', '/characters/%20']) {
      final match = router.configuration.findMatch(Uri.parse(location));
      expect(match.isError, isTrue, reason: location);
    }
  });

  test('namedLocation still builds the numeric path', () {
    final location = router.namedLocation('CharacterDetailsRoute', pathParameters: {'characterId': '7'});

    expect(location, '/characters/7');
  });
}
