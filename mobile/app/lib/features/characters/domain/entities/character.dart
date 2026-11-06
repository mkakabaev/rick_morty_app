import 'package:equatable/equatable.dart';

import 'character_id.dart';

class Character extends Equatable {
  final CharacterId id;
  final String name;
  final String status;
  final String species;
  final String imageUrl;
  final String origin;
  final String location;

  const Character({
    required this.id,
    required this.name,
    required this.status,
    required this.species,
    required this.imageUrl,
    required this.origin,
    required this.location,
  });

  @override
  List<Object> get props => [id, name, status, species, imageUrl, origin, location];
}
