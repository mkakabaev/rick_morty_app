import 'package:flutter/material.dart';

/// Pins a progress indicator to the midpoint between [listEndKey] and the
/// viewport bottom, so overscroll moves the gap without carrying the spinner
/// with a footer tile.
class GapCenteredProgress extends StatelessWidget {
  static const _indicatorSize = 24.0;

  final ScrollController controller;
  final GlobalKey listEndKey;

  const GapCenteredProgress({super.key, required this.controller, required this.listEndKey});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final overlayBox = context.findRenderObject() as RenderBox?;
        final endBox = listEndKey.currentContext?.findRenderObject() as RenderBox?;
        if (overlayBox == null || endBox == null || !overlayBox.hasSize || !endBox.hasSize) {
          return const SizedBox.shrink();
        }

        final listEndGlobal = endBox.localToGlobal(Offset.zero);
        final overlayTopGlobal = overlayBox.localToGlobal(Offset.zero);
        final rawGapTop = listEndGlobal.dy - overlayTopGlobal.dy;
        final gapBottom = overlayBox.size.height;
        if (rawGapTop >= gapBottom) {
          return const SizedBox.shrink();
        }

        // Visible gap only: if the list end is above the viewport, start from the top edge.
        final gapTop = rawGapTop < 0 ? 0.0 : rawGapTop;
        final centerY = (gapTop + gapBottom) / 2;
        return IgnorePointer(
          child: Stack(
            children: [
              Positioned(
                top: centerY - _indicatorSize / 2,
                left: 0,
                right: 0,
                child: const Center(
                  child: SizedBox(
                    width: _indicatorSize,
                    height: _indicatorSize,
                    child: CircularProgressIndicator(strokeWidth: 3),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
