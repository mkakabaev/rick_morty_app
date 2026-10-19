import 'dart:async';

import 'package:async/async.dart';
import 'package:equatable/equatable.dart';
import 'package:rxdart/rxdart.dart';

import 'error.dart';
import 'result.dart';

sealed class ValueState<T extends Object> extends Equatable {
  const ValueState();

  const factory ValueState.empty() = ValueStateEmpty;
  const factory ValueState.loading(T? value) = ValueStateLoading;
  const factory ValueState.loaded(T value) = ValueStateLoaded;
  const factory ValueState.loadFailed(RickMortyError error, T? value) = ValueStateLoadFailed;

  RickMortyError? get error => null;
  T? get value => null;
  bool get isEmpty => false;
  bool get isLoading => false;
  bool get hasValue => value != null;
  bool get isLoadFailed => false;

  T get requiredValue {
    final current = value;
    if (current == null) {
      throw StateError('Value is not available for this state');
    }
    return current;
  }

  RickMortyError get requiredError {
    final current = error;
    if (current == null) {
      throw StateError('Error is not available for this state');
    }
    return current;
  }

  @override
  List<Object?> get props => [error, value];

  /// Keep the current value (if any) and clear the error.
  ValueState<T> startLoading() => ValueState.loading(value);

  /// Apply a loader [Result], keeping the current value on failure.
  ValueState<T> endLoading(Result<T> result) =>
      result.isError ? ValueState.loadFailed(result.requiredError, value) : ValueState.loaded(result.requiredValue);

  ValueState<T> endLoadingWithError(RickMortyError error) => ValueState.loadFailed(error, value);

  ValueState<T> endLoadingWithValue(T value) => ValueState.loaded(value);

  @override
  String toString() {
    return switch (this) {
      ValueStateEmpty() => 'ValueState.empty()',
      ValueStateLoading(:final value) => 'ValueState.loading($value)',
      ValueStateLoaded(:final value) => 'ValueState.loaded($value)',
      ValueStateLoadFailed(:final error, :final value) => 'ValueState.loadFailed($error, $value)',
    };
  }
}

class ValueStateEmpty<T extends Object> extends ValueState<T> {
  const ValueStateEmpty();

  @override
  bool get isEmpty => true;
}

class ValueStateLoading<T extends Object> extends ValueState<T> {
  @override
  final T? value;

  const ValueStateLoading(this.value);

  @override
  bool get isLoading => true;
}

class ValueStateLoaded<T extends Object> extends ValueState<T> {
  @override
  final T value;

  const ValueStateLoaded(this.value);

  @override
  bool get isLoadFailed => false;
}

class ValueStateLoadFailed<T extends Object> extends ValueState<T> {
  @override
  final T? value;

  @override
  final RickMortyError error;

  @override
  bool get isLoadFailed => true;

  const ValueStateLoadFailed(this.error, this.value);
}

class ValueStateHost<T extends Object> {
  Completer<ValueState<T>>? _reloadCompleter;
  late final BehaviorSubject<ValueState<T>> _subject;
  final FutureResult<T> Function() loader;

  /// Cache read while [reload] is already in the loading state. A returned value is
  /// shown as loading data and kept when the loader fails.
  final Future<T?> Function()? hydrate;

  ValueStateHost({required this.loader, this.hydrate, T? seed}) {
    _subject = BehaviorSubject<ValueState<T>>.seeded(
      seed == null ? ValueState<T>.empty() : ValueState<T>.loaded(seed),
      onListen: () {
        if (!_subject.value.hasValue) {
          unawaited(reload());
        }
      },
    );
  }

  ValueStream<ValueState<T>> get valueStream => _subject.stream;

  /// Starts [reload] when a listener is attached and no value is loaded yet.
  ///
  /// An in-flight [reload] is left to finish. A loaded value, including one kept
  /// after a later failure, is left alone.
  void reloadIfSubscribedWithoutValue() {
    if (!_subject.hasListener || _subject.value.hasValue) {
      return;
    }
    unawaited(reload());
  }

  void reset() {
    _subject.value = ValueState<T>.empty();
  }

  void dispose() {
    unawaited(_subject.close());
  }

  void updateLoaded(T newValue) {
    _subject.value = ValueState.loaded(newValue);
  }

  Future<ValueState<T>> reload() async {
    final existingCompleter = _reloadCompleter;
    if (existingCompleter != null) {
      assert(_subject.value is ValueStateLoading);
      return existingCompleter.future;
    }

    final completer = _reloadCompleter = Completer<ValueState<T>>();
    _subject.value = _subject.value.startLoading();
    try {
      final hydrate = this.hydrate;
      if (hydrate != null && !_subject.value.hasValue) {
        final seeded = await hydrate();
        if (seeded != null && _subject.value.isLoading && !_subject.value.hasValue) {
          _subject.value = ValueState.loading(seeded);
        }
      }
      final r = await loader();
      _subject.value = _subject.value.endLoading(r);
      completer.complete(_subject.value);
    } catch (e, st) {
      completer.completeError(e, st);
    } finally {
      _reloadCompleter = null;
    }

    return completer.future;
  }
}
