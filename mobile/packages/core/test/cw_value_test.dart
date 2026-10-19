import 'package:core/core.dart';
import 'package:test/test.dart';

void main() {
  test('CWValue resolve and diffOnly', () {
    expect(CWValue.resolve(null, 10), 10);
    expect(CWValue.resolve(const CWValue(20), 10), 20);
    expect(CWValue.resolve(const CWValue(20), null as int?), 20);
    expect(CWValue.resolve(const CWValue(null as int?), 100), null);

    expect(CWValue.diffOnly(10, 10), isNull);
    expect(CWValue.diffOnly(null as int?, 10), const CWValue(10));
    expect(CWValue.diffOnly(10, null as int?), const CWValue<int>(null));
    expect(CWValue.diffOnly(10, 20), const CWValue(20));
    expect(CWValue.diffOnly(20, 10), const CWValue(10));
    expect(CWValue.diffOnly<int>(100, null), const CWValue<int>(null));
  });
}
