# contracts/

The API contract between the app and the backend (TD-023, `technical-planning/04-backend.md` §4). It is written first, and both sides follow it: the Dart client is generated from it, and CI checks the server against it. **When they disagree, the contract wins.**

| Path | What it is |
|---|---|
| `openapi/` | **The source.** OpenAPI 3.1: `openapi.yaml` (root: info, tags, the list of paths, shared components), `components/` (shared types, headers, pagination, problems), `modules/` (one file per backend module with its paths and schemas). |
| `openapi.yaml` | **Generated** bundle of `openapi/` (`make gen-contract`). Committed so that reviews, the Dart generator and the checks all read one file. Never edit it by hand. |
| `redocly.yaml` | Redocly CLI config: bundling only, telemetry off. |
| `spectral.yaml`, `spectral-functions/` | The style guide as lint rules (Spectral), with two small custom functions. |
| `oasdiff/` | Severity overrides for the breaking-change gate (`breaking-levels.txt`) and the server conformance check (`conformance-levels.txt`). |
| `selftest/` | Fixtures that prove the checks still catch what they must (`make contract-selftest`). |
| `catalog/` | JSON Schemas and the format of the food catalog release (A05, TD-072): the load files B07 imports. See [catalog/README.md](catalog/README.md). |
| `testdata/` | Golden files shared by the Dart and C# test suites ([README](testdata/README.md)). |

The tools (Redocly, Spectral, oasdiff) run as Docker images pinned by digest, offline, through `make` (`tools/contract-tools/compose.yaml`). They see the repository read-only; their only writable folder is `build/contract/`. You need Docker Engine and Compose v2 (root README, Prerequisites); `make doctor` checks them.

## How to change the API

1. **Edit the source** in `openapi/`: the module file for paths and module schemas (`modules/<module>.yaml`), `components/` for shared pieces. A new path also needs a line under `paths:` in `openapi/openapi.yaml`, and a module's first operation needs its tag there too.
2. **Run `make gen`.** It bundles `openapi/` into `openapi.yaml` and regenerates the Dart client (`packages/fb_api_client`, generated code committed; CI fails if it is stale).
3. **Run `make check-contract`.** It checks that the bundle is fresh, lints it, runs the self-tests, reports breaking changes, and compares the server with the contract.
4. **Change the server** (`backend/`) until `make contract-conformance` passes, and the app code that uses the client.
5. **Commit the source, the bundle and the generated client together.** CI fails if the bundle or the client is stale, or if the server differs from the contract.

| Target | Does |
|---|---|
| `make gen-contract` | Bundle `openapi/` into `openapi.yaml` |
| `make contract-bundle-check` | Fail if `openapi.yaml` is not the current bundle (`contracts/openapi.yaml is stale: run 'make gen' and commit.`) |
| `make contract-lint` | Spectral on the bundle, warnings fail |
| `make contract-selftest` | Every Spectral fixture fails with its rule, the breaking and conformance checks behave as expected |
| `make contract-breaking` | Breaking changes compared with the last `contracts-v*` tag (see below) |
| `make contract-conformance` | Builds the Host, then the server's build-time OpenAPI document must match the contract (`SERVER_DOC=<file>` to point elsewhere) |
| `make check-contract` | All of the above (part of `make check`) |
| `make contract-tools` | Pull the tool images (part of `make setup`) |

## Conventions

The full style guide is `04-backend.md` §4.2. These are the rules the contract is written to; most are checked by Spectral (rule names in brackets).

**Paths and operations.** Every path starts with `/v<major>/` (or `/health/`, `/.well-known/`) [`fb-path-versioned`]. Every operation has a camelCase `operationId` (it becomes the Dart method name) and exactly one tag, its module's (it becomes the Dart client class) [`operation-operationId`, `fb-operation-id-camel-case`, `operation-tag-defined`, `fb-single-tag`]. Today's tags: `Account`. Later: `Identity`, `Sync`, `Buddy`, `Catalog`, `Usage`.

**Headers.** Every `/v1/` operation lists the client headers `X-App-Version` (string), `X-Platform` (string, enum `android`, `ios`) and `X-Device-Id` (string, format `uuid`) as required header parameters with exactly those schemas (`$ref` them from `components/headers.yaml`) [`fb-client-headers`]. The API client sets them, so they don't appear as Dart method parameters. Every POST lists a required `Idempotency-Key` [`fb-idempotency-key`]. Every response carries `X-Request-Id` (declared on each response, `components/headers.yaml`): the request's W3C trace id, 32 lowercase hex. It is response-only; an inbound `X-Request-Id` is ignored, and inbound correlation is the W3C `traceparent` header. A POST that is safe to repeat without it can be marked `x-fb-idempotency: exempt` with an `x-fb-idempotency-reason` [`fb-idempotency-exempt`]; that is decided per endpoint and reviewed.

**Names and formats.** Property and query/path parameter names are camelCase [`fb-camel-case-properties`, `fb-camel-case-params`]. IDs (`id`, `<x>Id`) are UUIDs, `$ref: Id` [`fb-id-format`]; the one exception is `ProblemDetails.traceId`, the W3C trace id (32 hex). Instants (`<x>At`, `<x>AtUtc`) are RFC 3339 UTC date-times, `$ref: Instant`, with a `TzOffsetMin` where the local time matters [`fb-instant-format`]. Local days (`date`, `<x>Date`) are `YYYY-MM-DD`, `$ref: LocalDate` [`fb-local-date-format`]. Identifiers that are not our UUIDs (a barcode, a provider's subject) must not be named `…Id` (use `barcode`, `subject`, …). Quantities use the canonical units in `components/types.yaml` (g, ml, kcal, kg, cm).

**Required and nullable (S02 D4, A3).** Every property is listed in `required`. A value that can be absent is nullable, `type: [T, 'null']`, and is sent as JSON `null`, never as a missing key. The server never omits null members. Exceptions:
- `ProblemDetails` members `detail`, `instance` and `traceId` are optional (RFC 9457; the server always sends `traceId`, but clients must not depend on it).
- A **request** property added to an already published version is optional, with a server-side default (so older apps that don't send it keep working).

There are no "absent means unchanged" (merge-patch) semantics. An update is a full replacement (with `If-Match`) or a command POST.

**Unions.** A `oneOf` or `anyOf` needs a `discriminator` with `propertyName` and a `mapping` with one entry per variant, and every variant lists that property in `required` [`fb-oneof-discriminator`]. The only exception is a two-branch null-wrap (`oneOf: [{$ref: …}, {type: 'null'}]`, same for `anyOf`). A nullable union is a null-wrap around a `$ref` to the discriminated union, never a `{type: 'null'}` variant inside it. The Dart client turns a discriminated union into a sealed class with an `…Unrecognized` fallback variant for kinds it doesn't know yet.

**Pagination.** Cursor-based only: `cursor` and `limit` in (`components/pagination.yaml`), `nextCursor` out (`null` on the last page). Never `offset`, `page`, `pageNumber`, `pageSize`, `skip` or `take` [`fb-no-offset-pagination`].

**Errors.** Every 4XX/5XX/default response has a body whose only media type is `application/problem+json`, with the `ProblemDetails` schema (RFC 9457) or an `allOf` extension of it; the schema requires `type`, `title` and `status` [`fb-problem-json-errors`]. They are always present. Unknown members are extensions and clients ignore them.

- **`traceId`** is on every problem the server writes: the same value as the `X-Request-Id` response header. It finds the server's trace and log lines for the request; the app shows it (or logs it) for bug reports.
- **400 has one shape:** `ValidationFailed` (`ValidationProblemDetails`, a flat copy of the `ProblemDetails` members plus a required `errors` map). Keys are camelCase JSON paths (`items[0].qty`) or lowercase header names (`x-app-version`).
- **429** (`RateLimited`) comes with `Retry-After` (seconds), `RateLimit` and `RateLimit-Policy` (draft-ietf-httpapi-ratelimit-headers-11). These headers are sent on 429 only, not on successful responses.
- **426** (`UpgradeRequired`) is answered by every `/v1` operation except `getConfig`, which an outdated app needs to learn `minimumAppVersion`.

**Forward compatibility.** Clients ignore unknown fields, map unknown enum values to the generator's `$unknown` enum member (swagger_parser `unknown_enum_value`), and unknown union kinds to the `…Unrecognized` variant (`fallback_union: unrecognized`). So adding a response field, an enum value or a union variant is not breaking (`oasdiff/breaking-levels.txt`).

### Error type catalogue

`ProblemDetails.type` identifies the kind of problem. Ours are relative URI references `/errors/<kebab-slug>`. The app compares the string exactly and never dereferences it. An entry is never renamed or removed within an API version; adding one is fine. Problems we don't map (for example a framework 404) carry the framework's default `type` (an RFC link or `about:blank`), which is why `type` is a free string and not an enum.

| `type` | Status | When | Added |
|---|---|---|---|
| `/errors/unauthorized` | 401 | Invalid credentials or inactive session. |
| `/errors/forbidden` | 403 | The account cannot perform this operation. |
| `/errors/identity-conflict` | 409 | The verified identity belongs to another account; linking transfers no data. |
| `/errors/validation-failed` | 400 | The request is invalid: a field, or a missing/invalid client header. Carries an `errors` map (field → messages). Also when the request can't be read (malformed JSON, wrong type, missing member): then `errors` is empty. | S03 |
| `/errors/rate-limited` | 429 | Too many requests. Comes with `Retry-After`, `RateLimit` and `RateLimit-Policy`. | S03 |
| `/errors/version-conflict` | 412 | The resource changed since it was read (`If-Match` mismatch). 412, confirmed in S03. | S03 |
| `/errors/upgrade-required` | 426 | The app is older than `ClientConfig.minimumAppVersion`. | S03 |

Every type has a golden body in `testdata/problems/<slug>.json` (exactly what the server sends), checked by the C# pipeline tests and the Dart `Failure` mapping tests. Adding a type means a row here, a golden file and a `ProblemTypes` constant on both sides.

## Breaking changes

`make contract-breaking` compares `openapi.yaml` with an older version using `oasdiff breaking`. "Breaking" means it would break an app that is already installed: a removed endpoint or response field, a new required request field, a changed type, a narrower pattern, and so on. WARN-level findings fail too. oasdiff's exit code decides (`--fail-on WARN`); its wording is never parsed.

**Before the first app release (now).** No `contracts-v*` tag exists, so the gate compares with the merge-base with `origin/main` (on `main` itself: the previous commit), **reports** the breaking changes (log, GitHub notice, job-summary table) and **passes**. Nobody runs an old app yet, so `/v1` can still change (S02 A1, the owner's reading of TD-023's "published version").

**From the first app release on.** The first tag, `contracts-v1.0.0`, is created together with the first `app-v*` release that calls the API (A43), and `info.version` becomes `1.0.0`. From then on the gate compares with the newest `contracts-v*` tag and **fails** on any breaking change. Within `/v1` only additive changes are allowed: add a field instead of renaming one, or put the new shape under `/v2` next to `/v1` until old apps age out (`04` §8). The `426` minimum-version gate is the kill switch.

To check against a specific version at any time (it then blocks): `CONTRACT_BASE_REF=<git ref> make contract-breaking`.

## Server conformance

The server writes its own OpenAPI document at build time (`backend/artifacts/openapi/server.json`, gitignored). `make contract-conformance` runs `oasdiff changelog <contract> <server doc> --fail-on INFO`: any API difference fails (paths, parameters, status codes, media types, fields, types, formats, required/nullable, operationId, tags). Documentation differences (descriptions, examples, servers, ordering, component names, `$ref` vs inline) don't. The failure message reads from the contract's side: "removed" = the contract has it and the server doesn't.

## personalFood semantic rules

The `personalFood` v1 payload in `openapi/sync-entities.json` carries the types, enums, top-level numeric bounds and string length limits supported by the sync schema exporter. The shared semantic rules are in [A09 §3.0: Shared personalFood rules](../technical-planning/steps/A09-personal-foods-quick-add.md#3-design): trimmed minimum lengths, JSON list contents and limits, GTIN check digits, nutrient extras, serving units and amounts, and the entry-serving both-or-neither rule. A09a implements the app validation; B17 adds server semantic validation before A34 enables uploads.

Adding a `NutrientKey`, serving unit or `FoodState` code is a contract change: the server validator and shared corpus ship first, before any app emits the code (or it goes in a new `schemaVersion`); the app never emits unknown codes.

## chatMessage and proposal admission

`chatMessage` v1 and `proposal` v1 (B18) get **envelope-only admission**: everything the server checks is in `openapi/sync-entities.json`, and there is no entity-specific validator. Fields, types, nullability, closed vocabularies and bounds are in the schema; the design is the [B18 card](../technical-planning/steps/B18-chat-proposal-sync.md#low-level-plan) (D1–D8).

- **Generic rules (every entity):** each field present with its type (no missing or extra members), string `maxLength` in UTF-16 code units (a supplementary character counts 2), integer ranges (a whole-number `1.0` counts as an integer), `uuid` as lowercase canonical text, and the representability pass over the payload and every nested `...Json` string: well-formed JSON, depth ≤ 24, ≤ 128 members per object, ≤ 500 items per array, strings ≤ 32768 and keys ≤ 256 units, unique keys, exactly decimal-representable numbers, no U+0000 and **well-formed UTF-16 (existing)**: an unpaired surrogate anywhere, including inside a nested `...Json` string or key, is `invalidPayload`. Every failure is a bare `invalidPayload` that never echoes the value.
- **Closed envelope codes:** `chatMessage.role` (`user`, `assistant`), `chatMessage.status` (`queued`, `pending_offline`, `processing`, `done`, `failed`), `proposal.status` (`pending`, `confirmed`, `discarded`, `superseded`) and `proposal.outcome` (`unchanged`, `adjusted`, `discarded`, or `null` before resolution). A new code is server-first (TD-080): it ships in the contract and the server before any app emits it. `proposal.kind` (≤ 32) and `chatMessage.language` (≤ 16) are open bounded strings. The Dart copies are in `packages/fb_domain/lib/src/proposals/proposal_sync_codes.dart`, pinned to this file by a test.
- **Opaque engine JSON:** `budgetJson` (the shared question budget, only on the assistant row; `null` on user rows: app convention; the server checks no field pairing within a row, D6), `interpretationJson` and `draftJson` are bounded JSON strings of at most 32768 UTF-16 units, with any JSON root. The server never checks engine keys, versions, dimensions, nutrients or question IDs; A21's `ProposalDraftCodec.restore` diagnoses them on the phone. Their content evolves by the app-owned `codecVersion` (integer 1…2147483647; restore rejects versions it doesn't know), so **TD-080's server-first rule for inner vocabularies does not apply to them**. The codec's output must still satisfy the generic nested limits above.
- **Null references:** `originMessageId`, `budgetMessageId` and `interpretationJson` are `null` only on proposals not created from chat (AI-056 target change, DY-004, WO-022) (app convention; the server checks no field pairing within a row, D6). `draftJson` and `codecVersion` are always required on `proposal`.
- **Tombstones carry a scrubbed, still-valid payload** (app convention; the server applies the same admission to tombstones and checks no scrubbing): `chatMessage` sends `text: ""` and `budgetJson: null`; `proposal` keeps `codecVersion` and sends `draftJson: "{}"` and `interpretationJson: null`. Displaced versions can still hold content in history for up to 30 days.
- **Attachments are excluded:** `chatMessage` has no attachment field, and `additionalProperties: false` rejects one. Images and local paths never sync.
- **No cross-row validation:** a row is admitted on its own. The server never loads the referenced message or sibling cards and never compares top-level fields with copies inside `draftJson`; a missing or inconsistent row surfaces as `sessionIncomplete` / `budgetConflict` in restore.
- **Byte budget:** the largest valid `proposal` row (both JSON fields at 32768 units of non-ASCII BMP text) is about 197 KB as UTF-8 with non-ASCII unescaped, which fits the 256 KiB push cap. The uploader (A34) must send unescaped UTF-8 (Dart `jsonEncode`'s default), never `\u`-escaped non-ASCII, and should read integers as `num` → `int`.
- **Corpus:** the shared vectors (`testdata/sync/chat-proposal-validation-vectors.json`, B18 WP2) are generated from the Dart codes and real codec output and pin both sides.
