import 'package:flutter/material.dart';

class ScrollShadow extends StatelessWidget {
  final double opacity;

  const ScrollShadow({super.key, required this.opacity});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final alpha = theme.brightness == Brightness.dark ? 0.55 : 0.16;
    final color = theme.colorScheme.shadow.withValues(alpha: alpha);

    return SizedBox(
      height: 12,
      child: IgnorePointer(
        child: AnimatedOpacity(
          opacity: opacity,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [color, color.withValues(alpha: 0)],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
