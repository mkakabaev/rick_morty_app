import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'package:app/di/di.dart';
import 'package:app/l10n/l10n.dart';
import 'package:app/services/image_service/image_service.dart';
import 'package:core/core.dart';

import 'error.dart';

typedef ImageErrorBuilder = Widget? Function(BuildContext context, RickMortyError error, bool isOffline);
typedef ImageProgressBuilder = Widget? Function(BuildContext context);

class RickMortyImage extends StatefulWidget {
  final String url;
  final bool isOffline;
  final Color? backgroundColor;
  final ImageProgressBuilder? progressBuilder;
  final ImageErrorBuilder? errorBuilder;

  const RickMortyImage({
    super.key,
    required this.url,
    required this.isOffline,
    this.backgroundColor,
    this.progressBuilder,
    this.errorBuilder,
  });

  @override
  State<RickMortyImage> createState() => _RickMortyImageState();
}

class _RickMortyImageState extends State<RickMortyImage> {
  final _imageService = getIt<ImageService>();
  var _loadAttempt = 0;
  var _loaded = false;

  @override
  void didUpdateWidget(covariant RickMortyImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      _loaded = false;
      _loadAttempt = 0;
    } else if (oldWidget.isOffline && !widget.isOffline && !_loaded) {
      _loadAttempt++;
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget image = CachedNetworkImage(
      key: ValueKey(_loadAttempt),
      imageUrl: widget.url,
      cacheManager: _imageService.cacheManager,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      fadeInDuration: Duration.zero,
      fadeOutDuration: Duration.zero,
      imageBuilder: (context, imageProvider) {
        _loaded = true;
        return Image(image: imageProvider, fit: .cover, width: .infinity, height: .infinity);
      },
      progressIndicatorBuilder: (context, url, progress) => _Loading(builder: widget.progressBuilder),
      errorWidget: (context, url, error) {
        _loaded = false;
        return _Error(error: RickMortyError.from(error), builder: widget.errorBuilder, isOffline: widget.isOffline);
      },
    );

    final backgroundColor = widget.backgroundColor;
    if (backgroundColor != null) {
      image = ColoredBox(color: backgroundColor, child: image);
    }

    return image;
  }
}

class _Loading extends StatelessWidget {
  final ImageProgressBuilder? builder;

  const _Loading({required this.builder});

  @override
  Widget build(BuildContext context) {
    return builder?.call(context) ?? const Center(child: CircularProgressIndicator());
  }
}

class _Error extends StatelessWidget {
  final RickMortyError error;
  final ImageErrorBuilder? builder;
  final bool isOffline;

  const _Error({required this.error, required this.builder, required this.isOffline});

  @override
  Widget build(BuildContext context) {
    final built = builder?.call(context, error, isOffline);
    if (built != null) {
      return Semantics(label: error.message, child: built);
    }

    final l10n = context.l10n;
    final String label;
    String? tooltip;
    if (isOffline) {
      label = error.text(isOffline: true, l10n: l10n);
    } else if (error.type == .notFound) {
      label = l10n.imageNotFound;
    } else {
      label = l10n.imageNotLoaded;
      tooltip = l10n.imageNotLoaded;
    }

    Widget icon = const Icon(Icons.broken_image_outlined);
    final message = tooltip;
    if (message != null) {
      icon = Tooltip(message: message, excludeFromSemantics: true, child: icon);
    }
    return Semantics(label: label, child: icon);
  }
}
