/// A type-safe helper for passing nullable values to a class's `copyWith()` method,
/// enabling explicit intent to set a field to `null` versus leaving it unchanged.
///
/// In Dart, a nullable `copyWith` parameter cannot tell "no change" from "set to null":
///
/// ```dart
/// MyClass copyWith({int? a}) => MyClass(a: a ?? this.a);
/// ```
///
/// With [CWValue], omit the argument to keep the current value, or pass `CWValue(null)` to clear it.
extension type const CWValue<T extends Object>._((T?, Type) _value) implements Object {
  const CWValue(T? value) : this._((value, T));

  static T? resolve<T extends Object>(CWValue<T>? v, T? originalValue) => v == null ? originalValue : v._value.$1;

  T? get value => _value.$1;

  static CWValue<T>? diffOnly<T extends Object>(T? valueFrom, T? valueTo) {
    return valueFrom == valueTo ? null : CWValue(valueTo);
  }

  /// Transforms one [CWValue] to another inside a `copyWith` function.
  CWValue<R> cast<R extends Object>(R Function(T) converter) {
    final v = _value.$1;
    return v == null ? CWValue<R>(null) : CWValue(converter(v));
  }

  /// Transforms one [CWValue] to another inside a `copyWith` function, allowing a null result.
  CWValue<R> castNullable<R extends Object>(R? Function(T?) converter) {
    return CWValue(converter(_value.$1));
  }
}
