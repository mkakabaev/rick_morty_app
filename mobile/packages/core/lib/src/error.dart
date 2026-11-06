import 'package:equatable/equatable.dart';

enum AppErrorType { other, unauthorized, notFound, serverBusy, forbidden, badRequest, internalServerError, network }

class AppError extends Error with Equatable {
  final String message;
  final AppErrorType type;

  AppError(this.message, {this.type = .other});

  factory AppError.from(Object e) {
    if (e is AppError) {
      return e;
    }
    return AppError('$e');
  }

  static AppError? fromOptional(Object? e) {
    if (e == null) {
      return null;
    }
    if (e is AppError) {
      return e;
    }
    return AppError('$e');
  }

  @override
  String toString() {
    return message;
  }

  @override
  List<Object?> get props => [message, type];
}
