# S08 — Domain primitives & text normalization

| Phase | Depends on | Size | Status |
|---|---|---|---|
| P0 Foundations | S01 | M | ⬜ Not started |

**Goal.** The pure-Dart building blocks every calculation uses (units, nutrients, the one nutrition calculation, yields, sanity checks, time and IDs), plus the text normalization whose behaviour is specified by a golden file shared with the backend.

**Spec:** FD-002, FD-012, FD-060, FD-062 (domain side), LC-010, LC-011, LC-012, LC-021, DY-001, DY-002 (time helpers), LC-051 (parsing of local portion words) · **Decisions:** TD-009, TD-017, TD-030

## Scope
- **`fb_domain` value objects:** `Mass`, `Volume`, `Energy` (kcal), `Nutrients` (kcal, protein, carbs, fat, fiber + optional extras), `FoodState` (raw / cooked / dry / drained / fried / as sold), `Unit` with metric + imperial conversions (g, kg, oz, lb, ml, l, fl oz, cup, tbsp, tsp, piece/serving units with food-specific grams).
- **`NutritionCalculator`:** per-100 g/ml → entry nutrient snapshot, with **fixed rounding rules** (documented, used everywhere).
- **Sanity check** (FD-012): kcal ≈ 4P + 4C + 9F (+ fiber, alcohol) within a documented tolerance → `ok / warn / fail`.
- **`YieldConverter`** (FD-060/062): data-driven factors (the data comes from the catalog in S13), producing the conversion note ("200 g dry ≈ 500 g cooked").
- **Time:** `Clock` interface, `LocalDate`, entry time with `tz_offset_min`, `WeekCalendar` with a configurable week start (default Saturday). Helpers for "which local date does this instant belong to" (DY-001/002).
- **IDs & clocks:** UUIDv7 generator. **Hybrid logical clock** (wall time + counter + device ID, serialisable, comparable).
- **`fb_text`:** Arabic normalization (tashkeel, tatweel, alef forms, ة/ه, ى/ي, hamza forms, Arabic-Indic/Persian digits) and Latin normalization (case, accents, repeated letters). Number & unit parsing in EN/AR (number words, fractions "نص", "ربع", "half", unit words, local portion words like رغيف/صحن/حبة/كاسة).
- **`contracts/testdata/normalization_cases.yaml`:** ≥ 100 cases (input → normalized key). The **shared spec** the C# side must also pass (S30).
- Property tests (`glados`): unit round trips, HLC monotonicity and ordering, calculator linearity.

## Out of scope
- Arabizi skeleton matching (R2, FD-024). Food search ranking (S15). Persistence (S09).

## Fixed by the plan
- Canonical units g/ml/kcal/kg/cm with the original input kept (`05` §1).
- No `DateTime.now()` or randomness in domain code.

## Decide in the low-level plan
- The rounding rules (display vs storage precision) and the sanity tolerance values.
- Number representation (double vs a decimal type) for nutrients and masses.

## Exit criteria
- [ ] `fb_domain` and `fb_text` line coverage ≥ 95%.
- [ ] All normalization golden cases pass. The file format is documented in `contracts/testdata/README.md`.
- [ ] Property tests pass (≥ 1,000 runs each) in CI.
- [ ] Packages have no Flutter or I/O dependencies (allowlist test).

## Read first
`05-data-and-sync.md` §1 · `07-food-data.md` §5.1 · `spec/11-foods-and-data-quality.md` §1, §7

## Owner involvement
None. Optionally, add a few Arabic/Arabizi spellings you use to the golden file.

---

## Low-level plan
_Written in Phase B._

## Outcome
_Written in Phase E._
