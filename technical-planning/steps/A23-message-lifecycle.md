# A23 — Message lifecycle, pending & failures

| Track | Depends on | Size | Owner | Status |
|---|---|---|---|---|
| App | A22, **B18 (contract)** | L | Claude | ⬜ Not started |

_Old ID: S34 (renumbered by TD-063, 2026-10-16)._

**Goal.** Buddy never loses anything and never dead-ends: messages survive offline and errors, unconfirmed proposals wait visibly, and every failure says what to do. Together with B09's eval run, this reaches **milestone M3** (Buddy on the laptop).

**Spec:** AI-003, AI-045, AI-046, AI-047, AI-142, AI-150, AI-152, AI-153, AC-020, AC-033, DY-025, HM-004, SF-020, SF-030, UX-052, UX-053, G2, G3, T11, T40, T41 · **Decisions:** TD-011, TD-083 (Proposed)

## Scope
- **Ownership fixed 2026-10-24 (A21 PA1):** A22 creates/owns `chat_messages` and saves the message first. A23 creates/owns the drift **`proposals` table + migration (Risky)**, resolve-proposal op, status/outcome recording and consumes B18’s `chatMessage` / `proposal` sync entities. **B18 “chatMessage & proposal sync entities (server)”** is a new Codex backend step like B17: its contract commit comes first; A23 builds against that contract (orchestrator adds board row).
- **`chat_messages` lifecycle** (`03` §6): saved as `queued` before sending → `processing` → `done` / `pending_offline` / `failed`. The **`BuddyMessageQueue`**: idempotency key = message ID, retries with backoff, processes on reconnect and app foreground (TQ-03).
- **Offline:** a message sent offline shows as "will process when you're online" (AI-047). Once processed it becomes a normal proposal.
- **Atomic per-card resolution/outcomes:** one row per meal card, linked by `message_id`; metadata plus kind, versioned interpretation/draft JSON, status pending/confirmed/discarded/superseded, outcome unchanged/adjusted chips/discarded and resolved_at (`05` §2.3). A21 supplies draft ops only. The confirm use case appends the version-checked resolve-proposal op to those ops in **one `ChangeSet` / `ChangeSetApplier` transaction**, with `Origin.proposal(card.id)`; failure rolls back diary/status/outcome together. Discard resolves status/outcome without food writes. Outcomes feed `06` §5/A26 from confirmed/resolved records, never unconfirmed learning.
- **Pending proposals** (AI-045/046): kept when the sheet is dismissed. The **"N to confirm · +X kcal" strip** on Today (HM-004) reopens them. Never counted in totals or shown as diary entries (DY-025). They sync like any row (G3).
- **Failures:** AI unavailable → pending + manual search offered (AI-153). Not understood → says what it didn't get, with chips (AI-150). Vague → asks what was eaten with typical-item chips (AI-152, T11).
- **Out of scope / medical:** templated, kind declines (AI-003, SF-030, T40).
- **Language check:** a banned-word filter on all model-written text (SF-020, AI-142).
- **Chat history:** scrollback in the sheet, and **clear chat history** in settings without touching the diary (AC-033).
- **Milestone M3 run** (with Codex): E2E on the M3 case set (T01–T16, T19, T39–T41) from the owner's phone; Codex runs the eval half (`README.md` §5).

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

## Read first
`03-architecture.md` §6 · `spec/10-ai-assistant.md` §4.4, §14 · `spec/21-safety-and-wellbeing.md` §3–4

## Owner involvement
Use Buddy daily. Report anything that felt slow or confusing.

---

## Low-level plan
_Full plan written in Phase B; binding persistence handoff accepted by the orchestrator after A21 review at `59bb16e` (2026-10-24)._

**Tier/size/dependency:** **Risky / L** (was M), with **B18 (contract)** before implementation of sync payloads. New proposal migration, user-data resolution/outcomes, durable pending lifecycle and sync consumption justify L. A22 owns the chat-message migration/save path; A23 extends lifecycle and consumes the B18 definitions rather than creating ad hoc server types. B18 board row is the orchestrator’s task.

**Codec, per-card state and sync bound:** A21’s **512 KiB local input** ceiling is not the wire size. B18’s JSON **string fields are ≤32 KiB**. One row/card stores normalized interpretation and compact v1 card JSON plus its message-budget envelope, not the entire raw response/session copied into each row. A21’s compact projection removes mention/reason/model text, duplicate facts and derived totals/ops/previews; keeps every line/alternative fact/choice/quantity/provenance/ID and shared budget required for offline recompute. Six-item fixtures must fit ≤32768 UTF-8 bytes and code units per JSON string; B18 pins exact length semantics. If essential data still exceeds the bound, keep full local pending state and surface typed `syncPayloadTooLarge` with split/reduce-before-sync recovery; never drop essential options, lose user data, widen the contract or acknowledge the row as synced. A23 must model this recoverable unsynced state and test it against B18 admission.

**Restore/lifecycle invariants:** load all proposal rows for `message_id` (including confirmed/discarded budget history) into pure `ProposalDraftCodec.restore(cards, messageId, context)`. Union of issued question IDs must be ≤2; answered questions never free slots. Reject incomplete/conflicting budget snapshots with a typed recoverable failure and reconcile through the versioned application path; no codec write. Record lifecycle active/confirmed/discarded in the message session from successful transactions. For an active card, “today after this” uses refreshed confirmed intake + **that card alone**, so already-confirmed siblings are not added twice. Pending-strip kcal sums only active pending cards, not confirmed ones.

**Ordered work for the full plan:** (1) B18 contract/client/schema alignment and Risky `proposals` migration with all-version tests, outbox/capture and account deletion/clear-history considerations; (2) proposal create/update/resolve ops, atomic confirm/discard and outcomes, optimistic version/concurrent-confirm checks; (3) durable restore, compact sync bounds and mixed-row/budget recovery; (4) queue/failure/pending UI and M3 journeys. Full WP/file assignments remain for A23 Phase B; A21 implementation does not add these writers.

**Exact tests to assign in that plan:** `A23 migration adds proposals and preserves every prior schema`; `A23 confirm commits diary proposal status and outcome atomically`; `A23 failing resolve op rolls back diary and outbox`; `A23 duplicate or concurrent confirm cannot log twice`; `A23 discard records outcome without diary writes`; `AI-045 pending cards restore after restart without entering totals`; `A23 restored message cards share at most two issued question IDs`; `A23 confirmed sibling is counted only through confirmed intake`; `A23 compact proposal JSON respects B18 32 KiB field bounds`; `A23 oversized proposal remains local pending with recoverable sync size issue`; `A23 confirmed adjusted and discarded outcomes remain available to A26`. Use A23 rule comments for engineering checks and only A23 Spec IDs for requirement tags.

**Gates:** serial `make gen-app`, `make catalog-pack`, `make check-dart`, focused generated migration/applier/codec/sync/queue/widget tests, `make trace`, final full `make test-dart`. B18 provides contract-first schema/admission tests; Claude runs Docker/conformance/CI. Independent code + separate security review and app architecture check before merge. No direct repository writes or two-transaction confirm/status shortcut. Account cleanup, outbox and migration checks cannot be replaced by pure codec tests.

## Progress log

- 2026-10-24 · A21 architect review PA1/PA2 persistence handoff applied (orchestrator accepted): A23 owns Risky proposals migration, atomic resolution/outcomes and B18 sync consumption; size L and B18 (contract) dependency recorded. Compact per-card/shared-budget restore and 32 KiB versus 512 KiB limits specified. Planning only; B18 board row and full A23 plan remain with the orchestrator.

## Outcome
_Written in Phase E._
