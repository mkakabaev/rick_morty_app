import 'dart:typed_data';

import 'package:app/services/api_client/rest_api_client.dart';
import 'package:core/core.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('maps a 404 character response to notFound', () async {
    final dio = Dio();
    dio.httpClientAdapter = _StatusAdapter(404, '{"error":"There is nothing here"}');
    final client = RestApiClient(endpoint: 'https://rickandmortyapi.com/api', dio: dio);

    final result = await client.getCharacters(page: 1, name: 'zzz');

    expect(result.requiredError.type, AppErrorType.notFound);
    expect(result.requiredError.message, 'There is nothing here');
  });

  test('retries HTTP 429 with increasing pauses, then reports the server is busy', () async {
    final pauses = <Duration>[];
    final dio = Dio();
    dio.httpClientAdapter = _StatusAdapter(429, '{"error":"rate limit"}');
    final client = RestApiClient(
      endpoint: 'https://rickandmortyapi.com/api',
      dio: dio,
      delay: (pause) async {
        pauses.add(pause);
      },
    );

    final result = await client.getCharacters(page: 1);

    expect(pauses, RestApiClient.defaultRateLimitPauses);
    expect(result.requiredError.type, AppErrorType.serverBusy);
    expect((dio.httpClientAdapter as _StatusAdapter).calls, pauses.length + 1);
  });

  test('honours a Retry-After header, capped, instead of the default pauses', () async {
    final pauses = <Duration>[];
    final dio = Dio();
    dio.httpClientAdapter = _StatusAdapter(429, '{"error":"rate limit"}', headers: {'retry-after': '7'});
    final client = RestApiClient(
      endpoint: 'https://rickandmortyapi.com/api',
      dio: dio,
      rateLimitPauses: const [Duration(seconds: 1), Duration(seconds: 2)],
      delay: (pause) async {
        pauses.add(pause);
      },
    );

    await client.getCharacters(page: 1);
    expect(pauses, const [Duration(seconds: 7), Duration(seconds: 7)]);

    pauses.clear();
    dio.httpClientAdapter = _StatusAdapter(429, '{"error":"rate limit"}', headers: {'retry-after': '3600'});
    await client.getCharacters(page: 1);
    expect(pauses, [RestApiClient.maxRetryAfter, RestApiClient.maxRetryAfter]);
  });

  test('applies default timeouts to a Dio without any', () {
    final dio = Dio();
    RestApiClient(endpoint: 'https://rickandmortyapi.com/api', dio: dio);

    expect(dio.options.connectTimeout, RestApiClient.defaultConnectTimeout);
    expect(dio.options.receiveTimeout, RestApiClient.defaultReceiveTimeout);
    expect(dio.options.sendTimeout, RestApiClient.defaultSendTimeout);
  });

  test('keeps timeouts the caller configured', () {
    final dio = Dio(BaseOptions(connectTimeout: const Duration(seconds: 3)));
    RestApiClient(endpoint: 'https://rickandmortyapi.com/api', dio: dio);

    expect(dio.options.connectTimeout, const Duration(seconds: 3));
    expect(dio.options.receiveTimeout, RestApiClient.defaultReceiveTimeout);
  });

  test('a response with the wrong shape becomes an error result, not a crash', () async {
    final dio = Dio();
    dio.httpClientAdapter = _StatusAdapter(200, '{"info":{"count":1,"pages":1},"results":"not a list"}');
    final client = RestApiClient(endpoint: 'https://rickandmortyapi.com/api', dio: dio);

    final result = await client.getCharacters(page: 1);

    expect(result.isError, isTrue);
    expect(result.requiredError.type, AppErrorType.other);
  });
}

class _StatusAdapter implements HttpClientAdapter {
  final int statusCode;
  final String body;
  final Map<String, String> headers;
  var calls = 0;

  _StatusAdapter(this.statusCode, this.body, {this.headers = const {}});

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    calls += 1;
    return ResponseBody.fromString(
      body,
      statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
        for (final entry in headers.entries) entry.key: [entry.value],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
