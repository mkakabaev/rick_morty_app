import 'package:json_annotation/json_annotation.dart';

import 'character.dart';

part 'characters.g.dart';

@JsonSerializable(createToJson: false)
class CharactersResponseDto {
  final CharacterResponsePageInfoDto info;
  final List<CharacterDto> results;

  const CharactersResponseDto({required this.info, required this.results});
}

CharactersResponseDto deserializeCharactersResponseDto(Map<String, dynamic> json) =>
    _$CharactersResponseDtoFromJson(json);

@JsonSerializable(createToJson: false)
class CharacterResponsePageInfoDto {
  final int count;
  final int pages;
  final String? next;
  final String? prev;

  const CharacterResponsePageInfoDto({
    required this.count,
    required this.pages,
    required this.next,
    required this.prev,
  });

  factory CharacterResponsePageInfoDto.fromJson(Map<String, dynamic> json) =>
      _$CharacterResponsePageInfoDtoFromJson(json);
}
