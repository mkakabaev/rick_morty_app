import 'dart:io' show SocketException;
import 'dart:typed_data';

import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app/di/di.dart';
import 'package:app/l10n/l10n.dart';
import 'package:app/services/image_service/image_service.dart';
import 'package:app/ui/image.dart';
import 'package:app/ui/theme.dart';

import '../support/fake_image_service.dart';

const _png = <int>[
  0x89,
  0x50,
  0x4E,
  0x47,
  0x0D,
  0x0A,
  0x1A,
  0x0A,
  0x00,
  0x00,
  0x00,
  0x0D,
  0x49,
  0x48,
  0x44,
  0x52,
  0x00,
  0x00,
  0x00,
  0x01,
  0x00,
  0x00,
  0x00,
  0x01,
  0x08,
  0x06,
  0x00,
  0x00,
  0x00,
  0x1F,
  0x15,
  0xC4,
  0x89,
  0x00,
  0x00,
  0x00,
  0x0A,
  0x49,
  0x44,
  0x41,
  0x54,
  0x78,
  0x9C,
  0x63,
  0x00,
  0x01,
  0x00,
  0x00,
  0x05,
  0x00,
  0x01,
  0x0D,
  0x0A,
  0x2D,
  0xB4,
  0x00,
  0x00,
  0x00,
  0x00,
  0x49,
  0x45,
  0x4E,
  0x44,
  0xAE,
  0x42,
  0x60,
  0x82,
];

void main() {
  late FakeImageService images;

  setUp(() async {
    await getIt.reset();
    imageCache.clear();
    imageCache.clearLiveImages();
    images = FakeImageService();
    getIt.registerSingleton<ImageService>(images);
  });

  tearDown(() async {
    await images.dispose();
    await getIt.reset();
  });

  testWidgets('shows a gray avatar while offline and loads when internet returns', (tester) async {
    images.script.add(const SocketException('down'));
    images.script.add(_pngBytes());

    await tester.pumpWidget(_app(_image('https://img.test/offline.png', isOffline: true), size: 40));
    await tester.pump();
    await tester.pump();
    await tester.pump();

    expect(find.byIcon(Icons.broken_image_outlined), findsOneWidget);
    expect(images.calls, 1);

    await tester.pumpWidget(_app(_image('https://img.test/offline.png', isOffline: false), size: 40));
    await tester.pump();
    await tester.pump();

    expect(find.byType(Image), findsOneWidget);
    expect(images.calls, 2);
  });

  testWidgets('keeps a loaded image when the connection drops', (tester) async {
    images.script.add(_pngBytes());

    await tester.pumpWidget(_app(_image('https://img.test/kept.png', isOffline: false), size: 40));
    await tester.pump();
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.byIcon(Icons.broken_image_outlined), findsNothing);

    await tester.pumpWidget(_app(_image('https://img.test/kept.png', isOffline: true), size: 40));
    await tester.pump();

    expect(find.byIcon(Icons.broken_image_outlined), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(images.calls, 1);
  });

  testWidgets('shows a spinner while the cached image is downloading', (tester) async {
    images.holdOpen = true;

    await tester.pumpWidget(_app(_image('https://img.test/loading.png', isOffline: false), size: 40));
    await tester.pump();
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(images.calls, 1);
  });

  testWidgets('shows the offline placeholder when the image is missing', (tester) async {
    images.script.add(RickMortyError('missing', type: .notFound));

    await tester.pumpWidget(_app(_image('https://img.test/missing.png', isOffline: false), size: 240));
    await tester.pump();
    await tester.pump();
    await tester.pump();

    expect(find.byIcon(Icons.broken_image_outlined), findsOneWidget);
    expect(find.text('Image not found'), findsNothing);
    expect(find.text('Retry'), findsNothing);
    expect(tester.getSemantics(find.byIcon(Icons.broken_image_outlined)).label, 'Image not found');
    expect(images.calls, 1);
  });

  testWidgets('shows a failure when a download fails and the avatar once offline', (tester) async {
    images.script.add(const SocketException('down'));

    await tester.pumpWidget(_app(_image('https://img.test/dropped.png', isOffline: false), size: 40));
    await tester.pump();
    await tester.pump();
    await tester.pump();

    expect(find.byIcon(Icons.broken_image_outlined), findsOneWidget);
    expect(find.byTooltip("Couldn't load image"), findsOneWidget);

    await tester.pumpWidget(_app(_image('https://img.test/dropped.png', isOffline: true), size: 40));
    await tester.pump();
    await tester.pump();

    expect(find.byTooltip("Couldn't load image"), findsNothing);
    expect(tester.getSemantics(find.byIcon(Icons.broken_image_outlined)).label, 'No internet connection');

    images.script.add(_pngBytes());
    await tester.pumpWidget(_app(_image('https://img.test/dropped.png', isOffline: false), size: 40));
    await tester.pump();
    await tester.pump();

    expect(find.byType(Image), findsOneWidget);
    expect(images.calls, 2);
  });
}

Widget _image(String url, {required bool isOffline}) {
  return RickMortyImage(url: url, isOffline: isOffline);
}

Widget _app(Widget child, {required double size}) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    theme: applyAppColors(ThemeData()),
    home: Scaffold(
      body: Center(
        child: SizedBox(width: size, height: size, child: child),
      ),
    ),
  );
}

Uint8List _pngBytes() => Uint8List.fromList(_png);
