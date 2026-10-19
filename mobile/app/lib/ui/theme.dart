// ignore_for_file: avoid-non-null-assertion

import 'package:flutter/material.dart';

class AppColors extends ThemeExtension<AppColors> {
  final Color divider;
  final Color imageBackground;
  final Color imageProgress;
  final Color imagePlaceholder;

  const AppColors({
    required this.divider,
    required this.imageBackground,
    required this.imageProgress,
    required this.imagePlaceholder,
  });

  static AppColors of(BuildContext context) => Theme.of(context).extension<AppColors>()!;

  factory AppColors.fromScheme(ColorScheme scheme) {
    final divider = switch (scheme.brightness) {
      .light => scheme.outlineVariant.withValues(alpha: 0.4),
      .dark => scheme.outlineVariant,
    };
    return AppColors(
      divider: divider,
      imageBackground: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
      imageProgress: scheme.onSurface.withValues(alpha: 0.05),
      imagePlaceholder: scheme.onSurface.withValues(alpha: 0.1),
    );
  }

  @override
  AppColors copyWith({Color? divider, Color? imageBackground, Color? imageProgress, Color? imagePlaceholder}) {
    return AppColors(
      divider: divider ?? this.divider,
      imageBackground: imageBackground ?? this.imageBackground,
      imageProgress: imageProgress ?? this.imageProgress,
      imagePlaceholder: imagePlaceholder ?? this.imagePlaceholder,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) {
      return this;
    }
    return AppColors(
      divider: Color.lerp(divider, other.divider, t)!,
      imageBackground: Color.lerp(imageBackground, other.imageBackground, t)!,
      imageProgress: Color.lerp(imageProgress, other.imageProgress, t)!,
      imagePlaceholder: Color.lerp(imagePlaceholder, other.imagePlaceholder, t)!,
    );
  }
}

ThemeData applyAppColors(ThemeData theme) {
  final colors = AppColors.fromScheme(theme.colorScheme);
  return theme.copyWith(
    dividerTheme: DividerThemeData(color: colors.divider),
    extensions: [...theme.extensions.values, colors],
  );
}
