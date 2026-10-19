import 'package:core/core.dart';

extension RickMortyErrorExtension on RickMortyError {
  static RickMortyError? parseHttpResponse(int? statusCode, {String? message}) {
    switch (statusCode) {
      case 404:
        return RickMortyError(message ?? 'Not found', type: .notFound);
      case 429:
        return RickMortyError(message ?? 'Server busy. Try again later', type: .serverBusy);
      default:
        break;
    }
    return null;
  }
}
