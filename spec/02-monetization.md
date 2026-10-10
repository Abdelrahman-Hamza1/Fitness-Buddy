# 02 — Monetization

_Status: **Draft v1** · 2026-10-10 · Main decisions: D-003, D-041._

## 1. By release

| Release | Model |
|---|---|
| R1 (owner) | Free. No limits. |
| R2 (friends) | Free. A generous fair-use limit protects running costs (MN-020). |
| R3 (public) | **Free forever** tier + optional paid tier (below). |

## 2. Target model for R3

- **MN-001** `[R3]` **No ads, ever** (D-041, NG-3).
- **MN-002** `[R3]` **Always free, never paywalled**: manual logging, food search, barcode scan, label scan, quick-add and saved meals, batch dishes, diary, targets (including adaptive), weight tracking and graphs, measurements, workouts, weekly summary charts, export, account deletion. These are exactly the things competitors were criticised for paywalling (D-039).
- **MN-003** `[R3]` **Free AI allowance**: a daily number of Buddy requests (logging, edits, questions) on a cost-efficient model. The exact number is decided in R3 from real cost data from R1 and R2.
- **MN-004** `[R3]` **Paid tier**: higher or unlimited AI allowance, possibly a stronger model, the AI weekly review (if it turns out to be costly), recipe URL import. Price and billing period are decided in R3.
- **MN-005** `[R3]` Using AI allowance: one message = one request, regardless of how many proposals it produces. Confirming, discarding and adjusting a card with taps uses no allowance. Typed follow-ups that change a card do.
- **MN-006** `[R3]` The remaining allowance is visible in the input bar only when it's low (e.g. ≤ 3 left). Running out is handled kindly (AI-154): manual paths keep working, and nothing typed is lost.
- **MN-007** `[R3]` No pop-up upsells or interruptions. Upgrade options live in Me → Plan, and in the single "allowance used up" message.

## 3. Cost safeguards

- **MN-020** `[R2]` A fair-use limit per user per day protects running costs. It's set high enough that normal use never hits it.
- **MN-021** `[R1]` Repeat logging (chips, saved meals, barcode) never uses AI, which keeps costs down by design (DY-030).

## Open questions

| Question | When |
|---|---|
| Daily free allowance size | Decided before R3, from R1/R2 usage and costs |
| Paid price and period | Decided before R3 |
