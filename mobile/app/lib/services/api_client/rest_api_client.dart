import 'package:flutter/foundation.dart';

import 'package:core/core.dart';
import 'package:dio/dio.dart';

import '../networking/error_mappers.dart';

import 'api_client.dart';
import 'dtos/character.dart';
import 'retrofit/retrofit_entries.dart';
import 'retrofit/retrofit_workers.dart';

class RestApiClient with Loggable implements ApiClient {
  @visibleForTesting
  static const defaultRateLimitPauses = [
    Duration(seconds: 1),
    Duration(seconds: 2),
    Duration(seconds: 3),
    Duration(seconds: 5),
  ];

  /// Upper bound for a server-provided `Retry-After`, so one bad header cannot stall a screen.
  @visibleForTesting
  static const maxRetryAfter = Duration(seconds: 30);

  /// Applied when the caller's [Dio] has no timeouts of its own. Without them a dead
  /// link keeps a request pending forever and the reachability retry never fires.
  @visibleForTesting
  static const defaultConnectTimeout = Duration(seconds: 15);
  @visibleForTesting
  static const defaultReceiveTimeout = Duration(seconds: 30);
  @visibleForTesting
  static const defaultSendTimeout = Duration(seconds: 15);

  final Dio _dio;
  final List<Duration> _rateLimitPauses;
  final Future<void> Function(Duration delay) _delay;
  late final RestRetrofitClient _client;

  @override
  final Tags logTags = const Tags('RestApiClient');

  RestApiClient({
    required String endpoint,
    Dio? dio,
    List<Duration>? rateLimitPauses,
    Future<void> Function(Duration delay)? delay,
  }) : _dio = dio ?? Dio(),
       _rateLimitPauses = rateLimitPauses ?? defaultRateLimitPauses,
       _delay = delay ?? Future<void>.delayed {
    _dio.options.baseUrl = endpoint;
    _dio.options.connectTimeout ??= defaultConnectTimeout;
    _dio.options.receiveTimeout ??= defaultReceiveTimeout;
    _dio.options.sendTimeout ??= defaultSendTimeout;
    _dio.transformer = RetrofitWorkerBridgeTransformer();
    _client = RestRetrofitClient(_dio);
  }

  @override
  FutureResult<CharactersResponseDto> getCharacters({required int page, String? name}) =>
      _attempt((client) => client.getCharacters(page: page, name: name));

  @override
  FutureResult<CharacterDto> getCharacter(int id) => _attempt((client) => client.getCharacter(id));

  AppError _parseError(Object e, StackTrace stackTrace) {
    if (e is DioException) {
      e = _parseDioException(e) ?? e;
    }

    switch (e) {
      case AppError():
        return e;
      case FormatException(:final message):
        return AppError(message);
      default:
        // Typically a DTO shape mismatch thrown while decoding (TypeError, CheckedFromJsonException).
        // Surface it as an error result; a crash here would hide the response that caused it.
        log('Unexpected API error', error: e, stackTrace: stackTrace);
        return AppError.from(e);
    }
  }

  /// Parses an HTTP `Retry-After` header in seconds. HTTP-date values are ignored.
  static Duration? _retryAfterOf(Object error) {
    if (error is! DioException) {
      return null;
    }
    final raw = error.response?.headers.value('retry-after')?.trim();
    final seconds = raw == null ? null : int.tryParse(raw);
    if (seconds == null || seconds < 0) {
      return null;
    }
    final pause = Duration(seconds: seconds);
    return pause > maxRetryAfter ? maxRetryAfter : pause;
  }

  Object? _parseDioException(DioException e) {
    final DioException(:response, error: underlyingError, message: dioErrorMessage, type: dioErrorType) = e;

    if (underlyingError is AppError) {
      return underlyingError;
    }

    var message = dioErrorMessage;

    if (response != null) {
      // Try to extract error from API response body
      final data = unwrapBridgedResponseData(response.data);
      if (data is Map && data['error'] is String) {
        message = data['error'] as String;
      }

      // Hide verbose Dio message
      if (message?.startsWith('This exception was thrown because') ?? false) {
        message = response.statusMessage;
      }

      // From HTTP status
      final error = fromHttpResponse(statusCode: response.statusCode, message: message);
      if (error != null) {
        return error;
      }
    }

    // Default error handling
    switch (dioErrorType) {
      case .connectionError:
      case .connectionTimeout:
      case .sendTimeout:
      case .receiveTimeout:
      case .badCertificate:
        return AppError(message ?? 'Network error', type: .network);
      default:
        if (underlyingError != null) {
          return AppError.from(underlyingError);
        }
        return null;
    }
  }

  FutureResult<T> _attempt<T>(Future<T> Function(RestRetrofitClient client) requestBody) async {
    for (var attempt = 0; ; attempt += 1) {
      try {
        return Result.value(await requestBody(_client));
      } catch (error, stackTrace) {
        final parsedError = _parseError(error, stackTrace);
        if (parsedError.type == .serverBusy) {
          if (attempt < _rateLimitPauses.length) {
            await _delay(_retryAfterOf(error) ?? _rateLimitPauses[attempt]);
            continue;
          }
        }
        return Result<T>.error(parsedError, stackTrace);
      }
    }
  }
}
