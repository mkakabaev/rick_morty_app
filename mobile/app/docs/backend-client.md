# API client

HTTP lives under `lib/services/`. The characters repository depends on `ApiClient` and `ReachabilityService`. JSON calls use one stack: Dio + Retrofit.

## Layout

| Place | Role |
| --- | --- |
| `api_client/api_client.dart` | HTTP port. `getCharacters` and `getCharacter` |
| `api_client/rest_api_client.dart` | Dio client. Retries HTTP 429, then returns `Result.error` |
| `api_client/retrofit/` | Retrofit. `Parser.FlutterCompute` decodes on a worker isolate |
| `api_client/dtos/` | Wire DTOs. Not feature entities |
| `networking/error_mappers.dart` | Maps HTTP status codes onto `AppError` / `AppErrorType` |
| `image_service/` | Cached image downloads. Retries HTTP 429 on its own (capped) |
| `reachability/` | Online / offline primitive. Features map it to their own entity |

`AppConfig.apiBaseUrl` is `https://rickandmortyapi.com/api` for every flavor. `GET /character` accepts `page` and an optional `name`. `GET /character/{id}` loads one character.

A name with no matches is HTTP 404 and body `{"error":"There is nothing here"}`. `RestApiClient` maps that status to `AppError` with `AppErrorType.notFound` and keeps the body message. The characters repository turns `notFound` into an empty page. Other failures stay `Result.error`.

HTTP 429 is retried inside `RestApiClient` with pauses of `1s`, `2s`, `3s`, then `5s`. A numeric `Retry-After` header replaces the default pause for that attempt, capped at `maxRetryAfter` (30s). Those retries are not surfaced. After the last retry fails, the result is `AppError` with `AppErrorType.serverBusy`. The message is the response `error` string when the body has one, otherwise `Server busy. Try again later`.

`RestApiClient` sets connect / send / receive timeouts on its `Dio` when the caller has not (15s / 15s / 30s). A timeout becomes `AppErrorType.network`, which lets the reachability-driven retry run instead of leaving a request pending forever.

`AppError.message` is transport text and is not shown as-is for typed errors. `ErrorLocalization.text` in `lib/ui/error.dart` maps `AppErrorType` to localized copy; only `AppErrorType.other` falls back to `message`.

`fromHttpResponse` also maps 401 → `unauthorized`, 403 → `forbidden`, 400 → `badRequest`, and 5xx → `internalServerError`. This API does not currently return those statuses for the character endpoints; the mapping is shared with image downloads.

Image downloads use the same status mapping. A 429 is retried up to `maxAttempts = 5`, with a random pause from `1s` through `10s` between attempts. Those retries are not surfaced.

A failure that replaces the page uses `ErrorPlate`. A failure that keeps the current value uses `PageHost.showError`, which shows a snackbar when the page is the current route.

## Rules

- Repositories map DTOs and service primitives to entities. `lib/services/` does not import feature types.
- A new HTTP method is added to `ApiClient` and `RestRetrofitClient`.
