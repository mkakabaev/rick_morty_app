// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'characters.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CharactersResponseDto _$CharactersResponseDtoFromJson(
  Map<String, dynamic> json,
) => CharactersResponseDto(
  info: CharacterResponsePageInfoDto.fromJson(
    json['info'] as Map<String, dynamic>,
  ),
  results: (json['results'] as List<dynamic>)
      .map((e) => CharacterDto.fromJson(e as Map<String, dynamic>))
      .toList(),
);

CharacterResponsePageInfoDto _$CharacterResponsePageInfoDtoFromJson(
  Map<String, dynamic> json,
) => CharacterResponsePageInfoDto(
  count: (json['count'] as num).toInt(),
  pages: (json['pages'] as num).toInt(),
  next: json['next'] as String?,
  prev: json['prev'] as String?,
);
