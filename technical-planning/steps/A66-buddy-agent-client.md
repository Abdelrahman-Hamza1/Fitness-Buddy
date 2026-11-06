# A66 — Buddy agent client (app): turn runner, phone tools, conversation, streaming chat

| Track | Depends on | Size | Owner | Status |
|---|---|---|---|---|
| App | A23a, **B25** (contract) | L | Claude (Opus build), Codex review (Risky) | ⬜ |

**Goal.** The app talks to the agent (D-100, AI-160–AI-177): turns stream into the chat with live steps, phone tools answer from local data, the conversation and summary go up with each message, several cards per reply with Apply all, offline and failure handling (A23b's scope), and the dev trace view. The app switches from `/interpret` to `/turns`.

**Read first:** `spec/10` §4, §15, `06` §3, §6, §11, TD-125–TD-128, A22/A23 cards (A23b's written plan for the queue, failures and pending strip).

## Scope (work packages, one commit each)
- **WP1 Protocol:** turn runner over the generated types and a small SSE framing reader (event ids, heartbeats, ordered `text` chunks); start/continue; `ackTurn`; `error` handling; idempotent `turnId` = message ID; stop = close the stream (and never post a pending `continue`); late events ignored.
- **WP2 Persistence and recovery:** the durable **turn checkpoint** (request or continuation + results last sent, last event id, received proposals) and the retry rule (same round once with `priorAttempt`, never after a user stop, then failed with "Try again"); `ProposalSessionWriter` create/update by `proposalId` + `revision` (stale revisions dropped); on a retry keep the earlier attempt's confirmed cards and drop its still-pending ones when the retry's first proposal or `done` arrives; the **"possible duplicate"** hint when a card's food, meal and amount match one confirmed earlier in the same turn; the **`buddySummary`** entity (local table + sync codec, server admission from B25 WP1) and compaction (evicted entries past the watermark → `compact`, store the returned summary only if the revision still matches); message queue offline/unavailable and failures (A23b scope, AI-045, AI-047, AI-153).
- **WP3 Request builder and phone tools:** history (≤ 12 with outcomes by `proposalId`), personal slice (≤ 20 local matches against the message tokens, with facts), profile (memory slice when `memoryItem` exists, confirmed defaults, halal, units, Ramadan), snapshot (open cards with revisions); phone tools `find_my_foods`, `read_diary`, `read_body`, `read_workouts`, `read_memory` with the `06` §4.2 scopes enforced on the phone and the per-turn disclosure budget (≤ 120 rows, 48 KiB); unknown tools → `ok:false unsupported`.
- **WP4 Chat UI:** live step line (ARB per step code), reply text, question chips (AI-166), several cards per reply with **Apply all** (still-pending current revisions only, one ChangeSet, one Undo; AI-162), cards updating in place, stop button, pending strip and "{n} waiting", a minimal summary row in Buddy remembers (full screen in A67); existing food and weigh-in cards from `proposal` events, other kinds "Buddy can't do that in this version yet" until A67–A69.
- **WP5 Trace and switch:** trace view (AI-172) in dev and owner builds only (`trace: true`), local only, never synced; remove the interpret request path (B26 removes the server side).
- **Tests (TD-128):** only the confirmation guard (a `proposal` event never reaches `ChangeSetApplier` without a user action; Apply all applies only still-pending current revisions of that reply). Tests covering removed interpret code go with it; `make check-*` gates pass.

## Exit criteria
1. On the A55 against the laptop server: "2 eggs" → card in ≤ 5 s; "same as yesterday's lunch" → a `read_diary` round trip → card; a question → chips → answer continues; Apply all on a 3-card reply; stop mid-turn; kill the app mid-turn → resumes without duplicate cards; airplane mode → pending, then processed.
2. Trace view shows each step in the owner's build only.
3. CI green; Codex code + security review passed.

## Lane
Lane 2 (app), from the B25 contract handoff.

## Progress log

## Outcome
