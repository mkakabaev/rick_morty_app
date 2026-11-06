import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import 'package:app/di/di.dart';
import 'package:core/core.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:http/http.dart' as http;

import '../networking/error_mappers.dart';

import 'image_service.dart';

@LazySingleton(as: ImageService)
class ImageServiceImpl implements ImageService {
  static final _cacheManager = _ImageCacheManager(logTags: const Tags('ImageService'));

  @override
  BaseCacheManager get cacheManager => _cacheManager;
}

@visibleForTesting
HttpFileService rateLimitedImageFileServiceForTest({required http.Client httpClient, int pauseSeconds = 0}) {
  return _HttpFileService(
    parentTags: const Tags('Test'),
    httpClient: httpClient,
    minPause: pauseSeconds,
    maxPause: pauseSeconds,
  );
}

class _ImageCacheManager extends CacheManager {
  _ImageCacheManager({required Tags logTags})
    : super(Config('images', fileService: _HttpFileService(parentTags: logTags)));

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

  static Object _mapHttpError(Object error) {
    if (error is! HttpExceptionWithStatus) {
      return error;
    }
    final parsedError = fromHttpResponse(statusCode: error.statusCode, message: error.message);
    if (parsedError != null) {
      return parsedError;
    }
    return error;
  }
}

class _HttpFileService extends HttpFileService with Loggable {
  static const minPauseSeconds = 1;
  static const maxPauseSeconds = 10;
  static const maxAttempts = 5;

  final Random _random;
  final int _minPauseSeconds;
  final int _maxPauseSeconds;

  @override
  final Tags logTags;

  _HttpFileService({required Tags parentTags, super.httpClient, Random? random, int? minPause, int? maxPause})
    : _random = random ?? Random(),
      logTags = parentTags + 'FileService',
      _minPauseSeconds = minPause ?? minPauseSeconds,
      _maxPauseSeconds = maxPause ?? maxPauseSeconds;

  @override
  Future<FileServiceResponse> get(String url, {Map<String, String>? headers}) async {
    // Keep trying until we get a non-busy response
    var attempt = 0;
    while (true) {
      attempt += 1;
      final response = await super.get(url, headers: headers);
      final parsedError = fromHttpResponse(statusCode: response.statusCode);
      if (parsedError?.type != .serverBusy || attempt >= maxAttempts) {
        return response;
      }

      await response.content.drain<void>();
      final span = _maxPauseSeconds - _minPauseSeconds + 1;
      final duration = Duration(seconds: _minPauseSeconds + _random.nextInt(span));
      await Future<void>.delayed(duration);
    }
  }
}
