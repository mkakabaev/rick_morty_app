import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../dtos/character.dart';
import '../dtos/characters.dart';

// this overrides Flutter's compute() function. see retrofit_workers.dart for details
import 'retrofit_workers.dart' show compute;

part 'retrofit_entries.g.dart';

@RestApi(parser: Parser.FlutterCompute)
abstract class RestRetrofitClient {
  factory RestRetrofitClient(Dio dio, {String baseUrl}) = _RestRetrofitClient;

  @GET('/character')
  Future<CharactersResponseDto> getCharacters({@Query('page') required int page, @Query('name') String? name});

  @GET('/character/{id}')
  Future<CharacterDto> getCharacter(@Path('id') int id);
}
