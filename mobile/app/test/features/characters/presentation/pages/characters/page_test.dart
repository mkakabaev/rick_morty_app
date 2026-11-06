import 'package:flutter/material.dart';

import 'package:app/di/di.dart';
import 'package:app/features/characters/characters_ui.dart';
import 'package:app/features/characters/domain/entities/character.dart';
import 'package:app/features/characters/domain/entities/character_id.dart';
import 'package:app/features/characters/domain/entities/character_page.dart';
import 'package:app/features/characters/domain/use_cases/search_characters.dart';
import 'package:app/features/reachability/domain/entities/reachability.dart';
import 'package:app/features/reachability/domain/repositories/reachability_repository.dart';
import 'package:app/features/reachability/domain/use_cases/observe_reachability.dart';
import 'package:app/l10n/l10n.dart';
import 'package:app/navigation/routes/character_details.dart';
import 'package:app/ui/ui.dart';
import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../../support/fake_image_service.dart';
import '../../../../../support/scripted_characters_repository.dart';

void main() {
  late ScriptedCharactersRepository repository;
  late _Reachability reachability;
  late FakeImageService images;

  setUp(() async {
    await getIt.reset();
    repository = ScriptedCharactersRepository();
    reachability = _Reachability();
    images = FakeImageService()..holdOpen = true;
    getIt.registerFactory(() => SearchCharactersUseCase(repository));
    getIt.registerFactory(() => ObserveReachabilityUseCase(reachability));
    getIt.registerFactory(CharacterDetailsRoute.new);
  });

  tearDown(() async {
    await images.dispose();
    await reachability.dispose();
    await getIt.reset();
  });

  Future<void> pumpPage(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: applyAppColors(ThemeData()),
        home: ImageCacheScope(cacheManager: images.cacheManager, child: const CharactersPage()),
      ),
    );
  }

  // The AnimatedSwitcher crossfade is 300ms; image spinners animate forever, so pumpAndSettle is unusable.
  Future<void> settle(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
  }

  testWidgets('shows a loader, then the first page of characters', (tester) async {
    await pumpPage(tester);

    expect(find.byType(LoadingPlate), findsOneWidget);
    expect(repository.calls.single, (name: '', page: 1));

    repository.complete(const CharacterPage(items: [_rick, _morty], page: 1, hasMore: false));
    await settle(tester);

    expect(find.byType(LoadingPlate), findsNothing);
    expect(find.text('Rick Sanchez'), findsOneWidget);
    expect(find.text('Morty Smith'), findsOneWidget);
  });

  testWidgets('typing searches after the debounce and shows the empty state for no matches', (tester) async {
    await pumpPage(tester);
    repository.complete(const CharacterPage(items: [_rick], page: 1, hasMore: false));
    await settle(tester);

    await tester.enterText(find.byType(TextField), 'zzz');
    await tester.pump(const Duration(milliseconds: 100));
    expect(repository.calls, hasLength(1));

    await tester.pump(const Duration(milliseconds: 300));
    expect(repository.calls, hasLength(2));
    expect(repository.calls.last, (name: 'zzz', page: 1));

    repository.complete(const CharacterPage(items: [], page: 1, hasMore: false));
    await settle(tester);

    expect(find.text('No characters match "zzz"'), findsOneWidget);
    expect(find.text('Rick Sanchez'), findsNothing);

    await tester.tap(find.text('Clear search'));
    await settle(tester);
    expect(repository.calls.last, (name: '', page: 1));
  });

  testWidgets('a failed first page shows the error plate and retry reloads', (tester) async {
    await pumpPage(tester);
    repository.fail(AppError('Server error', type: .internalServerError));
    await settle(tester);

    expect(find.byType(ErrorPlate), findsOneWidget);
    expect(find.text('Something went wrong'), findsOneWidget);
    expect(find.text('Server error'), findsOneWidget);

    await tester.tap(find.text('Retry'));
    await tester.pump();
    expect(repository.calls, hasLength(2));

    repository.complete(const CharacterPage(items: [_rick], page: 1, hasMore: false));
    await settle(tester);

    expect(find.byType(ErrorPlate), findsNothing);
    expect(find.text('Rick Sanchez'), findsOneWidget);
  });

  testWidgets('offline hides retry and coming back online retries the failed load', (tester) async {
    reachability.emit(.offline);
    await pumpPage(tester);
    repository.fail(AppError('socket', type: .network));
    await settle(tester);

    expect(find.text('No internet connection'), findsOneWidget);
    expect(find.text('Retry'), findsNothing);

    reachability.emit(.online);
    await tester.pump();
    expect(repository.calls, hasLength(2));
  });
}

const _rick = Character(
  id: CharacterId.fromInt(1),
  name: 'Rick Sanchez',
  status: 'Alive',
  species: 'Human',
  imageUrl: 'https://example/rick.png',
  origin: 'Earth',
  location: 'Citadel',
);

const _morty = Character(
  id: CharacterId.fromInt(2),
  name: 'Morty Smith',
  status: 'Alive',
  species: 'Human',
  imageUrl: 'https://example/morty.png',
  origin: 'Earth',
  location: 'Earth',
);

class _Reachability implements ReachabilityRepository {
  final _status = BehaviorSubject<Reachability>.seeded(.online, sync: true);

  @override
  ValueStream<Reachability> observe() => _status.stream;

  void emit(Reachability value) => _status.add(value);

  Future<void> dispose() => _status.close();
}
