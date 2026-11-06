import 'package:core/core.dart';

AppError? fromHttpResponse({required int? statusCode, String? message}) {
  if (statusCode != null) {
    switch (statusCode) {
      case 404:
        return AppError(message ?? 'Not found', type: .notFound);
      case 429:
        return AppError(message ?? 'Server busy. Try again later', type: .serverBusy);
      case 401:
        return AppError(message ?? 'Unauthorized', type: .unauthorized);
      case 403:
        return AppError(message ?? 'Forbidden', type: .forbidden);
      case 400:
        return AppError(message ?? 'Bad Request', type: .badRequest);
      case >= 500 && < 600:
        return AppError(message ?? 'Internal Server Error', type: .internalServerError);
    }
  }
  return null;
}
