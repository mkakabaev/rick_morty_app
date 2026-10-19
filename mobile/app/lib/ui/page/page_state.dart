import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'page_bloc.dart';
import 'page_host.dart';

abstract class PageState<T extends StatefulWidget, BLOC extends PageBloc<BLOC_STATE>, BLOC_STATE> extends State<T> {
  @protected
  late final PageHost host;

  @protected
  late final BLOC bloc;

  StreamSubscription<BLOC_STATE>? _blocSubscription;

  /// When true, bloc emissions do not rebuild [buildPage].
  /// Subscribe pieces of the page with [blocSelector].
  /// Override with a constant value.
  /// [bloc.state] inside [buildPage] updates only when [buildPage] runs again.
  @protected
  bool get useBlocSelectors => false;

  @override
  void initState() {
    super.initState();

    host = DefaultPageHost(context);
    bloc = createBloc();
    _blocSubscription = bloc.stream.listen((state) {
      if (!mounted) {
        return;
      }
      didBlocChange(context, state);
    });
  }

  @override
  void dispose() {
    unawaited(_blocSubscription?.cancel());
    unawaited(bloc.close());
    super.dispose();
  }

  @protected
  BLOC createBloc();

  @nonVirtual
  @override
  Widget build(BuildContext context) {
    // this is for detached children of the page, which need to access the bloc and the page host
    return BlocProvider<BLOC>.value(
      value: bloc,
      child: PageHostScope(
        host: host,
        child: useBlocSelectors
            ? buildPage(context)
            // ignore: avoid-empty-build-when
            : BlocBuilder(bloc: bloc, builder: (context, _) => buildPage(context)),
      ),
    );
  }

  /// Rebuilds [builder] when [selector] returns a value that is not `==` to the previous one.
  /// [useBlocSelectors] must be true. The selected value must implement `==`.
  @protected
  Widget blocSelector<T1>({
    required BlocWidgetSelector<BLOC_STATE, T1> selector,
    required BlocWidgetBuilder<T1> builder,
    Key? key,
  }) {
    assert(useBlocSelectors, 'blocSelector requires useBlocSelectors');
    return BlocSelector<BLOC, BLOC_STATE, T1>(key: key, bloc: bloc, selector: selector, builder: builder);
  }

  @protected
  void didBlocChange(BuildContext context, BLOC_STATE blocState) {}

  @protected
  Widget buildPage(BuildContext context);
}
