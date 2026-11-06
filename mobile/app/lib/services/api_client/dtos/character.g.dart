// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'character.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CharacterDto _$CharacterDtoFromJson(Map<String, dynamic> json) => CharacterDto(
  id: (json['id'] as num).toInt(),
  name: json['name'] as String,
  status: json['status'] as String,
  species: json['species'] as String,
  image: json['image'] as String,
  origin: CharacterPlaceDto.fromJson(json['origin'] as Map<String, dynamic>),
  location: CharacterPlaceDto.fromJson(
    json['location'] as Map<String, dynamic>,
  ),
);

CharacterPlaceDto _$CharacterPlaceDtoFromJson(Map<String, dynamic> json) =>
    CharacterPlaceDto(name: json['name'] as String);
