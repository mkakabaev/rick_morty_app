import 'package:flutter/material.dart';

import 'package:app/di/di.dart';
import 'package:app/ui/ui.dart';

import 'bloc.dart';

class LaunchPage extends StatefulWidget {
  const LaunchPage({super.key});

  @override
  State createState() => _LaunchPageState();
}

class _LaunchPageState extends PageState<LaunchPage, LaunchPageBloc, LaunchPageBlocState> {
  @override
  LaunchPageBloc createBloc() => .new(host, launchRouterGate: getIt());

  @override
  Widget buildPage(BuildContext context) {
    final theme = Theme.of(context);
    final colors = AppColors.of(context);
    return Scaffold(
      backgroundColor: colors.launchBackground,
      body: Center(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 0.2),
          duration: const Duration(milliseconds: 1000),
          builder: (context, opacity, child) => Opacity(opacity: opacity, child: child),
          child: Image.asset('assets/images/Logo.png', color: theme.colorScheme.onSurface),
        ),
      ),
    );
  }
}
