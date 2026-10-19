import 'package:json_annotation/json_annotation.dart';

part 'character.g.dart';

@JsonSerializable(createToJson: false)
class CharacterDto {
  final int id;
  final String name;
  final String status;
  final String species;
  final String image;
  final CharacterPlaceDto origin;
  final CharacterPlaceDto location;

  const CharacterDto({
    required this.id,
    required this.name,
    required this.status,
    required this.species,
    required this.image,
    required this.origin,
    required this.location,
  });

  factory CharacterDto.fromJson(Map<String, dynamic> json) => _$CharacterDtoFromJson(json);
}

CharacterDto deserializeCharacterDto(Map<String, dynamic> json) => .fromJson(json);

@JsonSerializable(createToJson: false)
class CharacterPlaceDto {
  final String name;

  const CharacterPlaceDto({required this.name});

  factory CharacterPlaceDto.fromJson(Map<String, dynamic> json) => _$CharacterPlaceDtoFromJson(json);
}
