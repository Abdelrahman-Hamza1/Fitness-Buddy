# A68 — Buddy answers, suggestions, weekly review & Ramadan (app)

| Track | Depends on | Size | Owner | Status |
|---|---|---|---|---|
| App | A66, **B25**, **B26** (weeklyReview, check_fit) | M–L | Claude (Opus build), Codex review | ✅ |

**Goal.** Buddy answers questions about your data with code-computed numbers, suggests food that fits, writes the weekly review, and speaks Ramadan: spec 10 §10–§12 (AI-110–AI-132), halal (D-064, FD-081/082), the Buddy parts of Ramadan. Replaces A31, A39b and A41b.

## Scope
1. **QueryEngine** in `fb_domain` over the closed QueryPlan grammar (`06` §6) and the `query_data` phone tool; answer links to charts and diary days (AI-112).
2. **Suggestions:** `suggestion` cards (2–4 options, each tap → a food card, AI-121), the app's fit check drops options that don't fit, halal warning check.
3. **Weekly review:** at the week start (D-070) a `weeklyReview` turn with the `WeeklySummary` aggregates; the review card, cached per week, past reviews in the weekly summary (AI-130–132); the attached check-in proposal.
4. **Ramadan:** Ramadan state in the profile; suhoor/iftar wording checked on the A55 on a Ramadan-mode day.
5. **Tests (TD-128):** the confirmation guard for suggestion taps; the QueryEngine is code, so it gets its own small tests where a number could be wrong (AQ-09).

## Exit criteria
1. On the A55: "how much protein left", "avg calories last week", "when did I last do legs" answer with correct numbers and a link; "what can I eat with 600 kcal left" gives fitting options; a weekly review appears and reads in under 30 s.
2. CI green; Codex review passed.

## Lane
Lane 1 (after B26) or lane 2, whichever frees first; touches `fb_domain` and different cards than A67/A69.

## Low-level plan

_Written 2026-11-07 by the A68 engineer (Opus) against `main` at `694d8030` (B25 + A66 + B26). Tier **Risky** (AI proposals reach the card path; data leaves the phone through `query_data`). One engineer, WP1–WP5, one local commit each. A67 runs in parallel on the record cards: A68 stays out of `records/`, adds no drift migration and keeps its edits to shared buddy files (controller, thread state, message list, restorer, phone tools, context reader) to small additive hooks._

| # | Decision | Why |
|---|---|---|
| D1 | **QueryEngine** (`fb_domain/lib/src/insights/query_engine.dart` + `query_plan.dart`): a pure mirror of the frozen grammar (`QueryPlan`, `QueryPeriod`, `QueryFilters`), `QueryEngine.supports` (the valid combinations of `06` §6.3, nothing else), `QueryEngine.window` (period → inclusive dates, never after today, ≤ 400 days, `since` anchors passed in) and `QueryEngine.answer(plan, window, data)` → `QueryAnswer {claims, coverage, link}`. Claims carry canonical units (kcal, g, kg, cm, percent, count, date), rounded by code (kcal whole, g/kg/cm/percent 0.1). | AQ-09, AI-111 |
| D2 | **Semantics** (where 06 is silent): nutrient days come from the Progress series (`ProgressDay`, the same numbers as the charts, G10). `remaining` = today's target − today's intake (no target → no claim). `total` sums every day with intake in the window (today included); `average`/`max`/`min` use counted days (logged/estimated, not today, not incomplete; `completeDaysOnly:false` → every day with intake) and, for a macro, only days where it is fully known. `weight` = day weights (latest; change = last − first); `weightTrend` = the trend (latest at the window end; change = end − the day before the window, as the weekly summary). `measurement` like weight over the type's values. `workouts`/`sets` count sessions/sets; `sets`/`volume` total over the window, average/max/min per session; volume = Σ kg × reps of weight × reps sets. `exerciseLastDate last` = the latest session with the exercise, or an exercise whose primary muscle is in the group ("legs"). `exercisePr latest` = the heaviest weight in the window; change = that − the best before the window. `weighIns` = days with a weigh-in, `loggedDays` = days with intake. `weekdays` filters days/sessions; `slot` filters nutrients to that slot (resolved on the phone by ID or name; unknown slot → unsupportedPlan). No data → no claim (the model says it can't tell). | simplest sound option, consistent with the summary |
| D3 | **Links (AI-112):** the engine picks the target: one day → `diary` (date), nutrients over days → `progress`, weight → `weightGraph`, `last` → `workout` (session), PR → `exercise`. The phone keeps each answered `queryData` link of the turn (the server never echoes it), shows ≤ 2 as chips under the reply ("Open diary", …) and stores them in the reply row's local `answer_json` (`links`), restored like the question chips. Diary → Today on that date. | the link is the phone's own result |
| D4 | **Wiring:** `QueryDataReads` (`buddy/application/query/`) reads only what the plan needs through other features' barrels (`progressDaysProvider`, weight trend and weigh-ins, measurements, sessions + exercise library, Ramadan calendar for `ramadanStart`, the goal phase for `phaseStart`; slot rows through `BuddyPhoneReads.diary`). `PhoneTools` takes it as a port (`QueryAnswers`); the mapping generated ⇄ domain lives in `data/query_plan_codec.dart`. `buddyPhoneToolsProvider` (application) composes them; the controller uses it. One result = 1 disclosed row (aggregates only). No new SQL (existing reads), so the query-plan audit is unchanged. | layers; no new reads |
| D5 | **Suggestions (AI-120/121, FD-082):** a `suggestion` proposal never becomes a card. On arrival each option is built as a `foodLog` intent (same items, the option's `slotHint`) into a **preview** card (ProposalEngine, nothing written); the app drops options whose preview takes today over target by more than 5 % (`SuggestionFit`, fb_domain; unknown target → kept) and, with halal on, options whose foods `HalalCheck` flags pork or alcohol (unknown source → kept with the warning line). The kept options (≤ 4) show as a suggestion card under the reply: label, code-computed kcal and protein; "None of these fit what's left today" when all were dropped. **Tap → `AgentCardWriter.create`** (a holder row + pending proposal, no checkpoint after the turn) → the normal food card; only its Confirm logs. Options are kept in the reply's local `answer_json` (`suggestion`), restored with the turn; a picked option shows as picked in this session. | spec 10 §11; one write path |
| D6 | **Weekly review (AI-130–132):** `WeeklyReviewService` runs a `mode: weeklyReview` turn through the existing `BuddyTurnRunner` with an in-memory host (no phone tools, no cards, text only, the one retry rule kept): start body = the chat start body with `history []`, `personal []`, no compaction/summary, a fixed English message, and `weekly` = `WeeklySummary` → `BuddyWeeklySummary` (+ `checkIn {fromKcal, toKcal}` when this week's check-in card is pending). The text is cached **per week in a per-week setting** (`buddy.weeklyReview.<weekStart>`, JSON `{text, at}` ≤ 32 KiB, synced like settings, `Origin.system`): no drift migration. The weekly summary screen shows a **review card on top** (IN-001): cached → the text; the just-finished week without one → written once when the screen opens (local tiles never wait; a failure shows Try again); older weeks show only what was cached. The existing check-in card stays below (the attached proposal, AI-130). | no migration (A67 owns v18); IN-001, NT-004 open it |
| D7 | **Ramadan (RM, B26 D12):** the start request's `profile.ramadan` = `{active: fasting day today, fajr, maghrib}` ("HH:mm" device-local from the chosen city's prayer times) and the snapshot's slots follow today's slot mode (suhoor/iftar slots on a fasting day, normal otherwise). Computed in the controller from the Ramadan feature's providers and passed to the context reader. | suhoor/iftar wording needs the slots |
| D8 | **Tests (TD-128):** `buddy_suggestion_guard_test.dart`: a streamed `suggestion` writes no proposal and no diary op; a tap writes one pending card and no diary op; only its Confirm logs (once). `query_engine_test.dart`: the numbers that could be wrong (remaining, averages over counted days, macro coverage, trend change, last legs day, PR change, windows/limits, unsupported combinations), enough to keep the fb_domain 95 % gate. No UI tests (lean testing). | AQ-01, AQ-09 |

**Work packages:** WP1 QueryEngine (fb_domain + tests) · WP2 `query_data` tool, links in the reply · WP3 suggestions (+ guard test) · WP4 weekly review · WP5 Ramadan profile + docs. Exit 1 (A55 device checks) stays the owner's.

**Server assumptions (B25/B26 as merged):** the server forwards the plan with exercise handles swapped for local refs (`exerciseRef` = library ID or custom exercise ID); a claim's `value` may be null only with `date` (op `last`); `weeklyReview` accepts the chat start body with empty history/personal; text events carry the guarded review.

## Progress log

- 2026-11-07 · plan written (Opus engineer, lane 2) against 694d8030.
- 2026-11-07 · WP1 `87a68bab`: QueryEngine, QueryPlan model, windows, SuggestionFit (fb_domain, 21 tests, the new files fully covered).
- 2026-11-07 · WP2: `queryData` tool (codec, `BuddyQueryAnswers` over the features' providers, kept alive while read), links in the reply (chips, stored in the reply's local `answer_json`), `RamadanCalendar.lastStartBy`; `buddy_query_tool_test`.
- 2026-11-07 · WP3: suggestions (preview build per option, fit + halal drop, suggestion card, tap → pending card via `AgentCardWriter.create` without a checkpoint, kept in the reply's local `answer_json`); `buddy_suggestion_guard_test`.
- 2026-11-07 · WP4: weekly review (`WeeklyReviewWriter` runs a `weeklyReview` turn through the runner with an in-memory host; text cached per week in the synced setting `buddy.weeklyReview.d<yyyymmdd>`, export names 2026–2035; `WeeklyReviewCard` on top of the weekly summary, written once for the just-finished week, Try again on failure; pending check-in passed as `checkIn`).
- 2026-11-07 · rebased onto main edd65af3 (A67 merged; conflicts in controller/state/list/phone tools resolved additively, codegen rerun), fixups `8da8c9fc`.
- 2026-11-07 · WP5: Ramadan in the turn (`turnRamadan`: fasting day, fajr/maghrib "HH:mm" device-local, today's slot mode → suhoor/iftar slots in the snapshot), also for the weekly review.

- 2026-11-07 · local checks: `make check-dart` ✓, fb_domain suite ✓ (coverage 95.3 %), focused app tests (buddy, progress, settings, export, workouts, today, app, query-plan audit with TZ=UTC, unit display) ✓. Outcome drafted; Codex review next.
- 2026-11-07 · Codex review: changes required, no blockers, no suggestion bypass (3 majors, 2 minors). Fixed: `8d9d0ba9` (done reason through `TurnEnd`, cache only `answered`; writer kept per profile session, reset and runner stopped on a profile switch, one attempt per week unless Try again; settings write must be `Applied`, throws → failed), `140a55ef` (partly known macros marked through coverage; `weightTrend` + weekdays → unsupportedPlan). Tests: `weekly_review_writer_test`, two engine cases. Card closed ✅ pending the fix-check.
- 2026-11-07 · Codex fix-check: two majors left, fixed without a further round: the review writer checks its attempt/profile guard after every await before the send (a switch during preparation never sends); exact macro remaining/total only with full coverage, else no claim (the coverage shows why; kcal unaffected).

## Outcome

_Final (2026-11-07). Rebased onto `edd65af3` (A67); Codex fix-check follows._

**Built:** WP1–WP5 as planned, one rebase fixup and two review-fix commits. No contract change, **no drift migration** (the review cache is a per-week synced setting). Size: M–L as estimated (one engineer session plus one fix round).

**Reviews:** Codex combined review: changes required, no blocker, no suggestion confirmation bypass. Majors fixed: a `limit`/`quota` end was cached as the review (now only `answered`); the writer lost its state with the screen and could pay again (now kept per profile session, one attempt per week unless Try again, runner stopped on a profile switch); partly known macros gave exact remaining/total claims (now no claim unless the macro is fully known over the period; `coverage.loggedDays` counts only fully known days, so the model can say why). Minors fixed: `weightTrend` with weekdays → unsupportedPlan; the settings write must be `Applied` and a throw ends in Try again.

**Evidence:** `make check-dart` ✓; fb_domain suite ✓ (coverage 95.3 %); focused app tests (buddy, progress, settings, export, workouts, today, app, query-plan audit and the new tests with TZ=UTC) ✓. Full suites are the merge run's (TD-108). Exit 1 is the owner's device check; exit 2 in code + review.

**Deviations (simplest sound option):**
- `phoneToolsProvider` (data) is gone; `buddyPhoneToolsProvider` (application) composes `PhoneTools` with the QueryEngine port, so data never imports application.
- Reads of auto-dispose providers keep a listener until the value arrives (a plain `ref.read(...future)` disposed them mid-load).
- A partly known macro gives no remaining/total claim (no contract change); `coverage.loggedDays` < the days with food shows why.
- Measurement answers carry no link (#323). Links are the turn's answered `queryData` links (≤ 2).
- A suggestion-only reply without text stores the fixed `BuddyReplyTexts.suggestionRecord` row (never drawn). A picked option is "picked" only in this session (#325).
- The weekly review is written when the just-finished week's summary opens (IN-001; NT-004 opens it), not at app start (#326). Older weeks show only cached reviews. Export lists the per-week keys 2026–2035.
- `TurnHost` gained `links`; `TurnEnd` carries the done reason; `AgentCardWriter.create` takes an optional checkpoint and has `preview`. The buddy test harness registers the settings op handler.

**Server assumptions:** `exerciseRef` in plans/claims is the local exercise ID (library code or custom UUID); a `last` claim has `value: null` with a `date`; `weeklyReview` accepts the chat start body with empty history/personal and streams the guarded review as `text`, ending `done answered`; fajr/maghrib are device-local "HH:mm"; `coverage.loggedDays` < days with food means the macro isn't fully known.

**Owner device checks (exit 1, A55 against the laptop server):** "how much protein left", "avg calories last week", "when did I last do legs" → correct numbers + a link chip that opens the screen; "what can I eat with 600 kcal left" → 2–4 options with kcal/protein, a tap makes a card, Confirm logs it; open last week's weekly summary → the review on top (< 30 s to read), Try again offline; on a Ramadan-mode day, suhoor/iftar wording and slots.

**Backlog:** #323–#326.
