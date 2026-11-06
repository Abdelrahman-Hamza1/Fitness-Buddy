# A67 — Buddy records by chat (app): diary edits, saved meals, batches, personal foods, memory

| Track | Depends on | Size | Owner | Status |
|---|---|---|---|---|
| App | A66, **B25** | L | Claude (Opus build), Codex review (Risky: write path) | ⬜ |

**Goal.** Every record change Buddy can propose today on the server gets its card and its confirmed write on the phone: spec 10 §4.6 (AI-050, AI-051, AI-054, AI-055), §7 (AI-080–AI-084), §8 (AI-090–AI-092), §9 (AI-100–AI-103). Replaces A25, A26 and A27.

## Scope
1. Cards and ChangeSets for `diaryEdit` (before → after), `diaryDelete`, `ambiguousReference` (which-one chips carrying the patch), `diaryCopy`, `savedMealLog`, `savedMealCreate`, `batch`, `batchPortion`, `batchClose`, `personalFoodCreate` (to the personal-food form), `memoryChange`.
2. Local resolution of day hints and day/slot lookups (`targets: []`), as the B09a contract defines.
3. **User model and memory:** the **`memoryItem`** entity (local table + sync codec; server admission from B25 WP1), learned habits from confirmed data (`06` §6), the AI-065 offer to remember, the AI-084 weighing nudge, and the full **"Buddy remembers"** screen (memory items + the conversation summary, edit/delete/clear; AI-082, AI-165).
4. Card outcomes feed the history outcomes (TD-126).
5. **Tests (TD-128):** the confirmation guard for every new card kind (confirm writes exactly the card's ChangeSet; discard writes nothing; Undo restores).

## Exit criteria
1. On the A55: edit, move, delete, copy, saved meal, batch (cook, portion, close), personal food and remember/forget each work by chat and confirm with one tap and Undo.
2. "Buddy remembers" lists memory and the summary; deleting an item stops Buddy using it.
3. CI green; Codex review passed.

## Lane
Lane 2 (app), after A66.

## Progress log

## Outcome
