# A02 — Design system v0 & key screen mockups

| Track | Depends on | Size | Owner | Status |
|---|---|---|---|---|
| App | S06 ✅ | L | Claude | 🟨 In progress |

_Old ID: S07 (renumbered by TD-063, 2026-10-16)._

**Goal.** A token-based design system (`fb_design_system`) with the components every screen needs, plus static mockups of the key screens for the owner to react to (TQ-14). After this, feature steps build screens from components instead of inventing UI.

**Spec:** UX-040–044, UX-050, UX-051, UX-070, UX-071, SF-021, SF-022, SF-041, IN-020, AI-032 (estimate marker), FD-010 (badges) · **Decisions:** TD-014

## Scope
- **Tokens:** colour (brand, neutrals, one colour per macro, a **neutral over-target tone** never alarm red, success/info), type scale (bundled Latin + Arabic font pair), spacing, radii, elevation, motion durations. Light and dark themes.
- **Components:** buttons (primary/secondary/text), cards, list rows, section headers, **big number display** (HM-001), progress bar, macro bars, **chips** (assumption chip, answer chip, quick-add chip), **source badges** ⓨ ⓓ ⓡ ~ + legend sheet (UX-044), estimate marker with a range sheet (AI-032), **number pad + unit picker**, text input bar shell, bottom-sheet shell, **undo snackbar** (UX-030), skeletons (UX-051), **empty state** (UX-050), inline error/offline banners (UX-052/053), date header with day navigation.
- **Chart wrappers** API (implementation in A15): line + points, bands, goal line, tooltips. Only the interface + a placeholder here.
- **Quality:** an automated **WCAG AA contrast test** over the token palette (UX-071). Goldens for every component in light/dark, text scale 1.0 and 2.0 (UX-070), LTR and RTL.
- **Gallery** screen (dev flavor only) listing all components and states.
- **Static mockups** built from the components with fake data: **Today** (as in `spec/16` §1), **food proposal card** (as in `spec/10` §4.1, with a question and chips), **edit proposal (before → after)**, **weight card + chart placeholder**, **Progress tab** overview.

## Out of scope
- Real data, navigation flows, real charts (A08, A15, A16, A22).

## Fixed by the plan
- `material_ui` as the base, wrapped. Screens only use `fb_design_system` components.
- No streaks, badges-as-gamification, scores or alarm-red states (IN-020, SF-021).

## Decide in the low-level plan
- The font pair (e.g. Inter + IBM Plex Sans Arabic) and licences.
- The colour palette (a proposal with 2 variants for the owner to pick).
- The icon set (Material Symbols vs an alternative).

## Exit criteria
- [ ] The gallery shows every component in light/dark. Goldens for all components pass in CI (light/dark × scale 1.0/2.0 × LTR/RTL).
- [ ] The contrast test passes for all text/background token pairs.
- [ ] The owner reviewed the mockups **on the A55**. Feedback is recorded in the Outcome and applied (or ticketed to a later step).

## Read first
`spec/30-ux-principles.md` · `spec/16-insights-and-home.md` §1 · `spec/10-ai-assistant.md` §4 · `09-cross-cutting.md` §3, §7

## Owner involvement
A ~30-minute review of the gallery and mockups on the phone. Pick a palette variant.

The same phone session also covers S06b's deferred device acceptance (S06 A11): install the signed staging APK on the A55, check the four tabs and light/dark, `make cold-start` baseline (recorded in S06's Outcome), and `/v1/config` on the device: `make run-dev` + the local API (adb reverse), or the laptop test server if B03 is done.

---

## Low-level plan
_Written in Phase B (2026-10-17) by the step-planner, wave 1 lane D, against `plan/wave-1` 8920f82. Facts checked 2026-10-17 (sources at the end of §7)._

### 1. Summary
A new Flutter workspace package `packages/fb_design_system` holds the tokens (colour, type, spacing, radii, elevation, motion), two palette variants (A default, B for the owner to compare), light and dark `ThemeData` built on `material_ui`, a bundled Latin + Arabic font pair, its own small ARB for built-in component strings, the R1 component set, chart-wrapper interfaces with a placeholder, an automated WCAG AA contrast test, and component goldens across light/dark × 1.0/2.0 × LTR/RTL. The app switches to the design-system theme, its placeholder screens use DS components (backlog #35), and a dev-flavor-only **Design preview** (gallery, tokens, five static mockups, palette and theme switches) is reachable from the Me tab. The owner reviews it on the A55 in the same phone session as S06b's device acceptance.

### 2. Decisions

| # | Decision | Reason / source |
|---|---|---|
| D1 | **Fonts: Inter (variable, `opsz`+`wght`, 877 KB) + Noto Sans Arabic (variable, `wdth`+`wght`, 845 KB), both SIL OFL 1.1**, bundled as package assets from `google/fonts` at a pinned commit (sha256 in `assets/fonts/SOURCES.md`, each `OFL.txt` alongside). Inter is the primary family, Noto Sans Arabic its `fontFamilyFallback`, so Arabic food names and typed text render in a matched sans. Numbers use `FontFeature.tabularFigures()` (Inter has `tnum`). The OFL texts are registered with `LicenseRegistry` (lazy, read only when the licence page opens, so nothing extra on the startup path) | Measured 2026-10-17 on the files: Inter's default digits are proportional and it has `tnum`. **Noto Sans Arabic's Latin and Arabic-Indic digits are both tabular by default** (all 572 units). IBM Plex Sans Arabic (the card's example, 3 static weights ≈ 725 KB) has tabular Latin digits but **proportional Arabic-Indic digits and no `tnum`**, which would bite LC-004's digit style in R2. Both variable fonts have a `wght` axis, and since Flutter 3.41 `fontWeight` drives `wght` automatically, so one weight scale serves both scripts (Flutter breaking-change note). Plex is the fallback if the owner dislikes Noto's look. About +1.7 MB raw assets, less in the compressed APK |
| D2 | **Icons: the Material Icons font that `material_ui` already ships (`uses-material-design: true`), rounded variants, behind one `FbIcons` class** (const `IconData`s; previous/next and other directional icons with `matchTextDirection: true`). Material Symbols (`material_symbols_icons 4.2960.0`) is not added | No new dependency. Release builds tree-shake the icon font. Rounded glyphs fit UX-043's "modern". `FbIcons` is the only place icons are named, so a later switch to Symbols touches one file. Screens never use `Icons.*` directly (convention, checked in review) |
| D3 | **Two palettes, both full themes; variant A ships as the default** (table in §3.2). **A "Fresh"**: teal brand, cool slate neutrals. **B "Warm"**: deep indigo brand, warm stone neutrals. Each has its own self-consistent macro set (protein, carbs, fat, fiber), a **neutral over-target tone** (slate/stone 500 text tone, never red, SF-021), success and info. The hex values in §3.2 are the starting point. WP1 tunes lightness only until the contrast test passes, and keeps hue | Card: 2 variants for the owner. Giving each variant its own macro set lets the brand hue never collide with a macro colour. The pick is an **owner check that doesn't block** (TD-037, the owner is asleep): default A, so A02 can merge before the pick. **After the pick**, the losing variant and the switch are removed in a small follow-up (backlog item, done at the start of A08) |
| D4 | **Theme = explicit `ColorScheme` + `ThemeExtension`s, no `fromSeed`.** `FbTheme.light(variant)` / `FbTheme.dark(variant)` build `ThemeData` from the tokens: the colour scheme, text theme, and component themes (filled/outlined/text buttons, card, chip, snackbar, bottom sheet, navigation bar, input decoration, list tile). Product roles that Material lacks (macros, overTarget, success, info, badge, skeleton) live in `FbColors extends ThemeExtension<FbColors>`, read with `context.fbColors`. Spacing, radii, elevation and motion don't depend on the theme, so they're `abstract final class` consts (`FbSpace`, `FbRadius`, `FbElevation`, `FbMotion`) | `fromSeed` can't guarantee our macro hues or the contrast pairs. Using a ThemeExtension is the Material-native way to add roles. Consts keep spacing free at runtime |
| D5 | **The design system owns its built-in strings** (`lib/l10n/fb_ds_en.arb` → gen-l10n → `FbLocalizations`, output committed under `lib/l10n/gen/`). These are only strings intrinsic to a component: "Undo", the source-legend titles and descriptions, the badge letters, the range-sheet headings, number-pad semantics and "Done", date-header previous/next semantics, the chart placeholder. Everything content-like (titles, messages, numbers, food names) comes in as a parameter. The app adds `FbLocalizations.delegate` to `FitnessBuddyApp.localizationsDelegates` | Strings stay in ARB (rule 8), are ready for Arabic in R2, and screens can't forget the shared texts. Numbers are formatted by the app and passed in already formatted (LC-004's digit style stays app-side). The DS takes `double`s only for geometry (bar fill) |
| D6 | **Dependency allowlist for `fb_design_system`**: runtime deps `flutter`, `flutter_localizations` (gen-l10n output), `intl` (gen-l10n output), `material_ui 1.6.0` (same exact pin as the app, TD-014). A `test/dependencies_test.dart` (pattern of `fb_text`) also fails on `lib/` imports of `dart:io`, `package:flutter/material.dart` / `cupertino.dart` (use `material_ui`), any `package:fb_*`, riverpod, dio, go_router, drift or shared_preferences | Pure presentation: no state management, no I/O, no domain types. The app maps domain values (e.g. a food's source) onto DS enums. `material_ui 1.7.0` (2026-10-14) is out; it stays on 1.6.0 and is bumped on purpose (S06 D1) |
| D7 | **Goldens: alchemist 0.14.1 CI goldens with obscured text (S06 D17 unchanged), real bundled fonts loaded.** Alchemist's `loadFonts()` loads every family in `FontManifest.json`, so text **layout** (widths, line breaks, overflow at 2.0) uses Inter/Noto metrics, while glyphs are drawn as blocks. That makes the images the same on the laptop and on CI Linux. The glyph look (Arabic shaping, weights) is reviewed in the gallery on the A55, not in goldens | Deterministic by construction. Real-glyph goldens risk anti-aliasing diffs between machines and would need `diffThreshold` tuning. WP1 adds one **optional real-text type specimen** golden as a time-boxed spike (≤ 30 min): keep it if the laptop and CI produce the same PNG, otherwise drop it and record that in the Progress log |
| D8 | **Golden matrix: one PNG per component.** A helper `fbGoldenMatrix(description, fileName, states: {name: builder})` renders a grid. There are two blocks (text scale 1.0, then 2.0). Each block has one row per state, and each row has 4 cells: light-LTR, light-RTL, dark-LTR, dark-RTL. Every state is in all 8 combinations (the full card matrix, nothing sampled). Cells are fixed-width (360 dp, the phone width) at DPR 1.0, height intrinsic. Palette B gets **only** the tokens sheet golden (swatches in light/dark), not a second component matrix. **Mockup goldens** (in the app) are LTR only in R1 (`09` §3): light/dark × 1.0/2.0, a 360 × 800 viewport each | ~21 component PNGs + 1 tokens + 5 mockups, each a single pump. The estimate is < 90 s added to `test-dart` and roughly 2–4 MB of PNGs. Animations are frozen: goldens run with `disableAnimations: true`, which DS motion honours (skeleton pulse, highlight), so `pumpAndSettle` never hangs |
| D9 | **Text scale 1.0 and 2.0** in goldens, as the card says. `09` §7 says 1.0/1.5/2.0. 2.0 bounds 1.5, so only the big-number golden adds a 1.5 row (the one place where clamping happens, D10). The orchestrator aligns `09` §7 at close | Card wins; flagged in §7 |
| D10 | **Big number (HM-001)**: `FbBigNumber` uses the display style (tabular). Its own text scaler is clamped to ≤ 1.5 (the number is already 48 sp), plus `FittedBox(scaleDown)` so it never overflows. The caption and the progress bar under it scale normally | UX-070 without breaking the hero layout. `09` §7 "big numbers use responsive type" |
| D11 | **Over-target (SF-021, HM-001)**: `FbProgressBar`/`FbMacroBar` take `value` and `target`. When `value > target` the fill is full and uses `fbColors.overTarget` (neutral), with no warning icon. The caller's text says "X over". The only place `ColorScheme.error` is used is `FbInlineBanner.error` and input errors, and even there it's a muted brick, not alarm red | Spec. The no-error-colour rule is asserted by a test |
| D12 | **Source badges**: `enum FbSource { yours, database, referenceDish, estimate }` → ⓨ ⓓ ⓡ ~ (the four sources of `spec/11` §2; label scans and edited values are ⓨ). Adding a fifth value later is additive. Drawn as a 16 dp outlined circle with a letter from the DS ARB (not Unicode circled letters: Inter lacks them, and the letter needs translating in R2). They're monochrome (`onSurfaceVariant`) so they stay "small and consistent" (UX-044). Tapping any badge opens `showFbSourceLegend` (all four, short descriptions from `spec/11` §2). `FbEstimateMarker` (`~`) opens `showFbEstimateRange(rangeText, reason)` (AI-032) | FD-010, UX-044, AI-032, SF-041 |
| D13 | **Undo snackbar seam (UX-030)**: `showFbUndoSnackBar(context, {required String message, required VoidCallback onUndo, Duration duration = FbMotion.undoWindow /*5 s*/})` returns a handle with `close()`. It uses `ScaffoldMessenger`, has no data-layer dependency, and calls `onUndo` at most once. When `MediaQuery.accessibleNavigation` is true, Flutter doesn't auto-dismiss an action snackbar. `showFbUndoSnackBar` keeps that behaviour (WCAG 2.2.1), and a test pins it. Forward note for A08: a tap after A01's UndoStack window returns `UndoOutcome.expired`, which A08 maps to a "can't undo anymore" message. A02 also provides `showFbSnackBar(message)` (no action) for that message and for `conflict`. A01's UndoStack (lane L) is wired by the feature steps, not here | Brief seam |
| D14 | **Chart wrappers = interface + placeholder (A15 implements).** `FbTimeSeriesChart` takes `List<FbSeries>` (`FbPoint(DateTime at, double value)`, a style: line / points / line+points), `List<FbBand>` (lower/upper per point, e.g. the trend range), `FbGoalLine? goal`, `FbChartRange range`, and `String Function(FbPoint)? tooltip`. The doc comment states that time runs chronologically in both directions (LC-003, `09` §3). The placeholder paints a calm framed area with a muted label and keeps its aspect ratio, so the mockups lay out the same as with the real chart. No chart library types appear in the API | Card + A15's card ("screens never use the chart library directly") |
| D15 | **Design preview lives in the app**, as feature `features/design_preview/` (barrel, `presentation/`, `application/`). It's reachable only when `AppConfig.flavor == AppFlavor.dev`: a "Design preview" row on the Me tab and a detail route `DesignPreviewRoute` (`/me/design-preview`) nested in the Me branch. This is the "first detail screen" `app_route.dart` anticipates, so `AppNavigator` gains `push`/`pop`. In staging and prod the row and the route aren't registered (test). The mockups' fake data (food names, numbers) sits in `application/fake_data.dart`, as data, not UI strings. Real product copy ("kcal left today", "Log it", "Discard", "This week: {n} under") goes into `app_en.arb` with keys future steps reuse (`today…`, `proposal…`, `weight…`, `progress…`). Gallery-only labels use `preview…` keys | Card: dev flavor only. A runtime flavor gate is simpler and testable. The unreachable code in release builds is a few KB. The mockups use the same structure the real screens will |
| D16 | **Preview switches**: the theme variant and mode providers (`themeVariantProvider`, `themeModeProvider`, Riverpod notifiers, in memory, defaults `variant: a`, `themeMode: system`) live in `app/theme/` and are watched in `app/app.dart` for `theme`/`darkTheme`/`themeMode`. Only the preview UI lives in `features/design_preview` (the gallery app bar has an A/B segmented button and a light/dark/system toggle that set these providers, so the owner can compare without leaving the screen). In non-dev flavors nothing can change them, so they stay at the defaults | Owner can pick on the phone. Nothing is persisted (the pick is temporary by design, D3). Keeps `app/` from importing a feature's `application/` |
| D17 | **`tools/app_check` gains a package mode** (`app_check --package packages/fb_design_system`): only the lexical rules `raw-string` (whole `lib/`) and `directional`. `make app-check` runs both invocations | Directional layout and ARB-only strings must hold inside the DS too. A small extension of TD-052 (README + fixtures). **Coordination:** A01 adds rules (`db-write-api`, `db-write-call` and two layering rules) to the same tool. Whichever step lands second rebases. Rule IDs are unique, README rows are numbered in landing order, and `--package` mode runs only `raw-string` and `directional`, never the new A01 rules |
| D18 | **Makefile**: `goldens` regenerates both `packages/fb_design_system` and `apps/mobile`. `gen-app.sh` also runs `flutter gen-l10n` in the DS package, and `GEN_DART_DIRS` gains its `lib/l10n/gen`. New `install-android` (`FLAVOR`, `adb install -r` of the APK `build-android` produced, fails readably with no device) for the owner session. `make test-dart` picks the new member up automatically (`dart-test-all.sh`) | Same commands locally and in CI |
| D19 | **Font family names in the package's own tests**: the theme uses `fontFamily: 'Inter', package: 'fb_design_system'` (→ `packages/fb_design_system/Inter`). In the package's own `flutter test` run the manifest may list the family without the prefix, so `test/flutter_test_config.dart` loads both fonts under the prefixed name with `FontLoader` (`loadFbTestFonts()`). WP1 checks this first | Known Flutter behaviour for package fonts. If the fonts silently fall back, every golden's text metrics would be wrong |

**⚠️ OWNER:** none blocking. The **palette pick (A/B)** and the **mockup reactions** are owner checks collected for the morning (TD-037). The default is A. The font pair is free (OFL), with no vendor and no spec change.
**TD candidate:** "Design system conventions" (D1 fonts, D2 icons behind `FbIcons`, D4 explicit scheme + ThemeExtension, D5 DS-owned l10n, D7/D8 golden policy). Also a TD-052 amendment for the app_check package mode (D17).

### 3. Design

#### 3.1 Package layout (`packages/fb_design_system`, `resolution: workspace`, added to the root `workspace:` and `packages/README.md`)
```
pubspec.yaml            deps D6; flutter: generate: true; fonts: Inter, NotoSansArabic (assets/fonts/)
l10n.yaml               arb-dir lib/l10n, template fb_ds_en.arb, output lib/l10n/gen, class FbLocalizations, nullable-getter: false
assets/fonts/           Inter[opsz,wght].ttf, NotoSansArabic[wdth,wght].ttf, OFL-Inter.txt, OFL-NotoSansArabic.txt, SOURCES.md (commit, sha256)
lib/fb_design_system.dart            the only public barrel
lib/src/tokens/  palette.dart (FbPaletteVariant {a, b}; FbPalette roles × light/dark), colors.dart (FbColors ThemeExtension + context.fbColors),
                 typography.dart (FbType scale + numeric()), spacing.dart (FbSpace, FbRadius, FbElevation), motion.dart (FbMotion, honours disableAnimations),
                 contrast.dart (wcagContrast(a, b), FbContrastPair, fbContrastPairs(palette)), icons.dart (FbIcons)
lib/src/theme/   fb_theme.dart (FbTheme.light/dark(variant)), component_themes.dart, licenses.dart (registerFbFontLicenses)
lib/src/components/  button.dart, card.dart, list_row.dart, section_header.dart, big_number.dart, progress_bar.dart, macro_bars.dart,
                 chips.dart (assumption, answer, quick-add), source_badge.dart (+ legend sheet), estimate_marker.dart (+ range sheet),
                 number_pad.dart (+ NumberPadBuffer), unit_picker.dart, input_bar.dart, sheet.dart, undo_snackbar.dart, skeleton.dart,
                 empty_state.dart, inline_banner.dart, date_header.dart
lib/src/charts/  chart_types.dart (FbSeries, FbPoint, FbBand, FbGoalLine, FbChartRange), time_series_chart.dart (placeholder)
lib/l10n/        fb_ds_en.arb (+ gen/)
test/            flutter_test_config.dart (alchemist CI config + loadFbTestFonts), helpers/golden_matrix.dart, dependencies_test.dart,
                 tokens/, components/, charts/, goldens/ci/*.png
```

#### 3.2 Tokens
**Palette starting values** (light / dark). WP1 adjusts lightness until the contrast test passes:

| Role | A "Fresh" light | A dark | B "Warm" light | B dark |
|---|---|---|---|---|
| brand / onBrand | #0F766E / #FFFFFF | #5EEAD4 / #042F2E | #3730A3 / #FFFFFF | #A5B4FC / #1E1B4B |
| surface / surfaceContainer / High | #F8FAFC / #FFFFFF / #F1F5F9 | #0B1220 / #111A2B / #1A2436 | #FAFAF9 / #FFFFFF / #F5F5F4 | #14110F / #1C1917 / #292524 |
| onSurface / onSurfaceVariant (muted) | #0F172A / #475569 | #E2E8F0 / #94A3B8 | #1C1917 / #57534E | #F5F5F4 / #A8A29E |
| outline / outlineVariant | #94A3B8 / #E2E8F0 | #475569 / #1E293B | #A8A29E / #E7E5E4 | #57534E / #292524 |
| protein · carbs · fat · fiber | #4F46E5 · #B45309 · #BE185D · #4D7C0F | #A5B4FC · #FCD34D · #F9A8D4 · #BEF264 | #0F766E · #B45309 · #BE185D · #4D7C0F | #5EEAD4 · #FCD34D · #F9A8D4 · #BEF264 |
| overTarget (neutral) | #64748B | #94A3B8 | #78716C | #A8A29E |
| success · info | #15803D · #0369A1 | #86EFAC · #7DD3FC | #15803D · #0369A1 | #86EFAC · #7DD3FC |
| error (inline only, muted) | #9F3A2C | #F2B8AE | #9F3A2C | #F2B8AE |

**Type** (Inter + Noto Sans Arabic fallback, sp/line height/weight): display 48/56/600 (tabular), headline 24/32/600, title 18/24/600, body 16/24/400, bodySmall 14/20/400, label 14/20/500, caption 12/16/500. `FbType.numeric(style)` adds tabular figures. Mapped onto `TextTheme` (displayLarge…labelSmall) so material_ui widgets pick it up.
**Spacing** 4-pt: `s1 4 · s2 8 · s3 12 · s4 16 · s5 24 · s6 32 · s7 48`. **Radii** `sm 8 · md 12 · lg 16 · sheet 28 · pill`. **Elevation** `flat 0 · raised 1 · overlay 3` (cards are tonal and flat, "clean, not empty"). **Motion** `fast 120 ms · normal 200 ms · slow 300 ms · undoWindow 5 s`, curve `easeOutCubic`. `FbMotion.of(context)` returns `Duration.zero` when `MediaQuery.disableAnimations` is set.
**Contrast pairs** (`fbContrastPairs`): every text role on every background it's used on (onSurface/onSurfaceVariant/overTarget/brand/info/success/error on surface, surfaceContainer, surfaceContainerHigh; onBrand on brand; snackbar text on its background; chip label on chip backgrounds), each with ≥ 4.5:1 for text and ≥ 3:1 for large text (display, headline). Non-text UI (macro and over-target fills against the bar track and the surface, badge outline, input outline, focus ring) needs ≥ 3:1 (WCAG 1.4.11). Both variants × light/dark.

#### 3.3 Components (public API, all directional, every string a parameter or from `FbLocalizations`)
| Component | API sketch | Spec |
|---|---|---|
| `FbButton.primary/secondary/text` | `label`, `onPressed` (null = disabled), `icon?`, `expand` | UX-021 |
| `FbCard` | `child`, `onTap?`, `padding` (default `s4`) | UX-041 |
| `FbListRow` / `FbSectionHeader` | `title`, `subtitle?`, `leading?`, `trailing?`, `onTap?` / `title`, `trailing?` | HM-007 |
| `FbBigNumber` | `value` (formatted), `caption`, `over: bool` (neutral tone when over) | HM-001, D10 |
| `FbProgressBar`, `FbMacroBars` | `value`, `target`; macro bars: list of `FbMacroValue(kind, value, target, label)`, fiber smaller, label always next to the colour | HM-003, UX-042, UX-071, D11 |
| `FbAssumptionChip`, `FbAnswerChip`, `FbQuickAddChip` | `label`, `onTap`; answer chip `selected`, `isDefault`; quick-add `.add()` variant (+) | AI-033/034, DY-030 |
| `FbSourceBadge`, `showFbSourceLegend` | `source`, `onTap?` (default opens the legend) | FD-010, UX-044 |
| `FbEstimateMarker`, `showFbEstimateRange` | `rangeText`, `reason` | AI-032, SF-041 |
| `FbNumberPad` + `NumberPadBuffer`, `FbUnitPicker` | pad emits keys; the pure buffer applies digit/decimal/backspace/max digits/max decimals/no leading zeros; picker `units: List<FbUnitOption(id, label)>`, `selected`, `onSelected` | AI-040 |
| `FbInputBar` | `hint`, `onTap`, `onCamera?`, `onBarcode?` (shell, no text logic) | HM-008 |
| `FbSheet`, `showFbSheet` | drag handle, `title?`, `child`, safe area, sheet radius | UX-011 |
| `showFbUndoSnackBar` | D13 | UX-030 |
| `FbSkeleton.line/.box/.card` | calm pulse, frozen when animations are off | UX-051 |
| `FbEmptyState` | `icon`, `title`, `message`, `action?` | UX-050 |
| `FbInlineBanner` | `kind: info/offline/pending/error`, `message`, `action?`; calm tones, error = muted brick | UX-052/053 |
| `FbDateHeader` | `label`, `onPrevious`, `onNext?` (null = disabled), directional chevrons | HM-009 (header only) |
| `FbTimeSeriesChart` | D14 | IN-004 (interface) |

No streak, badge-as-reward, score or "failed" component exists (IN-020, SF-022).

#### 3.4 App changes (`apps/mobile`)
- `pubspec.yaml`: `fb_design_system: path: ../../packages/fb_design_system`. `app/theme/app_theme.dart` delegates to `FbTheme` with the variant/themeMode from the `app/theme/` providers (D16). `app/app.dart` adds `FbLocalizations.delegate`. `main.dart` calls `registerFbFontLicenses()` (sync, lazy).
- Backlog #35: the four tab placeholders become `FbEmptyState` (Today loses its plain title bar). `UpdateRequiredScreen` uses `FbButton`/`FbSpace`. The two existing app goldens are regenerated.
- `core/navigation`: `DesignPreviewRoute` + `AppNavigator.push/pop`. `app/router`: nested route in the Me branch, registered only in dev.
- `features/design_preview/`: `design_preview.dart` (barrel), `application/fake_data.dart`, `presentation/design_preview_screen.dart` (tabs **Mockups · Components · Tokens**), `presentation/gallery/*.dart` (one section per component, all states), `presentation/tokens_page.dart` (swatches + live contrast ratios), `presentation/mockups/{today,food_proposal,edit_proposal,weight_card,progress}_mockup.dart`.
- Mockups (fake data, no navigation): **Today** as in `spec/16` §1 (date header, big number + bar, weekly line, macro bars, "1 to confirm" strip, weight row, workout hint, diary slots with an empty Dinner, quick-add chips, input bar). **Food proposal** as in `spec/10` §4.1 (slot · time, items with ⓓ badges, an assumption chip, a question with answer chips and the default labelled, totals, "Today after this", Discard / Log it). **Edit proposal** (before → after rows of one entry + new totals, UX-026). **Weight card** (trend, weekly rate, chart placeholder). **Progress overview** (weekly summary card, calories/macros/weight chart placeholders, goal progress). One item uses an Arabic name (e.g. "Labaneh · لبنة") so the A55 shows Noto.

### 4. Work packages (branch `step/A02-design-system`, sequential, `make check test gen-check` after each)

| WP | Specialist | Tasks | Done when |
|---|---|---|---|
| WP1 Foundation | flutter-engineer (Opus) | Package skeleton + workspace + README. Fonts (D1) with SOURCES.md/OFL, licence registration. Tokens, both palettes, `FbColors`, type, spacing, motion, `FbIcons`. `FbTheme` + component themes. Contrast module + test (tune palette values). DS ARB + gen-l10n, `gen-app.sh`, `GEN_DART_DIRS`. Dependency test (D6). alchemist config + `loadFbTestFonts` (D19 check first) + `fbGoldenMatrix` + tokens-sheet golden (A and B). Optional real-text specimen spike (D7). app_check package mode + fixtures (D17). Makefile `goldens`/`install-android` (D18). App: theme switched to `FbTheme`, DS delegate, the existing 2 goldens regenerated | `make deps-dart gen check-dart test-dart gen-check` green. Contrast tests pass for A and B × light/dark. The tokens golden shows real font metrics (block widths differ from Ahem). `app_check --package` fails on a raw-string and a left/right fixture |
| WP2 Display components | flutter-engineer (Opus) | Button, card, list row, section header, big number, progress bar, macro bars, chips ×3, source badge + legend, estimate marker + range sheet, empty state, inline banner, skeleton, with widget tests (§5 B) | Widget tests green. Each component shows in a scratch golden at light-LTR (full matrices in WP4) |
| WP3 Input & shell components | flutter-engineer (Opus) | `NumberPadBuffer` + pad, unit picker, input bar, sheet, undo snackbar, date header, chart types + placeholder, with tests (§5 C) | Tests green. The barrel exports everything (`barrel exports every public component` test) |
| WP4 Golden matrices | flutter-engineer (**Sonnet**, mechanical) | One `fbGoldenMatrix` file per component (states listed in §5 D), `make goldens`, eyeball every PNG (overflow at 2.0, RTL mirroring), commit | `make test-dart` green on the laptop. CI `dart` job green on the branch. Total `test-dart` time increase recorded in the Progress log |
| WP5 Design preview + app migration | flutter-engineer (Opus) | `DesignPreviewRoute`, `AppNavigator.push/pop`, dev-only router registration, Me row. The `app/theme/` variant/mode providers (D16) wired into `app.dart`, with the preview's switches setting them. Gallery (every component, every state, light/dark via the switch), Tokens page. Placeholders → `FbEmptyState` (#35), update screen. ARB keys (`preview…` keys: Sonnet sub-brief allowed) | Tests §5 E green. app_check green. `make run-dev` shows the preview on a device or emulator (screenshot in the Progress log; CI's emulator test is untouched) |
| WP6 Mockups | flutter-engineer (Opus) | `fake_data.dart` + 5 mockups from DS components only. Product-copy ARB keys. Mockup goldens (LTR, light/dark × 1.0/2.0). Owner review instructions (§6) put into the Progress log | Mockup goldens green. No `Icons.`/raw colour/raw `EdgeInsets` in `features/design_preview/presentation/mockups/` (grep in review). `make build-android FLAVOR=dev` builds |
| WP7 Owner phone session | orchestrator + owner | §6 instructions, together with S06b WP7 | Palette pick + feedback recorded in the Outcome. Feedback applied (token tweaks) or ticketed |

### 5. Test list (Dart test names carry the spec ID first, `10` §5)
**A. Tokens & package (WP1)**
- `UX-071 every text/background token pair meets WCAG AA (variant A light, A dark, B light, B dark)`: 4.5:1 text, 3:1 large text. Prints the failing pair and its ratio.
- `UX-071 non-text UI tokens (macro fills, over-target, outlines, focus) reach 3:1 against their background`.
- `UX-071 wcagContrast matches known values (black/white 21:1, #777 on white 4.48:1)`.
- `UX-042 each variant has four distinct macro colours, the same in every component theme`.
- `SF-021 overTarget is a neutral tone: low saturation, distinct from ColorScheme.error`.
- `UX-040 FbTheme light and dark for both variants build, and use Inter with the Noto Sans Arabic fallback`.
- `fb_design_system dependencies are within the allowlist` · `lib/ imports no I/O, no flutter/material.dart, no fb_* package` (rules, no spec ID).
- `FbMotion returns zero durations when animations are disabled`.
- Golden `UX-042 UX-071 tokens sheet, variants A and B, light/dark`.

**B. Display components (WP2)**
- `HM-001 big number shows the over state in the neutral tone, without an error colour or warning icon` · `UX-070 big number clamps its text scale to 1.5 and never overflows at 2.0`.
- `SF-021 progress and macro bars above target fill with overTarget, never ColorScheme.error`.
- `UX-071 macro bars always show a text label next to each colour`.
- `FD-010 each source shows its own badge letter` · `UX-044 tapping a source badge opens the legend with all four sources`.
- `AI-032 tapping the estimate marker shows the range and the reason` · `SF-041 estimate marker is present for the estimate source`.
- `AI-034 answer chip marks the default answer` · `AI-033 assumption chip calls onTap`.
- `UX-050 empty state shows title, message and the optional action` · `UX-051 skeleton is static when animations are disabled`.
- `UX-052 UX-053 inline banners render each kind with its message and action`.
- `UX-021 primary button is visually dominant (filled) and disabled without onPressed`.

**C. Input & shell (WP3)**
- `AI-040 NumberPadBuffer: digits, one decimal point, backspace, max digits/decimals, no leading zeros, empty → no value` (table-driven).
- `AI-040 number pad keys and unit picker selection reach their callbacks`.
- `UX-030 undo snackbar shows the message, calls onUndo once on Undo, closes after 5 s`.
- `UX-030 undo snackbar close() dismisses it without calling onUndo`.
- `UX-030 / WCAG 2.2.1 with accessibleNavigation the undo snackbar is not auto-dismissed`; `showFbSnackBar shows a message with no action`.
- `HM-009 date header previous/next call back, next disabled when null, chevrons mirror in RTL`.
- `UX-011 sheet shell shows a drag handle and its title`.
- `IN-004 chart placeholder keeps its aspect ratio and accepts series, bands and a goal line`.
- `barrel exports every public component`.
- `LC-002 every built-in component string comes from FbLocalizations`. Also `app_check --package` runs in `make check`.

**D. Goldens (WP4)**, each file in light/dark × 1.0/2.0 × LTR/RTL: `buttons` (primary/secondary/text, enabled/disabled, with icon), `card`, `list_row` (plain, subtitle, leading+trailing, long title), `section_header`, `big_number` (under, over, + the 1.5 row), `progress_bar` (half, full, over), `macro_bars` (normal, one over), `chips` (assumption, answer selected/default, quick-add, add), `source_badges` (all five), `legend_sheet`, `estimate_range_sheet`, `number_pad`, `unit_picker`, `input_bar`, `sheet`, `undo_snackbar`, `skeletons`, `empty_state`, `inline_banners` (4 kinds), `date_header` (both enabled, next disabled), `chart_placeholder`. Names: `UX-070 UX-040 <component> golden matrix` (plus a component spec ID where one applies, e.g. `FD-010`).

**E. App (WP5–WP6)**
- `UX-010 the design preview is reachable from Me in the dev flavor` · `the design preview row and route don't exist in staging and prod`.
- `the preview switches change themeVariantProvider / themeModeProvider and the app theme between variants A and B and light/dark`.
- `UX-050 tab placeholders use the design-system empty state`.
- `LC-002 every visible string comes from AppLocalizations or FbLocalizations` (existing test extended).
- Mockup goldens, LTR, light/dark × 1.0/2.0: `HM-001 HM-003 HM-008 Today mockup` · `AI-031 AI-032 AI-033 AI-034 food proposal mockup` · `UX-026 AI-050 edit proposal mockup` · `HM-005 weight card mockup` · `IN-001 Progress overview mockup`.
- Existing `app_shell` and `update_required` goldens regenerated.

### 6. Exit-criteria mapping
| Exit criterion | Evidence |
|---|---|
| Gallery shows every component in light/dark. Goldens pass in CI (light/dark × 1.0/2.0 × LTR/RTL) | Gallery: the `barrel exports every public component` test, plus a gallery test that every exported component has a section. Light/dark through the switch (WP5 screenshot). Goldens: tests D green in CI's `dart` job on the branch head (run ID in the Progress log) |
| Contrast test passes for all text/background token pairs | Tests A `UX-071 …` green for A and B × light/dark. The tokens page shows the ratios on the device |
| Owner reviewed the mockups on the A55. Feedback recorded and applied or ticketed | WP7. Verifier marks ⚠️ until the owner session. Not blocking under TD-037. Outcome: pick + feedback list + where each item went |

**Owner phone session (~30 min, laptop + A55 by USB; WP7, S06b WP7 in the same sitting):**
1. On the phone: Settings › Developer options › USB debugging on (done once in S06b). Plug in and allow the laptop. The orchestrator checks `adb devices`.
2. Orchestrator: `git switch step/A02-design-system && make build-android FLAVOR=dev && make install-android FLAVOR=dev` (signed with the stable key from `~/.fitness-buddy/keys/release.env`; the "FB Dev" icon appears next to "FB Staging").
3. Owner: open **FB Dev** › **Me** › **Design preview**. **Mockups** tab first: Today, Food proposal (tap the assumption chip, an answer chip, the `~` marker, a ⓓ badge), Edit proposal, Weight card, Progress. Then the **A/B** switch at the top: look at Today and the proposal in both. Then the light/dark toggle. Then phone Settings › Display › Font size and style › largest, and look at Today again. **Components** and **Tokens** tabs: a quick scroll.
4. Owner answers: palette **A or B** (default A). Per mockup: anything cluttered, dated, or hard to read? The Arabic name looks right?
5. S06b part: install the CI staging APK (latest `android` artifact, Chrome) and check the four tabs + light/dark. Then `make cold-start` (10 runs, recorded in S06's Outcome). Then `/v1/config` on the device: the local Host (`backend/`: `dotnet run --project src/Host --urls http://localhost:5198`) + `make run-dev` (adb reverse), or the laptop test server if B03 is done.

### 7. Risks & unknowns
- **Package fonts not found in the package's own tests** (D19): WP1 checks it first (a test asserting the text width differs from Ahem). The fix is `loadFbTestFonts()`.
- **Obscured goldens don't show glyph problems** (Arabic shaping, weights): covered by the A55 review and the gallery. Optional real-text specimen spike (D7) with `diffThreshold` as a fallback. Drop it if it flakes.
- **Repeating animations hang alchemist's `pumpAndSettle`**: DS motion honours `disableAnimations` (D8). The golden helper sets it.
- **Golden churn and repo size** (~2–4 MB now, more per regeneration): one PNG per component keeps diffs reviewable. `make goldens` only after an intended change. Revisit (LFS) if `.git` growth gets noticeable.
- **Doc conflict**: `09` §7 says 1.0/1.5/2.0 and the card says 1.0/2.0. The plan follows the card plus a 1.5 row for the big number (D9). The orchestrator aligns `09` at close.
- **Palette values may need bigger shifts than "lightness only"** to pass AA (amber and lime on white are borderline): allowed within the same hue family. Values go into the Outcome.
- **Seams with later steps**: A01 (UndoStack) only calls `showFbUndoSnackBar`. A22 builds the real proposal card from the same components (mockups aren't reused as code). A15 picks the chart library behind `FbTimeSeriesChart` without changing its API. If A15 needs another parameter, it adds it (no breaking change in R1).
- **"Screens only use fb_design_system components"** isn't machine-enforced (`material_ui` widgets like `Scaffold` are still needed). Review checks it. Backlog item: an app_check rule once screens exist (A08).
- **Machine (7 GB, ~1 GB free)**: fonts +1.7 MB. Run tests per package, sequentially (`make test-dart` already does). No emulator. The dev release build reuses the warm Gradle cache (~72 s).
- **Backlog #50** (Dependabot `gradle`) says "A02 or next platform touch": it stays with the next platform touch (A02 doesn't touch Gradle).
- Sources (checked 2026-10-17): Inter and Noto Sans Arabic files, sizes and OFL from `github.com/google/fonts` `ofl/inter`, `ofl/notosansarabic`, `ofl/ibmplexsansarabic` (GitHub API listing). Digit widths and `tnum` measured from the downloaded TTFs. Flutter "FontWeight also controls the weight attribute of variable fonts" (docs.flutter.dev/release/breaking-changes/font-weight-variation, stable 3.41). pub.dev API: `alchemist 0.14.1` (2026-10-08), `material_ui 1.7.0` (2026-10-14), `material_symbols_icons 4.2960.0` (2026-07-23). alchemist 0.14.1 source (`loadFonts` reads `FontManifest.json`; obscured text draws blocks over the laid-out text).

### 8. Size check
**L, ~2.75 sessions**: WP1 ~0.75 (most unknowns), WP2 ~0.5, WP3 ~0.4, WP4 ~0.3 (Sonnet), WP5 ~0.4, WP6 ~0.4, plus review/verify. This is at the top of L, so no split up front. **Pre-agreed seam if WP1–WP3 overrun by > 0.5 session:** **A02a "Design system v0"** (WP1–WP4; exit: goldens + contrast + barrel/gallery-section tests) and **A02b "Design preview & mockups"** (WP5–WP7; exit: dev-only preview, mockup goldens, owner A55 review). A02b depends on A02a, and A08 depends only on A02a.

### Plan review (architect, 2026-10-17, wave 1)
- PA1: D12 enum is `FbSource { yours, database, referenceDish, estimate }` (four badges ⓨ ⓓ ⓡ ~, legend shows four); no ⓛ. Spec inconsistency logged in backlog for the owner.
- PA2: D13 accessibleNavigation behaviour pinned by a test; A08 `expired` forward note; `showFbSnackBar(message)` added.
- PA3: D17 coordination with A01's `app_check` rules (rebase, unique IDs, `--package` mode limited).
- Suggestion adopted (D16): theme variant/mode providers in `app/theme/` (defaults A + system); only the preview UI in `features/design_preview`.

## Progress log
- 2026-10-17: Wave 1 (TD-068): plan written, architect group review approve-with-changes, amendments applied. Plan approved by the orchestrator under TD-037 (no blocking owner item). Next: implementation.
- 2026-10-17: Phase C started on `step/A02-design-system` (process v2: Normal tier, Sonnet implements + reviews; owner: "full thing", own branch, don't block Codex). WP1 next.

## Outcome
_Written in Phase E._
