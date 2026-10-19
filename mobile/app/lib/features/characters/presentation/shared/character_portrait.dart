import 'package:flutter/material.dart';

import 'package:app/ui/ui.dart';

enum CharacterPortraitStyle { small, large }

class CharacterPortrait extends StatelessWidget {
  final String url;
  final CharacterPortraitStyle style;
  final bool isOffline;

  const CharacterPortrait({super.key, required this.url, required this.style, required this.isOffline});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final double iconSize;
    double? progressSize;
    switch (style) {
      case .small:
        iconSize = 32;
        progressSize = 24;

      case .large:
        iconSize = 120;
    }

    return RickMortyImage(
      url: url,
      isOffline: isOffline,
      errorBuilder: (context, error, isOffline) {
        IconData icon;
        if (isOffline) {
          icon = Icons.cloud_off;
        } else {
          if (error.type == .notFound) {
            icon = Icons.person;
          } else {
            icon = Icons.broken_image;
          }
        }
        return Icon(icon, size: iconSize, color: colors.imagePlaceholder);
      },
      backgroundColor: colors.imageBackground,
      progressBuilder: (context) => Center(
        child: SizedBox(
          width: progressSize,
          height: progressSize,
          child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(colors.imageProgress)),
        ),
      ),
    );
  }
}
