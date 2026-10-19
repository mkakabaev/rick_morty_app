import 'dart:async';

import 'package:core/core.dart';
import 'package:test/test.dart';

void main() {
  group('ValueState', () {
    test('empty', () {
      const state = ValueState<int>.empty();
      expect(state, isA<ValueStateEmpty<int>>());
      expect(state.isEmpty, isTrue);
      expect(state.isLoading, isFalse);
      expect(state.hasValue, isFalse);
      expect(state.value, isNull);
      expect(state.error, isNull);
      expect(() => state.requiredValue, throwsStateError);
      expect(() => state.requiredError, throwsStateError);
    });

    test('loading without a previous value', () {
      const state = ValueState<int>.loading(null);
      expect(state.isLoading, isTrue);
      expect(state.isEmpty, isFalse);
      expect(state.hasValue, isFalse);
      expect(state.value, isNull);
      expect(state.error, isNull);
      expect(() => state.requiredValue, throwsStateError);
    });

    test('loaded', () {
      const state = ValueState<int>.loaded(42);
      expect(state, isA<ValueStateLoaded<int>>());
      expect(state.hasValue, isTrue);
      expect(state.value, 42);
      expect(state.requiredValue, 42);
      expect(state.error, isNull);
      expect(() => state.requiredError, throwsStateError);
    });

    test('loadFailed without a previous value', () {
      final error = RickMortyError('Failed to load');
      final state = ValueState<int>.loadFailed(error, null);
      expect(state, isA<ValueStateLoadFailed<int>>());
      expect(state.isLoadFailed, isTrue);
      expect(state.hasValue, isFalse);
      expect(state.error, error);
      expect(state.requiredError, error);
      expect(() => state.requiredValue, throwsStateError);
    });

    test('transitions keep the previous value', () {
      var state = const ValueState<int>.empty();

      state = state.startLoading();
      expect(state, const ValueState<int>.loading(null));

      state = state.endLoading(Result.value(42));
      expect(state, const ValueState<int>.loaded(42));

      state = state.startLoading();
      expect(state, const ValueState<int>.loading(42));
      expect(state.hasValue, isTrue);
      expect(state.requiredValue, 42);

      final error = RickMortyError('Error');
      state = state.endLoading(Result.error(error));
      expect(state, ValueState<int>.loadFailed(error, 42));
      expect(state.hasValue, isTrue);
      expect(state.requiredValue, 42);
      expect(state.requiredError, error);
    });

    test('equality includes the variant', () {
      const empty = ValueState<int>.empty();
      const loading = ValueState<int>.loading(null);
      const loaded = ValueState<int>.loaded(42);

      expect(empty, const ValueState<int>.empty());
      expect(loaded, const ValueState<int>.loaded(42));
      expect(empty, isNot(loading));
      expect(loading, isNot(loaded));
      expect(const ValueState<int>.loaded(42), isNot(const ValueState<int>.loaded(7)));
    });
  });

  group('ValueStateHost', () {
    test('reload loads and keeps the previous value while in flight', () async {
      final finish = Completer<Result<int>>();
      final host = ValueStateHost<int>(loader: () => finish.future);

      final reload = host.reload();
      expect(host.valueStream.value, const ValueState<int>.loading(null));

      finish.complete(Result.value(1));
      expect(await reload, const ValueState<int>.loaded(1));
      expect(host.valueStream.value, const ValueState<int>.loaded(1));

      host.dispose();
    });

    test('reload coalesces in-flight calls', () async {
      var loads = 0;
      final finish = Completer<Result<int>>();
      final host = ValueStateHost<int>(
        loader: () async {
          loads++;
          return finish.future;
        },
      );

      final first = host.reload();
      final second = host.reload();
      finish.complete(Result.value(1));

      expect(await first, const ValueState<int>.loaded(1));
      expect(await second, const ValueState<int>.loaded(1));
      expect(loads, 1);

      host.dispose();
    });

    test('first listener starts loading when empty', () async {
      final host = ValueStateHost<int>(loader: () async => Result.value(7));

      expect(host.valueStream.value, const ValueState<int>.empty());
      final states = <ValueState<int>>[];
      final sub = host.valueStream.listen(states.add);

      await pumpEventQueue();
      expect(states, [
        const ValueState<int>.empty(),
        const ValueState<int>.loading(null),
        const ValueState<int>.loaded(7),
      ]);

      await sub.cancel();
      host.dispose();
    });

    test('reset returns to empty', () async {
      final host = ValueStateHost<int>(loader: () async => Result.value(1));
      expect(await host.reload(), const ValueState<int>.loaded(1));

      host.reset();
      expect(host.valueStream.value, const ValueState<int>.empty());

      host.dispose();
    });

    test('hydrate runs while loading and failure keeps the seeded value', () async {
      final finish = Completer<Result<int>>();
      final host = ValueStateHost<int>(loader: () => finish.future, hydrate: () async => 42);

      final reload = host.reload();
      expect(host.valueStream.value, const ValueState<int>.loading(null));

      await pumpEventQueue();
      expect(host.valueStream.value, const ValueState<int>.loading(42));

      finish.complete(Result<int>.error(RickMortyError('offline')));
      expect(await reload, ValueState<int>.loadFailed(RickMortyError('offline'), 42));

      host.dispose();
    });

    test('reloadIfSubscribedWithoutValue reloads a subscribed host that has no value', () async {
      var loads = 0;
      final host = ValueStateHost<int>(
        loader: () async {
          loads++;
          if (loads == 1) {
            return Result<int>.error(RickMortyError('offline'));
          }
          return Result.value(1);
        },
      );

      host.reloadIfSubscribedWithoutValue();
      expect(loads, 0);

      final subscription = host.valueStream.listen((_) {});
      await pumpEventQueue();
      expect(loads, 1);
      expect(host.valueStream.value.value, isNull);

      host.reloadIfSubscribedWithoutValue();
      await pumpEventQueue();
      expect(loads, 2);
      expect(host.valueStream.value, const ValueState<int>.loaded(1));

      host.reloadIfSubscribedWithoutValue();
      await pumpEventQueue();
      expect(loads, 2);

      await subscription.cancel();
      host.reloadIfSubscribedWithoutValue();
      await pumpEventQueue();
      expect(loads, 2);

      host.dispose();
    });

    test('updateLoaded writes a loaded value without the loader', () {
      final host = ValueStateHost<int>(loader: () async => Result.value(1));
      host.updateLoaded(9);
      expect(host.valueStream.value, const ValueState<int>.loaded(9));
      host.dispose();
    });
  });
}
