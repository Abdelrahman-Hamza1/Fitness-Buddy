# S08 — Domain primitives & text normalization

| Phase | Depends on | Size | Status |
|---|---|---|---|
| P0 Foundations | S01 | M | ✅ Done |

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
- [x] `fb_domain` and `fb_text` line coverage ≥ 95%.
- [x] All normalization golden cases pass. The file format is documented in `contracts/testdata/README.md`.
- [x] Property tests pass (≥ 1,000 runs each) in CI.
- [x] Packages have no Flutter or I/O dependencies (allowlist test).

## Read first
`05-data-and-sync.md` §1 · `07-food-data.md` §5.1 · `spec/11-foods-and-data-quality.md` §1, §7

## Owner involvement
None. Optionally, add a few Arabic/Arabizi spellings you use to the golden file.

---

## Low-level plan
_Written in Phase B (2026-10-13) by the step-planner. Version checks were done in a scratch package on Dart 3.13.5: glados 1.1.7 and kiri_check 1.3.2 both resolve with test 1.31.1 and both run 1,000 cases. `dart test --coverage-path` writes lcov without any extra package._

### 1. Summary
After S08, `fb_domain` holds the value objects and math that every later step uses: units and conversions, `Nutrients`, the one `NutritionCalculator` with fixed rounding, the FD-012 sanity check, `YieldConverter`, `Clock`/`LocalDate`/`EntryTime`/`WeekCalendar`, a UUIDv7 generator and a hybrid logical clock. `fb_text` holds the search-key normalization (Arabic + Latin), specified by `contracts/testdata/normalization_cases.yaml` (≥ 100 cases), and the EN/AR/Arabizi quantity parser (numbers, fractions, units, local portion words). Both packages keep **zero runtime dependencies**. `make test-dart` enforces ≥ 95% line coverage on both, in CI and locally (closes backlog #6).

### 2. Decisions

| # | Decision | Reason / source |
|---|---|---|
| D1 | **Numbers are `double`** for every mass, volume, energy and nutrient value, wrapped in value objects. Rounding happens only at the boundaries in D2/D3 | Values are < 10⁵ and need 0.01 precision. A double has 15+ significant digits. `decimal` 3.2.6 pulls `intl` + `rational` as runtime deps (breaks the empty allowlist), and integer fixed-point is overkill |
| D2 | **Storage precision:** snapshot nutrients (kcal, g, mg) and canonical amounts (g, ml, kg, cm) are rounded **once**, to **2 decimals**, half away from zero, when a value is persisted or snapshotted. `roundHalfAwayFromZero(x, d)` first rounds `x·10ᵈ` to 6 decimals (`toStringAsFixed`) to remove binary error, so 2.675 → 2.68 and 1.005 → 1.01. The original input (`input_amount`, `input_unit`) is kept as typed | Removes float noise, gives identical numbers on every run and platform, and 0.01 is below anything shown. One rounding point means no drift (`05` §1) |
| D3 | **Display rules** (`DisplayRounding`, numbers only; the app formats strings from ARB): kcal → whole number. Nutrients in g → 1 decimal below 10 g, whole from 10 g. mg → whole. Food g/ml → whole. Body kg and lb → 1 decimal. oz, fl oz → 1 decimal. cm, in → whole (height in ft + in). **Totals = round(sum of stored values)**, never a sum of displayed values | Matches what labels and common trackers show. Summing stored values keeps a day total equal for every view |
| D4 | **Unit factors:** oz = 28.349523125 g, lb = 453.59237 g (exact, international), fl oz = 29.5735295625 ml (US customary, so a 12 fl oz can = 355 ml), cup = 240 ml, tbsp = 15 ml, tsp = 5 ml (US nutrition-label values), in = 2.54 cm, ft = 12 in. Volume ↔ mass needs the food's density or a food-specific serving unit, otherwise the resolution fails with a reason (no silent guess) | The label values are what packaged food states. Arabic كوب is mapped to the same cup (D12) |
| D5 | **FD-012 sanity:** expected kcal is computed two ways, (a) 4P + 4C + 9F + 7·alcohol (carbs include fiber, US style) and (b) 4P + 4C + 2·fiber + 9F + 7·alcohol (carbs exclude fiber, EU style), and the **closer one** is used. Deviation `d = |kcal − expected|`. **ok** if d ≤ max(15 kcal, 15% of max(kcal, expected)). **warn** if d ≤ max(30 kcal, 30%). **fail** otherwise. **Hard fail** regardless: any negative value, kcal > 920 per 100 g, or P + C + F + fiber > 105 g per 100 g (mass basis only). Thresholds live in one `SanityTolerance` value with these defaults. The result carries the expected kcal and the deviation, so the UI can highlight (FD-041) | Food data doesn't say which carb convention it uses. Atwater general factors drift about 5–10% from specific factors, and label rounding adds a few kcal, so 15% catches typos without flagging honest data. The absolute floor protects low-kcal foods (vegetables, drinks). S13 runs this over the whole catalog and may tune the numbers (no spec change) |
| D6 | **Yield:** `YieldFactor(group, from, to, factor)` rows (data from the catalog in S13, test data here). The converter uses a direct row or the inverse of the reverse row, with no chaining. It converts **amounts** (500 g cooked rice → 200 g dry), and the calculator then uses the matched food's own per-100 g values. The note (`YieldNote`: from amount + state, to amount + state, factor) rounds the converted side to the nearest 5 g from 50 g, else whole grams. Words come from ARB in the app | Keeps "one calculation" (no second nutrient path). "≈" with 487 g reads falsely exact |
| D7 | **Time:** `Clock` = `DateTime nowUtc()` + `int offsetMinutesAt(DateTime utc)` (the device zone at that instant, so DST is right). `LocalDate` is its own value type (ISO `YYYY-MM-DD`, compare, plusDays, daysUntil). `EntryTime(occurredAtUtc, tzOffsetMin)` derives the local date-time and `LocalDate` from its **stored** offset, never the current one (DY-002). Offsets are validated to −720…+840. `WeekCalendar(weekStart)` uses ISO weekday numbers, **default Saturday** (LC-021, D-070) | DY-001/002 need instant + offset + local date (`05` §1). An injected clock keeps the domain deterministic |
| D8 | **Production clock and randomness live in one file:** `lib/system.dart` (`SystemClock`), a separate library that the main barrel doesn't export. A test fails if `DateTime.now(`, `Random(` or `Random.secure(` appears anywhere else in `fb_domain/lib` | Enforces the card's "no `DateTime.now()` or randomness in domain code" mechanically. The app's composition root imports `system.dart` |
| D9 | **UUIDv7 in-house** (about 50 lines, RFC 9562 §5.7, "method 1"): 48-bit Unix ms + a 12-bit `rand_a` counter (randomly seeded each new ms, incremented within the same ms; if the clock goes backwards the last ms is reused, so IDs from one generator are strictly increasing) + 62 random bits. It takes a `Clock` and a `dart:math` `Random` (tests pass `Random(seed)`, the app passes `Random.secure()`). Output: lowercase 8-4-4-4-12 text. Plus `isUuid(String)` and `uuidV7Millis(String)` | The `uuid` package (4.6.0) pulls `crypto` + `fixnum` as runtime deps. The algorithm is small and fully property-testable |
| D10 | **HLC text format:** `<wall ms, 13 digits zero-padded>-<counter, 5 digits zero-padded>-<deviceId>`, e.g. `1760351234567-00000-0199e3c2-…`. Parsed by fixed widths. The fixed widths make **string order = logical order** (wall, then counter, then device ID), so SQLite and Postgres can compare it as text. `now()` and `receive(remote)` follow the standard HLC rules. A counter above 99,999 throws. `receive` throws `HlcDriftException` if the remote wall time is more than `maxForwardDrift` ahead of the local physical clock (default 24 h, configurable) | Serialisable, comparable and readable in a DB row. 13 digits last until year 2286. The drift guard stops a phone with a wrong clock from poisoning every later write. What sync does with the exception is decided in the sync step. **TD candidate** (it becomes a wire format) |
| D11 | **Normalization key pipeline** (one function `normalizeKey`, order fixed and written in `contracts/testdata/README.md`): (1) delete invisibles (ZWNJ, ZWJ, LRM, RLM, BOM, soft hyphen) and apostrophes (`' ’ ʼ \``). (2) Arabic-Indic and Persian digits → ASCII. (3) Delete tashkeel (U+064B–U+065F, U+0670, U+06D6–U+06ED) and tatweel U+0640. (4) Lam-alef ligatures U+FEF5–U+FEFC → لا. Alef forms أ إ آ ٱ → ا. ة → ه. ى → ي. ؤ ئ → ء (as `07` §5.1). Persian ک → ك, ی → ي. (5) Lowercase (Dart `toLowerCase`, locale-independent), then strip Latin accents with an **explicit table** (Latin-1 Supplement + Latin Extended-A, plus ß → ss, æ → ae, œ → oe, ø → o) and delete combining marks U+0300–U+036F. (6) Every character that isn't a letter, a digit or a space → space. (7) Collapse runs of **2 or more identical letters** to one (any script; digits are untouched, so "100" stays). (8) Collapse whitespace, trim. The key is idempotent: `key(key(s)) == key(s)` | An explicit table instead of Unicode NFD, because Dart has no NFD and C# must give the same bytes (TD-030). Collapsing doubles on both sides (index and query) makes "chiiicken" = "chicken" and "7ommos" = "7omos" |
| D12 | **Parsing** (`fb_text`, Dart only): `parseNumber` and `parseQuantity(text) → ParsedQuantity?` (`amount`, `unitCode?`, `amountImplicit`, `rest` = the food text), with the quantity at the **start or end** of the text. Numbers: digits (after D11 digit folding), "." and "٫" as decimal point, "," as decimal point only when 1–2 digits follow, Unicode fractions (½ ¼ ¾ ⅓ ⅔), "1/2", "a/an" = 1, "dozen" = 12. EN number words zero–twenty, tens, hundred. AR words 1–10 in MSA and Egyptian/Levantine spellings (واحد/واحدة, اتنين/اثنين/تنين, تلاتة/ثلاثة, …), نص/نصف = ½, ربع = ¼, تلت/ثلث = ⅓, "ونص"/"and a half" = +½, "وربع" = +¼. A few Arabizi words (wa7ed, etnen/itnen, talata, nos/nus, rob3). **Arabic dual** of a portion word = 2 (رغيفين, حبتين, صحنين, كاستين). Units map to codes: `g kg oz lb ml l fl_oz cup tbsp tsp` and portion codes `piece loaf plate glass sandwich disc`. ملعقة alone → `tbsp` (documented assumption). كوب → `cup`. كاسة/كاس/كباية/كوباية → `glass`. Out of scope: ranges ("2-3"), several items in one text (Buddy handles both) | The FD-003/LC-051 word list. Codes are plain strings, so `fb_text` doesn't depend on `fb_domain` (a dev-only test checks that every unit code resolves in `fb_domain`) |
| D13 | **Golden file format** (`contracts/testdata/normalization_cases.yaml`): `version: 1`, then `cases:`, a list of `{id, input, key, note?}`. IDs are kebab-case with a category prefix (`ar-`, `lat-`, `digit-`, `mixed-`, `space-`, `arabizi-`), unique and stable. Invisible characters are written as `\uXXXX` in double-quoted YAML. A pass means `normalizeKey(input) == key` byte for byte, **and** `normalizeKey(key) == key`. At least 100 cases covering every rule in D11, plus must-cover dish spellings (فول/فُول/فوول, كشري/كشرى, ملوخية/ملوخيه, …) | Data only, stable IDs, both sides read the same bytes (testdata README rules). The idempotence check doubles as a guard on the file itself |
| D14 | **Property tests: `glados` pinned at 1.1.7** (dev only; last release Dec 2023, but its only deps are `characters`, `meta` and `test`, and it works on Dart 3.13 because pub relaxes the `<3.0.0` bound). One shared constant `propertyRuns = ExploreConfig(numRuns: 1000)` in each package's `test/helpers/`, used by every property test, always (local and CI). Bounded custom generators (no NaN or ∞). **Fallback: kiri_check 1.3.2** (maintained, also proven 1,000 runs) if glados breaks on a future SDK | The card and `10` §4 name glados. It is the lighter of the two (kiri_check pulls `timezone`, `date_kit`, `universal_platform`) |
| D15 | **Coverage gate in `make test-dart`:** `tools/scripts/dart-test-all.sh` gets a `COVERAGE_MIN` map (`fb_domain=95 fb_text=95`). For those packages it runs `dart test -j 2 --coverage-path=build/coverage/<pkg>.lcov` (one test run, not two), then `python3 -I` sums LH/LF over `lib/` and fails below the minimum, printing the percentage. A package with no executable lines passes. Every package also gets a **barrel test**: every `lib/src/**.dart` file is exported from the barrel (except `system.dart`, which has its own test), because lcov only lists files a test loads. No `coverage:ignore` comments | Same command on the laptop and in CI, no new CI step, no new dev dependency. Without the barrel test, an untested file would be silently left out of the percentage |
| D16 | **`Nutrients`:** the core five are required and ≥ 0 (FD-002). Extras are an optional `Map<NutrientKey, double>` with `NutrientKey` = sugar (g), saturatedFat (g), transFat (g), sodium (mg), cholesterol (mg), alcohol (g). Each key has a fixed unit. Missing ≠ 0 (absent extras stay absent when scaling or adding, and adding two `Nutrients` keeps an extra only if both have it) | "Never required" (D-019). A partial sum must not pretend to be complete. The catalog may add keys in S13 |

No ⚠️ OWNER items: no spec change, no Accepted TD change, no new runtime dependency or vendor.

### 3. Design

**3.1 `fb_domain`** (barrel `lib/fb_domain.dart` exports `lib/src/**`; `lib/system.dart` separate)
```
src/math/rounding.dart        roundHalfAwayFromZero, StoragePrecision (2), DisplayRounding (D3)
src/units/                    Mass (g), Volume (ml), Length (cm), Energy (kcal only, LC-012): immutable, +, −, ×, compare
                              MassUnit/VolumeUnit/LengthUnit enums with factors (D4) + stable codes; UnitSystem {metric, imperial}
                              Quantity(amount, unitCode) = the original input; ServingUnit(code, grams|ml) per food
                              FoodMeasures(basis g|ml, servingUnits, densityGPerMl?) → resolve(Quantity) →
                              sealed QuantityResolution: Resolved(canonical amount) | NeedsDensity | UnknownServingUnit
src/food/food_state.dart      enum FoodState {raw, cooked, dry, drained, fried, asSold} + codes
src/nutrition/nutrients.dart  Nutrients (D16), NutrientKey, scale(f), +, rounded() (storage)
src/nutrition/calculator.dart NutritionCalculator.compute(per100: Nutrients, measures: FoodMeasures, input: Quantity)
                              → sealed: Computed(NutrientSnapshot(nutrients rounded to storage, canonicalAmount, input)) | failure reason
src/nutrition/sanity.dart     SanityTolerance (D5 defaults), SanityCheck.check(per100, basis) → SanityResult(level ok|warn|fail,
                              expectedKcal, deviation, reason)
src/nutrition/yield.dart      YieldFactor, YieldConverter(List<YieldFactor>).convert(amount, group, from, to) → YieldNote? (D6)
src/time/                     Clock, LocalDate, EntryTime, DayOfWeek (ISO 1..7), WeekCalendar(weekStart = saturday):
                              weekStartOf(date), weekOf(date) → [start, start+6], localDateOf(utc, offset)
src/ids/uuid_v7.dart          UuidV7Generator(clock, random).next(), isUuid, uuidV7Millis (D9)
src/ids/hlc.dart              Hlc (wallMs, counter, deviceId; parse/toString/compareTo), HybridLogicalClock(clock, deviceId,
                              maxForwardDrift).now() / receive(Hlc) (D10)
system.dart                   SystemClock (the only DateTime.now(); offsetMinutesAt via toLocal().timeZoneOffset)
```
Rules kept: pure Dart, no runtime deps (allowlist stays empty), deterministic (D8), "one calculation": the app, `tools/catalog` and Buddy's ProposalEngine all call `NutritionCalculator`. `README.md` gains **Rounding rules** (D2/D3) and **Sanity tolerances** (D5) sections, the documented source the card asks for.

**3.2 `fb_text`** (barrel `lib/fb_text.dart`)
```
src/normalize/tables.dart     the character tables of D11 (Arabic folds, digit maps, Latin accent table)
src/normalize/normalizer.dart normalizeKey(String) + the step functions (foldDigits, foldArabic, foldLatin) for the parser
src/parse/number_words.dart   EN/AR/Arabizi number and fraction words (stored already normalized)
src/parse/unit_words.dart     unit and portion words → codes (D12), incl. dual forms
src/parse/quantity_parser.dart parseNumber, parseQuantity → ParsedQuantity
```
`fb_text` dev-depends on `fb_domain` (workspace path) only for the unit-code consistency test. Runtime deps stay empty.

**3.3 Shared spec.** `contracts/testdata/normalization_cases.yaml` (D13). `contracts/testdata/README.md`: the table row is marked "S08 (Dart) ✅, S30 (C#)", and a new section gives the file format, the D11 pipeline and tables (the C# implementer's spec), and the pass rule.

**3.4 Build.** `dart-test-all.sh` coverage (D15). `build/` is already gitignored. Pubspecs: `glados: 1.1.7` dev in both packages, `fb_domain` path dev dep in `fb_text`. Lockfile updated.

### 4. Work packages (sequential, all `flutter-engineer`; the laptop has 7 GB)

| WP | Content | Files | Done when |
|---|---|---|---|
| **WP1** fb_domain quantities & nutrition + gate | D1–D6, D14–D16: rounding, units, `FoodMeasures`, `FoodState`, `Nutrients`, calculator, sanity, yield. Test helpers (`propertyRuns`, generators). Barrel test. Coverage gate in `dart-test-all.sh` (closes backlog #6). README sections | `packages/fb_domain/{lib/src/math,units,food,nutrition}/**`, `test/**`, `pubspec.yaml`, `README.md`, `tools/scripts/dart-test-all.sh`, `pubspec.lock` | `make check-dart test-dart` green, coverage of fb_domain ≥ 95% printed. **Gate proof:** temporarily delete one test file → `make test-dart` fails with the percentage (output pasted in the WP report, then restored) |
| **WP2** fb_domain time & IDs | D7–D10: Clock, `system.dart`, LocalDate, EntryTime, WeekCalendar, UUIDv7, HLC. Determinism grep test (D8). Doc comments give the HLC format | `packages/fb_domain/lib/{system.dart,src/time,src/ids}/**`, tests | Green, coverage ≥ 95%, all property tests at 1,000 runs |
| **WP3** fb_text normalization + golden file | D11, D13: tables, `normalizeKey`, golden loader test (resolves `../../contracts/testdata/…` from the package dir, the way `dependencies_test` reads `pubspec.yaml`), ≥ 100 cases, idempotence property, testdata README | `packages/fb_text/lib/src/normalize/**`, tests, `contracts/testdata/normalization_cases.yaml`, `contracts/testdata/README.md` | Every golden case passes and names its `id` on failure. Case count ≥ 100 asserted. Green |
| **WP4** fb_text parsing | D12: number words, unit/portion words, `parseQuantity`, table-driven tests, unit-code consistency test against `fb_domain` | `packages/fb_text/lib/src/parse/**`, tests, `pubspec.yaml` | Green, fb_text coverage ≥ 95%, `make trace` lists the step's IDs as tested |

### 5. Test list (Dart test names start with the spec ID where one applies)

**fb_domain**
- `FD-002 core nutrients are required and non-negative; extras optional and kept apart from the core`; `FD-002 adding Nutrients keeps an extra only if both sides have it`
- `LC-011 any unit converts to canonical grams/ml whatever the unit setting` (g, kg, oz, lb, ml, l, fl oz, cup, tbsp, tsp, serving unit)
- `LC-010 display values follow the unit system (metric default, imperial lb/oz/fl oz/ft+in)`; `LC-012 energy is kcal only`
- `LC-051 a food-specific portion unit (loaf) resolves to that food's grams`; `volume input on a per-100 g food without density → NeedsDensity`; `unknown serving unit → UnknownServingUnit`
- `property: unit round trips g↔oz↔lb, ml↔fl oz↔cup↔tbsp↔tsp, cm↔in are identity within 1e-9 relative` (1,000 runs)
- `rounding: half away from zero at storage precision (2.675→2.68, 1.005→1.01, 0.004→0)`; `display rounding table (D3)`; `day total rounds the sum of stored values, not displayed values`
- `calculator: per-100 g × grams / 100, snapshot rounded once`; `per-100 ml drink with ml input`; `zero amount → zero nutrients`
- `property: calculator is linear within rounding (|f(a)+f(b)−f(a+b)| ≤ 0.015 per nutrient)` and `non-negative, monotonic in amount` (1,000 runs)
- `FD-012 consistent food → ok (US-style carbs)`, `… (EU-style carbs with fiber at 2 kcal/g)`, `alcohol counted at 7 kcal/g`, `15–30% off → warn`, `> 30% off → fail`, `low-kcal food within the 15 kcal floor → ok`, `negative value / kcal > 920 / macros > 105 g → hard fail`, `result reports expected kcal and deviation`
- `FD-060 cooked amount converts to dry via the factor`, `inverse row is used when only the reverse exists`, `no factor → null`, `property: convert there and back is identity within 1e-9` (1,000 runs)
- `FD-062 yield note carries from/to amounts and states, rounded to 5 g ("200 g dry ≈ 500 g cooked")`
- `DY-001 an instant maps to the local calendar date of its offset`, `DY-001 suhoor at 03:30 counts toward that calendar day (T31)`, `DST: offsetMinutesAt is used for the instant, not "now"`
- `DY-002 an entry keeps its stored local time and date after the device zone changes`; `tz offset outside −720…+840 is rejected`
- `LC-021 week starts Saturday by default`, `LC-021 week start is configurable`, `property: weekStartOf(d) ≤ d < weekStartOf(d)+7 and falls on the chosen weekday` (1,000 runs)
- `LocalDate parse/format ISO, invalid dates rejected`, `property: plusDays(n).plusDays(−n) is identity` (1,000 runs)
- `UUIDv7 has version 7 and the RFC variant`, `encodes the clock's ms`, `property: ids from one generator are strictly increasing, even with a clock that goes backwards` (1,000 runs), `same seed → same ids`
- `HLC toString/parse round trip`, `property: now() is strictly monotonic under any clock sequence`, `property: receive(r) > both the last local and r`, `property: string order equals compareTo order` (1,000 runs each), `counter overflow throws`, `remote beyond maxForwardDrift throws HlcDriftException`
- `structure: barrel exports every src file`; `DateTime.now / Random only in system.dart`; `SystemClock returns UTC and the device offset`; existing dependency allowlist tests

**fb_text**
- `golden: every case in normalization_cases.yaml passes (id in the failure)`, `golden: at least 100 cases, unique ids`, `golden: every expected key is a fixed point`
- `property: normalizeKey is idempotent on arbitrary Arabic/Latin/digit/symbol strings` (1,000 runs)
- `LC-051 portion words رغيف صحن حبة كاسة سندويشة قرص map to codes`, `LC-051 Arabic dual (رغيفين, حبتين) means 2`
- `parse: digits, decimals (. ٫ ,), Arabic-Indic digits, ½ and 1/2`; `EN number words and "and a half"`; `AR words نص ربع تلت, "ونص", MSA and dialect spellings`; `Arabizi nos/rob3/etnen`; `LC-011 "8 oz chicken" parses to 8 oz + "chicken"`; `quantity at the end ("chicken 150g")`; `no quantity → amountImplicit = 1`; `ملعقة alone → tbsp`; `unparseable text → null`
- `every fb_text unit code resolves in fb_domain`; existing dependency allowlist tests

### 6. Exit-criteria mapping

| Exit criterion | Shown by |
|---|---|
| fb_domain and fb_text line coverage ≥ 95% | D15 gate inside `make test-dart` (local + CI `dart` job). Percentages printed in the CI log. The WP1 gate proof shows it fails |
| All golden cases pass, format documented | WP3 golden tests in CI. `contracts/testdata/README.md` format section |
| Property tests ≥ 1,000 runs each in CI | Every property test uses the shared `propertyRuns` (1,000). Verifier greps that no property test sets its own lower `numRuns`. CI `dart` job green |
| No Flutter or I/O dependencies | Existing allowlist tests stay green with an empty allowlist, plus the D8 determinism test |

### 7. Risks & unknowns
- **glados is unmaintained** (Dec 2023). Dev-only, so it can't affect the app. If a future SDK breaks it, switch to kiri_check 1.3.2 (D14). Logged as a known dependency risk, not a blocker.
- **lcov counts fewer lines than a person would** (the spike showed constant `return` lines aren't counted). The gate measures what the tool reports. The barrel test closes the bigger hole (unloaded files).
- **Sanity thresholds are untested on real data** until S13 runs them over the catalog. They're one constant, so tuning is cheap. Noted for the S13 card.
- **C# must match D11 byte for byte** (S30). The explicit tables plus the golden file are the contract. Note for S30: don't use `string.Normalize(FormD)`. Use the same table.
- **HLC wire format** (D10) will appear in sync payloads. The sync step should add `contracts/testdata/sync/hlc_cases.yaml` so C# compares HLCs the same way. Note for the sync card. TD candidate.
- **Dual and dialect coverage** in the parser is a starting list. Every miss later becomes a case (owner optional: add your own spellings to the golden file).

### 8. Size check
**M, upper end (~1.75 sessions):** WP1 ≈ 0.5, WP2 ≈ 0.4, WP3 ≈ 0.4, WP4 ≈ 0.3, plus review and verify. No split is planned. If WP2 isn't done by the end of the first session, the natural seam is **S08a = fb_domain (WP1–2)** / **S08b = fb_text (WP3–4)**. They share nothing except the dev-only unit-code test.

### 9. Amendments after architect review (2026-10-13, orchestrator-applied, these override the sections above)

| # | Change | Overrides |
|---|---|---|
| A1 | **Repeat-collapse:** Latin a–z runs ≥ 2 → 1; Arabic long vowels ا و ي runs ≥ 2 → 1; any other Arabic letter only runs ≥ 3 → 1; digits untouched. Golden: اللبن ≠ البن, مملح ≠ ملح, فوول = فول, فوووول = فول | D11 step 7 |
| A2 | **No Unicode/locale APIs:** lowercase = ASCII A–Z + the explicit Latin-1/Ext-A fold table only; step 6 keeps an explicit allowed set (`a–z`, `0–9`, space, Arabic U+0621–U+063A and U+0641–U+064A after folding), everything else → space. Allowed set documented in `contracts/testdata/README.md`. Golden: İ, Cyrillic, emoji, ـ | D11 steps 5–6 |
| A3 | **Seat folding:** ئ → ي, ؤ → و; standalone ء unchanged (matches how ئ/ؤ are typed in Levantine/Egyptian writing). Golden: شيء / شئ / شي behaviour. `07` §5.1 wording clarified at close | D11 step 4 |
| A4 | **Sanity mass hard-fail uses the selected carb convention:** P+C+F (US) or P+C+F+fiber (EU). Test `FD-012 high-fiber US-style food (chia) is not a hard fail` | D5 |
| A5 | **UUIDv7 counter overflow:** seed rand_a with its top bit clear; on overflow advance to the next ms and reseed (RFC 9562 §6.2). Property: frozen clock, 5,000 IDs strictly increasing and valid | D9 |
| A6 | **HLC device ID** must be a lowercase canonical UUID (36 chars), validated. Doc + forward note for S09/S12/S26: compare HLC columns with binary collation (SQLite BINARY, Postgres `COLLATE "C"`). Receive returns a result (`ok` / `driftRejected`) instead of throwing; the drift policy is S26's | D10 |
| A7 | **Clock ban list** adds `DateTime.timestamp(`, `.toLocal(`, `.timeZoneOffset`, and the local-zone `DateTime(` constructor (grep outside `system.dart`); domain arithmetic uses `DateTime.utc` only | D8 |
| A8 | **Calculator computes from the stored (rounded) canonical amount;** storage rounding happens in the persisted column's unit (body weight in kg, food in g/ml). The yield calculation uses the exact converted amount; only the note's text is rounded to 5 g | D2, D6 |
| A9 | **Golden file typing:** every `input` and `key` is double-quoted; the loader asserts `String` and fails with the case `id`; documented in the README | D13 |
| A10 | **Parsing:** ملعقة صغيرة → `tsp`, ملعقة كبيرة → `tbsp` explicitly. Backlog: علبة (can/box) as an unresolved portion word. Forward notes: S13 tunes sanity thresholds; S15 dedups on a stricter key (no Latin repeat-collapse); S30 C# uses the same tables (no FormD) | D12, notes |

**Plan approved by the orchestrator under TD-037 (no ⚠️ OWNER item), 2026-10-13. TD candidates for close:** HLC wire format · search-key normalization rules (extends TD-030) · numeric precision.

## Progress log
_One dated line per event, newest last (process §8a)._

- 2026-10-13 · A: ready (S01 ✅, no owner prerequisites, main green 98ae7a7 after S02). Branch created. B: step-planner launched (does its own version checks: glados, UUIDv7, decimal).
- 2026-10-13 · B: low-level plan written (D1–D16, WP1–WP4, no ⚠️ OWNER; glados 1.1.7 spiked, kiri_check fallback). Architect review launched.
- 2026-10-13 · B: architect approve with changes; A1–A10 applied; plan approved under TD-037 (owner FYI). C: WP1 (flutter-engineer) launched.
- 2026-10-13 · C: WP1 committed (fb_domain units/nutrients/calculator/sanity/yield, 72 tests, coverage 100%, gate in dart-test-all.sh; backlog #6 done). WP2 (time, UUIDv7, HLC) launched.
- 2026-10-13 · C: WP2 committed (Clock/LocalDate/EntryTime/WeekCalendar, UUIDv7, HLC with receive result; 119 fb_domain tests, 100% coverage; DY-001/002, LC-021 covered). Note for S26: client drift 24 h vs server clamp "a few minutes". WP3 (fb_text normalization + golden) launched.
- 2026-10-13 · C: WP3 committed (normalizeKey 8-step pipeline, explicit tables, 171 golden cases, fb_text 100%). Gap → WP4: ligatures ﬁ/ﬂ and fullwidth Latin become spaces. WP4 (parsing) launched.
- 2026-10-13 · **RESUME POINT (usage limit approaching).** Committed + pushed: plan, A1–A10, WP1 (d576307), WP2 (2fd36c5), WP3 (6fc9753). **WP4 in flight, uncommitted** (flutter-engineer): fb_text quantity parser (D12 + A10 spoon rules, Arabic duals), dev-only test that every emitted unit code resolves via fb_domain `isKnownFoodUnitCode` (path dev-dep fb_text → fb_domain), and the WP3 follow-up (fold ligatures U+FB00–FB06 and fullwidth U+FF01–FF5E before the allowed-set filter; update golden + contracts/testdata/README.md). Not mapped on purpose: علبة (backlog). **To resume:** `git status` / `git diff` to see WP4's partial work; if `make check-dart test-dart` is green and the scope above is complete, commit it; otherwise re-brief a flutter-engineer with this line and the existing diff. Then: Phase D (code review; security not needed: no I/O, auth or infra), verifier, Outcome, close docs (`07` §5.1 clarify ئ→ي ؤ→و; TDs: HLC wire format, normalization rules, numeric precision; forward notes S09/S12/S13/S15/S26/S30; backlog علبة), merge via `merge/S08` (TD-039).
- 2026-10-13 · C: WP4 agent was cut off by the usage limit at its final gate run; orchestrator ran the gates (check-dart, test-dart green; fb_text 46 tests, 100% coverage; trace 0 warnings), checked scope (parser, unit-code test, A10 spoons, ligature/fullwidth folds + README) and committed. D: code review launched.
- 2026-10-13 · D: code review approve; 1 major (parser splits food names like حبة البركة / 7 Up with no uncertainty signal), minors (ban-list bypass via `.now()` shorthand / `.new`, µg → g, zero amounts, غ abbreviation, a third of, coverage-gate zero-lib edge), nits. Fix WP-F1 (flutter-engineer) launched. Golden is now 182 cases.
- 2026-10-13 · D: WP-F1 committed (8 items: `ParsedQuantity.original` + consumer rule + pinned regressions, end quantity wins over bare portion word, ban-list shorthand/.new/multi-line, µg/mcg never g, zero → null, غ after numbers, x2 counts, "a third of a cup", coverage-gate edge, rounding guard, docs). Round-2 review + verifier launched.
- 2026-10-13 · D/E: round-2 review approve (round-1 all fixed; 3 minors + 1 nit → backlog #28–31). Verifier PASS 4/4 on 48f5b42 (CI green, fresh clone green). Accepted under TD-037. Merge via `merge/S08` (TD-039).

## Outcome
_Written 2026-10-13 (Phase E)._

**Built.** `fb_domain`: rounding (store once, 2 dp, half away from zero; display rules), units (mass, volume, length, energy; metric/imperial), food measures (serving units, density), `FoodState`, `Nutrients` (+ optional extras), `NutritionCalculator`, `SanityCheck` (FD-012), `YieldConverter` (FD-060/062), `Clock`, `LocalDate`, `EntryTime` (stored offset, DY-002), `WeekCalendar` (Saturday default), UUIDv7, HLC, and a test-enforced ban on device clock/randomness outside `system.dart`. `fb_text`: `normalizeKey` (8-step pipeline, explicit tables, TD-050), quantity parser (EN/AR/Arabizi numbers, fractions, units, portion words, Arabic duals, spoon sizes) with `original` kept for the "match the whole text first" rule. `contracts/testdata/normalization_cases.yaml` (182 cases) + README spec for the C# side. Coverage gate ≥ 95% in `dart-test-all.sh` (backlog #6 done).

**Evidence.** Verifier PASS 4/4 on 48f5b42: coverage fb_domain 100% (564/564), fb_text 100% (384/384); 182 golden cases pass; 28 property tests at 1,000 runs; zero runtime deps; CI green; fresh clone green. `make trace`: 11 S08 IDs covered (FD-002, FD-012, FD-060, FD-062, DY-001, DY-002, LC-010, LC-011, LC-012, LC-021, LC-051), 0 warnings.

**Deviations.** Added `Length` (LC-010 ft+in) and `LocalDateTime`, `IdGenerator`. Ban list wider than A7 (`DateTime.parse`, `fromMillisecondsSinceEpoch` without `isUtc`, shorthand `.now()`, `.new`). Extra invisible-character deletions and Persian/loanword letter folds (ڤ پ چ گ), ligature and fullwidth folds. One lint off in fb_domain (`avoid_equals_and_hash_code_on_mutable_classes`: needs package:meta). WP4's agent was cut off by the usage limit at its final gate run; the orchestrator ran the gates and committed.

**Follow-ups.** Backlog #26–31 (علبة, shared fake clock, parser double-quantity and zero cases, ban-list shorthand edges, end-wins doc). Forward notes on S09, S12, S13, S15, S26, S30.

**New TDs.** TD-048 numeric precision · TD-049 HLC wire format · TD-050 search-key normalization rules (extends TD-030).

**Metrics.** Planned M (~1.75 sessions), actual ~1.5 sessions. 4 WPs + 1 fix WP. 2 review rounds. Findings: round 1: 1 major, 4 minor, 3 nits (all fixed); round 2: 3 minor + 1 nit (backlog). Tests added: fb_domain 121, fb_text 51 (incl. 28 property tests), golden 182 cases.
