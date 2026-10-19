import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'package:core/core.dart';

import '../networking/error_extension.dart';

import 'api_client.dart';
import 'dtos/character.dart';
import 'retrofit/retrofit_entries.dart';
import 'retrofit/retrofit_workers.dart';

class RestApiClient implements ApiClient {
  @visibleForTesting
  static const defaultRateLimitPauses = [
    Duration(seconds: 1),
    Duration(seconds: 2),
    Duration(seconds: 3),
    Duration(seconds: 5),
  ];

  final Dio _dio;
  final List<Duration> _rateLimitPauses;
  final Future<void> Function(Duration delay) _delay;
  late final RestRetrofitClient _client;

  RestApiClient({
    required String endpoint,
    Dio? dio,
    List<Duration>? rateLimitPauses,
    Future<void> Function(Duration delay)? delay,
  }) : _dio = dio ?? Dio(),
       _rateLimitPauses = rateLimitPauses ?? defaultRateLimitPauses,
       _delay = delay ?? Future<void>.delayed {
    _dio.options.baseUrl = endpoint;
    _dio.transformer = RetrofitWorkerBridgeTransformer();
    _client = RestRetrofitClient(_dio);
  }

  @override
  FutureResult<CharactersResponseDto> getCharacters({required int page, String? name}) =>
      _attempt((client) => client.getCharacters(page: page, name: name));

  @override
  FutureResult<CharacterDto> getCharacter(int id) => _attempt((client) => client.getCharacter(id));

  RickMortyError _parseError(Object error) {
    switch (error) {
      case DioException():
        final parsed = _parseDioException(error);
        if (parsed != null) {
          return parsed;
        }
      case RickMortyError():
        return error;
      case FormatException():
        return RickMortyError(error.message);
      default:
        break;
    }
    return RickMortyError.from(error);
  }

  RickMortyError? _parseDioException(DioException exception) {
    final DioException(:response, error: underlyingError, :message, type: dioErrorType) = exception;

    if (underlyingError is RickMortyError) {
      return underlyingError;
    }

    var effectiveMessage = message;
    if (response != null) {
      // Hide verbose Dio message
      if (message?.startsWith('This exception was thrown because') ?? false) {
        effectiveMessage = response.statusMessage;
      }

      // Try to extract error from API response body
      final data = unwrapBridgedResponseData(response.data);
      if (data is Map && data['error'] is String) {
        effectiveMessage = data['error'] as String;
      }

      final error = RickMortyErrorExtension.parseHttpResponse(response.statusCode, message: effectiveMessage);
      if (error != null) {
        return error;
      }
    }

    switch (dioErrorType) {
      case .connectionError:
      case .connectionTimeout:
      case .sendTimeout:
      case .receiveTimeout:
      case .badCertificate:
        return RickMortyError('Network error', type: .network);
      default:
        if (underlyingError != null) {
          return RickMortyError.from(underlyingError);
        }
        return null;
    }
  }

  FutureResult<T> _attempt<T>(Future<T> Function(RestRetrofitClient client) requestBody) async {
    for (var attempt = 0; ; attempt += 1) {
      try {
        return Result.value(await requestBody(_client));
      } catch (error, stackTrace) {
        final parsedError = _parseError(error);
        if (parsedError.type == .serverBusy) {
          if (attempt < _rateLimitPauses.length) {
            await _delay(_rateLimitPauses[attempt]);
            continue;
          }
        }
        return Result<T>.error(parsedError, stackTrace);
      }
    }
  }
}
