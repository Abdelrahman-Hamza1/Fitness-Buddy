# A23 — Message lifecycle, pending & failures

| Track | Depends on | Size | Owner | Status |
|---|---|---|---|---|
| App | A22, **B18 (contract)** | L | Claude | ⬜ Not started |

_Old ID: S34 (renumbered by TD-063, 2026-10-16)._

**Goal.** Buddy never loses anything and never dead-ends: messages survive offline and errors, unconfirmed proposals wait visibly, and every failure says what to do. Together with B09's eval run, this reaches **milestone M3** (Buddy on the laptop).

**Spec:** AI-003, AI-045, AI-046, AI-047, AI-142, AI-150, AI-152, AI-153, AC-020, AC-033, DY-025, HM-004, SF-020, SF-030, UX-052, UX-053, G2, G3, T11, T40, T41 · **Decisions:** TD-011, TD-083 (Proposed)

## Scope
- **Ownership fixed 2026-10-24 (A21 PA1):** A22 creates/owns `chat_messages` and saves the message first. A23 creates/owns the drift **`proposals` table + migration (Risky)**, resolve-proposal op, status/outcome recording and consumes B18’s `chatMessage` / `proposal` sync entities. **B18 “chatMessage & proposal sync entities (server)”** is a new backend step like B17: its contract commit comes first; A23 builds against that contract (orchestrator adds board row).
- **`chat_messages` lifecycle** (`03` §6): saved as `queued` before sending → `processing` → `done` / `pending_offline` / `failed`. The **`BuddyMessageQueue`**: idempotency key = message ID, retries with backoff, processes on reconnect and app foreground (TQ-03).
- **Offline:** a message sent offline shows as "will process when you're online" (AI-047). Once processed it becomes a normal proposal.
- **Atomic per-card resolution/outcomes:** one row per meal card with immutable `originMessageId` and current `budgetMessageId`; metadata plus kind, `codecVersion`, versioned interpretation/draft JSON (interpretation holds **only this card’s normalized intents**, referring to facts/options stored once in compact card JSON), status pending/confirmed/discarded/superseded, outcome unchanged/adjusted chips/discarded and resolved_at (`05` §2.3). A21 supplies draft ops only. The confirm use case appends the version-checked resolve-proposal op to those ops in **one `ChangeSet` / `ChangeSetApplier` transaction**, with `Origin.proposal(card.id)`; include the owning assistant-message budget update in that same ChangeSet; failure rolls back diary/card-status/outcome/message-budget together. Discard resolves status/outcome without food writes. Outcomes feed `06` §5/A26 from confirmed/resolved records, never unconfirmed learning.
- **Pending proposals** (AI-045/046): kept when the sheet is dismissed. The **"N to confirm · +X kcal" strip** on Today (HM-004) reopens them. Never counted in totals or shown as diary entries (DY-025). They sync like any row (G3).
- **Failures:** AI unavailable → pending + manual search offered (AI-153). Not understood → says what it didn't get, with chips (AI-150). Vague → asks what was eaten with typical-item chips (AI-152, T11).
- **Out of scope / medical:** templated, kind declines (AI-003, SF-030, T40).
- **Language check:** a banned-word filter on all model-written text (SF-020, AI-142).
- **Chat history:** scrollback in the sheet, and **clear chat history** in settings without touching the diary (AC-033).
- **Milestone M3 run:** E2E on the M3 case set (T01–T16, T19, T39–T41) from the owner's phone, plus the eval half with `buddy_eval` (`README.md` §5).

## Out of scope
- The pending-proposal notification (A40). Creating the `chat_messages` table/save-first operation (A22); deterministic proposal math and local session codec (A21).

## Fixed by the plan
- User input is saved before any network call (UX-052). Processing happens on foreground, not in the background (G2).

## Decide in the low-level plan
- Retry/backoff parameters and the "failed" vs "pending" boundary.

## Exit criteria
- [ ] **T41 / OF-02 (Buddy part):** a message sent in airplane mode → pending → reconnect → becomes a proposal (E2E).
- [ ] Killing the app mid-request loses nothing and doesn't double-bill (idempotency) (test).
- [ ] The pending strip shows the correct count and kcal, and reopens the cards (widget test).
- [ ] **M3 (app part):** the M3 journeys pass E2E on the A55 against the laptop server; proposal p90 ≤ 5 s measured from the owner's location. (The AQ thresholds are B09's eval run.)
- [ ] `apps/mobile/test/features/buddy/data/proposal_sync_vectors_test.dart`: `A23 proposal row mapper matches the sync corpus in both directions` (B18 D10; corpus `contracts/testdata/sync/chat-proposal-validation-vectors.json`).

## Read first
`03-architecture.md` §6 · `spec/10-ai-assistant.md` §4.4, §14 · `spec/21-safety-and-wellbeing.md` §3–4

## Owner involvement
Use Buddy daily. Report anything that felt slow or confusing.

---

## Low-level plan
_Full plan written in Phase B; binding persistence handoff accepted by the orchestrator after A21 review at `59bb16e` (2026-10-24)._

**Tier/size/dependency:** **Risky / L** (was M), with **B18 (contract)** before implementation of sync payloads. New proposal migration, user-data resolution/outcomes, durable pending lifecycle and sync consumption justify L. A22 owns the chat-message migration/save path; A23 extends lifecycle and consumes the B18 definitions rather than creating ad hoc server types. B18 board row is the orchestrator’s task.

**Codec, per-card state and sync bound:** A21’s **512 KiB local input** ceiling is not the wire bound. B18 validates JSON string fields at **≤32768 UTF-16 units** (supplementary character =2 units), plus `codecVersion` integer. Each proposal row stores card state, owned question IDs, immutable `originMessageId` and current `budgetMessageId`. `interpretation` holds **only this card’s normalized intents**, not siblings or another copy of facts/options already in compact card JSON. A21 strips redundant model text/derived totals/ops/previews and deduplicates facts, while retaining required recompute data. The **assistant `chat_messages` row stores the message-level budget once**, as a bounded JSON field; never copy it into proposal rows. Six-item projection tests pin 32768/32769 UTF-16-unit boundaries. If essential data still exceeds the bound, keep full local pending state and surface `syncPayloadTooLarge` with split/reduce-before-sync recovery; no essential truncation or false sync acknowledgement.

**Restore/lifecycle invariants (PA17/PA18):** load the assistant message row and all current cards selected by **`budgetMessageId`**, then call pure `ProposalDraftCodec.restore(message, cards, context)`. Its one budget contains ≤2 ever-issued question IDs; answers never free slots. Cross-check owned IDs and open/answered ownership against the cards in A21, **not B18**: missing message/card rows → `sessionIncomplete`; present but inconsistent rows → `budgetConflict`, with versioned application recovery and no codec writes. A follow-up M2 retains the card’s immutable `originMessageId=M1` but updates `budgetMessageId=M2`; carried open questions live in M2’s budget and survive M2 restore. One ChangeSet updates card + M2 budget plus any changed M1 membership, preserving M1 issued history without requiring moved cards as current members. Confirmation/discard likewise update card + message atomically. Stored status vocabulary is **pending/confirmed/discarded/superseded**, with A21 **active ≡ pending**; A21 never emits superseded (AI-044 updates in place), and historical superseded rows cannot confirm. Per-card preview is refreshed confirmed intake + that active card alone; pending-strip kcal excludes resolved cards.

**Ordered work for the full plan:** (1) B18 contract/client/schema alignment and Risky `proposals` migration with all-version tests, outbox/capture and account deletion/clear-history considerations; (2) proposal create/update/resolve ops, atomic confirm/discard and outcomes, optimistic version/concurrent-confirm checks; (3) durable restore, compact sync bounds and mixed-row/budget recovery; (4) queue/failure/pending UI and M3 journeys. Full WP/file assignments remain for A23 Phase B; A21 implementation does not add these writers.

**Exact tests to assign in that plan:** `A23 migration adds proposals and preserves every prior schema`; `A23 confirm commits diary proposal status outcome and message budget atomically`; `A23 failing resolve op rolls back diary and outbox`; `A23 duplicate or concurrent confirm cannot log twice`; `A23 discard records outcome without diary writes`; `AI-045 pending cards restore after restart without entering totals`; `A23 assistant row budget and current message cards restore at most two issued question IDs`; `A23 confirmed sibling is counted only through confirmed intake`; `A23 compact proposal JSON respects B18 32768 UTF-16 unit bounds`; `A23 oversized proposal remains local pending with recoverable sync size issue`; `A23 confirmed adjusted and discarded outcomes remain available to A26`; `A23 follow-up restores carried questions by budgetMessageId with immutable origin`; `A23 proposal interpretation contains only card intents without duplicate facts`; `A23 stored pending maps to active and superseded stays nonconfirmable`. Use A23 rule comments for engineering checks and only A23 Spec IDs for requirement tags.

**Gates:** serial `make gen-app`, `make catalog-pack`, `make check-dart`, focused generated migration/applier/codec/sync/queue/widget tests, `make trace`, final full `make test-dart`. B18 provides contract-first schema/admission tests; Claude runs Docker/conformance/CI. Independent code + separate security review and app architecture check before merge. No direct repository writes or two-transaction confirm/status shortcut. Account cleanup, outbox and migration checks cannot be replaced by pure codec tests.

**B18 contract handoff (2026-10-28, B18 WP1 §8):** build the `proposals` table and mapper against `proposal` v1 in `contracts/openapi/sync-entities.json` and the codes in `fb_domain` `proposal_sync_codes.dart` (`ProposalStatus` with `ofLifecycle`, `ProposalOutcome`, `ChatProposalSyncBounds`); admission rules in `contracts/README.md` §chatMessage and proposal admission.
- Top-level columns (`status`, IDs, `codecVersion`) are authoritative over the copies inside `draftJson`; the server never cross-checks them.
- The mapper turns synced fields back into restore input with `ProposalDraftCodec.cardFromSync` / `messageFromSync`. Unknown `kind`/`codecVersion` or null refs mean "not restorable" (a generic card), never a crash; a `foodLog` row with null refs or interpretation fails with a fixed issue.
- A pulled non-terminal message (`queued` / `pending_offline` / `processing`) is processed only by its last-writer `device_id`, or after an A23-chosen timeout.
- Dedupe assistant replies by `replyToMessageId` (a crash-retried interpret response stays idempotent).
- Clear history (AC-033): tombstoning an assistant row orphans its pending cards (`sessionIncomplete`), so keep or resolve them deliberately. Tombstones **must** carry a scrubbed valid payload: `chatMessage` with `text: ""` and `budgetJson: null`; `proposal` keeping `codecVersion` with `draftJson: "{}"` and `interpretationJson: null`. Cleared chats can still remain in server history for up to 30 days (displaced versions, AC-012, `05` §7); the privacy policy must say so (backlog item added at B18 close).
- Mapper `ProposalResult`s are never logged or interpolated (a success's `toString` contains the decoded draft); only `issue` may be logged.
- Outcome wire codes are `unchanged` / `adjusted` / `discarded` (null until resolved). Failure codes and reply chips (AI-150/152) aren't in v1: they become local-only columns or an additive v2.
- Read integers as `num` → `int` (B18 D15).
- `syncProjection` returns success for two shapes the server rejects (B18 corpus `codecServerRejects`): a card with more than 128 chip taps (`choices` exceeds 128 members) and an amount below decimal range (e.g. `1e-30` g). Both are pathological; add a precheck in `syncProjection` (`syncPayloadTooLarge`, or reject the amount) or keep such rows local, so A34 never queues an unpushable row.
- New exit criterion: `proposal_sync_vectors_test.dart` (B18 D10, below).

## A22a handoff (2026-10-29, A22a review round 1)

Binding for A23's plan (from A22a's build and reviews):
- **`dateHint` isn't in the proposal draft codec.** A22a's engine resolves B09's day grammar (`DayHint`; ten years back at most, never before 1970 or in the future) and keeps the hint on the intent, but `ProposalDraftCodec` intents don't carry it, so a restored card would fall back to the reference day. Add it (codec version bump + corpus) **before** restore by `budgetMessageId`.
- **Never replay A22's `queued`/`failed` rows (PA10).** They have no durable request snapshot; treat them as failed or send them as a new message with a new Idempotency-Key.
- **Contributor seam:** `proposalPersistenceContributorsProvider` (`onReply`, `onConfirm`, `onDiscard`) returns ops appended to the same change set as A22's own; A23 adds proposal create/resolve/outcome and assistant-message budget ops there, never a second transaction. **Whichever of A22b/A23 merges second wires `onFollowUp`** (shared files `send_buddy_message.dart`, `proposal_resolution.dart`, `message_list.dart`).
- The thread controller refreshes open cards on non-proposal diary change sets (domain events); A23's restored cards should join that path.

## A22b handoff (2026-10-29, A22b close)

- **The draft codec must carry `assumedAmounts` and `removedComponents`** (engine state added by A22b: stepper eligibility kept apart from "explicit", and a generated oil removed on its own) **before** restore by `budgetMessageId`; otherwise a restored card brings a removed oil back and loses its − / +. Codec version bump + corpus (backlog #194).
- **`onFollowUp` is wired** (A22b merged first): the follow-up's assistant row and the rebuilt card share one change set; A23 adds its proposal/budget ops there.
- **Discard Undo is in memory** and enabled only while `ProposalResolution.discardUndoable` (no contributors). Before A23 registers contributors that write on discard, add a resolve-undo or Discard Undo turns off.
- A card is read-only while its follow-up is in flight (`BuddyThread.isUpdating`); a retried follow-up on a logged/discarded card gets a fixed reply and no new card. Keep both when turns become durable.

## Progress log

- 2026-10-24 · A21 architect review PA1/PA2 persistence handoff applied (orchestrator accepted): A23 owns Risky proposals migration, atomic resolution/outcomes and B18 sync consumption; size L and B18 (contract) dependency recorded. Compact per-card/shared-budget restore and 32 KiB versus 512 KiB limits specified. Planning only; B18 board row and full A23 plan remain with the orchestrator.

- 2026-10-24 · A21 re-check PA16–PA18/PA25 applied: assistant-row-only budget, current budgetMessageId restore with immutable originMessageId, pending/active mapping and no engine superseding, exact UTF-16 string bounds, card-only normalized interpretation and atomic card+message writes. Cross-row consistency remains A21 restore. Planning only.

## Outcome
_Written in Phase E._
