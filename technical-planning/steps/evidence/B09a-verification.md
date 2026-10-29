# B09a verification: security & privacy (Phase D)

2026-10-29, private development laptop, lane 2, branch `step/B09a-buddy-intents-server` at `07d6b5f`
(review of `git diff origin/main...HEAD`, 35 files; the contract part is already on main, `c8c49ee`).
Reviewer: fresh `security-reviewer` (Opus), read-only except this file. All inputs are synthetic;
no provider key, no paid call (WP7 live smoke is not part of this review).

## Scope

Risky step: AI context, proposals, data sent to the provider. Checked against `CLAUDE.md` rules 1, 2, 6,
card B09 (D3, D6, D9, PA5, PA8, PA13, D15), `06` §3, `09` §4, TD-091, TD-092:

1. What reaches OpenAI (`ProductionProtocol.Input`, repair instruction).
2. Model output can't inject IDs or nutrition (validation, mapping, provenance).
3. The `stated` literal guard (D9/TD-092) and value bounds.
4. Logs, spans, metrics, Sentry, audit and Postgres logs on every path; the new `IdentityPrivacyTests` fact.
5. Replay isolation, context list limits, eval fixture provenance, the 1,600-token cap.

## Commands and results

| Command | Result |
| --- | --- |
| `git fetch origin && git diff --stat origin/main...HEAD` | 35 files, no new packages (no csproj/pubspec package changes) |
| `tools/scripts/heavy.sh dotnet test --project tests/Buddy.Tests -c Release` (from `backend/`) | **201/201 passed** |
| `tools/scripts/heavy.sh dotnet test --project tests/Persistence.Tests -c Release -- --filter-class …BuddyApiTests --filter-class …IdentityPrivacyTests` | **20/20 passed** (incl. `B09_interpret_context_and_intents_leave_no_content_in_logs_and_telemetry`, the list-limit theory, the new-kinds replay test) |
| Scratch probe of a verbatim copy of `ProductionProtocol.Numbers` (not committed) | see §3; every non-ASCII trick fails closed; one benign over-acceptance (`1,2,3` → 123) |
| grep of `tools/buddy_eval/cases/b09.yaml`, `m3.yaml` for emails, keys, owner name, phone numbers | none; 53 cases, all synthetic texts, case-local IDs, file self-describes as synthetic |
| `dotnet build-server shutdown` | done |

Full suites and the eval gate (`BuddyPublicEvalTests`, `check-buddy-eval.py`) run in CI only (testing rule).

## Findings

### 1. Provider egress: pass
- `ProductionProtocol.Input` (`ProductionProtocol.cs:34-50`) is an explicit allowlist: text, now, tz offset,
  Ramadan {active, fajr, maghrib}, slot name/window, personal-food names/aliases/state, memory kind/key/value,
  `recentEntries` {ref, date, slot, name}, `savedMeals`/`openBatches` {ref, name}, custom exercise names,
  `activeCard` {slot, time, lines {name, amount, unitCode, state}} only when present.
- Never forwarded: request/proposal/slot/entry/meal/batch/personal-food IDs, entry grams, personal nutrients
  and servings, `activeProposal`, any principal. Pinned by `Provider_projection_uses_list_indexes_and_never_ids_grams_or_nutrients`
  (root keys, per-list keys, `ref == position`, ID and number canaries absent).
- The only amounts are the user's own active-card line amounts (A22 PA6). No identity anywhere.
- Repair (`ProductionLlmClient.cs:55-57`) appends a fixed sentence with the closed PA13 code only; the first
  output is never passed back. `store:false`, no tools, unchanged.

### 2. Model output can't inject IDs or nutrition: pass
- The v2 grammar (`ParsedMessage.cs`) has no Guid/key field. Every emitted UUID comes from the request:
  `entries[r].Id`, `meals[index].Id`, `OpenBatches[index].Id`, `input.ActiveProposal`, personal `candidate.Id`;
  catalog keys only from `IFoodResolver` (PA5).
- Indexes are range- and uniqueness-checked against the **same** list the resolver dereferences (`Refs`, `ListRef`,
  `ProductionProtocol.cs:168-173`); the empty-list case (any index accepted, PA8) is re-guarded in the resolver
  (`ResolveReferences.cs:56`, `ResolveCreations.cs:179-180`), so no out-of-range dereference.
- Only `ProductionLlmClient` produces a `Success` message, and only after `Parse` → `Validate`; per-kind member
  allowlists reject stray groups (`stated` outside `personalFoodCreate` = `mixedGroups`).
- Model nutrition stays the badged per-100 g estimate on unmatched foods (B08); a memory subject keeps a food only
  with a real match (`ResolveCreations.cs:22-26`). No totals, no writes; everything is a proposal for the app.

### 3. `stated` literal guard: pass with a minor
- Values must be members of the numbers in `input.Text` only (not context); bounds nutrients 0–10,000, servings
  (0, 100,000] (`ProductionProtocol.cs:211-219`). Regex is ASCII `[0-9]`, linear (no ReDoS); text ≤ 1,000 chars.
- Probe: `40g`→40; `2x20`→{2,20} (40 rejected); `1e3`→{1,3}; `-50`→50 (negatives already bounded);
  Arabic-Indic/Persian digits and `٫` normalize; fullwidth, Bengali and superscript digits, the Arabic comma `،`,
  `½`, and European `1.200,5` yield no extra value → output rejected (safe direction); 30-digit tokens overflow to
  nothing; `12.50` = 12.5.
- Minor m2 below: comma stripping concatenates digit lists, and the guard checks membership, not field binding.

### 4. Logs and telemetry: pass
- `LogOutcome`, span tags and the duration metric carry outcome, model, prompt version, the closed
  `invalid` code, timing, token counts and estimated cost only (`ProductionLlmClient.cs:46-51, 74-75`).
- The new privacy fact is sound: 15 EN/AR/Arabizi canaries cover the message, every new context list, the
  active-card line, model-only strings (mention, subject, create name, and the invalid first output) and a stated
  figure; paths 200 with a real `refRange` repair, replay, 409, 400, injected resolver 500 (exception message
  carries the text; Sentry envelope asserted present and scrubbed), 503 and 429; sinks: logs, scopes, spans,
  metrics, Sentry, `identity.audit`, Postgres server logs. It also asserts the closed code **does** appear, so
  the test can't pass vacuously. Gaps are small (m3, m5).

### 5. Replay, limits, fixtures: pass
- Ledger queries are scoped by `user_id` from the JWT under the RLS session and keyed `(user_id, message_id)`;
  the fingerprint covers the whole input (including `activeCard`); a different user can't read or collide.
- Context limits enforced in `InterpretRequest.Validate` before any send; the theory proves at-limit dispatches
  and limit+1 is 400 with zero provider calls for all 8 lists.
- Eval fixtures synthetic (above). CI uploads the synthetic `B09-offline.json` for 7 days; no secrets.

### 6. 1,600-token cap: residual, no partial write
- A truncated response is `status: incomplete` → `LlmStatus.Incomplete`; `Parse` is never called
  (`ProductionLlmClient.cs:34-38`), the interpretation is not saved, the endpoint answers pending 503.
  If a truncated body ever arrived as "completed", JSON fails → `shape` → one repair → Clarify. **Never a
  partial interpretation and never a write** (the server writes nothing; the app confirms).
- It is **not** a Clarify: the same `requestId` stays pending until expiry (24 h), and a resend of the same long
  message will likely truncate again (each costs a quota call). The offline count already shows ~1,780 tokens for
  a ten-intent, nine-item message; reasoning tokens share the cap. UX/cost risk, not a security one (m1).

### Ranked findings

Blockers: none. Majors: none.

- **[minor] m1** `backend/src/Modules/Buddy/Infrastructure/ProductionLlmClient.cs:34` · `Application/InterpretMessage.cs:36`:
  truncation → pending 503 (never a partial write), and the production path has no test for it (only the spike
  `OpenAILlmClient` does). Impact: long multi-intent messages fail as "unavailable" and burn quota on resend.
  Fix: add a `BuddyApiTests` case (`status: incomplete`, `max_output_tokens`) asserting 503, one send, no stored
  response, usage recorded; WP7 records real output tokens; consider a typed Clarify ("too long, split it") for
  `max_output_tokens` in B15 (product call, owner).
- **[minor] m2** `backend/src/Modules/Buddy/Infrastructure/ProductionProtocol.cs:242`: the comma-stripped reading
  turns `1,2,3` into 123, and membership doesn't bind a number to its field (kcal/protein swap, or the `100` of
  "per 100g" as kcal, passes). Impact: a wrong but user-typed-looking figure in a personal-food proposal; bounded,
  `personalFoodCreate` only. Fix: accept the stripped reading only for thousands grouping (`^\d{1,3}(,\d{3})+$`);
  keep A27's D9 handoff (prefill a review form, never one-tap confirm) as the real control.
- **[minor] m3** `backend/tests/Persistence.Tests/IdentityPrivacyTests.cs:304-310`: the repair request body
  isn't pinned. The code is safe by construction, but a test would catch a regression that echoes the invalid
  output to the provider. Fix: capture the wire bodies and assert the second contains
  `Previous output was invalid (refRange)` and not `CANARY-B09-MENTION` (present only in the model's first output).
- **[minor] m4** `technical-planning/06-buddy-ai.md:56`: the "what the provider sees" sentence omits the
  custom-exercise names that are forwarded, and "grams are never forwarded" sits next to card amounts that can be
  in g. Fix: list `customExercises` names; say "entry grams".
- **[minor] m5** same test: custom slot names, custom exercise names and Ramadan times aren't canaried (same
  logging path, low value). Optional.

## Privacy check

Logs / spans / metrics / Sentry / audit / Postgres logs: **pass** (code inspection + the passing privacy fact).
AI context: **pass**, minimal allowlisted projection, list positions instead of IDs, no identity, no grams or
nutrients except the user's own active-card amounts. Repair: code only.

## Residual risks for the owner

- `buddy.attempts.response` keeps the resolved interpretation for 24 h for replay (RLS, erasure, cleanup; B08
  design). It now also holds stated figures, memory values, create names and diary entry IDs, and is in database
  backups for that window.
- Model-written free text (mention, names, memory value, batch name) goes back to the app unvalidated beyond
  length: the app must render it as plain text and confirm every proposal (rule 2). Only self-injection exists today.
- A `scope: all` delete can carry up to 30 targets; the app's confirmation must show all of them.
- OpenAI abuse-monitoring retention (up to 30 days, no ZDR in R1/R2, TQ-06) is unchanged.
- Per-request catalog lookups (10 intents × 30 items) are unchanged from B08; the token cap bounds them in practice.

## Verdict

**Approve with findings** (0 blockers, 0 majors, 5 minors). None needs an owner decision; m1's Clarify mapping is
an optional product follow-up.
