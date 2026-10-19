import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app/services/api_client/rest_api_client.dart';
import 'package:core/core.dart';

void main() {
  test('maps a 404 character response to notFound', () async {
    final dio = Dio();
    dio.httpClientAdapter = _StatusAdapter(404, '{"error":"There is nothing here"}');
    final client = RestApiClient(endpoint: 'https://rickandmortyapi.com/api', dio: dio);

    final result = await client.getCharacters(page: 1, name: 'zzz');

    expect(result.requiredError.type, RickMortyErrorType.notFound);
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
    expect(result.requiredError.type, RickMortyErrorType.serverBusy);
    expect((dio.httpClientAdapter as _StatusAdapter).calls, pauses.length + 1);
  });
}

class _StatusAdapter implements HttpClientAdapter {
  final int statusCode;
  final String body;
  var calls = 0;

  _StatusAdapter(this.statusCode, this.body);

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
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
