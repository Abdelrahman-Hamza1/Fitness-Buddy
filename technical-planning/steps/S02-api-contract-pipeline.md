# S02 — API contract pipeline

| Phase | Depends on | Size | Status |
|---|---|---|---|
| P0 Foundations | S01 | M+ | ✅ Done |

**Goal.** The OpenAPI contract becomes the enforced boundary between app and backend: written once, linted, versioned, turned into a Dart client, and checked against the real server, all in CI. Proven end to end with one real endpoint (`GET /v1/config`).

**Spec:** — (enables everything that talks to the API) · **Decisions:** TD-023

## Scope
- `contracts/openapi/` structure: root document, shared components (`ProblemDetails` + error `type` catalogue, standard headers, `Cursor`/pagination, `Id` (UUIDv7), `Instant`, `LocalDate`, units), and one module file per future module (empty except Account/Config).
- First endpoint: **`GET /v1/config`** (minimum app version, feature flags map, client thresholds map).
- **A tricky-shape fixture:** a `oneOf` + discriminator schema (like Buddy's intents) to prove the Dart generator produces sealed/union types that work. This is the main technical risk of the step.
- **Redocly CLI** bundling to `contracts/openapi.yaml` (committed).
- **Spectral ruleset** (`contracts/spectral.yaml`) encoding `04` §4.2: path versioning, problem+json on 4xx/5xx, cursor pagination (offset params forbidden), required headers, camelCase, `Idempotency-Key` on unsafe POSTs, ID/time formats.
- **oasdiff** breaking-change check against the last `contracts-v*` tag (the first tag is created in this step).
- **Dart client generation** into `packages/fb_api_client` (dio-based), generated code committed, `make gen` regenerates it. CI fails if the regenerated output differs.
- **Server side, minimal:** `GET /v1/config` implemented in `backend/src/Host` (hard-coded values for now), the ASP.NET Core OpenAPI document generated at build time, and a **conformance check** that diffs it against the contract.
- `contracts/testdata/` folder + README (golden files shared by both stacks, filled by later steps).
- **From S01 review (A15):** `make gen` must format its generated output, and the generated client must be excluded from analysis (`--fatal-infos`). The `fb_api_client` dependency allowlist test needs `dio` (and the generator's runtime packages).
- `contract` CI workflow (`10` §7).

## Out of scope
- Full HTTP conventions, middleware, problem-details mapping (S03). Auth (S24).

## Fixed by the plan
- Contract-first, OpenAPI 3.1, REST conventions in `04` §4. The server's DTOs must match the contract, and the contract wins.

## Decide in the low-level plan
- **Dart generator** (`swagger_parser`, `openapi-generator` dart-dio, or another). Criteria: OpenAPI 3.1, `oneOf` + discriminator → sealed classes, nullable handling, freezed/json_serializable output, maintenance. Prove it on the fixture.
- **C# side:** hand-written DTO records + conformance diff (default), or C# DTOs generated from the contract. Pick what keeps the diff clean and readable.
- How to normalise the generated vs authored documents so the conformance diff ignores cosmetic differences (ordering, descriptions) but catches real ones.

## Exit criteria
- [x] `make gen` bundles the contract and regenerates the Dart client. The client compiles, and a Dart test deserialises the `oneOf` fixture into the right subtype.
- [x] Changing the contract without the server (or the reverse) fails CI with a readable message.
- [x] A breaking change (e.g. removing a field) fails oasdiff. An additive change passes.
- [x] Spectral fails on a test fixture that uses `?offset=` pagination or a non-problem+json error.
- [x] `GET /v1/config` runs locally (`dotnet run`) and matches the contract.

## Read first
`04-backend.md` §4 · `03-architecture.md` §7 · `10-engineering-practices.md` §7

## Owner involvement
None.

---

## Low-level plan
_Written in Phase B (2026-10-12) by the step-planner, from the orchestrator's research decisions R1–R5 (`research-notes.md`, the two S02 sections)._

### 1. Summary
After S02, `contracts/openapi/` holds the source contract: a root document, shared components, and one file per module. `contracts/openapi.yaml` is the committed Redocly bundle, with one real endpoint, `GET /v1/config`. `make gen` bundles the contract and regenerates `packages/fb_api_client` (swagger_parser → freezed + retrofit on dio), formatted and exempt from lints. The Host serves `GET /v1/config` from hand-written C# records and writes its OpenAPI document at build time. `oasdiff changelog` fails on any API difference between that document and the contract. Spectral (our `04` §4.2 rules), the oasdiff breaking gate (against the last `contracts-v*` tag; `contracts-v0.1.0` is created at merge), self-tests of all three tools, and a regeneration diff all run in CI under the single `ci` gate. Redocly, Spectral and oasdiff run as digest-pinned Docker images with no network.

### 2. Decisions

| # | Decision | Reason / source |
|---|---|---|
| D1 | **Dart generator: `swagger_parser` 1.45.0**, `json_serializer: freezed`, `use_freezed3: true`, retrofit on dio, `root_client: true` (`FbApi`), `put_clients_in_folder: true`, `unknown_enum_value: true`, **`fallback_union: unrecognized`**, `mark_files_as_generated: true`, **`skipped_parameters: [X-App-Version, X-Platform, X-Device-Id]`** (a dio interceptor sets these, `02` API-client row). Two `schemes:`: the contract → `lib/src/generated/`, the union fixture → `test/generated/` (D3). `build.yaml`: `explicit_to_json: true`. **Exact pins:** runtime dio 5.11.1, retrofit 4.10.0, freezed_annotation 3.1.0, json_annotation 4.12.0; dev swagger_parser 1.45.0, build_runner 2.16.1, freezed 4.0.1, json_serializable 6.14.1, retrofit_generator 10.2.11. Dependabot `pub` **ignores** swagger_parser, build_runner, freezed, freezed_annotation, json_serializable, retrofit_generator. They move together with the Flutter pin (the analyzer < 14 cap), on purpose, with a regen commit | R1, proven 9/9 on the fixture. `fallback_union` must not equal a real variant name (the research crash), and Buddy may get a real `unknown` intent. Dependabot can't regenerate, so a generator bump would always fail `gen-check` |
| D2 | **Pre-generation transform:** `tools/scripts/gen-dart.sh` copies each input spec into `packages/fb_api_client/.dart_tool/fb_gen/` and deletes lines matching `^\s*format: date\s*$` (anchored, so `date-time` survives). It then asserts that `format: date` no longer appears in any form, failing loudly if Redocly ever emits flow style. `LocalDate` reaches Dart as a `String` `YYYY-MM-DD`, and the app wraps it later | R1 gotcha: swagger_parser hard-codes `format: date` → `DateTime` and serializes it with a time part |
| D3 | **The `oneOf` fixture stays out of the published contract:** `packages/fb_api_client/test/fixtures/union_fixture.openapi.yaml` (a Buddy-like `Intent` union with `discriminator.mapping`, 3 variants including one named `unknown`, a list of intents in a response, a type-array nullable, a `oneOf` null-wrap, `LocalDate`). It's generated by the same script into `test/generated/` | A fake schema in `contracts/` would ship in the app's API and be frozen by the breaking gate (`api-schema-removed`). The real `Intent` arrives with the Buddy steps |
| D4 | **Nullability/required convention:** every property is listed in `required`. A value that can be absent is `type: [T, 'null']` and is sent as JSON `null`, never as a missing key. **Exceptions:** (a) `ProblemDetails` optional members are omitted (D5); (b) a request property *added to a published version* is optional, with a server default (C#: non-positional `init` property with a default). C#: positional records, STJ defaults (nulls written, no `DefaultIgnoreCondition`). Dart: `required T?` | It's exactly what .NET 10 emits for positional records (all required, nullable → `[null, T]`), so DTOs need no attributes. oasdiff treats type arrays and `oneOf` null-wraps alike. **TD candidate** (API schema conventions, amends `04` §4.2) |
| D5 | **ProblemDetails:** the contract's own RFC 9457 schema. `type` (string, `uri-reference`), `title` (string) and `status` (integer int32) are required and non-null. `detail` and `instance` are optional strings. Extra members are allowed (extensions). The server keeps the framework `ProblemDetails` and adds a **`ProblemDetailsSchemaTransformer`** that rewrites its all-nullable, all-optional schema into this shape (proven in research). **Error type catalogue:** a `ProblemType` string-enum component listing the stable URIs named in `04` §4.2: `/errors/validation-failed`, `/errors/rate-limited`, `/errors/version-conflict`, `/errors/upgrade-required`. They're **relative URI references**. `ProblemDetails.type` itself stays a free string, because the framework emits RFC links for unmapped statuses. `ValidationProblem` (the `errors` map) and the 400/426/429 responses come with S03's mapping | No API domain exists yet (hosting comes later), and the type must stay stable from v1. RFC 9457 §3.1.1 allows relative references, and the app compares the raw string. **TD candidate** (with D4) |
| D6 | **`operationId` and tags stay strictly checked:** Spectral `operation-operationId`, `operation-operationId-unique`, `operation-tags` and `operation-tag-defined` are raised to error, plus `fb-operation-id-camel-case`. Conformance compares them (server `.WithName()` / `.WithTags()`). **One tag per module** (`Account`, later `Identity`, `Sync`, `Buddy`, `Catalog`, `Usage`) | `operationId` is the Dart method name and a tag is the Dart client class, so drift would silently rename the app's API. They aren't wire-breaking, so the breaking gate (D12) ignores them (oasdiff: info) |
| D7 | **Spectral:** `extends: [[spectral:oas, recommended]]`, `oas3-unused-component: off` (shared components are defined ahead of use, on purpose), `info-contact: off`, run on the **bundle** with `--fail-severity=warn`. Custom `fb-*` rules are listed in §3.2. **Self-test fixtures** live in `contracts/selftest/spectral/*.yaml`. Each starts with `# expect: <rule-code>`, and `contract-selftest.sh` asserts that each one fails *with that code* and that the real bundle passes | Exit criterion 4 as a permanent CI test. It also guards the ruleset against accidental loosening |
| D8 | **Contract tools = Docker images pinned by tag@sha256**, in `tools/contract-tools/compose.yaml` (redocly/cli 2.62.1, stoplight/spectral 6.17.0, tufin/oasdiff v1.33.0, digests as in research-notes). Every service has `network_mode: none`, `user: ${UID}:${GID}`, the repo mounted at `/work`, `REDOCLY_TELEMETRY=off`, `DO_NOT_TRACK=1` and `SCARF_NO_ANALYTICS=true`, and runs through `docker compose run --rm`. No Node toolchain. `make setup` pulls the images (`contract-tools` target). `make doctor` checks the docker CLI, daemon access and Compose v2. The README lists **Docker Engine + Compose v2** as a prerequisite. Dependabot gets a `docker-compose` entry for `/tools/contract-tools` | R2. Same precedent as actionlint in S01. **TD candidate:** TD-040 addendum, "Node-based dev tools run as digest-pinned Docker images, offline" |
| D9 | **Server:** hand-written C# DTO records. `Microsoft.AspNetCore.OpenApi` + `Microsoft.Extensions.ApiDescription.Server` 10.0.12 (CPM). Build-time document `backend/artifacts/openapi/server.json` (already gitignored), from `--file-name server --document-name v1 --openapi-version OpenApi3_1`. JSON: `NumberHandling = Strict`, `JsonStringEnumConverter(JsonNamingPolicy.CamelCase)`. `MapOpenApi()` **only in Development**. Makefile `export PATH := $(DOTNET_ROOT):$(PATH)`. The **enum schema transformer is deferred** to the first step that adds an enum (backlog, with the proven snippet), because S02 has no enum to test it with. No startup side effects exist yet. The `GetDocument.Insider` guard rule goes into `backend/README.md` for S04 | R3. Hand-written records keep the diff readable. Generated C# DTOs add a tool without removing the route/status/media-type diff |
| D10 | **Conformance = `oasdiff changelog contracts/openapi.yaml backend/artifacts/openapi/server.json --fail-on INFO --allow-external-refs=false --severity-levels contracts/oasdiff/conformance-levels.txt`** (sets `api-schema-removed`, `api-version-decreased` and `api-version-not-bumped` to `none`). **No other normalisation:** oasdiff already ignores info, servers, descriptions, examples, key order, component names and `$ref` vs inline (17/17 mutations caught). The wrapper prints `Server API does not match the contract (the contract wins):`, then the oasdiff lines, then the fix hint (change the C# endpoint/DTO, or change the contract first and run `make gen`). In CI it adds `--format githubactions` annotations. The contract's client-header parameters are documented on the server by **`ClientHeadersOperationTransformer`** (every `/v1/` operation). S03 enforces them | R4. Card item "normalise generated vs authored": answered by oasdiff's semantics plus the levels file |
| D11 | **`GET /v1/config`:** tag `Account`, `operationId: getConfig`, the three client-header parameters, `200` `application/json` `ClientConfig {minimumAppVersion: string, featureFlags: map<string,bool>, thresholds: map<string,number/double>}` (all required), and `500` → `InternalError` (problem+json). The Host returns hard-coded `{"minimumAppVersion":"0.1.0","featureFlags":{},"thresholds":{}}` from `Host/Config/` until the Account module exists. No invented flags or thresholds. Real values, the 426 gate (and whether config is exempt from it) come in S03 | Card scope. Empty maps are honest. The 500 response exercises problem+json end to end |
| D12 | **Breaking gate:** `oasdiff breaking <base> contracts/openapi.yaml --fail-on WARN --severity-levels contracts/oasdiff/breaking-levels.txt`. Base = `git show <tag>:contracts/openapi.yaml`, with `tag = git describe --tags --abbrev=0 --match 'contracts-v*' HEAD`, overridable with `CONTRACT_BASE_REF=<ref>`. **No tag reachable → notice + pass.** The levels file downgrades `response-property-enum-value-added`, `response-body-one-of-added`, `response-property-one-of-added`, `response-body-any-of-added` and `response-property-any-of-added` to `info`, because clients have `$unknown` / `unrecognized` fallbacks (`04` §4.2 forward compatibility, D1). Fail on WARN, because WARN items (request property removed, response media type changed, pattern changed) also break old apps. The first tag, **`contracts-v0.1.0`**, goes on the S02 squash commit on `main` (O3) | R4. oasdiff's defaults treat those five additions as `error`, which would block every new intent kind or enum value |
| D13 | **CI layout (deviation from R5's single job):** a new **`contract`** job (Docker only: `contract-tools contract-bundle-check contract-lint contract-selftest contract-breaking`, checkout with `fetch-depth: 0` for tags). The **`dart`** job adds `make gen-check`. The **`dotnet`** job adds `make contract-conformance`, which reuses the Release build that already wrote `server.json`. Gate: `ci.needs: [dart, dotnet, contract]`. The ruleset is unchanged | One all-in-one job would set up Flutter and .NET a second time and build the backend twice (~3 extra min per push). Each check still fails `ci` with its own message. If the orchestrator prefers one job, WP5 changes only the workflow |
| D14 | **Exit criteria 2 and 3 are proven three ways:** permanent self-tests on fixture pairs (in CI), local mutation demos in WP2/WP4 (output pasted), and CI proof branches pushed by the orchestrator (O2, plus O4 after the tag), like S01's O3 | Self-tests keep proving it after S02. Proof branches show the real CI message |

### 3. Design

**3.1 Files**
```
contracts/README.md                       how to change the API (edit openapi/ → make gen → commit both), conventions D4–D6, D12
contracts/redocly.yaml                    bundling only (telemetry: off, apis.fitness-buddy.root: openapi/openapi.yaml)
contracts/openapi/openapi.yaml            root: openapi 3.1.1, info.version 0.1.0, local-dev servers entry, tags (one per module),
                                          paths → $ref modules/*, components → $ref components/* (so shared components are bundled)
contracts/openapi/components/problems.yaml    ProblemDetails, ProblemType (enum), responses.InternalError
contracts/openapi/components/headers.yaml     parameters AppVersion (X-App-Version, required, string), Platform (X-Platform, required,
                                              enum android|ios), DeviceId (X-Device-Id, required, uuid), IdempotencyKey (required, uuid);
                                              headers XRequestId
contracts/openapi/components/pagination.yaml  parameters Cursor (cursor, optional string), Limit (limit, int32, minimum 1; max set per
                                              endpoint); schema NextCursor ([string, null])
contracts/openapi/components/types.yaml       Id (string/uuid, "UUIDv7"), Instant (date-time, RFC 3339 UTC), LocalDate (date),
                                              TzOffsetMin (int32), Grams, Milliliters, Kilocalories, Kilograms, Centimeters (number/double)
contracts/openapi/modules/account.yaml        /v1/config + ClientConfig
contracts/openapi/modules/{identity,sync,buddy,catalog,usage}.yaml   `paths: {}` + a one-line comment (filled by later steps)
contracts/openapi.yaml                    GENERATED bundle (committed; .gitattributes linguist-generated)
contracts/spectral.yaml                   §3.2
contracts/oasdiff/{conformance-levels.txt,breaking-levels.txt}
contracts/selftest/spectral/*.yaml        one failing fixture per fb-* rule group (# expect: <code>)
contracts/selftest/breaking/{base,field-removed,additive,enum-value-added}.yaml
contracts/selftest/conformance/{contract.yaml,server-match.json,server-renamed.json}   (reuse the research files)
contracts/testdata/README.md              purpose + naming rules for shared golden files (filled from S06/S07 on)
tools/contract-tools/compose.yaml         D8
tools/scripts/{gen-dart.sh,contract-selftest.sh,contract-breaking.sh,contract-conformance.sh}
packages/fb_api_client/{pubspec.yaml,analysis_options.yaml,build.yaml,swagger_parser.yaml,README.md}
packages/fb_api_client/lib/fb_api_client.dart            barrel → src/generated/export.dart (+ root client)
packages/fb_api_client/lib/src/generated/**              GENERATED + analysis_options.yaml without lints (written by gen-dart.sh)
packages/fb_api_client/test/{dependencies_test,config_client_test,problem_details_test,union_fixture_test}.dart
packages/fb_api_client/test/{fixtures/union_fixture.openapi.yaml, helpers/fake_adapter.dart}
packages/fb_api_client/test/generated/**                 GENERATED from the fixture (+ no-lint analysis_options.yaml)
backend/src/Host/{FitnessBuddy.Host.csproj,Program.cs}
backend/src/Host/Config/{ClientConfig.cs,ConfigEndpoints.cs}
backend/src/Host/OpenApi/{ProblemDetailsSchemaTransformer.cs,ClientHeadersOperationTransformer.cs}
backend/tests/Contract.Tests/{FitnessBuddy.Contract.Tests.csproj,ConfigEndpointTests.cs}
backend/{Directory.Packages.props,FitnessBuddy.slnx,README.md}
pubspec.yaml (workspace += packages/fb_api_client) · pubspec.lock · Makefile · .gitattributes · .github/{workflows/ci.yml,dependabot.yml} · README.md
```

**3.2 Spectral `fb-*` rules** (all `error`, all on the resolved bundle)

| Rule | Encodes (`04` §4.2) |
|---|---|
| `fb-path-versioned` | path keys match `^/(v[0-9]+\|health\|\.well-known)/` |
| `fb-problem-json-errors` | every `4XX`/`5XX`/`default` response has content, and its only media type is `application/problem+json` |
| `fb-no-offset-pagination` | no query parameter named `offset`, `page`, `pageNumber`, `pageSize`, `skip` or `take` |
| `fb-client-headers` | every operation under `/v1/` has header parameters `X-App-Version`, `X-Platform`, `X-Device-Id` (`schema` function, `contains`) |
| `fb-idempotency-key` | every `post` has a required `Idempotency-Key` header parameter |
| `fb-camel-case-properties` / `fb-camel-case-params` / `fb-operation-id-camel-case` | schema property names, query/path parameter names and `operationId` match `^[a-z][a-zA-Z0-9]*$` |
| `fb-id-format` / `fb-instant-format` / `fb-local-date-format` | properties `id`/`*Id` → `format: uuid`. `*At` → `date-time`. `date`/`*Date` → `date` |

**3.3 Makefile** (new targets. `UID`, `GID` and `REPO_ROOT` are exported for compose, and `PATH` is prefixed with `$(DOTNET_ROOT)`)

| Target | Does |
|---|---|
| `gen` = `gen-contract gen-dart` | The card's "`make gen`" |
| `gen-contract` | `redocly bundle openapi/openapi.yaml -o openapi.yaml` (cwd `contracts/`) |
| `gen-dart` | `gen-dart.sh`: strip (D2) → `rm -rf` both generated dirs → `dart run swagger_parser` → write the no-lint `analysis_options.yaml` → `dart run build_runner build --delete-conflicting-outputs` → `dart format` both dirs |
| `gen-check` | `gen-dart`, then `git status --porcelain -- packages/fb_api_client` must be empty, else `Generated client is out of date: run 'make gen' and commit.` plus the file list |
| `contract-tools` | `docker compose -f tools/contract-tools/compose.yaml pull` (part of `setup`) |
| `check-contract` = `contract-bundle-check contract-lint contract-selftest contract-breaking contract-conformance` | Part of `check` (after `check-dotnet`) |
| `contract-bundle-check` | bundle into `build/contract/openapi.yaml`, then `diff -u` against the committed bundle, else `contracts/openapi.yaml is stale: run 'make gen' and commit.` |
| `contract-lint` | `spectral lint contracts/openapi.yaml --ruleset contracts/spectral.yaml --fail-severity=warn` |
| `contract-selftest` / `contract-breaking` / `contract-conformance` | the scripts (D7, D12, D10). `contract-conformance` first deletes `obj/**/*.OpenApiFiles.cache` and builds `src/Host` Release (incremental), so `server.json` is always fresh |

**3.4 Server** (respects `04` §3: Host is the composition root, endpoints are thin, the DTO lives with its endpoint group): `Program.cs` = `ConfigureHttpJsonOptions` (D9) → `AddOpenApi("v1", o => { o.AddSchemaTransformer<ProblemDetailsSchemaTransformer>(); o.AddOperationTransformer<ClientHeadersOperationTransformer>(); })` → `Build` → `MapOpenApi()` if Development → `app.MapConfigEndpoints()`. `ConfigEndpoints`: `MapGet("/v1/config", () => TypedResults.Ok(ClientConfig.Defaults)).WithName("getConfig").WithTags("Account").ProducesProblem(500)`. Classes are `sealed`/`internal` where the build allows. `Contract.Tests` (xUnit v3/MTP + `Microsoft.AspNetCore.Mvc.Testing` 10.0.12) uses `WebApplicationFactory<Program>`.

**3.5 Data flow:** `contracts/openapi/**` →(Redocly)→ `contracts/openapi.yaml` →(strip + swagger_parser + build_runner + format)→ `fb_api_client` (committed). The same bundle is checked by Spectral, compared by oasdiff with `server.json` (conformance), and compared with the `contracts-v*` tag's bundle (breaking). The contract wins every disagreement.

### 4. Work packages (contract first. WP3 and WP4 may run in parallel worktrees after WP2)

| WP | Specialist | Tasks | Done when |
|---|---|---|---|
| **WP1 Contract tooling & rules** | platform-engineer | `tools/contract-tools/compose.yaml` (D8). Makefile: exports, `contract-tools`, `gen-contract`, `contract-bundle-check`, `contract-lint`, `contract-selftest`, `contract-breaking`, `contract-conformance` (script part, taking `SERVER_DOC`), `setup`/`check` wiring. The three scripts + `contracts/spectral.yaml`, `contracts/oasdiff/*`, `contracts/selftest/**`, `contracts/redocly.yaml`. `doctor.sh` Docker checks. Dependabot `docker-compose` entry + the D1 `pub` ignores. README prerequisites (Docker) | `make contract-tools contract-selftest` green: each Spectral fixture fails with its expected code, `field-removed` fails breaking, `additive` and `enum-value-added` pass, `server-renamed` fails conformance with the readable message (pasted). `bash -n` on the scripts. `make doctor` shows Docker. A run with networking blocked still works (compose `network_mode: none` confirmed with `docker inspect`) |
| **WP2 Contract content** | platform-engineer | §3.1 `contracts/openapi/**` (D4, D5, D6, D11), `contracts/README.md`, `contracts/testdata/README.md`, `make gen-contract` → committed bundle, `.gitattributes` `linguist-generated` for the bundle | `make contract-bundle-check contract-lint contract-breaking` green (breaking: "no tag" notice). **Local proof (pasted):** with `CONTRACT_BASE_REF=HEAD`, removing `ClientConfig.minimumAppVersion` fails breaking, and adding a required response property passes. Editing a source file without re-bundling fails `contract-bundle-check` with the stale message |
| **WP3 Dart client** | flutter-engineer | **Spike first (≤ 30 min):** two `schemes:` with the fixture output in `test/generated/` under build_runner (fallback: a second `swagger_parser.fixture.yaml` run with `-f`). Then: the package (D1), `gen-dart.sh` (D2), `gen-dart`/`gen-check` targets, workspace entry, `pubspec.lock`, the §5 Dart tests, `.gitattributes` for the generated dirs, package README | `make gen` twice → the second run is a no-op (`git status` clean). `make deps-dart check-dart test-dart gen-check` green. A hand edit in a generated file makes `gen-check` fail with its message (pasted). `dart analyze --fatal-infos` clean |
| **WP4 Host endpoint + conformance** | dotnet-engineer | §3.4, CPM entries, `Contract.Tests` in the `.slnx`, Makefile `PATH` export and the Host-build half of `contract-conformance`, `backend/README.md` (OpenAPI conventions: DTO rules D4, transformers, the `GetDocument.Insider` guard rule, the deferred enum transformer) | `make deps-dotnet check-dotnet test-dotnet contract-conformance` green. `dotnet run --project src/Host` + `curl -i localhost:<port>/v1/config` output pasted. **Local proofs (pasted, reverted):** adding a property to the C# record fails conformance; making a contract field optional + `make gen` without a server change fails conformance. Build-time generation overhead per Host build measured |
| **WP5 CI wiring** | platform-engineer | D13: `contract` job, `gen-check` in `dart`, `contract-conformance` in `dotnet`, `ci.needs`, header comments. 10 §7 workflow text drafted for O5 | `actionlint` clean (pinned image, as in S01). After the orchestrator pushes, `ci-status.sh <sha>` → `ci` ✅ with `contract` listed |

**Orchestrator steps:**
- **O1** Push after WP5, then `ci-status.sh` green.
- **O2** Proof branches from the step branch: `ci-proof/contract-only` (add a required `motd: [string, null]` to `ClientConfig` in the contract + `make gen`, server untouched → `dotnet` fails in conformance) and `ci-proof/server-only` (add a property to the C# record only → `dotnet` fails). Record the run URLs, then delete both.
- **O3** At merge (TD-039 flow): once `merge/S02` is on `main`, run `git tag -a contracts-v0.1.0 <main-sha> -m "Contract v0.1.0 (S02)"` and `git push origin contracts-v0.1.0`. This triggers one permission prompt, because tag pushes aren't in `settings.json`.
- **O4** After the tag: `ci-proof/breaking` from `main` (remove `minimumAppVersion` → `contract` fails in breaking), then delete it. Evidence for exit criterion 3 against the real tag.
- **O5** Docs at close: `02` API-client row (swagger_parser), `04` §4.1/§4.2 (D4, D5, D12), `10` §1 (`contracts/` subfolders, `tools/contract-tools/`), `10` §7 (CI as built), README prerequisites, TDs, backlog (§7).

### 5. Test list

| Test | Proves |
|---|---|
| `fb_api_client: no Flutter SDK dependency` · `runtime dependencies within {dio, retrofit, freezed_annotation, json_annotation}` · `lib/ imports no Flutter or dart:io/ui/ffi/isolate/html` | `10` §3 package purity (A15) |
| `union fixture: each kind decodes to its own sealed subtype` | Exit 1, main risk |
| `union fixture: toJson round-trips with nested objects as maps` | Exit 1 (`explicit_to_json`) |
| `union fixture: an unknown future kind decodes to the unrecognized variant` | `04` §4.2 forward compatibility |
| `union fixture: switch over the sealed type is exhaustive` | Sealed union usable in app code |
| `union fixture: a list of intents decodes through a dio call (fake adapter)` | retrofit/dio wiring with unions |
| `union fixture: type-array nullable and oneOf null-wrap both become T?` | D4 on the Dart side |
| `union fixture: LocalDate stays a YYYY-MM-DD string on the wire` | D2 strip works |
| `getConfig calls GET /v1/config without header params and decodes ClientConfig maps` | Exit 1 + D1 `skipped_parameters` |
| `ProblemDetails decodes a problem+json body and ignores extension members` | D5 |
| `GetConfig_returns_200_json_with_contract_shape` (C#: status, `application/json`, exactly the three keys, string/object/object kinds) | Exit 5 (runtime JSON, not only the document) |
| `contract-selftest`: each `contracts/selftest/spectral/*.yaml` fails with its `# expect` code, and the real bundle passes | Exit 4 |
| `contract-selftest`: breaking `field-removed` fails, `additive` passes, `enum-value-added` passes | Exit 3, D12 levels |
| `contract-selftest`: conformance `server-match` passes, `server-renamed` fails with the readable message | Exit 2, D10 levels |
| `contract-bundle-check` / `gen-check` / `contract-conformance` in CI | Exit 2 (stale bundle, stale client, server drift) |

No spec IDs (the card's Spec line is "—"), so the tests carry no traceability tags.

### 6. Exit-criteria mapping

| Exit criterion | Demonstrated by |
|---|---|
| `make gen` bundles + regenerates. The client compiles, and a Dart test decodes the `oneOf` fixture into the right subtype | WP3 done-when (second `make gen` is a no-op) + the `union fixture:` tests in `make test-dart` and CI |
| Contract changed without the server (or the reverse) fails CI with a readable message | Conformance self-test (CI) + WP4 local proofs + **O2** proof branches (`dotnet` job failure, message in the log, URLs in the Outcome). A stale client/bundle fails `gen-check`/`contract-bundle-check` |
| Breaking change fails oasdiff, additive passes | Breaking self-test (CI) + WP2 local proof with `CONTRACT_BASE_REF` + **O4** proof against `contracts-v0.1.0` |
| Spectral fails on `?offset=` and on a non-problem+json error | `contract-selftest` in the `contract` job (fixtures `offset-pagination.yaml`, `error-not-problem-json.yaml`) |
| `GET /v1/config` runs locally and matches the contract | WP4 `dotnet run` + `curl` output + `Contract.Tests` + `contract-conformance` green |

### 7. Risks & unknowns

| Risk | Handling |
|---|---|
| Docker Hub pull limits on GitHub runners (3 images in `contract`, 1 in `dotnet`) | Watch the first runs. Fallback: `docker save` the pinned images into `actions/cache`, keyed on the digests, or mirror them to GHCR (no new vendor). Backlog entry |
| Dependabot `docker-compose` may not bump `tag@sha256` digests (unverified), or may require a standard compose file name | `compose.yaml` is a standard name. Check after the first monthly run. Fallback: manual bump with the quarterly toolchain review. Backlog |
| swagger_parser `schemes:` output into `test/` under build_runner | WP3 spike. Fallback: a separate fixture config file run with `-f` |
| `ProblemType` enum values are URIs, so the Dart enum names may come out ugly (`errorsRateLimited`) | Acceptable. If unusable, keep the catalogue in the `ProblemDetails.type` description only and note it in the Outcome |
| Build-time OpenAPI generation runs on every Host build (slower builds, needs `dotnet` 10 on PATH) | `PATH` export in the Makefile. WP4 measures the overhead. If it's > 10 s, gate generation behind `-p:OpenApiGenerateDocuments=true` in `contract-conformance` only |
| Build-time generation without `MapOpenApi()` in Production | WP4 confirms that `server.json` is produced with Development-only mapping. Fallback: map always, but behind the private-network rule in S03 (security reviewer to confirm) |
| **TD-023 says "breaking change to a published version"**, and tagging v0.1.0 now freezes `/v1` before any app ships | Not solved in S02. Backlog question for the first step that needs a breaking change. **Rec:** an oasdiff `--err-ignore` file reviewed by the architect and cleared at the next tag, allowed only before the first `app-v*` release. That clarifies TD-023, so it needs the owner's OK *then* |
| Contract headers are declared (and `required`) before S03 enforces them | Documented on both sides. S03 adds the middleware **and** the app-side dio interceptor (forward note for the S03 card) |
| Tag integrity (the breaking gate trusts `contracts-v*`) | Backlog: optional tag ruleset (no deletion or update of `contracts-v*`), owner clicks |
| Card conflicts flagged, not changed silently | R5's single `contract` job → D13 split. R3's enum transformer → deferred (D9). The card's `ProblemDetails` "catalogue" → `ProblemType` enum; `ValidationProblem` and other error responses → S03 (D5) |

Backlog items at close: Docker image caching (if limits bite), Dependabot compose verification, enum schema transformer (first enum), the TD-023 pre-release breaking-change policy, the `contracts-v*` tag ruleset, the S03 forward note (header middleware + interceptor, `RespectRequiredConstructorParameters`/`RespectNullableAnnotations` for request DTOs).

### 8. Size check
**M, ~1.5 sessions.** The research already proved the two hard parts (generator on the union, conformance on 17 mutations), so most of the work is assembly. WP3 and WP4 can run in parallel after WP2. The slow part is the CI push-and-poll loop (WP5, O2, O4). If it runs long, split at the natural seam: **S02a** contract, tooling, Dart client and their CI (WP1–WP3, WP5 without conformance), and **S02b** Host endpoint and conformance (WP4, O2). No split is proposed up front.

### 9. Amendments after architect review (2026-10-13, orchestrator-applied, these override the sections above)

| # | Change | Overrides |
|---|---|---|
| A1 | **No contract tag in S02; pre-release policy.** While no `contracts-v*` tag is reachable, `contract-breaking` diffs against `git merge-base HEAD origin/main`, prints the breaking list as a notice + job-summary table, and **passes**. The first tag is **`contracts-v1.0.0`**, created with the first `app-v*` release that calls the API (note on the S29 card and in `10` §7 `mobile-release`); `info.version` → 1.0.0 then. From then on the gate blocks. Exit criterion 3 = permanent fixture self-tests + the WP2 local `CONTRACT_BASE_REF` proof. O3/O4 dropped. Interprets TD-023's "published" (owner FYI). Backlog: drop the "pre-release ignore-file" item; keep the tag-ruleset item for when the tag exists | D12, O3, O4, §6 row 3, §7 TD-023 row |
| A2 | **No `ProblemType` enum.** `ProblemDetails.type` stays a free string; the catalogue (relative `/errors/<kebab-slug>`, opaque string, never dereferenced, never renamed/removed within a version) lives in the `type` description and a table in `contracts/README.md`. `type`/`title`/`status` stay required. Forward notes: S03 golden problem bodies in `contracts/testdata/problems/*.json` used by C# and Dart mapping tests, always set `type`/`title`, runtime test for statuses without a framework default (429); S24 JwtBearer 401/403 must emit problem+json | D5, §3.1 problems.yaml |
| A3 | **D4 additions:** no absent-means-unchanged (merge-patch) semantics; updates are full replacement (`If-Match`) or command POSTs. "Null, never a missing key" is a server emission rule: no `JsonIgnoreCondition.WhenWritingNull` anywhere (backend/README DTO rules) | D4 |
| A4 | **New Spectral rule `fb-oneof-discriminator`:** every `oneOf` except a two-branch `{$ref, type: 'null'}` null-wrap needs `discriminator.propertyName` + `mapping`, and that property is required in every variant. Plus a self-test fixture | §3.2, D7 |
| A5 | **Sequential WPs, WP1+WP2 merged:** WP1+2 (platform) → WP3 (flutter, holds the `schemes:` spike) → WP4 (dotnet) → WP5 (platform). No parallel worktrees (7 GB laptop). Size **M+, ~2 sessions**; S02a/S02b seam kept as the pre-agreed split | §4, §8 |
| A6 | **`/v1/config` in the Host is a temporary exception to `04` §3.** Backlog: move `Host/Config/` into the Account module when it is created (S24/S28), same operationId + tag (conformance proves the move). Forward note S06: config is fetched in the background and cached, never on the startup path; the 426 gate never blocks startup on the network | D11, §3.4 |
| A7 | **Suggestions taken:** don't reference `XRequestId` from any response yet (oasdiff #1094). Dependabot ignores also `json_annotation` and `retrofit`. `fb-idempotency-key` honours `x-fb-idempotency: exempt` (with a reason), decided per endpoint in S24. `minimumAppVersion` gets a semver `pattern` now. Backlog: generic runtime-response-vs-schema validation in Contract.Tests once there are several endpoints | D1, D7, D11, §3.2 |
| A8 | **Forward notes for S03:** header middleware and `ClientHeadersOperationTransformer` derive from one definition (a `/v1` route group with endpoint metadata); `/v1/config` declares the headers even if exempt from the 426 gate. O5 rewrites the `10` §7 `contract` row as distributed (contract job + dart gen-check + dotnet conformance) and drops its path-filter trigger | D10, D13, O5 |
| A9 | **After review (WP-F1):** `fb-oneof-discriminator` also covers `anyOf` and requires one mapping entry per branch; `fb-problem-json-errors` requires `type`/`title`/`status` in the schema (directly or via `allOf`); `fb-client-headers` checks header schemas; new `fb-single-tag` and `fb-idempotency-exempt`; `fb-no-offset-pagination` = offset, page, pageNumber, pageSize, skip, take. `gen-check` looks only at the generated dirs and compares worktree vs index. The `dotnet` job runs conformance before the tests | §3.2, §3.3, D13 |

**Owner items — APPROVED 2026-10-13 ("Ok"):** A1 reading of TD-023 (first contract tag with the first app release), Docker + Compose v2 as a dev prerequisite, the plan as amended.

**TD candidates for recording at close:** API schema conventions (D4+A3, D5+A2; amends `04` §4.2) · contract versioning before release (A1; clarifies TD-023, owner FYI) · Dart client generator swagger_parser (D1) · server conformance via hand-written records + `oasdiff changelog` (D9/D10) · TD-040 addendum: Docker-pinned contract tools, Docker + Compose v2 as a dev prerequisite (D8).

## Progress log
_One dated line per event, newest last (process §8a)._

- 2026-10-12 · A: ready (S01 ✅, no owner prerequisites, main green fde7c5b). Branch created. B: research launched: (1) Dart generator proof on the oneOf fixture, (2) contract tooling install + .NET 10 OpenAPI generation + conformance-diff normalisation.
- 2026-10-12 · B: research (2) done → Docker-digest-pinned Redocly 2.62.1 / Spectral 6.17.0 / oasdiff v1.33.0; hand-written C# DTOs + `oasdiff changelog --fail-on INFO` conformance (17/17 mutations caught); .NET 10 build-time OpenAPI gotchas (Makefile PATH, NumberHandling.Strict, enums, problem responses). Notes in research-notes.md. Waiting on research (1).
- 2026-10-12 · B: research (1) done → swagger_parser 1.45.0 (freezed sealed unions + retrofit/dio, fallback variant for unknown kinds) proven 9/9; pre-gen strip of `format: date`; analyzer-cap pin set (freezed 4.0.1, build_runner 2.16.1). step-planner launched.
- 2026-10-12 · B: low-level plan written (D1–D14, WP1–WP5, O1–O5; no ⚠️ OWNER). Architect review launched.
- 2026-10-13 · B: architect review was cut off by the usage limit (no result); re-launched.
- 2026-10-13 · B: architect: approve with changes; A1–A8 applied. Owner gate: plan summary sent with the TD-023 FYI.
- 2026-10-13 · Owner approved the plan ("Ok"). C: WP1+2 (platform-engineer) launched.
- 2026-10-13 · C: WP1+2 committed (contract tooling, rules, self-tests, contract + bundle); make check green. WP3 (flutter-engineer, fb_api_client) launched.
- 2026-10-13 · C: WP3 committed (fb_api_client, gen/gen-check, 16 tests; deviations: gen-check compares worktree vs index; build_runner flag removed). WP4 (dotnet-engineer) launched.
- 2026-10-13 · C: WP4 committed (Host /v1/config, conformance mandatory; both local drift proofs fail as intended). WP5 (CI wiring) launched.
- 2026-10-13 · C: WP5 committed (d6b5644: contract job, gen-check, conformance; gate needs 3). O1 CI running. O2 proofs pushed: `ci-proof/contract-only` 8cdd91e, `ci-proof/server-only` 4599b8e (local conformance fails with `motd` added). D: code + security review launched.
- 2026-10-13 · O1 ✅ CI green on 157a1f3 (dart, dotnet, contract, ci). O2: contract-only 8cdd91e → dotnet conformance failure with annotation "removed the required property `motd`" (run 38355896980) + dart test failure; server-only 4599b8e → dotnet failure (run 38355908330), but likely from Contract.Tests before conformance runs: fix = conformance before tests + info→error annotations. Proof branches deleted. Security review: approve, 0 blocker/major, minors 1 (read-only repo mount) and 2 (workflow-command injection) to fix. Waiting on code review.
- 2026-10-13 · D: code review: approve, 1 major (pre-release breaking notice misfires on identical specs), 5 minor, 2 nits. Fix WP-F1 (platform-engineer) launched with all code + security findings + the conformance-before-tests CI order.
- 2026-10-13 · D: WP-F1 committed (12 items: exit-code-based pre-release breaking report + self-tests, anyOf/mapping-count union rule, problem+json schema + header schema rules, fb-single-tag, read-only tool mount, stop-commands wrapping, conformance before tests with ::error annotations). Re-proof `ci-proof/server-only` + round-2 reviews + verifier next.
- 2026-10-13 · CI green on e71471b (dart, dotnet, contract, ci). Re-proof server-only 9a9fc75 → dotnet failure with `::error` annotation "added the required property `motd`" (check-run 115162563575) ✅; branch deleted. Close-out docs + TD-043..047 committed (4103a33). Round-2 review + verifier were cut off by the usage limit; re-launched after reset.
- 2026-10-13 · D/E: round-2 review approve (11/11 fixed, 3 nits → backlog #23–25). Verifier PASS 5/5 on 39ab535. Outcome written, board ✅. Merge via `merge/S02` → `main` (TD-039).

## Outcome
_Written 2026-10-13 (Phase E)._

**Built.** `contracts/` (OpenAPI 3.1 source per module + shared components, committed Redocly bundle, README with conventions and the error catalogue). Spectral `fb-*` rules for `04` §4.2 (versioned paths, problem+json with required type/title/status, no offset pagination, client-header schemas, Idempotency-Key with an explicit exemption, camelCase, ID/time/date formats, discriminated unions with complete mappings, one tag per operation) and a self-test suite (24 fixtures) that proves every rule and gate still fires. oasdiff breaking gate (pre-release: reported, not blocking, TD-044) and server conformance (`oasdiff changelog --fail-on INFO`, TD-046). Redocly/Spectral/oasdiff as digest-pinned, offline, read-only Docker images (TD-047). `packages/fb_api_client` generated by swagger_parser (freezed sealed unions with an `unrecognized` fallback, retrofit on dio), `make gen` / `make gen-check` (TD-045). Host `GET /v1/config` from hand-written records, build-time OpenAPI document with ProblemDetails + client-header transformers, `Contract.Tests`. CI: `contract` job, `gen-check` in `dart`, conformance (before tests) in `dotnet`; `ci` gate needs all three.

**Evidence.** Verifier PASS 5/5 on 39ab535 (fresh clone: `make gen` leaves the tree clean; tests pass; breaking proof with `CONTRACT_BASE_REF=HEAD`; `dotnet run` + curl → `{"minimumAppVersion":"0.1.0","featureFlags":{},"thresholds":{}}`). CI green on 39ab535 (dart, dotnet, contract, ci). Proof branches: contract-only (run 38355896980) → dotnet `::error` "removed the required property `motd`"; server-only (check-run 115162563575) → dotnet `::error` "added the required property `motd`". `make trace` R1 319/0/319, 0 warnings.

**Deviations.** No contract tag in S02 (A1/TD-044; the card's "first tag created in this step" is replaced). No `ProblemType` enum (A2). CI checks distributed across three jobs instead of one `contract` workflow (D13). Enum schema transformer deferred (no enum yet). `gen-check` compares worktree vs index; build_runner's removed `--delete-conflicting-outputs` flag dropped. Extra rules beyond the plan: `fb-single-tag`, `fb-idempotency-exempt`, schema checks in `fb-problem-json-errors`/`fb-client-headers`, `anyOf` in `fb-oneof-discriminator` (A9). Tool containers mount the repo read-only (security review).

**Follow-ups.** Backlog #16–#25 (Docker Hub limits, Dependabot compose digests, enum transformer, `contracts-v*` tag ruleset at S29, move `/v1/config` into Account, generic runtime schema validation, log noise, 3 review nits). Forward notes added to the S03, S06, S24 and S29 cards.

**New TDs.** TD-043 API schema conventions · TD-044 contract versioning before release (owner OK) · TD-045 swagger_parser · TD-046 server conformance · TD-047 Docker-pinned contract tools.

**Metrics.** Planned M+ (~2 sessions), actual ~2 sessions including two usage-limit interruptions (both resumed from the Progress log). 4 WPs (WP1+2, WP3, WP4, WP5) + 1 fix WP. 2 review rounds. Findings: code 1 major, 5 minor, 2 nits; security 0 major, 2 minor, 1 info; round 2: 3 nits (backlog). Tests added: 16 Dart (fb_api_client), 1 C# (Contract.Tests), 24 contract self-test fixtures + 2 report-only breaking cases. Lesson: push the progress log *before* code during CI waits (a docs push cancelled a run).
