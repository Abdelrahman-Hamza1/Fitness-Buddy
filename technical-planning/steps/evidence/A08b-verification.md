# A08b verification (2026-10-23)

Tier **Risky** (user-data write path, `PROCESS.md` A.2). This file records the write-path evidence (WP5, Codex) and the separate security review. UI evidence (WP6/WP7) is in the card's §5/§6 and the Progress log.

## Write-path properties → tests

| Property | Tests (spec IDs first) |
|---|---|
| Only `ChangeSetApplier` writes; every op has an exact inverse (A01 D3 state comparison) | `apps/mobile/test/features/diary/data/diary_editing_test.dart`: `AI-072 OverrideNutrients sets edited_by_user and …` (+ undo restores per-100, snapshot and flag), `copy, Undo → every copy and copied group tombstoned`, `save, Undo → the saved meal and all its items tombstoned` |
| Undo is atomic (no partial revert) | `copy, edit one copy, Undo → conflict and every copy stays`, `DY-023 save, edit one saved item, Undo rejects atomically` |
| Copy/save write exactly what the user saw, or nothing (PA2/PA7/PA8, in the applier transaction) | `diary_editing_test.dart`: the PA2 staleness table (entry added / edited / deleted / moved out / moved in, group renamed / moved → `sourceChanged` / `VersionConflict` / `RowNotFound`, each with nothing written via `rejectsUnchanged`: live rows + outbox), `PA7 a live group disappearing rejects with nothing written`, `PA7 an unchanged orphan entry copies; a group-state …`, `DY-023 a member of a partially selected group added or removed …`, `PA7 PA8 cross-day group is missing in layout and slot copy`; constructor: `DY-023 CopyMeal constructor requires expected entries ⊆ …` (fb_domain) |
| `edited_by_user` lifecycle (AI-072): override sets; amount edit keeps and scales; food change clears; copy/save carry; history re-log/replace carry | `AI-072 an amount edit after an override scales it …`, `AI-072 a food change clears the flag`, `DY-023 CopyMeal and SaveMeal carry edited_by_user`, `FD-010 a history re-log of an edited retired snapshot …`, `AI-072 a live catalog choice clears edited history flag` |
| Override validation: finite, ≥ 0, per-field caps (20,000 kcal, 5,000 g, 50,000 mg), `-0.0` → 0, derived per-100 finite and ≤ 1e12 (sync contract max) else `outOfRange`; zero amount rejected; same values → no write; corrupt stored rows surface | `AI-072 field caps reject huge values; negative zero normalises`, `AI-072 property: overriding field f to v gives …` (1,000 runs), `AI-072 amount 0 → InvalidOp(zeroAmount); same values on …`, `AI-072 override surfaces corrupt stored rows without writes` |
| Stale versions never write; unexpected errors are not swallowed | `D12 edit commands drop duplicate pending work and clear …`, `DY-021 unexpected Undo error rethrows and clears pending …`, A08a `DY-022 unexpected apply error still clears pending and hidden` |
| `watchEntry(id)` is the authoritative live read for open sheets (PA4) | `watchEntry(id) follows the row across a slot and day …` |
| Privacy: no values in `toString`/errors/logs | `toString of OverrideNutrients shows no values` (fb_domain); review: no log/print/telemetry added |

Gates on every WP commit: `make gen-app catalog-pack check-dart test-dart trace` (Codex) and `make gen-check` (orchestrator); `fb_domain` coverage 100% (2,019/2,019 lines). Full suite at WP5 round 2: 1,279+ tests passed, one existing opt-in skip.

## Security review (Claude security-reviewer, separate from the Codex builder)

- **Round 1** (8486e1b): approve with findings, no blockers. Major: history re-log/replace dropped the edited flag (decision: carry it). Minors: no override caps/overflow guard; cross-day live groups blocked copying; test gaps; nits (-0.0, amount rewrite on override, SaveMeal name length only in the controller). All fixed in 69eb4b0.
- **Round 2** (69eb4b0): all fixed; new major: a controller catch-all (introduced by the orchestrator's round-1 brief) hid real bugs and could report "failed" after a committed write. Fixed in 160a53b: only `ChangeRejected` is mapped, everything else rethrows after clearing state. Minor: stale estimate range on re-log → kept only when the amount matches. Nit: `outOfRange` mapping narrowed to `NutrientOverride.apply`.
- Privacy check: pass both rounds.

## Code and UX reviews (UI, WP6)

- Codex code review (c774c8a): changes required, no blockers (Move sheet staleness, copy-eligibility stamp, Reload re-reading untouched fields, replace failure copy). Fixed in aa8ba26; Codex re-check: **approve**.
- ux-reviewer: approve with findings; accepted changes in aa8ba26; per-nutrient override trace + reset → backlog #97 (owner call on the A55, #96).

## Device

CI `android-it`: Patrol `OF-01 DY-021 DY-022 DY-023 UX-030 offline diary journey` (WP7). Green on 72dd6dc (job 120518659289, first attempt). The device run found one real bug the host tests couldn't: for up to 5 s after an action, the shell scaffold's Undo snackbar covered a sheet's buttons (sheets opened in the tab navigator) and took the tap meant for Save. Fixed by opening sheets on the root navigator; DS regression test `UX-030 a sheet opened inside the tab navigator sits above the shell's Undo snackbar …` fails without the fix. Also: a refused amount/override save now always explains itself. The owner's real-day check on the A55 is backlog #96.
