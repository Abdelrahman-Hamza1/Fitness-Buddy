# S34 — Message lifecycle, pending & failures

| Phase | Depends on | Size | Status |
|---|---|---|---|
| P4 Buddy core | S33 | M | ⬜ Not started |

**Goal.** Buddy never loses anything and never dead-ends: messages survive offline and errors, unconfirmed proposals wait visibly, and every failure says what to do. This closes Phase 4.

**Spec:** AI-003, AI-045, AI-046, AI-047, AI-142, AI-150, AI-152, AI-153, AC-020, AC-033, DY-025, HM-004, SF-020, SF-030, UX-052, UX-053, G2, G3, T11, T40, T41 · **Decisions:** TD-011

## Scope
- **`chat_messages` lifecycle** (`03` §6): saved as `queued` before sending → `processing` → `done` / `pending_offline` / `failed`. The **`BuddyMessageQueue`**: idempotency key = message ID, retries with backoff, processes on reconnect and app foreground (TQ-03).
- **Offline:** a message sent offline shows as "will process when you're online" (AI-047). Once processed it becomes a normal proposal.
- **Pending proposals** (AI-045/046): kept when the sheet is dismissed. The **"N to confirm · +X kcal" strip** on Today (HM-004) reopens them. Never counted in totals or shown as diary entries (DY-025). They sync like any row (G3).
- **Failures:** AI unavailable → pending + manual search offered (AI-153). Not understood → says what it didn't get, with chips (AI-150). Vague → asks what was eaten with typical-item chips (AI-152, T11).
- **Out of scope / medical:** templated, kind declines (AI-003, SF-030, T40).
- **Language check:** a banned-word filter on all model-written text (SF-020, AI-142).
- **Chat history:** scrollback in the sheet, and **clear chat history** in settings without touching the diary (AC-033).
- **Phase 4 acceptance run:** the eval + E2E on the P4 case set from the owner's location.

## Out of scope
- The pending-proposal notification (S45).

## Fixed by the plan
- User input is saved before any network call (UX-052). Processing happens on foreground, not in the background (G2).

## Decide in the low-level plan
- Retry/backoff parameters and the "failed" vs "pending" boundary.

## Exit criteria
- [ ] **T41 / OF-02 (Buddy part):** a message sent in airplane mode → pending → reconnect → becomes a proposal (E2E).
- [ ] Killing the app mid-request loses nothing and doesn't double-bill (idempotency) (test).
- [ ] The pending strip shows the correct count and kcal, and reopens the cards (widget test).
- [ ] **Phase 4 exit:** T01–T16, T19, T39–T41 meet the AQ thresholds in `spec/40` §2. Proposal p90 ≤ 5 s measured from the owner's location.

## Read first
`03-architecture.md` §6 · `spec/10-ai-assistant.md` §4.4, §14 · `spec/21-safety-and-wellbeing.md` §3–4

## Owner involvement
Use Buddy daily. Report anything that felt slow or confusing.

---

## Low-level plan
_Written in Phase B._

## Outcome
_Written in Phase E._
