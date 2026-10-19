# API client

HTTP lives under `lib/services/`. The characters repository depends on `ApiClient` and `ReachabilityService`. JSON calls use one stack: Dio + Retrofit.

## Layout

| Place | Role |
| --- | --- |
| `api_client/api_client.dart` | HTTP port. `getCharacters` and `getCharacter` |
| `api_client/rest_api_client.dart` | Dio client. Retries HTTP 429, then returns `Result.error` |
| `api_client/retrofit/` | Retrofit. `Parser.FlutterCompute` decodes on a worker isolate |
| `api_client/dtos/` | Wire DTOs. Not feature entities |
| `networking/error_extension.dart` | Maps HTTP 404 and 429 onto `RickMortyError` |
| `image_service/` | Cached image downloads. Retries HTTP 429 on its own |
| `reachability/` | Online / offline primitive. Features map it to their own entity |

`AppConfig.apiBaseUrl` is `https://rickandmortyapi.com/api` for every flavor. `GET /character` accepts `page` and an optional `name`. `GET /character/{id}` loads one character.

A name with no matches is HTTP 404 and body `{"error":"There is nothing here"}`. `RestApiClient` maps that status to `RickMortyError.notFound` and keeps the body message. The characters repository turns `notFound` into an empty page. Other failures stay `Result.error`.

HTTP 429 is retried inside `RestApiClient` with pauses of `1s`, `2s`, `3s`, then `5s`. Those retries are not surfaced. After the last retry fails, the result is `RickMortyErrorType.serverBusy`. The message is the response `error` string when the body has one, otherwise `Server busy. Try again later`.

Image downloads use the same status mapping. A 429 is retried until the response is not busy, with a random pause from `1s` through `10s`. Those retries are not surfaced.

A failure that replaces the page uses `ErrorPlate`. A failure that keeps the current value uses `PageHost.showError`, which shows a snackbar when the page is the current route.

## Rules

- Repositories map DTOs and service primitives to entities. `lib/services/` does not import feature types.
- A new HTTP method is added to `ApiClient` and `RestRetrofitClient`.
