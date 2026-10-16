# B09 — Buddy intents: edits, memory, batches & foods

| Track | Depends on | Size | Owner | Status |
|---|---|---|---|---|
| Backend | B08, **A21** | M | Codex | ⬜ Not started |

_Old ID: S35, S36 and S37 server parts (renumbered by TD-063, 2026-10-16). The app sides are A25, A26 and A27._

**Goal.** The interpret service understands diary edits, memory statements, batches, personal foods and saved meals, and the eval measures Buddy end to end with the real ProposalEngine.

**Spec:** AI-050, AI-051, AI-054, AI-055, AI-090, AI-091, AI-092, AI-100, AI-101, AI-102, DY-031, DY-040–045 (interpretation side), T03, T20–T29 · **Decisions:** TD-009, TD-032

## Scope
- **Contract first, in one commit per group** with a Progress-log line each (A25/A26/A27 build on them):
  - `DiaryEdit` (target entry IDs + patch: amount / food swap / slot / day / time), `DiaryDelete`, `Copy` (source date+slot → target), `AmbiguousReference` (candidate entry IDs); request context `recentEntries` (≈ 3 days: IDs, names, grams, slot) and date hints the app resolves locally.
  - `Memory` intent (explicit statements, AI-055); request context: the user-model slice (≤ ~20 items, `06` §5).
  - `Batch` intent (ingredients, quick vs leftovers, the portion eaten now), references to `openBatches`; `PersonalFood` intent (AI-054); saved meal by name and "save this as …" (DY-031).
- Prompt updates, validation and resolver changes for each intent; reference resolution to entry IDs (AI-091).
- **Full AQ metrics:** `buddy_eval` runs the real ProposalEngine (A21's `fb_domain` entry point) on API responses and computes AQ-02–08 + AQ-10 per language.
- Eval cases (+ AR/Arabizi variants): T03, T20–T29, plus the M3 set re-run with full metrics (milestone M3 eval half).

## Out of scope
- The app engines, cards and screens (A25–A27). Vision (B10). Q&A and suggestions (B11).

## Exit criteria
- [ ] Contract conformance green; the Dart client regenerated.
- [ ] The eval reports full AQ metrics. M3 cases (T01–T16, T19, T39–T41) meet the AQ thresholds (M3 eval half).
- [ ] T03, T20–T29 meet their thresholds (`spec/40` §2).
- [ ] Context bounds and privacy tests: no identity, no content in logs, per-list limits.

## Read first
`06-buddy-ai.md` §3–5 · `spec/10-ai-assistant.md` §5–7 · `spec/12-diary-meals-recipes.md` · B08 and A21 Outcomes

## Owner involvement
None. Real misses from dogfooding become eval cases.

---

## Low-level plan
_Written in Phase B._

## Outcome
_Written in Phase E._
