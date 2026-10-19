import 'package:equatable/equatable.dart';

enum RickMortyErrorType { other, network, notFound, serverBusy }

class RickMortyError extends Error with Equatable {
  final String message;
  final RickMortyErrorType type;

  RickMortyError(this.message, {this.type = .other});

  factory RickMortyError.from(Object e) {
    if (e is RickMortyError) {
      return e;
    }
    return RickMortyError('$e');
  }

  static RickMortyError? fromOptional(Object? e) {
    if (e == null) {
      return null;
    }
    if (e is RickMortyError) {
      return e;
    }
    return RickMortyError('$e');
  }

  @override
  String toString() {
    return message;
  }

  @override
  List<Object?> get props => [message, type];
}
