# fb_api_client

The Dart client for the Fitness Buddy API, generated from the contract
`contracts/openapi.yaml` (S02, TD-023). Never edit the generated code and never
hand-write API types: change the contract (`contracts/openapi/`), run
`make gen`, and commit the contract, the bundle and this package together.

## Use

```dart
import 'package:fb_api_client/fb_api_client.dart';

final api = FbApi(dio); // one client per contract tag: api.account, ...
final ClientConfig config = await api.account.getConfig();
```

- **Clients** are retrofit classes on dio, one per contract tag (`Account` →
  `AccountClient`), reached through the root client `FbApi`. The method name is
  the `operationId`.
- **Models** are immutable freezed classes with `fromJson`/`toJson`.
- **Client headers** (`X-App-Version`, `X-Platform`, `X-Device-Id`) are not
  method parameters (`skipped_parameters`): a dio interceptor sets them (S03).
- **Errors:** non-2xx responses throw `DioException`. A problem+json body
  decodes with `ProblemDetails.fromJson(e.response!.data)` (mapping comes in
  S03).

## Type mapping

| Contract | Dart |
|---|---|
| `type: [T, 'null']` or `oneOf: [$ref, {type: 'null'}]` | `required T?` (sent as `null`, never omitted; D4) |
| `Instant` (`format: date-time`) | `DateTime` |
| `LocalDate` (`format: date`) | `String` `YYYY-MM-DD` (see below) |
| `Id` (`format: uuid`) | `String` |
| `number` / `format: double` | `double` |
| `additionalProperties: T` | `Map<String, T>` |
| `oneOf` + `discriminator.mapping` | a freezed **sealed** union (`Intent` → `IntentLogFood`, …) with an extra `…Unrecognized` variant for kinds this app version doesn't know |

## Regenerate

`make gen` (bundle, then this package) or `make gen-dart` (this package only).
`tools/scripts/gen-dart.sh`:

1. copies the bundle and the fixture into `.dart_tool/fb_gen/` and deletes
   `format: date` lines (swagger_parser maps it to a `DateTime` with a time part;
   the script fails if `format: date` survives in another spelling),
2. deletes `lib/src/generated/` and `test/generated/`,
3. runs swagger_parser with `swagger_parser.yaml` (two schemes, below),
4. writes a no-lint `analysis_options.yaml` into each generated folder (lints
   off, compile errors still reported),
5. runs build_runner (freezed, json_serializable with `explicit_to_json`,
   retrofit; `build.yaml`),
6. formats the output.

Regeneration is deterministic. CI runs `make gen-check`, which regenerates and
fails with "Generated client is out of date: run 'make gen' and commit." if
the result differs from git.

## Layout

| Path | What |
|---|---|
| `lib/fb_api_client.dart` | The barrel: import only this. |
| `lib/src/generated/` | GENERATED from `contracts/openapi.yaml`. |
| `test/fixtures/union_fixture.openapi.yaml` | A tricky-shape fixture (Buddy-like `Intent` union, nullables, `LocalDate`). Not part of the API, so it never ships or gets frozen by the breaking gate. |
| `test/generated/` | GENERATED from the fixture. Tests only. |
| `test/` | Dependency purity, the config client through a fake dio adapter, `ProblemDetails`, and the union fixture. |

## Upgrading the generator

swagger_parser, build_runner, freezed, json_serializable, retrofit_generator
and the runtime packages they emit code for (retrofit, freezed_annotation,
json_annotation) are pinned exactly and ignored by Dependabot. They
move together, with the Flutter pin (the workspace's `test` version caps
`analyzer` below 14), in one commit with the `make gen` output. Check the
union fixture tests after every bump.
