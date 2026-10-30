# A15 — Weight graph & measurements

| Track | Depends on | Size | Owner | Status |
|---|---|---|---|---|
| App | A12, A13a, A14 | L | Claude | A15a ✅ · A15b ✅ (owner sign-off pending) |

_Old ID: S22 (renumbered by TD-063, 2026-10-16)._

**Goal.** The weight graph that replaces the owner's note, with all its overlays, plus body measurements and their graphs. The chart library is confirmed (TD-012) by a feasibility check at the start.

**Spec:** WB-020, WB-021 (goal line, projection cone, phase shading; Ramadan shading data arrives in A41), WB-022, WB-023, WB-040 (form), WB-041, WB-042 (manual body fat), ~~WB-043~~ (moved to A40, A15a PA10), IN-004 · **Decisions:** TD-012

## Scope
- **Feasibility check first (≤ ½ session):** fl_chart with points + trend line + goal line + uncertainty cone + shaded bands + touch tooltips. If any part fails, `CustomPainter` for that layer. **Record TD-012.**
- **Chart widgets** in `fb_design_system` (the wrappers from A02): time-axis handling (chronological in any direction, LC-003-ready), ranges 1M/3M/6M/1Y/All, tooltips.
- **Weight graph** (WB-020–022): raw points + trend, goal weight line, projected path to the goal with a cone (from the trend rate + uncertainty), **shaded phases** (TG-012), a band API for Ramadan periods (fed in A41), tap a point → value, date, note, trend at that date.
- **Summary stats** (WB-023): change since phase start, this month vs the monthly target, average weekly rate.
- **Measurements:** built-in types (waist, chest, hips, arm, thigh, neck) + custom types, a form entry (chat in A29), a graph per type (trend smoothing only with ≥ 5 points), body fat % manual with its own graph (WB-042), and ~~a measurement reminder on/off setting stored for A40 (WB-043)~~ (moved to A40, A15a PA10).
- **The owner's weight history:** a simple multi-row manual entry (paste import comes with Buddy in A29).

## Out of scope
- Paste import (A29). Ramadan detection (A41). The Progress tab layout (A16).

## Fixed by the plan
- Charts are wrapped in design-system widgets. Screens never use the chart library directly.

## Decide in the low-level plan
- The projection cone method (e.g. a rate ± standard error over the last N weeks).
- Down-sampling for "All" ranges with years of data.

## Exit criteria
- [ ] **TD-012 recorded** with the feasibility result.
- [ ] The weight graph renders the owner's real history with every overlay. The owner signs off ("this replaces my note").
- [ ] Goldens for the graph in each range (light/dark). Tooltip interaction test.
- [ ] Measurements: add, edit, delete with undo. Graphs per type.
- [ ] Rendering 2 years of daily points stays smooth on the A55 (no frame > 16 ms during pan).

## Read first
`spec/14-weight-and-body.md` §3, §5 · `02-tech-stack.md` §1 (charts)

## Owner involvement
Enter your weight history (or hand it over for entry). Review the graph.

---

## Low-level plan
_A15a "Weight graph" part, compacted on 2026-10-29 from the prepared A15 plan (step-planner, architect plan review PA1–PA17 applied; chart research `A15-charts.md`). A15b "Weight history entry & measurements" (WP6–WP10, Risky: contract, two synced tables, migration, multi-row entry, measurement screens) keeps its own plan section when it starts. Owner direction 2026-10-29: plan + code now (time-boxed), architecture and code review later; CI on the branch is the test evidence (no local test runs)._

**Split (D1).** A15a = WP1–WP5, **Normal** (no new write code, no migration): TD-012, the DS chart, projection + stats, the graph screen, entry points. A15b depends on A15a. WB-043 (measurement reminder) moves to A40 (PA10).

**Decisions (A15a).**
- **D2 TD-012 = `CustomPainter`, settled by research, no prototype** (PA1): fl_chart 1.3.0 works under material_ui but has no culling, repaints every path per pan frame, fights our drag recogniser, still needs our slicing/LTTB/labels/off-scale marker, and ties the DS to in-framework Material. Evidence: `evidence/A15a-chart-feasibility.md`; TD-012 row rewritten (owner FYI).
- **D3 DS API.** `FbTimeSeriesChart` keeps its name: `series`, `range`, `panBounds?`, `onRangeChanged`, `bands` (the cone), `goal` (+ edge marker when off-scale), `periods` (`FbPeriod` start/end/label/`FbPeriodTone {phaseA, phaseB, highlight}`; phase labels top, highlight bottom), `selected`/`onSelect` (`FbPointRef`), `formatValue`, `formatDate`, `semanticLabel`, `emptyLabel`, `aspectRatio`. `FbSeries` gains `selectable`, `tone {primary, secondary, muted}`; `FbSeriesStyle` gains `dashedLine` (open to additions); `FbPoint` gains `key`; `tooltip` removed (details render outside). **Time runs in reading direction** (LC-003, PA2): oldest at start, so in RTL the oldest is at the right. X values are naive wall-clock `DateTime.utc(local fields)` (PA7). **Pan (PA4):** transient internal offset during drag, one `onRangeChanged` with a continuous start on drag end; a new `range` resets it. Selection always drawn (PA8), tap tolerance ≥ 24 dp, semantics increase/decrease step the selection. Tokens only; style differs by dash/dot, not only colour (UX-071).
- **D4 Down-sampling:** LTTB per series over the visible slice (binary search), lines ≤ 1 vertex/dp, dots ≤ 1 per 3 dp; hit-testing on full data; cached axis `TextPainter`s; `RepaintBoundary`.
- **D5 Windows (WB-020)** in `features/progress/application/graph_window.dart`: `GraphRange {m1, m3, m6, y1, all}`, 3M default, ends today, calendar months (day clamped); All = first weigh-in → today (≥ 1 month); future margin ¼ window when a projection shows; pan bounds [first − 7 d, today + margin]; All doesn't pan. `weightGraphWindowProvider` (keepAlive, session-only) holds range + panStart; "Today" chip resets.
- **D6 Y scale** `nice_scale`: 3–5 ticks on 0.1/0.2/0.5/1/2/5/10 steps, 8 % padding, fitted to the visible slice; the goal is included only if it at most doubles the span, else an edge marker.
- **D7 Projection + cone (PA5)** pure `WeightProjection.of` in `fb_domain/src/body/weight_graph.dart`: needs a goal weight, a fresh trend with a weekly rate ≥ 0.05 kg/week toward the goal, not reached. Centre `T + r·t/7` from the latest trend point; σ = OLS slope SE of the day choices in the 56 days ending at the anchor (≥ 4 points over ≥ 14 days), floor 0.1 kg/week; edges centre ± 1.28·σ·t/7, clamped at the goal; drawn until the slow edge reaches the goal or 730 days; reach date where the centre meets the goal ("Goal around {month} at your current trend"); none past 730 days. Rate uncertainty only, never a probability. Constants in `ProjectionConfig`.
- **D8 Goal line, phases, Ramadan seam:** the active phase's target weight (targetDate/targetRate only); `GoalHistory.phases` in view → alternating `phaseA/phaseB` periods labelled by `goalPhaseLabel` (targets barrel, PA9); `chartHighlightPeriodsProvider` returns `const []` for A41.
- **D9 Tap → details (WB-022):** an `FbCard` under the chart: value as typed, date/time, note, "Trend {w} that day"; "Not used for the trend" + **Use for trend** (A14 `chooseForTrend`, undo); **Edit** → A14 `showWeighInSheet(edit:)`. Vanished selection clears.
- **D10 Stats (WB-023, PA3/PA11):** pure `WeightStats.of`: reference = active phase start else first weigh-in; start value `trendOn(start)` or the first trend point after a stale/missing one; change since start; this month = trend today − trend at end of last month (or from a phase start this month, pro-rated target); **monthly target = `monthlyKgFromWeeklyRate` of the same achievable rate A13 shows** (TG-011 line, SF-011-capped), from `targetsExplanationProvider`; average weekly rate after ≥ 14 days, "Average since {date}"; missing pieces "—" + reason.
- **D11/D12 Placement and entry:** screen, providers and window in `features/progress/` (imports body, targets, settings barrels). Routes `TodayWeightGraphRoute` `/today/weight` and `WeightGraphRoute` `/progress/weight`; Today's `WeightCard` gets a "Weight graph" row; the Progress tab gets a Weight row until A16.
- **D21 Copy:** neutral words only (change, trend, projection, goal, "likely range at the current rate"); no red/green; ARB `weightGraph*`; DS strings in `fb_ds_en.arb`.
- **D22 Perf:** host vertex-cap test + printed benchmark; Patrol frame timings and the A55 profile pan run (owner item, recorded here) gate exit 5.

**Work packages.**
- **WP1** `docs(A15a): TD-012 chart feasibility result`: evidence note + TD-012 row.
- **WP2** `feat(design-system): time-series chart with bands, periods, selection and pan`: §5.1 tests, `time_series_chart` golden matrix (replaces `chart_placeholder`), mockups updated.
- **WP3** `feat(body): weight projection and stats`: `weight_graph.dart` + tests (glados property on the cone), README section.
- **WP4** `feat(progress): weight graph with goal, projection, phases and point editing`: window, providers, screen, details, stats, routes, Progress row, ARB, widget tests, goldens.
- **WP5** `feat(body): weight graph entry on Today`: `WeightCard` row + goldens, Patrol `weight_graph_test.dart`; close commit `[it]`.

**Tests (spec ID first).** DS: `IN-004` matrix golden, `LC-003` RTL reading direction + drag follows finger, `WB-022` tap ≥ 24 dp / full-data hit test / selection drawn / semantics stepping, `WB-020` pan offset → one `onRangeChanged`, LTTB keeps extremes and caps, 2 years → ≤ 360 vertices / 120 dots, nice scale + goal edge rule. Domain: `WB-021` centre, σ, edges, clamp, horizon, reach date, every no-projection reason, glados cone property; `WB-023` start value (stale rule), this month (pro-rated), monthly target from the rate, average after 14 days, no phase; toString carries no values. App: `WB-020` windows (31 Mar − 1 month = 28/29 Feb), chips (3M default, survives leaving), pan + Today; `WB-021` overlays drawn + unnamed phase label + Ramadan seam; `WB-022` tap shows value/date/note/trend, Use for trend with undo, Edit opens the sheet; `WB-023` stats; `LC-010` lb; `UX-050/051/052`; `HM-005` card row → graph, Back → Today; `UX-013` Progress row. Goldens per range light/dark + text scale 2.0.

**Exit mapping (A15a).** TD-012 → WP1. Overlays + goldens per range + tooltip test → WP2/WP4. Real-history sign-off → A15b close. A55 smooth pan → host caps + Patrol timings + owner profile run (verifier ⚠️ until recorded).

**Risks.** A55 pan perf (mitigation: static-layer `Picture` cache). Golden antialiasing (integral strokes, CI goldens). Shared files with A13c (targets presentation: untouched here, only the barrel is read) and A44 (palette: tokens only, so goldens regenerate after A44 lands).

### A15b "Weight history entry & measurements": Low-level plan
_**Codex plan review round 1 (2026-10-30): approve with required changes; PA1–PA8 applied (table at the end of this plan; where they differ, the amended text wins).** Step-planner, 2026-10-30, lane 3 (`~/work/fitness_buddy_3`, branch `step/A15b-weight-history-measurements` from `origin/main` 2cab3c0). Recovered from the prepared A15 plan (2026-10-28, WP6–WP10, architect review PA1–PA17; scratchpad `plans/A15-plan.md`, not in git) and **re-verified against the code on main**; every change against that plan is listed under "Changed since the prepared plan". Decision numbers continue the A15 plan (D13–D20 were A15b's); new ones start at D23. **Tier: Risky** (user-data write path, two new synced tables, a migration, a contract change). **Reviews (owner rule, 2026-10-30): Codex only, read-only.** Plan review by Codex, then the orchestrator self-approves (TD-037, no blocking owner item). Code review by Codex (code + security, Risky). No local test runs: codegen, `make check-dart`, `make check-dotnet` / `dotnet build` locally; CI is the evidence._

**Summary.** After A15b the owner can type years of old weigh-ins as rows on one screen (date + value, flags for duplicates, unit mix-ups and jumps) and save them as **one change set with one undo**. The weight graph then shows the real history with every A15a overlay. They can also log body measurements through a form: waist, chest, hips, arm, thigh, neck, body fat % and their own custom types. Each type has its own graph (A15a's `FbTimeSeriesChart`; a trend line only from 5 entries, WB-041), and every add, edit or delete has undo. Measurements live in two new synced tables (`measurement_types`, `measurements`, **schema v10**), written only through `ChangeSetApplier`. Their contract entities land in A15b's own contract commit. **Server admission of their semantic wire rules is split out into a new backend step, B20** (D23).

**Changed since the prepared plan (re-verification).**
- **Server admission → B20 (new).** PA6 assumed B19 would admit the measurement pair rule. B19 closed without measurements (B19 D1: "a sibling server step"), and the exporter has no `oneOf`/`if`/`pattern` (`tools/scripts/export-sync-schemas.py`), so the rules need a TD-080 validator → D23.
- **Schema v10, not v(N+1)=8.** Main is at v8 (A36 took v8), and lane 1's A23a adds v9 (proposals). A15b writes `from_9_to_10.dart` and merges after A23a (D20).
- **Measurement list and graph screens move to `features/progress/`** (D24). `ChartWindow`/`GraphRange` live in `features/progress/application/graph_window.dart`, and body → progress would be a cycle (progress already imports body). Data, ops, actions and the sheets stay in `features/body/`. This mirrors A15a's weight graph.
- **`AppRouter.outsideTabs` exists** (A13b), so `WeightHistoryRoute` is just added to it. The router gains a body-barrel import.
- **Custom measurements are lengths** (cm/in), and body fat is the only percent kind (D13). The prepared plan left this open.
- **`EntryTime.fromLocal(LocalDateTime, Clock)`** exists (DST-safe), so past rows use it for 08:00 local (D17).
- **`ChangeSet.maxOps` = 500** (`fb_domain/src/changes/change_op.dart`) bounds a batch at 500 rows (D17).
- **WB-043 is already on A40's Spec line.** This card's Spec and Scope now mark it moved (PA10).
- **WPs renumbered in execution order**: the contract and tables become separate WPs (one commit each). Old → new: WP6 → WP6, WP8 → WP7, WP7 (contract) → WP8, WP7 (tables) → WP9, WP9 → WP10, WP10 → WP11.
- **Backlog #165** (the A15a weight graph UX pass) is folded into the Codex review's UX checklist (owner rule: Codex-only reviews). **#164** (the A55 pan run) stays an owner item at this close.

#### Decisions (A15b)

| # | Decision | Reason |
|---|---|---|
| D13 | **Storage, in `core/db/tables/body_tables.dart`.**<br>• **`measurement_types`** (`MeasurementTypeRow`, entity `measurementType`, UUIDv7, custom types only): `SyncColumns` + `name` TEXT NOT NULL.<br>• **`measurements`** (`MeasurementRow`, entity `measurement`, UUIDv7): `SyncColumns` + `kind` TEXT NOT NULL CHECK IN ('waist','chest','hips','arm','thigh','neck','bodyFat','custom') · `custom_type_id` TEXT NULL (no FK: synced) · `measured_at_utc` INT NOT NULL CHECK ≥ 0 · `tz_offset_min` INT NOT NULL CHECK −720…840 · `local_date` TEXT NOT NULL · `value` REAL NOT NULL CHECK ≥ 0 (cm, or % for `bodyFat`) · `input_value` REAL NOT NULL CHECK ≥ 0 · `input_unit` TEXT NOT NULL CHECK IN ('cm','in','percent') (TD-017).<br>• **Local CHECKs equal the wire** (the weigh_ins convention: never stricter than admission). There's no CHECK on the semantic pairs (D14 rules M1–M3); the handler enforces them on writes and the mappers tolerate them on reads.<br>• Partial index `ix_measurements_live (kind, custom_type_id, local_date, measured_at_utc) WHERE deleted_at IS NULL` in `body.drift`.<br>• Three outbox triggers per table in `sync_triggers.drift`.<br>• Built-in types are code, not rows. **Custom types are lengths (cm/in).** No note column, and no left/right for arm/thigh (a custom "Left arm" covers it). The time is an `EntryTime` (DY-002); the form shows the date only | `05` §2.2, TD-017. A closed vocabulary keeps the wire expressible (TD-080). One value column with the unit implied by the kind keeps graphs simple |
| D14 | **Contract (own commit first, WP8): `feat(contract): measurementType and measurement sync entities`.**<br>• `contracts/openapi/sync-entities.json`:<br>  – `measurementType` v1 = `createdAtMs`, `origin`, `editedByUser`, `name` (string, maxLength 120);<br>  – `measurement` v1 = the same three + `kind` (enum of the 8 codes), `customTypeId` (`["string","null"]`, format uuid), `measuredAtUtc` (integer 0…2^53−1), `tzOffsetMin` (integer −720…840), `localDate` (date), `value` and `inputValue` (number 0…1e6), `inputUnit` (enum `cm`/`in`/`percent`).<br>  – All properties required, `additionalProperties: false`.<br>• Fixtures: one built-in `waist` payload per entity in `contracts/testdata/sync/entity-payloads.json` (schema-1 file; every C# all-fixture loop then covers them). `contracts/testdata/sync/measurement-payload-variants.json` holds `bodyFat` in %, a custom measurement in inches and a 120-unit type name (the `targets-payload-variants.json` pattern).<br>• `make gen-sync-schemas` regenerates `backend/src/Modules/UserData/Infrastructure/Schemas/entities.json` (never hand-merged).<br>• **`contracts/README.md` § "Measurement semantic rules" is the single source B20 admits:**<br>  – **M1 custom type:** `customTypeId` is non-null exactly when `kind` = `custom`.<br>  – **M2 unit fits kind:** `inputUnit` = `percent` exactly when `kind` = `bodyFat`, else `cm`/`in`.<br>  – **M3 percent bound:** a `bodyFat` `value` and `inputValue` are at most 100.<br>  – **Not wire rules:** local plausibility (D15), `value` = `inputValue` × factor, `localDate` ↔ `measuredAtUtc`, the custom type existing or being live, name uniqueness (cross-row, TD-089 style).<br>  – **Tombstones** keep full payloads under the same rules. A new built-in kind is a new `measurement` schemaVersion, server validator first (TD-080).<br>• `contracts/testdata/README.md` documents the variants file. `05` §5.5 entity list + one line.<br>• No OpenAPI path or generated-client change: `make gen` touches only `entities.json` | Contract-first (rule 4), the A13a WP1 / B19 WP1 precedent. Additive, so no owner gate |
| D15 | **Domain and write path.**<br>• **`fb_domain/src/body/measurement.dart`:**<br>  – `MeasurementKind` (8, with `code`, `isLength`);<br>  – `MeasurementTypeRef {kind, customTypeId?}` with a stable `key` (`waist` … or `custom-<uuid>`, for routes and providers);<br>  – `MeasurementInput {value, unit: MeasurementUnit {cm, inch, percent}}`, canonical value = `StoragePrecision.round(value × factor)` (inches via `LengthUnit.inch`);<br>  – `MeasurementDraft {type, time: EntryTime, input}` + `validate()` → `MeasurementIssue {unit, outOfRange, customWithoutType, time}`;<br>  – `Measurement {id, version, type, time, localDate, value, input}`, `MeasurementType {id, version, name}`.<br>• **Local-write bounds** (`MeasurementBounds`): lengths **10–300 cm** (3.9–118.1 in), body fat **2–75 %**, future tolerance 5 min.<br>• **`CustomTypeName.validate`:** trimmed, 1–40 characters, no `\p{Cc}` (`\p{Cf}` allowed). **Live-name uniqueness is case-insensitive, compared in Dart** (`trim().toLowerCase()`, not SQL `NOCASE`; PA15).<br>• `toString()` never shows values or names.<br>• **Ops (`measurement_ops.dart`, family `measurement`):**<br>  – `CreateMeasurement(id, draft)`;<br>  – `UpdateMeasurement(id, expectedVersion, draft)` (an identical draft writes nothing);<br>  – `DeleteMeasurement(VersionedId)`;<br>  – `CreateMeasurementType(id, name)`;<br>  – `RenameMeasurementType(id, expectedVersion, name)`;<br>  – `DeleteMeasurementType(VersionedId type, List<VersionedId> measurements)`: exact live membership at the shown versions, else `InvalidOp('sourceChanged')`; tombstones all atomically.<br>• **`MeasurementOpHandler`** (`features/body/data/`, registered in `app/app_scope.dart`):<br>  – drafts validated in the transaction;<br>  – `InvalidOp('invalidDraft')`, `('time')` (< 1970), `('future')` (> now + 5 min), `('unknownType')` (missing or tombstoned type), `('duplicateName')`;<br>  – one read per op; no custom events (`ChangeSetApplied(entities: {'measurement','measurementType'})`).<br>• **`UpdateMeasurement` keeps the type** (a changed `draft.type` → `InvalidOp('typeChanged')`); moving an entry to another type is delete + create.<br>• **Revert guards (PA1).** Undo bypasses the handler's forward checks, so every op returns `OpPlan.revertGuards` (the workout pattern: `workout_op_handler.dart` `_notInUse` / `_referencedAfter`, run read-only by `ChangeSetApplier.revert` before any inverse write). Each guard evaluates the **state after the inverse**: live rows now, minus the rows the inverse tombstones or restores to something else, plus the rows it restores live.<br>  – `CreateMeasurementType` → `_typeNotInUse(id)`: a live measurement still points at the type after the undo → `InvalidOp('typeInUse')`.<br>  – `DeleteMeasurement`, `UpdateMeasurement` (restore of a live custom measurement) → `_typeLiveAfter`: its custom type must be live after the undo → `InvalidOp('unknownType')`.<br>  – `RenameMeasurementType`, `DeleteMeasurementType` (restore of a live type name) → `_nameUniqueAfter`: no other live type has the same trimmed, lower-cased name after the undo → `InvalidOp('duplicateName')`.<br>  – A guard failure rejects the whole undo; nothing is written and no outbox row is added. Version conflicts are the applier's own check.<br>  – Weigh-in batches have no references, so `logMany` needs no guard (its undo is plain tombstones).<br>  – Rows applied by sync (A34) never pass through handlers; D25's tolerant reads cover them.<br>• Every UI write is a direct action with undo (UX-030). Deleting a custom type **with entries** asks first, and is still undoable | The A14 op shape, so A29's chat and import proposals reuse it unchanged. The guards keep undo from orphaning or duplicating what forward writes refuse |
| D16 | **Series and graphs (WB-041/042; PA14).**<br>• **Extract A14's smoothing loop** into `smoothDaily(List<(LocalDate, double)> dayValues, TrendWeightConfig config) → List<double>` (`fb_domain/src/body/smooth_daily.dart`). `TrendWeight.compute` delegates with identical numbers: A14's tests stay unchanged, plus an equality test.<br>• `MeasurementSeries.of(measurements)` = all points + day choices (earliest per `local_date`, ties by id) + `smoothDaily` over the day choices, **shown only when the type has ≥ 5 points (entries)**, WB-041 as written (PA4). 5 entries on fewer than 5 days still show a trend over their day choices. No rate, no projection.<br>• A type's graph: dots + trend line, range chips **All by default**, no goal/cone/phases (A16 adds IN-009).<br>• Header: "Latest 92.0 cm · {date}" and "−3.5 cm since {first date}". Body fat has a % axis | One smoothing for every body series. TD-088's numbers unchanged |
| D17 | **Multi-row weight history (PA12, PA13).**<br>• **Screen and entry points:** `WeightHistoryScreen` (`features/body/presentation/`), **`WeightHistoryRoute` `/weight-history` in `AppRouter.outsideTabs`**, opened from the weight graph's AppBar action "Add past weigh-ins" and a secondary action in its empty state.<br>• **Rows:** unit chips (kg/lb, default from the unit setting). Each row is a date chip (≤ today) + an `FbNumberField` value + remove. The first row starts without a date (the picker opens on today); "Add row" dates the next one **previous + 7 days, capped at today**.<br>• **Time:** `EntryTime.fromLocal(date 08:00, clock)`; **a row dated today gets `min(08:00, now)`** (`WeighInBatch.timeFor`).<br>• **Pure `WeighInBatchCheck`**, rows checked in date order:<br>  – **blocking** `incomplete` / `outOfRange` / `future` (Save disabled);<br>  – **excluded until "Keep"**: `duplicate` (a live weigh-in, or an earlier row, on that date within 0.05 kg) and `implausible` (A14 `WeighInCheck` against existing ∪ earlier *included* rows; `LikelyOtherUnit` offers "Use lb/kg");<br>  – **info**: `sameDay` (an existing weigh-in that date with another value: the row stays included, and the line explains the earliest-of-day rule).<br>• **Build and apply are split:** pure `WeighInBatch.ops(drafts, ids) → List<CreateWeighIn>`; `WeighInActions.logMany` wraps them in one `ChangeSet(origin: direct)` with **one undo entry** ("12 weigh-ins added · Undo").<br>• **Limits:** ≤ 500 rows (`ChangeSet.maxOps`). Nothing typed is lost on error (UX-052). Leaving with typed rows asks first (a body-local discard sheet: foods' sheet is feature-private).<br>• **A29 reuses** `WeighInBatchCheck` + `WeighInBatch.ops` as a confirmed import proposal | Needed for the owner sign-off. One atomic write. The proposal path reuses the builder |
| D18 | **Measurement screens and sheets.**<br>• **`MeasurementsScreen`** (`/progress/measurements`): rows for waist, chest, hips, arm, thigh, neck, body fat, then custom types by name (latest value + date, or "No entries yet"). Primary "Add measurement" → `showMeasurementSheet` with type chips; "Add custom measurement" → `showCustomTypeSheet`.<br>• **`MeasurementTypeScreen`** (`/progress/measurements/:type`, `type` = `MeasurementTypeRef.key`; an unknown or deleted key shows "This measurement was removed"): graph + selection details (the A15a D9 pattern: value as typed, date, Edit) + entries newest first (`FbSwipeActions` delete with undo; tap → edit). Custom types get a menu with Rename / Delete type.<br>• **`MeasurementSheet`** (`FbSheet`, pinned Save): value pad prefilled with the type's latest value; unit chips (cm/in from the unit setting, LC-010; body fat fixed %); a date chip (≤ today; today → now, a past date keeps the edited time of day or 08:00 local); Delete in edit mode.<br>• **Edit ≠ create (PA3):** an edit opens with the row's **exact** input value, unit, instant and stored offset (no latest-value prefill, no unit-setting default, no "now"). Until the user changes a field, the stored value is kept as is (the `weigh_in_form.dart` rule: an untouched prefill saves the stored input, so 92.25 isn't rounded by the pad), and open + Save writes nothing (`MeasurementUnchanged`, no undo entry). A date-only change keeps the local time of day and the row's own offset (`EntryTime.onDate`, A06 D6).<br>• `CustomTypeSheet` for name create/rename.<br>• UX-050–052 states. **No reminder switch** (PA10 → A40) | WB-040's form path in A14's sheet style |
| D20 | **Schema v10 and the A23a dependency.** A15b takes **v10**: `migrations/from_9_to_10.dart` (two `createTable`s, `createIndex(ixMeasurementsLive)`, six triggers), `stepByStep(... from9To10:)`, `schemaVersion => 10`, dump `drift_schema_v10.json`, `test/drift/user/generated/schema_v10.dart`.<br>**WP9 starts with `git fetch && git merge origin/main`.** If A23a (v9) is on main, build v10 on top of it.<br>**If it isn't:** WP9 builds v9 locally (`from_8_to_9`), and the **renumber recipe** runs right after A23a lands, before any merge (a Sonnet chore):<br>  1. Merge `origin/main`, keeping A23a's `from_8_to_9.dart`, `drift_schema_v9.json`, `schema_v9.dart` untouched (frozen).<br>  2. Drop A15b's v9 dump and generated schema. Rename the migration to `from_9_to_10.dart`, its function `from8To9` → `from9To10` and its parameter `Schema9` → `Schema10` (conventions as in `from_7_to_8.dart`).<br>  3. Set `schemaVersion` and the `stepByStep` line; union `tables:` / `syncedTables` / `include:`.<br>  4. `tools/scripts/heavy.sh make db-migrations`; fix `_from`/`_to` and the `schema_vN` imports in `measurement_migration_test.dart`.<br>  5. Union `export_registry.dart`, `export_snapshot.dart`, `sync_triggers.drift`, `app_scope.dart`, `docs/export-format.md`, `sync_triggers_test.dart`, `export_test.dart`.<br>  6. Keep `measurement_migration_test.dart`'s v9-rows-and-queued-outbox preservation case, now on A23a's v9.
  7. `tools/scripts/check-frozen-migrations.sh` after `git fetch origin main`; `make gen-check check-dart`.
  8. **Never reuse a database from a provisional A15b-v9 build** (emulator, A55 dev install): its v9 isn't A23a's v9. Wipe or uninstall before running a v10 build.<br>The contract commit (D14) doesn't renumber | The A14 D11 protocol. A15b merges after A23a (orchestrator ordering) |
| D23 | **Server admission is a separate backend step, B20 "Measurement sync entities (server)"** (Risky, M; depends on B05, B19, **A15b (contract)**).<br>• **B20 scope:** a `MeasurementPayloadValidator` for exactly D14's M1–M3 (B19's fail-closed dispatch by entity and version, one hook line in `SyncPayloads.InvalidReason`); a Dart-generated corpus `contracts/testdata/sync/measurement-validation-vectors.json` with app parity through A15b's real mappers and writers; C# pure + Testcontainers tests (push, pull, LWW + history, tombstones/fences, RLS, guest 403, erasure, a privacy canary with a custom type name); a security review.<br>• **A34 gains B20** as a dependency: nothing uploads measurements before B20.<br>• Until B20, the server admits the two entities by schema only (the generic path; A15b's fixtures run through the existing C# all-fixture loops in CI). Nothing uploads yet (A34), so this isn't a security trade-off.<br>• **Deploy hold (PA5):** generic admission would accept rows that break M1–M3. So no live server, the B03 laptop server included, takes a build carrying WP8's registry until B20 is merged. The orchestrator records the hold in the backlog and in B20's card.<br>• **A15b doesn't touch `backend/`** except the generated `entities.json` | TD-095: A15b is already L (~2.8 sessions); with the server part (~1.5) it would be ~4.3, above L. `13` §10: a feature needing both tracks is one step per track. B17/B18/B19 are the precedent. Backlog #189 (workout entities) stays separate (rec): its contract isn't designed yet |
| D24 | **Feature placement.**<br>• **`features/body/`:** measurement data (mappers, handler, repository), providers, actions, `MeasurementSheet`, `CustomTypeSheet`, `measurement_text.dart`, the weight history screen and form. The body barrel exports the providers, actions, `showMeasurementSheet`, `showCustomTypeSheet`, `measurement_text.dart` and `WeightHistoryScreen`.<br>• **`features/progress/`:** `MeasurementsScreen`, `MeasurementTypeScreen`, `measurement_graph_providers.dart` (a session-only window per type key; reuses `ChartWindow`/`GraphRange`). It extracts A15a's private range chips into `presentation/graph_range_chips.dart` (the weight graph uses it unchanged).<br>• Only barrels across features; presentation never imports `data/` or `core/db` | One-way dependencies (progress → body), as in A15a D11 |
| D25 | **Tolerant reads.** `measurementOf(row)` / `measurementTypeOf(row)` throw a content-free `MeasurementMappingError` for:<br>• an unknown kind or unit;<br>• an M1/M2/M3 mismatch;<br>• a non-finite value, or one ≤ 0 or > 1e6;<br>• a malformed date;<br>• an empty trimmed name.<br>Repositories skip and count such rows, never log values, and **hide measurements whose custom type is missing or tombstoned** (a sync race; `DeleteMeasurementType` keeps local writes consistent). Two live types with the same name, possible after sync, are both shown | The A14/A13a tolerant-read convention: a synced row never crashes a screen |
| D26 | **Copy (PR-12, SF-020–022).**<br>• Neutral words only ("change", "trend", "latest"). No praise, no red/green for direction.<br>• ARB blocks `weightHistory*` and `measurement*` after the `weightGraph*` block.<br>• Values formatted by `weight_text.dart` and a new `measurement_text.dart` (one decimal, the unit as typed or the setting's).<br>• The body-fat label is "Body fat" with the unit "%". No health judgement on any value | `CLAUDE.md` rule 8. A13's SF-020 guard covers the new strings |

**⚠️ OWNER items** (collected; they don't block the merge, TD-037):
1. **Real-history sign-off** (exit 2): "the weight graph renders my real history with every overlay; this replaces my note". The owner enters the history on the A55 through the new screen (or hands it over), then looks at the graph. Tracked as a backlog row and as the M2 gate (A16).
2. **A55 2-year profile pan run** (exit 5, backlog #164; method in A15a D22): recorded in this card's Progress log.

**No owner gate:** no spec change (WB-041's "≥ 5 points" applied as written; WB-043 only moved steps), no Accepted-TD change (TD-080 applied as written; TD-088 reused unchanged), no vendor or cost, no security trade-off (D23). **Owner FYI:** the new B20 step; custom types are lengths; one value for arm/thigh; body-fat local range 2–75 %; past weigh-ins default to 08:00.

**TD candidate: TD-103 (next free after TD-102) "Body measurements model"**, Proposed in WP9 (number confirmed at merge):
- built-in kinds are a closed wire enum, and custom types are synced rows;
- lengths are canonical in cm, body fat in %, with the input as typed;
- M1–M3 are TD-080 wire rules, admitted by B20;
- the measurement trend is TD-088's smoothing over day choices, shown from 5 points (WB-041), with no rate;
- undo of measurement ops is guarded on the post-undo state (references and local name uniqueness).

#### Design

**Contract diff** (`contracts/openapi/sync-entities.json`, additive):
```jsonc
"measurementType": { "1": { "type":"object", "additionalProperties":false,
  "required":["createdAtMs","origin","editedByUser","name"],
  "properties":{ /* createdAtMs, origin, editedByUser as every entity */ "name":{"type":"string","maxLength":120} } } },
"measurement": { "1": { "type":"object", "additionalProperties":false,
  "required":["createdAtMs","origin","editedByUser","kind","customTypeId","measuredAtUtc","tzOffsetMin","localDate","value","inputValue","inputUnit"],
  "properties":{ /* metadata */
    "kind":{"type":"string","enum":["waist","chest","hips","arm","thigh","neck","bodyFat","custom"]},
    "customTypeId":{"type":["string","null"],"format":"uuid"},
    "measuredAtUtc":{"type":"integer","minimum":0,"maximum":9007199254740991},
    "tzOffsetMin":{"type":"integer","minimum":-720,"maximum":840},
    "localDate":{"type":"string","format":"date"},
    "value":{"type":"number","minimum":0,"maximum":1000000},
    "inputValue":{"type":"number","minimum":0,"maximum":1000000},
    "inputUnit":{"type":"string","enum":["cm","in","percent"]} } } }
```

**fb_domain** (pure, exported from `fb_domain.dart`, 100 % coverage, no `DateTime.now()`):
```
src/body/smooth_daily.dart       smoothDaily(dayValues, config); TrendWeight.compute delegates (PA14)
src/body/measurement.dart        MeasurementKind, MeasurementUnit, MeasurementTypeRef(.key/.parse), MeasurementInput,
                                 MeasurementDraft(+validate), MeasurementBounds, CustomTypeName, Measurement, MeasurementType
src/body/measurement_ops.dart    MeasurementOp family (6 ops, D15)
src/body/measurement_series.dart MeasurementSeries.of → points, dayChoices, trend? (≥ 5 points)
src/body/weigh_in_batch.dart     WeighInBatchRow, WeighInRowFlag {incomplete,outOfRange,future,duplicate,implausible,sameDay},
                                 WeighInBatchCheck.check(rows, existing, today, timeFor), WeighInBatch.timeFor(date, clock),
                                 WeighInBatch.ops(drafts, ids)
README.md                        "Measurements" section + the smoothDaily note under "Weight trend"
```

**App (`apps/mobile/lib/`)**
```
core/db/tables/body_tables.dart        + MeasurementTypes, Measurements, entity consts       [WP9]
core/db/body.drift                     + ix_measurements_live
core/db/sync_triggers.drift            + 6 triggers
core/db/app_database.dart (+ .g/.steps) tables, syncedTables +2, schemaVersion 10, from9To10
core/db/migrations/from_9_to_10.dart   · drift_schemas/user/drift_schema_v10.json
core/export/export_registry.dart       + 2 specs · core/db/export_snapshot.dart order ('measurement' by local_date,
                                       measured_at_utc, id) · docs/export-format.md columns
app/app_scope.dart                     + MeasurementOpHandler(db)
features/body/data/measurement_mappers.dart     measurementOf, measurementTypeOf, columns writers (D25)
features/body/data/measurement_op_handler.dart  (D15)
features/body/data/measurement_repository.dart  watchTypes(), watchMeasurements() (live, readable, type live)
features/body/application/measurement_providers.dart  measurementTypesProvider, measurementsProvider,
                                       measurementSeriesProvider(key), latestByTypeProvider
features/body/application/measurement_actions.dart    log/update/delete/createType/renameType/deleteType;
                                       typed outcomes; pending-key double-submit guard (the WeighInActions shape)
features/body/application/weigh_in_actions.dart       + logMany(drafts) [WP7]
features/body/application/weight_history_form.dart    pure reducer: rows, unit, keep flags, check results [WP7]
features/body/presentation/weight_history_screen.dart · weight_history_discard_sheet.dart [WP7]
features/body/presentation/measurement_sheet.dart · custom_type_sheet.dart · measurement_text.dart [WP10]
features/body/body.dart                exports (D24)
features/progress/presentation/measurements_screen.dart · measurement_type_screen.dart · graph_range_chips.dart [WP10]
features/progress/application/measurement_graph_providers.dart [WP10]
features/progress/presentation/weight_graph_screen.dart  AppBar action + empty-state action → WeightHistoryRoute [WP7]
features/progress/presentation/progress_screen.dart      + Measurements row [WP10]
core/navigation/app_route.dart         WeightHistoryRoute [WP7]; MeasurementsRoute, MeasurementTypeRoute(key) [WP10]
app/router/app_router.dart             outsideTabs += WeightHistoryRoute; progress branch nests both measurement routes
l10n/app_en.arb (+ gen)                weightHistory*, measurement*
```

**Data flow and rules.**
- **Writes:** sheet/screen → `MeasurementActions` / `WeighInActions.logMany` → `ChangeSetApplier` (single writer) → drift. The outbox triggers capture the change, and the undo stack records it.
- **Reads:** drift → repository streams → providers → screens (`03` §2).
- **Barrels only;** presentation never touches `data/` or `core/db` (`make app-check`).
- **Nothing reaches the network** (local-first). The outbox rows wait for A34 (after B20).
- **No user content in logs:** mapper errors and `toString` are content-free.

#### Work packages
**One `flutter-engineer` builds every WP in order** (TD-095; the contract WP is JSON plus codegen, as in B19 WP1), one commit each, plus a Progress-log line and a push per WP. Each WP is done when:
- `make gen-check check-dart` is green (WP8 also runs `make check-dotnet`), with `git diff --check`;
- its tests are written (named in the test list) and green in **CI on the pushed branch**. No local test runs; on a CI failure, reproduce only the failing tests through `tools/scripts/heavy.sh` with `timeout 600`.

Goldens are generated as codegen, file by file, **only those the change affects** (PA8): `tools/scripts/heavy.sh timeout 600 flutter test --update-goldens --tags golden <file>`. Images are reviewed, then committed.

| WP | Tasks · files | Done when |
|---|---|---|
| **WP6 · Domain** `feat(body): shared daily smoothing, measurement model and batch weigh-ins` | `smooth_daily.dart` (+ `TrendWeight.compute` delegating), `measurement.dart`, `measurement_ops.dart`, `measurement_series.dart`, `weigh_in_batch.dart`, barrel exports, README; tests §5.5 | §5.5 in CI; fb_domain coverage gate 100 %; A14's `trend_weight_test.dart` unchanged |
| **WP7 · Weight history entry** `feat(body): add past weigh-ins in one go` | `logMany`, `weight_history_form.dart`, `weight_history_screen.dart`, discard sheet, `WeightHistoryRoute` (outsideTabs) + router body import, weight graph AppBar action + empty-state action, ARB `weightHistory*`; tests + goldens §5.7a; regenerate `weight_graph_states`/`weight_graph_ranges` goldens (AppBar action) | §5.7a in CI; router location test lists `/weight-history` |
| **WP8 · Contract** `feat(contract): measurementType and measurement sync entities` | D14: `sync-entities.json`, `entity-payloads.json`, `measurement-payload-variants.json`, `make gen-sync-schemas` → `entities.json`, `contracts/README.md` § Measurement semantic rules, `contracts/testdata/README.md`, `05` §5.5 line; Progress-log line naming the change. **Must not contain** app or C# code changes | `make gen` leaves no diff beyond `entities.json`; `make check-sync-schemas`, `make check-contract`, `make check-dotnet` locally; CI `dotnet` job green (the all-fixture admission, UTF-16 coverage, production round-trip and account-deletion loops now include both entities) |
| **WP9 · Tables, migration, write path** `feat(body): measurement tables (schema v10) and write path` | First `git merge origin/main` (D20). D13 tables, index, triggers, `app_database.dart`, `from_9_to_10.dart`, `heavy.sh make db-migrations`, `make gen-app`; mappers, handler, repository, `app_scope.dart`, export registry/snapshot, `docs/export-format.md`; TD-103 row (Proposed) in `12-decisions-and-questions.md`; tests §5.6 | §5.6 + existing AC-012/AC-030 loops in CI; `tools/scripts/check-frozen-migrations.sh`; `make app-check` |
| **WP10 · Measurement screens** `feat(body): body measurements with graphs per type` | providers, actions, `MeasurementSheet`, `CustomTypeSheet`, `measurement_text.dart`, body barrel; progress `MeasurementsScreen`, `MeasurementTypeScreen`, `measurement_graph_providers.dart`, `graph_range_chips.dart` (extracted; weight graph uses it), routes + Progress row, ARB `measurement*`; tests + goldens §5.7b | §5.7b in CI |
| **WP11 · Device journeys and close** `test(body): measurement and weight history journeys [it]` | `patrol_test/measurements_test.dart` (2 journeys); grep `patrol_test/` for Progress/weight graph finders the new AppBar action or row could shift (memory rule); `tools/scripts/heavy.sh make build-it`; backlog rows (owner sign-off; B20 handoff); close commit **`[it]`** | `android-it` green (25-min budget; a never-green journey may need one fix round) |
| **Close** (orchestrator) | **Codex review (code + security, Risky)**, read-only, whole diff, including the #165 UX checklist for the weight graph and these screens. Fixes by the engineer. The orchestrator writes `evidence/A15b-verification.md` from Codex's security findings, then the Outcome, board, backlog (#164 recorded or still owner, #165 closed, the D23 deploy hold), and the B20 card (from D23, with the hold). Merge after A23a via `tools/scripts/merge-step.sh A15b "Weight history entry & measurements" step/A15b-weight-history-measurements` (background; one merge at a time) | No open blocker/major; CI green on the merge commit |

#### Test list (spec ID first, `10` §5)

**§5.5 Domain** (`packages/fb_domain/test/body/`)
- `WB-010 smoothDaily gives exactly TrendWeight's trend values for the same day choices` (PA14)
- `WB-040 built-in kinds are waist, chest, hips, arm, thigh, neck and body fat; custom types are named lengths`
- `WB-040 a length typed in inches is stored in cm, rounded once, and shown back as typed`
- `WB-040 MeasurementDraft rejects lengths outside 10–300 cm, body fat outside 2–75 %, non-finite values, percent on a length, cm on body fat, a custom kind without a type and a time before 1970`
- `WB-040 custom type names are trimmed, 1–40 characters, no control characters, ZWJ/RLM allowed, unique ignoring case including non-ASCII letters` (PA15)
- `WB-040 measurement ops: value equality, uuid and version checks; DeleteMeasurementType carries its measurements`
- `WB-041 a series has no trend below 5 points and a smoothed trend from 5` · `WB-041 5 entries spanning fewer than 5 days show a trend` (PA4) · `WB-041 several entries on one day are all points; the earliest feeds the trend`
- `WB-042 body fat is a percent series`
- `measurement types, drafts and ops toString show no values or names`
- `WB-005 WeighInBatchCheck blocks incomplete, out-of-range and future rows`
- `WB-005 WB-031 a duplicate of an existing weigh-in or of an earlier row is excluded until kept`
- `WB-005 a row unit mix-up (214 after 97 kg) is implausible and suggests lb; a 4 % jump within 7 days asks; kept rows become references for later rows`
- `WB-003 a row on a date with a different existing weigh-in gets the sameDay info flag and stays included` (PA13)
- `WB-003 WeighInBatch.timeFor gives 08:00 local on past dates, min(08:00, now) today, and the right offset across a DST change`
- `WB-001 WeighInBatch.ops builds one CreateWeighIn per included row with the given ids, at most 500`
- `WB-031 a Keep is cleared when its row's date, value or unit changes, or when an earlier row or existing weigh-in it was checked against changes` (PA6)
- `WB-031 zero included rows (all excluded or blocked) give nothing to save` (PA6)

**§5.6 Data** (`apps/mobile/test/drift/user/`, `test/features/body/data/`, `test/features/body/application/`)
- `A15b migration v9→v10 keeps every v9 row and queued outbox entry and adds measurement_types and measurements with their index and six triggers` (`measurement_migration_test.dart`; `migration_test.dart` loops every version)
- `A15b the measurementType and measurement fixtures and variants map 1:1 to the table columns by snake_case, both directions; every content column is on the wire` (PA6 tripwire)
- `WB-040 CreateMeasurement writes value, input, time, local date and one outbox row`
- `UX-030 undo of CreateMeasurement tombstones the row` · `UX-030 DeleteMeasurement tombstones the row and undo restores its content`
- `UpdateMeasurement with a stale version is rejected and writes nothing; an identical draft writes nothing`
- `a custom measurement whose type is missing or deleted is rejected (unknownType)`
- `a measured time more than 5 minutes ahead is rejected (future); before 1970 (time); an invalid draft (invalidDraft)`
- `a duplicate live custom type name is rejected regardless of case; a stale rename is rejected` (PA15)
- `WB-040 UX-030 DeleteMeasurementType tombstones the type and its measurements atomically; changed membership is rejected; undo revives all`
- `UX-030 AC-012 undo of every measurement op restores the user-visible content with a newer version and HLC, writes valid inverse metadata (origin, updated_hlc) and appends one new outbox row per touched row; created rows become tombstones` (PA2, per `row_writer.dart`)
- `UX-030 an undo that conflicts with a later edit is rejected atomically: nothing written, no outbox row` (PA2)
- `UX-030 create type → add measurement → undo the type creation is rejected (typeInUse) and writes nothing; undoing the measurement first, then the type, succeeds` (PA1)
- `UX-030 delete a measurement → delete its type → undo the measurement deletion is rejected (unknownType); undoing the type deletion first, then the measurement, restores both` (PA1)
- `UX-030 rename a type → create a new type with the old name (any case) → undo the rename is rejected (duplicateName)` · `delete a type → create one with its name → undo the deletion is rejected (duplicateName)` (PA1)
- `an UpdateMeasurement that changes the type is rejected (typeChanged)`
- `watchMeasurements emits a type's live rows by date, time and id; a measurement of a missing or deleted type is hidden`
- `tolerant read: an unknown kind, an M1/M2/M3 mismatch, a non-finite or zero value or an empty name skips the row and counts it; nothing logged` (D25)
- `WB-001 UX-030 logMany applies the batch with one undo entry; undo tombstones every created row with a newer version and one new outbox row each; a refused row writes nothing; an undo after one of the rows was edited is rejected atomically` (PA2)
- `D25 a measurement that arrives before its custom type is hidden until the type arrives; a tombstoned type hides its measurements` (PA6)
- `AC-030 export is table-level: an orphan measurement (type missing or deleted) is still exported with its custom_type_id` (PA6)
- existing `AC-012 every synced table has insert/update/no-delete outbox triggers` · `AC-030 every synced table has an export spec` · `AC-030 every column is exported or excluded with a reason` · `docs/export-format.md lists every file.column` + new `AC-030 export includes measurement types and measurements`

**§5.7a Weight history UI** (`test/features/body/`)
- `WB-001 weight history: rows with a date and value; Save adds them with one undo and the graph shows them`
- `WB-005 WB-031 weight history: a duplicate or a large jump is excluded until Keep; Use lb fixes a mix-up; a same-day different value shows an info line` (PA13)
- `UX-052 weight history: incomplete, out-of-range or future rows disable Save; leaving with typed rows asks first; nothing typed is lost after a refused save`
- `LC-010 weight history defaults to the unit setting and accepts the other unit`
- `UX-013 weight history opens outside the tabs from the graph's action and its empty state; Back returns to the graph` (PA12)
- Goldens `weight history: empty · flagged rows` (light/dark × 1.0/2.0); regenerated `weight_graph_states`, `weight_graph_ranges`

**§5.7b Measurement UI** (`test/features/body/presentation/`, `test/features/progress/`)
- `WB-040 adding a waist measurement from the form shows it in the list and on its graph`
- `WB-040 UX-030 editing a measurement; deleting with undo from the list and from the sheet`
- `WB-040 editing an older entry while a newer one exists opens with the older entry's exact value, unit, date, time and offset` (PA3)
- `WB-040 opening an entry and saving without a change writes nothing and adds no undo entry` (PA3)
- `WB-040 a date-only change keeps the value as stored, the local time of day and the row's offset` (PA3)
- `WB-040 add, rename and delete a custom type; deleting one with entries asks first; undo restores type and entries`
- `WB-041 each type has its own graph; the trend line appears from 5 points`
- `a measurement graph orders points by wall-clock x across a DST rollback` (PA6, the A15a review major)
- `WB-022 tapping a measurement point shows its value as typed and date, and Edit opens the sheet`
- `WB-042 body fat is entered in % and has its own graph with a % axis`
- `LC-010 the imperial setting defaults lengths to inches; a value typed in cm stays cm`
- `UX-050 measurements empty state` · `a type with no entries invites the first one` · `UX-051 loading` · `UX-052 error shows Try again`
- `UX-013 the Progress tab's Measurements row opens the list; a type row opens its graph; Back returns`
- `a removed type's route shows the removed state`
- Goldens `measurements list: empty · with data` · `measurement type: no trend · trend · body fat` · `measurement sheet: length · body fat · edit` · `custom type sheet` (light/dark × 1.0/2.0)

**Patrol** (`patrol_test/measurements_test.dart`, `[it]`): `A15b measurements: add, edit, delete with undo, custom type graph` · `A15b weight history: add three past weigh-ins, see them on the graph, undo`.

**Contract (WP8, CI):** `make check-sync-schemas`, `make check-contract`, and the existing C# loops `All_current_entity_fixtures_still_pass_schema_admission`, `Ill_formed_utf16_cases_cover_chat_proposal_and_weighIn_note` (registry coverage), `Every_current_entity_round_trips…` and the account-deletion fixture loop, now over both new entities.

#### Exit-criteria mapping (A15b's share)

| Exit criterion | Demonstrated by |
|---|---|
| The weight graph renders the owner's real history with every overlay; owner sign-off | §5.7a (history saved and shown on the graph) + A15a's overlay tests/goldens; **⚠️ OWNER** check on the A55 after entering the history (collected; backlog row; M2 gate in A16) |
| Measurements: add, edit, delete with undo; graphs per type | §5.6 write-path and undo tests, §5.7b UI tests, Patrol `A15b measurements …` |
| Rendering 2 years of daily points stays smooth on the A55 | A15a's host caps, benchmark and Patrol timings (done); **⚠️ OWNER** profile run #164, recorded in the Progress log (stays ⚠️ until then) |
| (TD-012; goldens per range; tooltip test) | Done in A15a |

#### Risks & unknowns

| Risk | Handling |
|---|---|
| **A23a's v9 lands after WP9 starts** (lane 1) | D20: merge `origin/main` first, else build v9 and renumber before merge. A15b merges after A23a. Shared files, unioned at merge: `app_database.dart` (+ gen), `generated/schema.dart`, `app_scope.dart`, `sync_triggers.drift`, `export_registry.dart`, `sync_triggers_test.dart`, `export_test.dart`, `docs/export-format.md`, `fb_domain.dart`, TD table. A15b never touches buddy/chat/proposals files or the B18 corpus |
| **Server admits measurements by schema only until B20** | Nothing uploads before A34; A34 depends on B20 (board). **Deploy hold** (D23/PA5): no live server, B03 included, takes WP8's registry before B20 |
| **Board / `PROGRESS.md`** (lane 2's `chore/progress-page` adds a generated page; CI fails a stale one) | After any board/backlog edit on this branch, run `make progress` once that chore is on main; regenerate on rebase, never hand-merge |
| **Goldens shift** (the weight graph's AppBar action; A44 palette) | Regenerate the two weight-graph golden files in WP7; tokens only |
| **Patrol journeys never green on the emulator** | Owner rule: expect one fix round; `[it]` on WP11; UI copy changes grep `patrol_test/` |
| **Owner's history has real >3 % weekly jumps** (many flagged rows) | Per-row Keep; if it's tedious on the A55, add a "Keep all" in a follow-up (owner FYI); the paste import (A29) is the bulk path |
| **500-row batch** (one transaction, 500 outbox rows, 500-op undo) | Within `ChangeSet.maxOps`; A08's DB perf showed larger writes are fine; `logMany` test with 500 rows |
| **Undo across interleaved edits** (type created, measured, renamed or deleted in between) | PA1 revert guards on the post-undo state + interleaving tests; the applier rolls back atomically |
| **B20 not yet a card** | The orchestrator creates it at A15b close from D23 (board row added now) |

#### Size check
WP6 0.5 · WP7 0.5 · WP8 0.2 · WP9 0.6 · WP10 0.8 · WP11 0.2 = **~2.8 sessions (L)**, plus the Codex review round. The server part is **B20 (M, ~1.5 sessions)**. Together they'd be ~4.3 sessions, above L, hence D23's split. No further split of A15b: WP7 (history) is independent of the schema, so it lands even while v9 is pending. The PA1 guards and tests add about 0.1–0.2 session to WP9; still L.

#### Plan review (Codex, read-only, 2026-10-30): approve with required changes, all applied

| # | Amendment | Where |
|---|---|---|
| PA1 | **Required.** Semantic revert guards evaluated on the post-undo state (type in use, type live, name unique), following the workout guard pattern; `UpdateMeasurement` can't change the type; interleaving tests | D15, §5.6, Risks |
| PA2 | **Required.** Undo expectations follow `row_writer.dart`: restored content with newer version/HLC, valid inverse metadata, new outbox rows (created rows become tombstones), atomic rollback on conflict, for measurements and `logMany` | §5.6 |
| PA3 | **Required.** Edit ≠ create: exact stored input, unit, instant and offset until changed; open + Save is a no-op; date-only change keeps time of day and offset; tests | D18, §5.7b |
| PA4 | **Required.** WB-041 as written: trend from ≥ 5 points (entries), not 5 distinct days; test with 5 entries over fewer than 5 days | Summary, D16, TD-103, §5.5, §5.7b |
| PA5 | Optional, applied. Explicit deploy hold: no live server takes WP8's registry before B20 | D23, Risks, Close |
| PA6 | Optional, applied. Edge tests: Keep invalidation, zero included rows, DST-rollback ordering of measurement points, custom-type arrival orders and export of orphans | §5.5, §5.6, §5.7b |
| PA7 | Optional, applied. D20 renumber recipe tightened (function and `Schema` param renamed, A23a's v9 kept, no reuse of provisional v9 databases, v9 preservation test kept) | D20 |
| PA8 | Goldens: `flutter test --update-goldens` file by file through `heavy.sh` with `timeout 600` is accepted as codegen; regenerate only the goldens the change affects | WPs |

## Progress log
- 2026-10-29 · A15a low-level plan written into the card (compacted from the prepared, architect-reviewed A15 plan). Branch `step/A15a-weight-graph`.
- 2026-10-29 · WP1 (TD-012 = `CustomPainter`, row rewritten, `evidence/A15a-chart-feasibility.md`), WP2 (DS chart: `chart_types`, `time_series_painter`, `chart_geometry`, `lttb`, `nice_scale`; reading-direction x, transient pan → one `onRangeChanged`, tap ≥ 24 dp on full data, semantics stepping, goal edge marker, cached labels; `time_series_chart` golden matrix replaces `chart_placeholder`; mockup goldens regenerated), WP3 (`fb_domain/src/body/weight_graph.dart`: `WeightProjection`, `WeightStats`, glados cone property; README "Weight projection"; TD-099 Proposed after the main merge), WP4 (`features/progress/`: `graph_window.dart`, `weight_graph_providers.dart`, `weight_graph_screen.dart`; routes `/today/weight`, `/progress/weight`; Progress Weight row; `weightGraph*` ARB) and the WP5 card row committed and pushed. CI on bd2e3b8 failed in `dart-test (packages)` (chart semantics: increase/decrease need neighbouring values; fixed in e16520f, chart tests green locally) and `dart-test (app:3/3)` (not inspected: GitHub API quota exhausted; likely goldens). **Not done (next session):** check CI on the branch head; regenerate the goldens CI reports (weight card + Today now have row 3); WP4 widget tests + weight graph goldens per range (§5 tests list); `HM-005`/`UX-013` navigation tests; Patrol `weight_graph_test.dart` + `[it]` close commit; A55 profile pan run (owner item); `GoalMonthTarget` shared helper not created (stats take the TG-011 rate from `targetsExplanationProvider`, deviation for review).
- 2026-10-29 · Review round (architecture approved; Codex review findings fixed): merged `origin/main` (A44 Embrace, B09b; a fast-forward merge instead of a rebase, because the force-push was refused) with the projection TD renumbered **TD-099**; points sorted by chart time with a rollback test (e5a39e3); `MonthlyTargetRate` (manual / generated / unavailable), so a manual target that needs review shows no monthly target (3e8ad3c); the graph follows `todayProvider` and refreshes on resume (fb4e1a2); a refused Use for trend shows a snack bar (0aaa2a1); the value scale fits only visible dots plus interpolated line edges (108663e); goldens regenerated for the card's row 3 and Embrace (4b94b17); evidence: screen widget tests, HM-005/UX-013 navigation, `weight_graph_ranges`/`weight_graph_states` goldens, Patrol `weight_graph_test.dart` with printed pan frame timings, the router location test lists both graph routes (f9004fa). Onboarding and weigh-in Patrol finders are unaffected by row 3 (they target row texts, not positions). Open: the A55 profile pan run (owner item); `ux-reviewer` pass.
- **Status: built; architecture approved; review findings fixed, awaiting CI and the code-review close** (owner direction 2026-10-29: plan + code time-boxed; reviews later). Not merged.
- 2026-10-30 · A15b low-level plan written (step-planner; recovered prepared plan re-verified against main 2cab3c0): WP6–WP11, schema v10 after A23a, server admission split out to B20, TD-103 candidate. Branch `step/A15b-weight-history-measurements`. Next: Codex plan review, orchestrator self-approval.
- 2026-10-30 · Codex plan review round 1: approve with required changes; PA1–PA4 (revert guards on the post-undo state, undo/outbox expectations per `row_writer.dart`, edit ≠ create, WB-041 ≥ 5 points as written) and optional PA5–PA8 (deploy hold before B20, edge tests, tighter D20 recipe, goldens as codegen) applied. Next: orchestrator self-approval, then WP6.
- 2026-10-30 · A15b plan approved by the orchestrator after Codex plan review round 1 (PA1–PA8 applied in 7d30c36). Next: WP6 → WP11 by one engineer; CI is the test evidence; Codex reviews at close.
- 2026-10-30 · WP6 (domain): `smooth_daily.dart` (`TrendWeight.compute` delegates, A14 tests untouched), `measurement.dart`, `measurement_ops.dart`, `measurement_series.dart`, `weigh_in_batch.dart` (Keep = an opaque `keepToken` of flag + row + exact reference, so edits clear it), README sections; §5.5 tests. Local adjustment: the inch range hint is 4.0–118.1 in (3.9 in rounds to 9.91 cm, below 10 cm). `make check-dart` green; CI is the test evidence.
- 2026-10-30 · WP7 (weight history): `WeighInActions.logMany` (one change set, one undo entry `weighInsLogged`), pure `weight_history_form.dart`, `WeightHistoryScreen` + body-local discard sheet, `WeightHistoryRoute` `/weight-history` in `outsideTabs` (router imports the body barrel), weight graph AppBar action + empty-state text action, ARB `weightHistory*`; tests: logMany (undo/outbox/refusal/conflict/500 rows), form reducer, §5.7a screen tests, UX-013 navigation, router lists; goldens `weight_history` (new) and `weight_graph_states`/`weight_graph_ranges` regenerated. Local adjustments: the screen takes an optional `initial` form (goldens); the date chip sits on a line with Remove and the value field below it (text scale 2.0); a local number parser (body can't import the targets barrel: cycle). `make check-dart` green.
- 2026-10-30 · WP8 (contract, own commit): `measurementType` v1 (`name` ≤ 120) and `measurement` v1 (`kind` enum of 8, `customTypeId` uuid|null, `measuredAtUtc`, `tzOffsetMin`, `localDate`, `value`/`inputValue` 0…1e6, `inputUnit` cm/in/percent) added to `sync-entities.json`; one fixture each in `entity-payloads.json`; `measurement-payload-variants.json` (body fat %, custom in inches, 120-char name); `make gen-sync-schemas` → `entities.json` (only backend change); `contracts/README.md` § Measurement semantic rules (M1–M3, the single source B20 admits, deploy hold), `contracts/testdata/README.md`, `05` §5.5 entity list + line. `make gen-contract gen-dart` leaves no other diff; `check-sync-schemas`, `check-contract`, `check-dotnet` green. Additive: no owner gate.
- 2026-10-30 · CI on ad9d35e (WP6–WP8): packages, dotnet, contract green; `dart-test (app:2/3)` red only in `l10n_test` LC-002 (a pending drift stream-close timer: the weight history is the first outside-tab screen that watches the database, and the test never unmounted the app); fixed in WP9 with `unmountApp` at the test's end (reproduced and verified with a single-file run).
- 2026-10-30 · WP9 (tables, migration, write path): `git merge origin/main` was a no-op (A23a's v9 not on main), so per D20 the step is built **provisionally as v9** (`from_8_to_9.dart`, `drift_schema_v9.json`, `schema_v9.dart`); the renumber recipe to v10 runs after A23a lands, before merge. Tables `measurement_types`/`measurements` (CHECKs = wire), `ix_measurements_live`, six triggers, `syncedTables` +2; `measurement_mappers.dart` (tolerant reads, D25), `MeasurementOpHandler` (forward checks + PA1 revert guards on the post-undo state: `typeInUse`, `unknownType`, `duplicateName`), `MeasurementRepository`, `app_scope.dart`, export registry/snapshot order, `docs/export-format.md`; TD-103 Proposed. Tests §5.6 (migration + contract tripwire, handler + undo/guards, repository + tolerant reads, export). Local adjustment: the repository exposes one `watch()`/`read()` returning `MeasurementData` (types, measurements, skipped count) instead of separate `watchTypes`/`watchMeasurements` (one consistent snapshot hides orphans). `make gen-app check-dart` green.
- 2026-10-30 · CI on a976475 (WP9): 3 red tests, all test-side: the app's handler-family lists (`change_providers_test`, `settings_store_test`) gain `MeasurementOp`, and a CreateMeasurement test measured at 23:00 local, after the harness's now; fixed in 42a30f6.
- 2026-10-30 · WP10 (measurement screens): body `measurement_providers.dart` (`measurementsProvider` without automatic retry, `latestByTypeProvider`, `measurementSeriesProvider(key)`), `MeasurementActions` (typed outcomes, pending keys, value-free undo labels), pure `measurement_form.dart` (PA3 edit ≠ create), `MeasurementSheet`, `CustomTypeSheet`, `measurement_text.dart`; progress `MeasurementsScreen`, `MeasurementTypeScreen` (graph, details, entries with swipe delete, Rename/Delete type with a confirm sheet), `measurement_graph_providers.dart` (window per key, All default; wall-clock point order), `graph_range_chips.dart` extracted (the weight graph uses it, plus a shared `graphTickLabel`); routes `/progress/measurements` and `/progress/measurements/:type` nested in the Progress branch; Progress row; ARB `measurement*`; tests §5.7b (form, actions, screens, DST order, navigation, router lists) and goldens `measurements_list`, `measurement_type`, `measurement_sheet`, `custom_type_sheet`. Local adjustments: the sheet's value is an `FbNumberField` (keyboard) rather than the number pad; after "Add custom measurement" the new type's form opens; the list shows values in the unit setting (details and entries as typed). `make gen-app check-dart` green.
- 2026-10-30 · CI on d6587ea (WP10): 2 red tests, both test-side (a retype of the same text is not a change, so the stored input correctly stays; CLDR's narrow no-break space before AM in the details time); fixed in 475ffa5, both files re-run green locally.
- 2026-10-30 · WP11 (device journeys, `[it]`): `patrol_test/measurements_test.dart` with `A15b measurements: add, edit, delete with undo, custom type graph` and `A15b weight history: add three past weigh-ins, see them on the graph, undo`; `patrol_test/` grep: no finder shifts (the weight graph journey opens from Today and taps texts; the new AppBar action is an icon; the Progress tab gains a row below Weight graph); `heavy.sh make build-it` green; backlog #213 (owner real-history sign-off, M2 gate) and #214 (B20 handoff + deploy hold); `make progress`. **Next (orchestrator):** check `android-it` on this push (never-green journeys may need one fix round), Codex review (code + security + #165 UX), the D20 renumber to v10 once A23a is on main (never reuse a provisional-v9 database), B20 card, close.
- 2026-10-30 · `android-it` on b869322: red in `A15b measurements …` on both attempts (the entry rows below the chart are lazy list children, not built on the emulator's screen, so the finder was empty); attempt 1 also had an unrelated `today_diary_test` session flake (retryable `SessionFailure`), green on attempt 2. Fixed in the review commit: the journey scrolls (bounded) to rows before tapping. The weight history journey's result was cut off in the annotations; it gets the stable-key rewrite in the same commit.
- 2026-10-30 · Codex review round 1 (code + security, a9a6393..b869322): no blockers; fixed: **M1** an unrepresentable synced instant (year 10000, inside the wire bound) is skipped and counted by both mappers (measurements and weigh-ins: the graph reads the wall clock), with repository-to-graph regression tests; **m2** a forward write needs a live *readable* custom type (`unknownType` otherwise); **m3** Keep tokens hold an earlier row by position and typed content, not its time (today's follows the clock until 08:00), with an advancing-clock test; **m4** Patrol: stable `WeightHistoryScreen.valueKey` per row with bounded scrolling, waits for the sheet fields and enabled buttons. Coverage: PA1 single-undo of type + entry, PA2 newer-HLC/undo-origin asserts in `logMany`, the migration test seeds every v8 synced table (chat and workouts by hand). Close prep: B20 card `B20-measurement-sync.md` (validator M1–M3, corpus, Testcontainers, security review, deploy hold), board link, backlog #214 (B20 handoff) and #215 (deploy hold). `make check-dart` green.
- 2026-10-30 · Codex re-check of ace704c: all items verified, no new blocker or major; CI on ace704c green apart from `android-it` (still running at the Outcome commit). Outcome written, board A15b ✅ (owner sign-off pending, #213). Next: wait for A23a's v9 on main, then the D20 renumber to v10 (+ A23a's proposals seeded in the migration test), `[it]` push, merge by the orchestrator.
- 2026-10-30 · Merged `origin/main` with A23a (73b6ea6, schema v9 = proposals + 2 chat columns) and ran the **D20 renumber**: A23a's `from_8_to_9.dart`, `drift_schema_v9.json`, `schema_v9.dart` kept untouched; A15b's step is now `from_9_to_10.dart` (`from9To10`, `Schema10`), `schemaVersion` 10, `drift_schema_v10.json` + `schema_v10.dart` via `heavy.sh make db-migrations`; the migration test runs v9→v10 and also seeds A23a's `proposals` and the new chat columns (`request_json`, `answer_json`). Unions: `app_database.dart` (tables, `syncedTables`, steps), `app_scope.dart`, `sync_triggers.drift`, export registry/test (both export tests kept), handler-family lists, `fb_domain.dart`, ARB, `docs/export-format.md` (23 CSVs). Backlog rows renumbered to **#213** (owner sign-off), **#214** (B20 handoff), **#215** (deploy hold) after A23a's #211/#212; TD-103 doesn't collide (A23a took TD-100–102). `make gen-check check-dart` green. Never reuse a provisional-v9 database from this branch.

## Outcome
### A15a "Weight graph"
**Built by Claude (TD-085, TD-095: one agent) in lane 4, 2026-10-29: plan and code time-boxed by the owner, reviews afterwards. Size about the planned L for WP1–WP5, plus one review-fix round. A15b (weight history entry & measurements) is still to do.**
- **Built:** TD-012 settled as a DS-owned `CustomPainter` chart (evidence `evidence/A15a-chart-feasibility.md`). `FbTimeSeriesChart` with:
  - time running in reading direction (LC-003) on plain wall-clock dates;
  - LTTB down-sampling of the visible slice, readable value ticks fitted to visible values (interpolated line edges), and an edge marker for an off-scale goal;
  - cone bands, labelled periods (phase labels at the top, highlight at the bottom), and tap selection within 24 dp on the full data, with the selection always drawn;
  - screen-reader stepping between points, and a transient pan offset reported once on drag end;
  - cached labels and a `RepaintBoundary`.

  `fb_domain`: `WeightProjection` (the card's rate, a cone from the OLS slope standard error, clamped at the goal, a 730-day horizon, a reach date) and `WeightStats` (change since the phase start with the stale-start rule, this month against the pro-rated TG-011 target, average since a date), plus `MonthlyTargetRate`. The progress feature: `graph_window.dart` (calendar-month ranges, 3M default, pan bounds), `weightGraphProvider` (independent of the window, follows `todayProvider`, no automatic retry), `WeightGraphScreen` (range chips, Today reset, dots, trend, goal line, projection cone, goal phases, the A41 `chartHighlightPeriodsProvider` hook, point details with Edit and Use for trend with undo, the WB-023 summary, empty/loading/error states). Routes `/today/weight` and `/progress/weight`; the weight card's third row "Weight graph"; a Weight row on the Progress tab.
- **Deviations:** no fling (only a drag pans; it reports once on drag end). The PA3 shared month-target helper is **`MonthlyTargetRate`** (manual / generated / unavailable with a reason, read from the targets explanation), and `WeightStats` does the month conversion and pro-rating. A manual target that needs review shows no monthly target. Main was merged into the branch instead of rebasing it (the force-push was refused); it squash-merges the same way. TD-012 was rewritten as **Accepted** (`CustomPainter`; it was Pending, so no owner gate; owner FYI). The projection TD is **TD-099 (Proposed)**. In the Patrol journey, point selection calls the chart's `onSelect` (pixel hit-testing is proved by the DS tests).
- **Reviews:** architecture approved (boundaries; projection and pro-rating match the plan). Codex code review: **1 major** (chart points sorted by chart x, not UTC: clock rollback) and **4 minors** (no generated fallback for a manual target that needs review; the date follows midnight and resume; feedback when Use for trend is refused; scale fitted to visible values), all fixed with tests (e5a39e3, 3e8ad3c, fb4e1a2, 0aaa2a1, 108663e). The first CI run also found a chart semantics bug (increase/decrease need the neighbouring values), fixed in e16520f.
- **Metrics:** about 72 tests added:
  - DS: 20 chart tests plus a golden matrix (light/dark × LTR/RTL × 1.0/2.0);
  - `fb_domain`: 26 (projection, stats, `MonthlyTargetRate`, a glados property on the cone);
  - app: 21 widget/provider/navigation tests (HM-005, UX-013) plus goldens `weight_graph_ranges` (1M/3M/6M/1Y/All, light/dark) and `weight_graph_states` (3M at 2.0, selected, empty);
  - Patrol `A15 weight graph ranges pan and point edit with two years of weigh-ins`, with printed pan frame timings;
  - a printed host benchmark for slicing, LTTB and scaling 730×2 points.
- **TDs:** TD-012 Accepted (`CustomPainter`). TD-099 weight projection & cone, Proposed.
- **Follow-ups:** backlog #164 (owner A55 profile pan run, exit 5), #165 (`ux-reviewer` pass on the graph), #166 (fling on the chart, if wanted).

### A15b "Weight history entry & measurements"
**Built by Claude (TD-085, TD-095: one engineer, lane 3), 2026-10-30, in about one long session (plan ~2.8 sessions L; actual about the planned size, helped by "no local test runs"). WP6–WP11 plus one review round; renumbered to schema v10 on top of A23a (D20); merge by the orchestrator.**
- **Built:**
  - `fb_domain`: `smoothDaily` (the A14 trend now delegates to it, same numbers), the measurement model (`MeasurementKind` ×8, units, `MeasurementTypeRef` keys, drafts with local bounds, `CustomTypeName`), the six measurement ops, `MeasurementSeries` (trend from 5 entries, WB-041), and `WeighInBatchCheck`/`WeighInBatch` (blocking, excluded-until-Keep and info flags; Keep tokens that clear on edits; 08:00 past times; at most 500 rows).
  - Weight history: `WeighInActions.logMany` (one change set, one undo), the pure form, `WeightHistoryScreen` (`/weight-history`, outside the tabs) with a discard sheet; entry points on the weight graph (AppBar action and empty state).
  - Contract (own commit): `measurementType` and `measurement` v1, fixtures and variants, regenerated `entities.json`, `contracts/README.md` § Measurement semantic rules (M1–M3).
  - Storage: `measurement_types` and `measurements` (CHECKs equal the wire), the live index, six outbox triggers, the migration (schema **v10**, after A23a's v9; built provisionally as v9 and renumbered per D20), tolerant mappers, `MeasurementOpHandler` with PA1 revert guards on the post-undo state (`typeInUse`, `unknownType`, `duplicateName`), the repository, export specs and docs.
  - Screens: the Measurements list and per-type screen (graph with ranges, All by default; details with Edit; entries with swipe delete and undo; Rename/Delete type with a confirm sheet), the measurement and custom type sheets (PA3: an edit keeps the stored input, instant and offset until changed), shared `GraphRangeChips`, routes nested in the Progress tab and its Measurements row.
  - Two Patrol journeys.
- **Deviations (local, logged; no behaviour or TD change):**
  - the measurement sheet uses the DS keyboard `FbNumberField`, not the number pad;
  - the repository serves one consistent snapshot (`watch()`/`read()` → `MeasurementData` with a skipped count), not separate `watchTypes`/`watchMeasurements`;
  - after "Add custom measurement" the new type's form opens;
  - the list and graphs show values in the unit setting; details and entries show them as typed;
  - the inch range hint is 4.0–118.1 in (3.9 in rounds below 10 cm);
  - the migration was built as v9 and renumbered to v10 after A23a (D20), and the `l10n_test` now unmounts the app (the first outside-tab screen that watches the database);
  - the weigh-in mapper also skips unrepresentable synced instants (review M1 applied to both body tables).
- **Reviews:** Codex plan review (PA1–PA8, applied before building). Codex code + security review round 1 (a9a6393..b869322): **0 blockers, 1 major** (a synced instant in year 10000 crashed the graph) and **3 minors** (a forward write to an unreadable type, Keep tokens that changed with the clock before 08:00, Patrol finder robustness), plus 3 coverage items (PA1 single undo, PA2 undo HLC/origin, every v8 table seeded in the migration test). All fixed in ace704c; the Codex re-check verified all of them.
- **CI fix rounds:** 4, all test-side: the l10n test's pending drift timer; the handler-family lists plus a future test time; a retyped value and CLDR's narrow no-break space; and on the device, lazy rows below the fold in the measurements journey.
- **Metrics:**
  - about 88 tests added: `fb_domain` 22 (one glados property); app 59 unit, data, widget and navigation tests; 5 new golden files (`weight_history`, `measurements_list`, `measurement_type`, `measurement_sheet`, `custom_type_sheet`; light/dark × 1.0/2.0) and 2 regenerated (`weight_graph_states`, `weight_graph_ranges`); 2 Patrol journeys;
  - WPs: 6 (WP6–WP11), plus 1 review commit and 2 CI-fix commits.
- **TDs:** TD-103 "Body measurements model", Proposed (number confirmed at merge).
- **Owner items (don't block the merge):**
  - real-history sign-off (exit 2, M2 gate in A16; backlog #213);
  - the A55 2-year profile pan run (exit 5; backlog #164, stays ⚠️ until recorded).
- **Follow-ups:**
  - B20 (card written; backlog #214) and the **deploy hold** (#215): no server runs the measurement registry before B20;
  - never reuse a database from the provisional-v9 builds of this branch (emulator, A55 dev install);
  - a "Keep all" on the weight history if the owner's real history flags many rows.
