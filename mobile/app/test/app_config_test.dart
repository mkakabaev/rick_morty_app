import 'package:app/app_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('resolves a known flavor name', () {
    expect(Flavor.fromName('dev'), Flavor.dev);
    expect(Flavor.fromName('stage'), Flavor.stage);
    expect(Flavor.fromName('prod'), Flavor.prod);
  });

  test('falls back instead of throwing when the flavor is missing or unknown', () {
    expect(Flavor.fromName(null), Flavor.fallback);
    expect(Flavor.fromName(''), Flavor.fallback);
    expect(Flavor.fromName('qa'), Flavor.fallback);
  });

  test('every flavor builds a config', () {
    for (final flavor in Flavor.values) {
      final config = AppConfig.fromFlavor(flavor);
      expect(config.flavor, flavor);
      expect(config.title, isNotEmpty);
      expect(Uri.parse(config.apiBaseUrl).isAbsolute, isTrue);
    }
  });
}
