# A22 — Chat sheet & proposal card

| Track | Depends on | Size | Owner | Status |
|---|---|---|---|---|
| App | A08, A20, A21, **B08**, **B18** (contract) | L | Claude | ⬜ Not started |

_Old ID: S33 (renumbered by TD-063, 2026-10-16)._

**Goal.** The most important interaction in the app: type what you ate → a proposal card appears within seconds → adjust with taps or a follow-up sentence → one tap to log. It must feel instant and never like filling in a form.

**Spec:** AI-001, AI-030, AI-031, AI-032, AI-033, AI-034, AI-035, AI-036, AI-037, AI-040, AI-041, AI-042, AI-043, AI-044, AI-140, AI-143, UX-002, UX-003, UX-011, UX-012, UX-020–026, HM-008 · **Decisions:** TD-011, D-079, D-080

## Scope
- **Input bar** (AI-001, HM-008) on Today (and Workouts in A37): focus opens the **chat bottom sheet** (UX-011) over the current screen, with the numbers behind it still visible. Pull up to full height for history, swipe down to dismiss (UX-012).
- **Send (ownership fixed 2026-10-24, A21 PA1):** A22 creates and owns the drift `chat_messages` table/migration and save-message ops through `ChangeSetApplier`; the message is saved first (full queue/retry lifecycle in A23), the **skeleton card** appears immediately (AI-030), then the interpret call runs → the ProposalEngine builds the draft → the card renders.
- **Message shape (A21 PA17/PA20):** build against B18’s contract after A21 WP4 → B18 contract commit → A22. `chat_messages` has normal metadata, role/text/status plus `codecVersion` and one bounded JSON budget field on the **assistant** row (issued question IDs/card ownership/open state/effective thresholds). User text is saved before dispatch; assistant row is the sole durable budget owner. Attachment refs/local paths are local-only, excluded from `chatMessage` sync. No per-proposal budget copies.
- **Food proposal card** (`spec/10` §4.1, UX-020): slot · time, dish name, item lines (name, amount + unit, kcal, source badge), estimate markers with a range sheet (AI-032), **assumption chips** (AI-033), **in-card questions** with answer chips (AI-034, AI-063), totals + "today after this" (AI-031), primary **Log it** and secondary **Discard**.
- **Adjusting:** tap an amount → inline number pad + unit picker (AI-040). Tap a name → up to 3 alternatives + search (AI-041). Swipe to remove, "+ add item" by text or search (AI-042). Tap slot/time (AI-043). **Follow-up typing updates the open card** (AI-044, UX-023) with the change highlighted (UX-024).
- **Confirm:** the application confirm use case composes this card’s draft ops into a `ChangeSet` with its own `Origin.proposal(card.id)` (A21 returns ops, not a ChangeSet). A23 extends this seam with resolve-proposal/status/outcome and assistant-message-budget ops in the **same transaction**; the ChangeSetApplier writes it, the card collapses to "logged ✓" + a one-line reply (AI-140, **English per AI-143**), the numbers behind animate (UX-025), haptics, undo available (AI-035).
- **Discard** (AI-037). Nothing counts until confirmed (AI-036).
- **Entry assumption display (A21 PA3, TD-084 Proposed):** map versioned `a1:` codes in `Provenance.assumptions` / `diaryEntry.assumptionsJson` to localized ARB text in `entry_details.dart` and proposal chips. Support yield, oil all/most, share, origin and fallback time/slot codes. Unknown code/version or legacy raw text → generic localized assumption, never render raw code/text verbatim. No server vocabulary validator.
- **Per-card session (A21 PA2/PA5):** one card per meal, lifecycle active/confirmed/discarded; preview = confirmed intake + only this card’s active lines, never sibling drafts. Follow-up uses `ProposalEngine.rebuild(previousCard, newRequest)` and its typed diff, retains compatible IDs/adjustments and counts carried open questions in the follow-up assistant message’s single budget. `originMessageId` never changes; `budgetMessageId` moves to the current assistant message. Restore loads the message + cards by `budgetMessageId`; the ChangeSet updates card + message together.
- Reply templates in ARB (EN), checked against the SF-020 banned words.

## Out of scope
- Offline queue, pending strip, failure states (A23). Other proposal kinds (A25+). Camera/barcode buttons' behaviour (A28/A29).

## Fixed by the plan
- One consistent card layout for all proposal kinds (UX-020). Adjustments happen on the card, never in a separate form (UX-022).

## Decide in the low-level plan
- Card component structure so later kinds (edit, delete, weigh-in, workout, import, target change) reuse it.
- Keyboard/sheet interaction details on Android.

## Exit criteria
- [ ] **Journeys J1, J2, J3** pass as patrol E2E tests against the local API with recorded AI fixtures.
- [ ] A follow-up "make it 2 eggs" updates the same card with a highlight (test).
- [ ] Goldens for the card states: loading skeleton, with question, with estimate, after confirm (light/dark, scale 2.0).
- [ ] On the A55 against the laptop server (B03): message → card p90 ≤ 5 s over 20 real messages (recorded).
- [ ] The owner logs real meals for 2–3 days and gives feedback.
- [ ] `apps/mobile/test/features/buddy/data/chat_message_sync_vectors_test.dart`: `A22 chat message row mapper matches the sync corpus in both directions` (B18 D10; corpus `contracts/testdata/sync/chat-proposal-validation-vectors.json`).

## Read first
`spec/10-ai-assistant.md` §4 · `spec/30-ux-principles.md` §2–3 · `spec/01-personas-and-journeys.md` J1–J3 · `03-architecture.md` §5–6

## Owner involvement
Daily use + feedback. This is the moment the core value appears.

---

## Low-level plan
_Full plan written in Phase B; binding handoffs below accepted by the orchestrator after A21 plan review at `59bb16e` (2026-10-24)._

**Tier/size:** Risky / L: A22 owns `chat_messages` persistence, migration and save-before-send; do not treat it as UI-only. A23 owns `proposals`, resolve ops/outcomes and B18 sync consumption. A22 does not independently invent either proposal persistence or server sync schemas.

**Planning constraints for the future WPs:** first build the chat-message table/migration plus save op and prove the message commits before interpret dispatch; all writes go through the applier. Frozen migrations/all-prior-version upgrades and outbox triggers must pass; **build against B18’s contract** (A21 WP4 → B18 contract commit → A22); budget JSON strings are bounded to 32768 UTF-16 units, with a codecVersion integer. No raw attachment path enters the sync projection. Next integrate A21’s per-card ops/ID/preview/rebuild seam; leave resolve-proposal/status/outcome composition extensible for A23 and never perform a second transaction for those transitions. Then map assumption codes through ARB (including diary details) and run widget/golden checks. Finally measure rendered tap→updated frame using A21’s six-item fixture, separately from A21’s UI-free profile engine benchmark.

**Exact tests to include in A22’s full plan:** `A22 message is saved before interpret dispatch`; `A22 chat message migration preserves existing user rows`; `A22 widget preview excludes already confirmed sibling draft lines`; `AI-044 follow-up updates existing card and highlights changed amount`; `A22 known assumption codes render localized text`; `A22 unknown assumption code or legacy text renders generic assumption`; `A22 confirm use case composes only selected card ops and origin`; `A22 assistant message alone stores the shared question budget`; `A22 chatMessage sync omits local attachment paths`. Use rule annotations for A22 engineering tests; the full plan assigns migration/golden paths and required gates. Add actual migration tests from every previous schema version, not only a fresh DB test.

**Gates/handoff:** `make gen-app`, `make catalog-pack`, `make check-dart`, focused migration/applier/widget tests, `make trace`, then full `make test-dart` at close, serially. Independent code/security reviews for the new write path; no spec/TD acceptance implied. A21 owns `apps/mobile/integration_test/proposal_recompute_benchmark_test.dart` (profile, adb, engine p95 ≤50 ms). A22 owns the UI harness (≥100 taps, same fixture, median/p95/max and jank; check engine+render ≤50 ms separately). If the A55 is unavailable, record owner check; never claim device performance from the host p95 ≤10 ms gate. M3 live round trips still require explicit paid scope.

**B18 contract handoff (2026-10-28, B18 WP1 §8):** build the drift table and mapper against `chatMessage` v1 in `contracts/openapi/sync-entities.json` and the codes in `fb_domain` `proposal_sync_codes.dart` (`ChatMessageRole`, `ChatMessageStatus`, `ChatProposalSyncBounds`); admission rules in `contracts/README.md` §chatMessage and proposal admission.
- Composer cap 1000 UTF-16 units (`contracts/openapi/modules/buddy.yaml` `text.maxLength`).
- Stored assistant text ≤ 8192 UTF-16 units, cut without splitting a surrogate pair; strip U+0000 (the server rejects both an unpaired surrogate and U+0000).
- `language` is a normalized short tag from a fixed app list (`en` / `ar` / `ar-Latn`) or null, never the raw model `intent.language`.
- No attachment paths in the sync projection (the schema has no such field and rejects extras).
- `chatMessage` and `proposal` row IDs are random UUIDv7, never UUIDv5 derived from content.
- Mapper `ProposalResult`s are never logged or interpolated (a success's `toString` contains the decoded draft); only `issue` may be logged.
- Display order is `createdAtMs` then `id`; replies are grouped by `replyToMessageId`.
- User rows send `codecVersion`/`budgetJson` as null; the assistant row carries the one shared budget. Read integers as `num` → `int` (B18 D15).
- New exit criterion: `chat_message_sync_vectors_test.dart` (B18 D10, below).

## Progress log

- 2026-10-24 · A21 architect review PA1/PA2/PA3/PA5/PA12 handoffs applied (orchestrator accepted): A22 owns Risky chat-message persistence/save-before-send, per-card confirmation composition, assumption-code ARB mapping and rendered device measurement. Planning only; full A22 plan and implementation remain pending.

- 2026-10-24 · A21 re-check PA17/PA18/PA20/PA24/PA26 applied: B18 contract dependency, assistant-row-only budget shape/current binding, atomic card+message seam, attachment exclusion and distinct widget test name. Planning only.

## Outcome
_Written in Phase E._
