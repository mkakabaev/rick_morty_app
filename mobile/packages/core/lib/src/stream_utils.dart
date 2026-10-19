import 'package:rxdart/rxdart.dart';

extension BehaviorStreamExtensions<T> on BehaviorSubject<T> {
  bool addDistinct(T value) {
    if (!hasValue || value != this.value) {
      addSafe(value);
      return true;
    }
    return false;
  }
}

extension SubjectExtensions<T> on Subject<T> {
  void addSafe(T value) {
    if (!isClosed) {
      add(value);
    }
  }
}
