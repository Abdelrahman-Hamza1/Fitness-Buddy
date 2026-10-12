# S02 — API contract pipeline

| Phase | Depends on | Size | Status |
|---|---|---|---|
| P0 Foundations | S01 | M | ⬜ Not started |

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
- [ ] `make gen` bundles the contract and regenerates the Dart client. The client compiles, and a Dart test deserialises the `oneOf` fixture into the right subtype.
- [ ] Changing the contract without the server (or the reverse) fails CI with a readable message.
- [ ] A breaking change (e.g. removing a field) fails oasdiff. An additive change passes.
- [ ] Spectral fails on a test fixture that uses `?offset=` pagination or a non-problem+json error.
- [ ] `GET /v1/config` runs locally (`dotnet run`) and matches the contract.

## Read first
`04-backend.md` §4 · `03-architecture.md` §7 · `10-engineering-practices.md` §7

## Owner involvement
None.

---

## Low-level plan
_Written in Phase B._

## Outcome
_Written in Phase E._
