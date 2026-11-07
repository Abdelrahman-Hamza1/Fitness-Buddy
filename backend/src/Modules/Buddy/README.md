# Buddy

The agentic Buddy (D-100, `technical-planning/06-buddy-ai.md`, TD-124–TD-128): `POST /v1/buddy/turns` and `/turns/continue` stream a turn; `POST /v1/buddy/label` reads a nutrition-label photo. Everything the module produces is a **proposal** or text; it has no user-data write path (`ConfirmationGuardTests`, AQ-01). The one-shot `POST /v1/buddy/interpret` (B08/B09a) was retired in B26 with its prompts, parser, replay ledger (its `buddy.attempts` table stays, erased and drained by expiry, until backlog #318 drops it once no pre-B26 instance can run), the B02 CLI, `tools/buddy_eval` and the CI eval gates (TD-128); its resolvers and semantic rules live on in the action tools.

## Agent turns (B25)

`POST /v1/buddy/turns` and `/turns/continue` (`technical-planning/06-buddy-ai.md` §2–§7, TD-124–TD-128) are the agentic Buddy.

- **Layers.** `Api/` maps the public bodies (`BuddyTurnRequests.cs`, public records and enums for the validation generator) to Application inputs and writes the stream (`SseTurnWriter`: `id: {turnId}:{round}:{seq}`, one `data:` JSON per event, flush per event, `: ping` heartbeat, `Cache-Control: no-cache`, `X-Accel-Buffering: no`, no buffering). `Application/Agent/` holds the use cases (`RunTurn`), the loop (`BuddyAgent`), tools (`ServerTools`, `ActionTools`, `PhoneTools`, `ToolRunner`), the context projection (`TurnContextBuilder`) and the user-visible text (`ReplyWriter`). `Domain/Agent/` holds the events, phone-tool calls, the QueryPlan, claims, proposal IDs, card arithmetic and the guards (`ReplyGuard`). `Infrastructure/Agent/` holds the ledger, the sealer and the model adapter.
- **Problems before the stream, events after.** 400 (validation, `Idempotency-Key` ≠ `turnId`, `weekly` missing for `mode: weeklyReview` or present for `chat`), 401, 409 (an acknowledged round), 429 (the turn's one message denied), 503 (disabled, no seal key, recovery). After the headers only events: `error invalid` (continuation or results don't match), `error expired` (> 10 min, or a third attempt), `error unavailable|timeout`.
- **Ledger** (`buddy.turns`, `buddy.turn_rounds`; RLS, erasure, 24 h cleanup): content-free counts and states only. A new turn reserves one Usage message (`ReserveMessageAsync`); each physical send reserves one Usage call. A round is completed when its terminal event was flushed, else cancelled; started, cancelled or unacknowledged rounds re-run once as attempt 2; `continue` for round r+1, `ackTurn` or 10 minutes acknowledge. Sends and completion are fenced by attempt (a superseded attempt stops; an in-process fence cancels it at once), and a continuation is void once a newer attempt of its round started. The turn row also holds the disclosed phone rows/bytes (120 / 48 KiB per turn); a round's first continue records a digest of its results, and a retry must repeat them.
- **Continuation**: AES-256-GCM over the workspace (transcript without images, handles, claims, cards, the personal data seen), bound to API version, user, turn and round; valid 10 minutes. The phone holds it; the server keeps nothing between rounds.
- **Budget** (`Buddy:Agent`, authoritative in the ledger): 60 s from the first start (covering model, tool and action work), 10 sends (rewrites and the summary step count), 3 phone rounds, 64k/8k tokens (each send's projected input is checked first), ≤ 6 calls per step, ≤ 8 KiB per tool result. At any limit or quota: a templated wrap-up without a send (`done limit|quota`).
- **Claims and guards**: every number the model may mention is a claim `{id, metric, operation, period, value, unit, label}`; the model writes `{fact:k3}` and code renders value, unit and label. Bare numbers outside the whitelist, unknown claim IDs and moral food words get one rewrite (closed issue codes only), then a template. Declines are templates.
- **Action tools** validate with interpret's former rules (`Domain/ParsedIntentRules`) before resolving; a tool's dependency failure is the closed result `unavailable`, any other failure after the headers ends with `error unavailable`.
- **Deviations from 06** (B25 card, Progress log): server tools run one after another (they share the workspace and the scoped catalog connection); barcode products answer questions but cards resolve by name; `compute` converts amounts with the food's own servings and leaves yields to the phone's engine; question options that fail the guard are dropped (no rewrite).

```json
{ "Buddy": { "Agent": { "SealKeyFile": "/run/secrets/buddy-agent-seal-key", "TraceEnabled": false,
  "RegisteredDailyMessages": 100, "RegisteredDailySends": 400, "GuestDailyMessages": 30, "GuestDailySends": 120 } } }
```

The seal key is base64 of 32 random bytes in a private file (0600, not a symlink). `phone-server.py configure-buddy` creates it once (and upgrades a B08-era overlay on the next `up`), with `TraceEnabled` on for the owner's server. Logs carry a hash of the turn ID, round, attempt, outcome code, send count, tool names, card count and prompt version; spans and metrics carry task, model, prompt version, outcome and tokens; the dev `trace` event goes only to the phone. Live check: `tools/scripts/buddy-agent-smoke.py --live` (paid; scenarios `log`, `phone`, `retry`).

## Breadth (B26)

- **Workouts** (WO-030–033): `exercise_search` over Catalog's exercise library (`IExerciseLibrary`, cached ten minutes; the library is also appended to the static system prompt for caching); `propose_workout` takes a library code or an `x` handle, and per exercise the user's literal set notation, which code parses (`Domain/Agent/SetNotation`: `3x8 80`, `80x8x3`, `8,8,7 @80`, `80x8, 85x6`, `+10 3x8`, `3 sets of 8 at 80`, a load alone, cardio). Parsed notation wins over the model's sets (assumption chip); without notation every set number must be in the message. `copyFrom` copies a session seen through `read_workouts`. Dumbbell loads default to per dumbbell.
- **Body and imports**: `propose_measurement` (built-in kinds, unit checked, value literal) and `propose_import` (each row's original text a literal piece of the message, its value and unit inside it).
- **Suggestions**: `check_fit` (resolved options vs today's remaining claims) and halal (`Domain/Agent/HalalCheck`, the app's keyword lists on names): flags in `search_foods`, halal-only `suggest_foods`.
- **Label read** (`ExtractLabel`, `ChatClientLabelReader`, prompt `label-v1`): one structured vision call, one allowance message + one send reserved together (429 before any call), no Idempotency-Key (a read changes nothing; a retry is a new read). `LabelRules` converts kJ → kcal, salt → sodium and g ↔ mg and drops impossible values; the app's review screen runs FD-012. Log line: outcome, found, prompt, timing, tokens.
- **Weekly review** (`mode: weeklyReview` + `weekly`): aggregates only reach the model; a code-made header (intake vs target, protein days, trend, workouts and PRs, the phone's check-in) plus at most two guarded observations; no tools.
- **Ramadan**: the context carries `fastingNow` (from `now`, `fajr`, `maghrib`); suhoor/iftar wording lives in `agent-v1`.

## Intents and resolution (B09a)

The action tools resolve parsed intents with three resolvers:
- `ResolveFoods`: B08's personal → catalog → badged-estimate food resolution, unchanged. It serves foodLog items, diary-edit replacements, batch ingredients, personal-food components and memory subject foods (memory keeps a real match only).
- `ResolveReferences`: diaryEdit, diaryDelete, ambiguousReference, diaryCopy, savedMealLog and savedMealCreate.
- `ResolveCreations`: memoryChange, batch, batchPortion, batchClose and personalFoodCreate.

The model links mentions to list positions. The server maps them to request IDs and **decides ambiguity** (TD-091), in this order:
1. no link: `targets: []` when the reference has a date or slot hint (the app looks it up locally), otherwise clarify `referenceNotFound`;
2. scope all, or one link: those entries are the targets;
3. several links with a date/slot qualifier: `ambiguousReference` carrying the operation and the patch;
4. several unqualified links: the newest (date, slot) group, which is the target when it has one entry and otherwise asks.

`ambiguousReference` never comes from the model. A copy without a source slot and an ambiguous save are clarify `unclear`. An unmatched food without an estimate turns its whole intent into clarify `unmatchedFood`. Stated personal-food figures are emitted exactly as validated against the message (TD-092) and never filled or computed. Day hints use the closed grammar `today | yesterday | daysAgo:N | lastWeekday:… | date:[YYYY-]MM-DD`, which the app resolves locally. **Every UUID in a response comes from the request context** (recentEntries, savedMeals, openBatches, personalFoods, activeProposal). (PA5).

## Configuration

Buddy is disabled by default and loads no key until explicitly enabled (`Buddy:Enabled`, `Buddy:ApiKeyFile`); the agent's limits are `Buddy:Agent` above. For the private phone server, `python3 tools/scripts/phone-server.py configure-buddy` prepares an API-only read-only mount of the owner's external key and the seal key; it takes effect on the next CI-verified deployment. The key file must be private, absolute and not a symlink; never in app settings, argv or logs. The fixed OpenAI transport doesn't follow redirects. `store:false` does not claim provider zero retention.

## Verification

TD-128: no Buddy test suite and no eval gate. CI keeps `ConfirmationGuardTests` (Architecture.Tests), the no-content canaries `IdentityPrivacyTests.B25_agent_turns_…` and `B26_label_read_…`, conformance and the layer rules. Live checks: `tools/scripts/buddy-agent-smoke.py --live` (paid, owner's key).
