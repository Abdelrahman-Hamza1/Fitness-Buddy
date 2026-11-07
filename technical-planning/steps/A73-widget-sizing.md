# A73 — Widgets use their space (app, Android)

| Track | Depends on | Size | Owner | Status |
|---|---|---|---|---|
| App | A71 | S–M | Claude (Opus plan + build), one Codex review | ✅ |

**Goal.** Owner feedback on the A55 (2026-11-07): "the widgets are too spacious, too big when not a lot of the size is utilized". A71's content has fixed sizes (76 dp ring, 10–18 sp text) inside a card that stretches to the launcher's cells, which are large on One UI. Make the content fill the widget at every size, and allow smaller sizes (UX-082 defaults unchanged).

## Scope
1. **Size-aware layouts:** Android 12+ `RemoteViews(Map<SizeF, RemoteViews>)` (and `onAppWidgetOptionsChanged` + OPTION_APPWIDGET_* sizes on 8–11) choose a layout per actual size; the ring, numbers and buttons scale up in bigger sizes (bigger ring and text, taller buttons), less padding.
2. **Compact variants:** numbers widget down to 2×1 (ring + protein side by side, or kcal number + protein line); medium widget down to 4×1 (ring, kcal left, macros in one row; buttons only from 2 rows). Lower `minResizeWidth/Height` to what those layouts truly need; keep `targetCell*` defaults (4×2, 2×2, 2×1).
3. Same snapshot, same tap routing, hidden/signed-out states in every variant; light/dark colours unchanged.
4. Tests (lean): the size → layout choice (pure Kotlin or Dart mapping, whichever holds the logic), and existing widget tests stay green.

## Exit criteria
1. On the A55: each widget looks full at its default size and when resized smaller/larger; nothing clipped.
2. CI green; Codex review passed.

## Low-level plan

_Written 2026-11-07 by the A73 engineer (Opus), lane 1, on `4cc561c5`. Tier **Normal** (Android rendering only: no data, no new component, permission or dependency). Self-approved (orchestrator brief). WP1–WP3, one local commit each._

| # | Decision | Why |
|---|---|---|
| D1 | **Variants per widget, each with the minimum size its content needs** (dp; sums in each layout's header comment). Medium: `ROW` 280×72 (ring 56 + the four macros in one row; with no numbers the row holds Speak · Ask · Weigh, UX-085 "buttons only"), `REGULAR` 280×136 (A71's look, tighter: ring 72, buttons 36), `LARGE` 320×184 (ring 96, 12–17 sp text, 6 dp bars, 48 dp buttons). Numbers: `ROW` 110×64 (ring 48 + protein beside it), `ROW_LARGE` 150×84 (ring 64 + bigger protein; the 2×1 cell on One UI), `REGULAR` 110×120 (ring 68 + protein under it), `LARGE` 150×170 (ring 100). Buttons: `REGULAR` 110×40 (icons), `LARGE` 140×72 (bigger icon above its label). | One UI cells are ~90–110 dp tall: the regular content left half the card empty |
| D2 | **Choice rule in one pure Kotlin function** (`WidgetSizing.choose`, no Android types), a copy of the platform's rule for `RemoteViews(Map<SizeF, RemoteViews>)` (`RemoteViews.findBestFitLayout`): of the variants that fit, the one closest to the size (squared distance); none fits → the smallest. Unknown size (0, options not reported yet) → the regular variant (the default cell size). | One rule for both paths; JVM-testable |
| D3 | **Android 12+:** one `RemoteViews(Map)` with every variant; the launcher picks per actual size, no redraw on resize. **Android 8–11:** per widget id, `choose(OPTION_APPWIDGET_MIN_WIDTH, OPTION_APPWIDGET_MIN_HEIGHT)` (the smaller of portrait/landscape on each axis: never clipped, at worst a size smaller in portrait), redrawn in `onAppWidgetOptionsChanged`. The options come from `AppWidgetManager`, not the broadcast; ids are filtered to our provider's (an outside app can still only cause a redraw). | Responsive on 12+, correct on 8–11 |
| D4 | **Advertised sizes:** `minResizeWidth/Height` = the smallest variant (medium 280×72, was 280×146; numbers 110×64, was 110×126; buttons 110×40, unchanged); each family's smallest variant is ≤ every other on both axes, so every allowed size fits a variant (A71 review: never advertise a size the content can't fit; JVM test reads the provider XML). `minWidth/minHeight` (pre-12 default span) = the regular variant; `targetCell*` unchanged (4×2, 2×2, 2×1). | Smaller sizes, nothing clipped |
| D5 | **Same ids in every variant** (ring, ring_value, …, plain_block, buttons) so one render path fills them; the medium row has no `eaten_of` (skipped). Same tap PendingIntents (fixed actions, explicit, immutable), same signed-out/hidden/stale handling, colours from the existing day/night resources, drawables reused. `previewLayout`/`initialLayout` stay the regular layouts (the picker shows the default size). | No new surface |

**Work packages:** WP1 `WidgetSizing.kt` + JVM test (`HomeWidgetSizingTest`) · WP2 the new layouts, tightened regular layouts, size-aware rendering in `HomeWidgets.kt`, provider metadata · WP3 docs (this card's Outcome, board).

## Progress log
- 2026-11-07: card from owner feedback; one engineer plans + builds.
- 2026-11-07 · plan written (Opus engineer, lane 1) on `4cc561c5`; self-approved per the brief.
- 2026-11-07 · WP1 `15324cf4`: `WidgetSizing.kt` (variants with their minimum sizes, `choose` = the platform's best-fit rule) + host JVM test `HomeWidgetSizingTest` (runs in `make test-android-unit`, CI `android` job).
- 2026-11-07 · WP2 `691967b9`: six new layouts (`widget_medium_row/_large`, `widget_numbers_row/_row_large/_large`, `widget_buttons_large`), the three regular ones tightened; `HomeWidgets.update` sends a `RemoteViews(Map)` on 12+ and picks per id on 8–11 (`onAppWidgetOptionsChanged`), ids filtered to ours; provider XML minimums. Test checks the provider XML against the variants and every layout's ids.
- 2026-11-07 · checks: `make test-android-unit` ✓ (HomeWidgetSizingTest 7, SessionStorageCommitterHostTest 6), `:app:compileDevDebugKotlin` ✓ (resources linked), `make check-dart` ✓, focused tests ✓ (TZ=UTC: test/android, features/home_widgets, core/home_widget: 24), `build-android-selftest.sh` ✓, `make apk-hardening-selftest` ✓. Not run on a device.
- 2026-11-07 · Codex review: no blockers, 1 major, 2 minors, all fixed in one commit. Major (compact rows clipped "~92/150"-style values at their minimums): the one-row layouts (medium row, numbers row and large row) show only the eaten grams (new additive snapshot key `<macro>.eaten`, snapshot v1 unchanged, Kotlin falls back to the full text); worst cases measured in every layout header ("~1,250" compact, "~1,250/300" roomy with the label ellipsizing, "~2,500" and "kcal eaten" in every ring). Minors: `fitsIn` uses Android's `ceil(actual) + 1 > layout` tolerance (+ fractional-boundary test); the visibility per state is a pure `WidgetFace.of` used by the render path and tested for every variant × numbers / no numbers / signed out; test names say what they prove (declared sizes, declared ids). Not JVM-testable without Robolectric (not a dependency): inflating each layout at its minimum and the tap PendingIntents — the A55 check covers them. `make test-android-unit` ✓ (9 + 6), `:app:compileDevDebugKotlin` ✓, `make check-dart` ✓, focused Dart tests ✓ (TZ=UTC: 24).

## Outcome

_Built 2026-11-07 on `4cc561c5` (lane 1). Not pushed; the Codex review and merge are the orchestrator's._

**Built:** WP1–WP2 as planned, WP3 = this card. Size: S–M. No Dart change (same snapshot), no manifest change (no new component, permission or receiver; `TodayWidgetClock` untouched).

| Widget | Layouts (min dp) | `minResize` before → after | Default |
|---|---|---|---|
| Medium | row 280×72 · regular 280×136 · large 320×184 | 280×146 → **280×72** (4×1) | 4×2 |
| Numbers | row 110×64 · large row 150×84 · regular 110×120 · large 150×170 | 110×126 → **110×64** (2×1) | 2×2 |
| Buttons | regular 110×40 · large (labels) 140×72 | 110×40 (same) | 2×1 |

**Notes:** the one-row layouts show only the eaten grams per macro (the bar shows the target; A73 review). The medium row has no room for "eaten / target" and the buttons; with no numbers (hidden or no day) the buttons take the row instead (UX-085 "buttons only"). Large layouts assume the 4-wide cell is ≥ 320 dp (most phones; the A55 should be ~350–380); narrower falls back to the regular layout. The widget picker previews stay the regular layouts. Below Android 12 the size is the smaller of portrait/landscape (never clipped, may be a size smaller).

**Owner checks on the A55:** each widget at its default size (medium should show the large layout, numbers the large ring, buttons with labels); shrink medium to 4×1 and numbers to 2×1; hidden numbers and signed out in the row sizes; dark mode; nothing clipped (especially "~" values like "~1,240" inside the ring).

