import 'dart:async';
import 'dart:math';

import 'package:flutter_cache_manager/flutter_cache_manager.dart';

import 'package:app/di/di.dart';
import 'package:core/core.dart';

import '../networking/error_extension.dart';

import 'image_service.dart';

@LazySingleton(as: ImageService)
class ImageServiceImpl implements ImageService {
  static final _cacheManager = _ImageCacheManager();

  @override
  BaseCacheManager get cacheManager => _cacheManager;
}

class _ImageCacheManager extends CacheManager {
  _ImageCacheManager() : super(Config('images', fileService: _RateLimitedHttpFileService()));

  @override
  Stream<FileResponse> getFileStream(
    String url, {
    String? key,
    Map<String, String>? headers,
    bool withProgress = false,
  }) {
    return super
        .getFileStream(url, key: key, headers: headers, withProgress: withProgress)
        .transform(
          StreamTransformer<FileResponse, FileResponse>.fromHandlers(
            handleError: (error, stackTrace, sink) {
              sink.addError(_mapHttpError(error), stackTrace);
            },
          ),
        );
  }
}

Object _mapHttpError(Object error) {
  if (error is! HttpExceptionWithStatus) {
    return error;
  }
  final parsedError = RickMortyErrorExtension.parseHttpResponse(error.statusCode, message: error.message);
  if (parsedError != null) {
    return parsedError;
  }
  return error;
}

class _RateLimitedHttpFileService extends HttpFileService with LoggerObject {
  static const minPauseSeconds = 1;
  static const maxPauseSeconds = 10;

  final _random = Random();

  @override
  String get logName => 'ImageService.Fetch';

  @override
  Future<FileServiceResponse> get(String url, {Map<String, String>? headers}) async {
    // Keep trying until we get a non-busy response
    var attempt = 0;
    while (true) {
      attempt += 1;
      final response = await super.get(url, headers: headers);
      final parsedError = RickMortyErrorExtension.parseHttpResponse(response.statusCode);
      if (parsedError?.type != .serverBusy) {
        return response;
      }

      await response.content.drain<void>();
      final span = maxPauseSeconds - minPauseSeconds + 1;
      final duration = Duration(seconds: minPauseSeconds + _random.nextInt(span));
      this.log("Server is busy for $url at attempt #$attempt, waiting for $duration... ");
      await Future<void>.delayed(duration);
    }
  }
}
