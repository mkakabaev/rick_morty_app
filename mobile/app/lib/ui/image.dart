import 'package:flutter/material.dart';

import 'package:app/l10n/l10n.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:core/core.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

import 'error.dart';

typedef ImageErrorBuilder = Widget? Function(BuildContext context, AppError error, bool isOffline);
typedef ImageProgressBuilder = Widget? Function(BuildContext context);

class AppImage extends StatefulWidget {
  final String url;
  final bool isOffline;
  final Color? backgroundColor;
  final ImageProgressBuilder? progressBuilder;
  final ImageErrorBuilder? errorBuilder;
  final BaseCacheManager cacheManager;

  const AppImage({
    super.key,
    required this.url,
    required this.isOffline,
    this.backgroundColor,
    this.progressBuilder,
    this.errorBuilder,
    required this.cacheManager,
  });

  @override
  State<AppImage> createState() => _AppImageState();
}

class _AppImageState extends State<AppImage> {
  var _loadAttempt = 0;
  var _loaded = false;

  @override
  void didUpdateWidget(covariant AppImage oldWidget) {
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
      cacheManager: widget.cacheManager,
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
        return _Error(error: AppError.from(error), builder: widget.errorBuilder, isOffline: widget.isOffline);
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
  final AppError error;
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

/// Exposes the app image [BaseCacheManager] to descendant widgets.
class ImageCacheScope extends InheritedWidget {
  static BaseCacheManager of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<ImageCacheScope>();
    if (scope == null) {
      throw FlutterError('ImageCacheScope.of() called with no ImageCacheScope ancestor.');
    }
    return scope.cacheManager;
  }

  final BaseCacheManager cacheManager;

  const ImageCacheScope({super.key, required this.cacheManager, required super.child});

  @override
  bool updateShouldNotify(ImageCacheScope oldWidget) => cacheManager != oldWidget.cacheManager;
}
