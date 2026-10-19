import 'package:core/core.dart';
import 'package:test/test.dart';

enum _Sample { alpha, beta }

void main() {
  group('MyEnumByName', () {
    test('returns matching value', () {
      expect(_Sample.values.byNameOrNull('alpha'), _Sample.alpha);
      expect(_Sample.values.byNameOrNull('beta'), _Sample.beta);
    });

    test('returns null for unknown or null name', () {
      expect(_Sample.values.byNameOrNull('gamma'), isNull);
      expect(_Sample.values.byNameOrNull(null), isNull);
      expect(_Sample.values.byNameOrNull(''), isNull);
    });
  });
}
