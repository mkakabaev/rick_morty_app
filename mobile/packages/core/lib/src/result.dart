import 'package:async/async.dart';

import 'error.dart';

typedef FutureResult<T> = Future<Result<T>>;

extension ResultExtension<T> on Result<T> {
  ///
  /// Easy way to return the error casted to [RickMortyError] unconditionally. This reduces amount of code needed to handle errors.
  ///
  RickMortyError get requiredError {
    final error = asError?.error;
    if (error == null) {
      throw StateError('Result is not an error. Check isError before calling requiredError');
    }
    return RickMortyError.from(error);
  }

  ///
  /// Easy way to return the value unconditionally. This reduces amount of code needed to handle values.
  /// in case of missed value, the optional error is thrown (if available).
  T get requiredValue {
    final valueResult = asValue;
    if (valueResult == null) {
      if (isError) {
        throw requiredError;
      }
      throw StateError('Result is not a value. Check isValue before calling requiredValue');
    }
    return valueResult.value;
  }

  /// Add toString() capability without having to extend it
  String myToString() {
    if (isValue) {
      return '<ResultValue $requiredValue>';
    }
    return '<ErrorValue: $requiredError>';
  }

  ///
  /// In many situations we need not the concrete result value but a signal that the value was obtained successfully.
  /// Se this is a way to achieve it
  ///
  Result<void> get asVoid {
    if (isValue) {
      return Result.value(null);
    }
    return asError ?? Result.error(StateError('Result is not a value nor an error'));
  }

  Result<R> mapError<R>() {
    return Result.error(requiredError);
  }

  Result<R> map<R>(R Function(T value) mapper) {
    try {
      if (isValue) {
        return Result.value(mapper(requiredValue));
      }
    } catch (e) {
      return Result.error(StateError('Error mapping result $T to $R: $e'));
    }
    return asError ?? Result.error(StateError('Result is not a value nor an error'));
  }
}
