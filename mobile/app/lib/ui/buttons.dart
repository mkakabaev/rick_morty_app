import 'package:flutter/material.dart';

enum ButtonStyle { primary, secondary }

class Button extends StatelessWidget {
  final String title;
  final VoidCallback? onTap;
  final bool isEnabled;
  final ButtonStyle style;
  final bool showProgress;
  final bool disabledOnProgress;
  final EdgeInsets? margin;

  const Button({
    super.key,
    required this.title,
    required this.onTap,
    this.isEnabled = true,
    this.showProgress = false,
    this.disabledOnProgress = true,
    this.style = .primary,
    this.margin,
  });

  const Button.secondary({
    super.key,
    required this.title,
    required this.onTap,
    this.isEnabled = true,
    this.showProgress = false,
    this.disabledOnProgress = true,
    this.margin,
  }) : style = .secondary;

  @override
  Widget build(BuildContext context) {
    final effectiveEnabled = isEnabled && (disabledOnProgress ? !showProgress : true);
    final effectiveOnTap = effectiveEnabled ? onTap : null;

    Widget w;
    switch (style) {
      case .primary:
        w = FilledButton(
          onPressed: effectiveOnTap,
          child: _buildContent(effectiveEnabled: effectiveEnabled),
        );
      case .secondary:
        w = TextButton(
          onPressed: effectiveOnTap,
          child: _buildContent(effectiveEnabled: effectiveEnabled, progressSize: 20),
        );
    }

    if (margin != null) {
      w = Container(margin: margin, child: w);
    }
    return w;
  }

  Widget _buildContent({required bool effectiveEnabled, double progressSize = 24, double progressStrokeWidth = 2}) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Text(title, style: effectiveEnabled ? null : TextStyle(color: Colors.grey[600])),
        if (showProgress)
          SizedBox(
            width: progressSize,
            height: progressSize,
            child: CircularProgressIndicator(strokeWidth: progressStrokeWidth),
          ),
      ],
    );
  }
}
