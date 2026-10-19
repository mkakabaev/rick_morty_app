import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'page_host.dart';

abstract class PageBloc<BLOC_STATE> extends Cubit<BLOC_STATE> {
  @protected
  final PageHost pageHost;

  PageBloc(super.initialState, this.pageHost);

  void emitSafe(BLOC_STATE state) {
    if (!isClosed) {
      emit(state);
    }
  }
}
