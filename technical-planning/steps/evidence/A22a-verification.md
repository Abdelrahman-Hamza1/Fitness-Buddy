# A22a verification (2026-10-29)

Tier **Risky** (a new synced user-data table `chat_messages`, migration **v7**, the `chatMessage` op family, the proposal-confirm write path, personal-food names leaving the phone in the interpret context; `PROCESS.md` Part C). Built by Claude (TD-085/TD-095), lane 1, branch `step/A22a-chat-sheet` on `main` `c420081` (A13b).

This file maps the exit criteria and the plan's tests to commits and executed checks (a7, engineer's evidence). The independent `code-reviewer`, `security-reviewer` and `ux-reviewer` sections are added by those reviews; the security review appends its own properties → evidence table, findings and privacy check below.

## Commits

| WP | Commit | What |
|---|---|---|
| a1 | `36ad6e4` | `fb_domain` chat values, `chatMessage` ops, `ChatText` (UTF-16 rules, glados), `ChatLanguage` |
| a1 | `dc706fa` | `chat_messages` table, migration `from_6_to_7` (schema v7), outbox triggers, export spec, op handler, allowlist sync mapper, repository, sync corpus test |
| a2 | `5548dfc`, `5d29eff` | Send path (save-first, D6 failure classes, 45 s Buddy timeout), request builder + corpus (`contracts/testdata/buddy/interpret-requests.json`, TD-093), proposal resolution (D12 contributors, D25 single-flight confirm, one undo), thread controller, privacy canaries; raw-answer decoding |
| B09a handoff | `9ae74ca` | `DayHint` grammar; decoder/engine prefer `dateHint`, fall back to `timeHint == 'yesterday'`; future/unparseable → `unrecognized`; fixed "can't do that in this version yet" reply |
| a3 | `d4eb85a` | DS card shell/skeleton/line/actions/resolved row/highlight, composer, message bubble, counting big number; chat sheet, UTF-16 composer cap, message list, food card, Today input bar → sheet |
| a4 | `b0b182f` | `AssumptionCode` (writer + parser), `core/l10n/assumption_labels.dart` (diary details + card notes), copy guard, card and DS goldens |
| a5 | `89fd86d` | J1–J3 recorded fixtures, host journeys, Patrol journey over an in-app fake transport; Patrol/widget tests reach search through the sheet |
| a6 | `992ec58` | Device round-trip harness `integration_test/buddy_round_trip_test.dart` (manual) + README |
| close | `1305fc0` | Rebase onto A13b: count-up on A13b's Today numbers, shared SF-020 regex, goldens regenerated |
| a2 (backend) | `9a115a9` | `Every_app_interpret_request_vector_binds_and_validates` (server admits every phone-built request) |

## Exit criteria → evidence

| Exit criterion | Status | Evidence |
|---|---|---|
| Journeys J1, J2, J3 pass as Patrol E2E against the local API with recorded AI fixtures | **Met with the D18 deviation** (orchestrator call, owner FYI) | `patrol_test/buddy_journeys_test.dart` `AI-030 AI-032 AI-143 J1 J2 J3 Buddy journeys log through the chat sheet` (real app + sheet, recorded answers served by `patrol_test/support/buddy_fake_api.dart`; runs on `android-it` with `[it]`); host `test/features/buddy/buddy_journeys_test.dart`: `A22 recorded fixtures are contract valid and build without issues`, `AI-030 J1 home-cooked weighed meal asks two questions then logs`, `AI-032 J2 family plate is an estimate with a range then logs`, `AI-143 J3 eating out in Arabic logs with an English reply`; server side: `backend/tests/Buddy.Tests/InterpretRequestVectorTests.cs` `Every_app_interpret_request_vector_binds_and_validates` (5 vectors). The J1–J3 texts against the laptop server are part of the owner's A55 run (below) |
| A follow-up "make it 2 eggs" updates the same card with a highlight | **A22b** | Out of A22a scope (split, D1); A22b b1 |
| Goldens for the card states: loading skeleton, with question, with estimate, after confirm (light/dark, scale 2.0) | **Met** | `apps/mobile/test/features/buddy/presentation/food_card_golden_test.dart` → `goldens/ci/food_card_{loading_skeleton,with_question,with_estimate,after_confirm}.png` (light/dark × 1.0/2.0); DS shell `packages/fb_design_system/test/components/proposal_card_golden_test.dart` → `proposal_card.png` (incl. a before → after sample, UX-026) |
| On the A55 against the laptop server: message → card p90 ≤ 5 s over 20 real messages | **⚠️ OWNER, pending** | Harness ready: `integration_test/buddy_round_trip_test.dart` `A22 message to card p90 on the device` (skips unless `--dart-define=A22_ROUND_TRIP=1`; throw-away profile; prints only `case-n ms`, median, p90). Not run: paid sends need the owner's D19 go-ahead (bundled ≤ $0.25 ask), and B09a's server part deployed on the laptop. Expect p90 near or above 5 s (R4, backlog #83); report honestly, never from host timings |
| The owner logs real meals for 2–3 days and gives feedback | **A22b** (can start after A22a merges) | Owner dogfood |
| `chat_message_sync_vectors_test.dart`: row mapper matches the sync corpus in both directions | **Met** | `apps/mobile/test/features/buddy/data/chat_message_sync_vectors_test.dart` `A22 chat message row mapper matches the sync corpus in both directions` (a1, green after every rebase) |

## Plan tests (§5) → files

| Test | File |
|---|---|
| ★ `A22 chat message migration preserves existing user rows` | `test/drift/user/chat_message_migration_test.dart` (loops over every generated version v1…v6 → v7) |
| `A22 chat message rows capture the outbox and are never hard-deleted` | `test/core/db/sync_triggers_test.dart` |
| `A22 chat message handler rejects invalid wire values without writing`, ★ `A22 assistant message alone stores the shared question budget` | `test/features/buddy/data/chat_message_op_handler_test.dart`, `test/features/buddy/application/send_buddy_message_test.dart` |
| `A22 chat text sanitizer keeps UTF-16 bounds…`, `A22 language tag is normalized…` | `packages/fb_domain/test/chat/` |
| ★ `A22 chatMessage sync omits local attachment paths` | `test/features/buddy/data/chat_message_mappers_test.dart` |
| ★ `A22 message is saved before interpret dispatch`, retry/503/400/409/429, fallback template, fixed templates, unsupported template, contributors in the same transaction | `test/features/buddy/application/send_buddy_message_test.dart` |
| `A22 interpret requests use a 45 second receive timeout` | `test/features/buddy/data/buddy_api_test.dart` |
| `A22 interpret context sends only matched personal foods within bounds`, `A22 interpret request vectors match the builder byte for byte` | `test/features/buddy/data/interpret_request_builder_test.dart`, `interpret_request_vectors_test.dart` |
| `A22 send path never logs message text replies or proposal results` | `test/features/buddy/application/buddy_privacy_test.dart` |
| ★ `A22 confirm use case composes only selected card ops and origin`, concurrent confirm, undo once, log it after undo, AI-036, AI-037, rejected rebuild, sibling preview | `test/features/buddy/application/proposal_resolution_test.dart` |
| `AI-030` skeleton, `UX-011 UX-012` sheet over Today at 320 × 640 and 412 × 915, `UX-023` focus, offline usable, second 503 → composer, 400/429 → search, `UX-003` one tap + haptics + no global snackbar | `test/features/buddy/presentation/buddy_sheet_test.dart` |
| `AI-031`, `AI-032`, `AI-033`, `AI-034` (+ `UX-024` highlight), `AI-035`, log it after undo, 5 s undo window, `AI-037`, ★ `A22 widget preview excludes already confirmed sibling draft lines`, Log it disabled while confirming, text scale 2 at 320 dp | `test/features/buddy/presentation/food_proposal_card_test.dart` |
| `A22 composer caps input at 1000 UTF-16 units` | `test/features/buddy/presentation/utf16_length_formatter_test.dart` |
| `UX-025` count-up | `test/features/today/presentation/today_numbers_count_up_test.dart`, DS `proposal_card_test.dart` |
| `UX-020 UX-021 UX-026` shell part order | `packages/fb_design_system/test/components/proposal_card_test.dart` |
| `AI-001 HM-008 input bar opens the chat sheet` | `test/features/today/presentation/today_screen_test.dart` |
| `A22 assumption codes parse what the engine writes` | `packages/fb_domain/test/proposals/assumption_code_test.dart` |
| ★ `A22 known assumption codes render localized text`, ★ `A22 unknown assumption code or legacy text renders generic assumption` | `test/core/l10n/assumption_labels_test.dart` |
| `A22 reply and card copy has no moral food words` | `test/features/buddy/presentation/buddy_copy_test.dart` (A13b's `sf020MoralWords` + alarm words) |
| `A22 date hint …` (B09a handoff) | `packages/fb_domain/test/proposals/day_hint_test.dart`, `proposal_engine_test.dart` |

## Commands run (engineer, lane 1)

| Command | Result |
|---|---|
| `heavy.sh make check-dart` (after the A13b rebase) | exit 0: format, analyze (`--fatal-infos`), `app-check: OK`, frozen migrations OK |
| `heavy.sh make gen-check` | OK (client, app, drift steps/schemas, l10n) |
| `heavy.sh make db-migrations` | v7 dump + steps + `schema_v7.dart`; v5/v6 unchanged |
| `heavy.sh make goldens` | regenerated; images reviewed |
| `heavy.sh flutter test test/features/buddy test/features/today test/app test/l10n test/core/l10n test/drift test/core/db/sync_triggers_test.dart test/core/export` | green; `today_perf_test` W1 chip-row case missed its budget once under parallel load, then passed alone (4/4) |
| `dart test test/proposals` (fb_domain) | green (incl. glados properties) |
| `heavy.sh` build + `dotnet test --project tests/Buddy.Tests … --filter-class '*InterpretRequestVectorTests*'` | 6/6 passed; `dotnet build-server shutdown` |

Not run locally (close gates): full `make test-dart` / `test-dotnet`, `make build-it` and `android-it` (Patrol; the last commit carries `[it]`), CI.

## Known gaps handed on

- **A23:** the proposal draft codec doesn't carry `dateHint`, so a restored card falls back to the reference day; rows A22 left `queued`/`failed` have no durable request snapshot (never replayed, PA10); durable restore by `budgetMessageId` (D11/R9).
- **A22b:** follow-up (`activeCard`), adjustments, render-timing harness, dogfood.
- **Backlog (D6):** distinct problem types for "in flight" vs "unavailable" 503s.

## Owner-gated item

- **D19 (⚠️ OWNER, not merge-blocking):** the A55 round trip (20 paid sends, part of the bundled ≤ $0.25 ask: A55 sends + 2–3 days of dogfood + ≤ 10 follow-up eval sends). Needs B09a's server part on the laptop server and the dev build on the A55. Record the harness output (`case-n ms`, median, p90) here when run; until then the exit checkbox stays unchecked.

## Review round 1 (2026-10-29)

Code (changes required, 4 majors), security (approve, 1 major), UX (changes required, 3 majors); no blockers. Fixed per the orchestrator's decisions, one commit per group (engineer, lane 1).

| # | Finding | Fix | Commit | Test |
|---|---|---|---|---|
| M1 | `dateHint` unbounded; other-day cards looked like today (security) | `DayHint` → null beyond `DayPager.defaultMaxDays` (3650) back or before 1970 (routed `unrecognized`); header "Thu, Oct 15 · Breakfast · …", "{day} after this", "Logged … for {day}"; loader reads that day's confirmed intake | `81acd8a` | `day_hint_test` (bounds, property), engine routing (`date:1969-12-31`, `daysAgo:3651`), `A22 a card for another day shows the day in its header, preview and logged line` |
| M2 | Raw answer lost on 401 refresh/replay (code) | Buddy clone gets its own `AuthInterceptor.forDio(clone)`, so the replay passes `_RawAnswers` | `a2d323e` | `A22 an answer replayed after a 401 refresh is still read raw` (fails without the fix) |
| M3 | Unexpected throws wedge the thread (code) | `_build` catch-all → fixed template; controller catches around prepare/dispatch (turn `failed(server)`), confirm (card open + couldNotLog), discard, undo; post-confirm sibling refresh can't hide Undo | `060dacb` | `A22 unexpected throws never wedge the thread` (throwing loader config, applier on reply and on Log it) |
| M4 | Round-trip harness timed widget counts (code) | Waits on the thread state (new turn left `sending`) | `266b0cb` | analyzer only (manual device harness) |
| M5 | Card top hidden (UX) | New card → sheet to full height + `Scrollable.ensureVisible` of its top; follow key includes the row count | `0161e16` | `A22 a new card opens the sheet to full height and shows from its top` |
| M6 | Chips lacked context and edit cue (UX) | "Rice: cooked", "Chicken: 150 g", "All/Most oil eaten", "Your share: 50%"; DS chip pencil, own semantics ("Assumption: …", hint "change it"), disabled while confirming; question copy "How was the rice weighed?" / "Which one?" | `6678c05` | `proposal_labels_test` `AI-033 assumption chips name what they are about`, AI-033 card test (semantics, pencil) |
| M7 | Estimate totals unmarked (UX, SF-041/D-045) | `~` on total (+ marker with range/reason), today-after and logged line | `b61383c` | AI-032 card test (`~75 kcal`, `Today after this: ~75 eaten`, `Logged ~75 kcal · ~75 eaten today`) |
| extra | Stale daily totals at confirm (extra reviewer) | Controller refreshes open cards on non-proposal diary change sets (also while the sheet is closed); logged summary from the refreshed session | `91cbfd1` | `A22 a diary change made elsewhere refreshes open cards and the logged summary` |
| FIX NOW | Stopwords in food matching; assumption numbers ≤ 100000; shared `ApiJson` (API role + vector test); testdata README | | `477f7dc` | `A22 joining words never tie a message to a personal food`, malformed-code cases, `InterpretRequestVectorTests` 6/6, Buddy.Tests 220/220, Host.Tests 98/98, Contract.Tests 2/2 |
| FIX NOW | Cards + medical/unsupported keep both sentences; default answer pinned | | `2bdcef8` | `A22 cards with a medical or unsupported part keep both sentences`, `A22 a question lists the assumed (fallback) answer first` |
| FIX NOW | Undo window from `loggedAt`; composer restore on reopen; skeleton label; bubble semantics; empty header; FbIconButton Send; ARB note join; cards-template bubble not drawn; offline/final-503 Search foods; "Logged" fallback; neutral Discarded icon; `copyWith` keeps `undoRefused`; `BuddyInterpreted.json` doc | | `420ef77` | sheet tests (offline, second 503 + reopen), card tests |
| FIX NOW | AI-140 tag on J3; A23 handoff section (codec `dateHint`, PA10, contributor seam, `onFollowUp` rule) | | docs commit | — |

Also fixed: the DS barrel test didn't list the A22 components (missed in a3, would have failed CI) — `6678c05`.

**Deferred to the backlog:** #141 drag handle tap/semantics (A22b), #142 Discard undo (A22b), #143 draft survives close / passed to search (A23), #144 per-message text direction (A22b), #145 header tap target (A22b), #146 vectors through the real endpoint (B09b), #147 owner A55 checks.

**Not done / deliberately:** the optional "Still working…" line after ~8 s on the skeleton (left out: calm placeholder only); offline now offers Search foods rather than Try again (orchestrator decision; Try again stays for timeout/500/first 503).

Local checks for this round: `make check-dart` exit 0 after each group; focused buddy/DS/fb_domain tests green until the owner's new rule (no local test runs; CI decides), `make goldens` once (food card goldens regenerated and reviewed: with question, with estimate); `dotnet build` Release clean.

## Review round 2 (2026-10-29, fix check of `2b1bca4..b374256`)

- **major:** a write that succeeded could look failed when the post-apply refresh threw (card reopened with "couldn't log", no Undo; the user might log twice). Now `ProposalResolution.confirm` keeps the card logged with its Undo once the change set is applied, recomputes it as confirmed without fresh context, and reports `BuddyRefreshFailed` (type only); previews stay stale until the next refresh. Test: `A22 a logged card stays logged with its Undo when the refresh after the write fails`.
- **minor:** the logged row's `loggedAt` is the undo entry's `appliedAt` (carried on `CardLogged`), so the card's Undo window can't outlive the stack's.
- Also since round 1: CI flagged the design-preview gallery missing the A22 components (`b374256`), and the nightly android-it's city-skeleton overflow was fixed (`e9fc523`, reproduced at 320 × 640 with a 250 dp keyboard inset). Round-1 note: the AI-140 rename of the J3 host test is in `420ef77`, not the docs commit.
