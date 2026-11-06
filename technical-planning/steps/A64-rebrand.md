# A64 — Rebrand: the Momentum mark and the Ink & Sky palette

| Track | Depends on | Size | Owner | Status |
|---|---|---|---|---|
| App | A62, A63 | M–L | Claude plans and builds (one Opus `flutter-engineer`), one combined Codex review (Normal) | ✅ Closed (owner one-shot; device checks #155) |

_2026-11-06. The owner's pick after a week of daily use and a long design session (canvas https://claude.ai/artifact/LDy1WaS8h6iiH1PSbo45KD, local copies `~/work/ux-sketches/identity-2026-11-06/`): "Let's take the 3 lines as codex drew it but with different color theme" → "Let's go with ink and sky. Let the rebranding begin! All 1 shot please." and "Make sure NOTHING is missed." One shot = plan, build, review and merge without a plan-approval stop; the owner approved the identity itself, which amends the Accepted TD-098 (new TD-116, spec D-098)._

**Goal.** Every place the app shows its identity switches from "Embrace" (two hugging figures, teal/mint, Nunito) to **Momentum** (three slanted rounded shapes rising left to right) in **Ink & Sky** (ink blue-grey brand, sky-blue spark), in light and dark, on the phone and on Android's own surfaces (launcher icon, themed icon, splash, window, notifications). Nothing keeps the old look; nothing else about the app changes.

**Spec:** UX-040 (amended), UX-042 (macro colours, one per macro), SF-021 (over-target neutral), UX-03x accessibility (AA) · **Adds:** D-098 (draft below) · **Decision:** TD-116 (draft below; amends TD-098's mark, palette and font clauses; TD-107 light default unchanged).

## Fixed decisions (owner-approved 2026-11-06)
- **Mark "Momentum".** Codex's drawing, as on the canvas board `ThemeBoard.dc.html`: three rounded pills (radius = half width), skewed 22° to the right, bottoms aligned, heights rising (≈ 32 / 48 / 66 of 100), widths ≈ 19 / 19 / 21, gap ≈ 4. Reference geometry (100 × 100, the canvas): `translate(3.17,3) skewX(-22)` of rects `x=32.32 y=48 w=19 h=32`, `x=55.32 y=32 w=19 h=48`, `x=78.32 y=14 w=21 h=66`, `rx = w/2`. Colours by position: **soft** (left), **mid** (middle), **strong** (right: the brand ink on light surfaces, the sky spark on the ink plate and on dark).
- **Palette "Ink & Sky"** (starting values; tune only to pass the AA contrast test, and list every deviation in the Outcome):
  - Light: brand `#1E2A32` (on it white), brand container `#E6EEF2` / on it `#1E2A32`, surface `#FAFAF8`, card `#FFFFFF`, raised/track `#EEF1F3`, text `#1A2329`, muted text `#57636B`, divider `#E5E9EC`, control outline ≥ 3:1, spark `#6EC8FF`, spark container `#DDF1FF` / on it `#06324D`, mark soft `#D3E3EA`, mark mid `#8FB3C4`.
  - Dark: surface `#0E1418`, card `#1A242B`, raised `#24303A`, text `#EAF0F3`, muted `#A7B3BA`, brand `#A9CDDC` (on it `#0E1418`), brand container `#22343F` / on it `#D6E8F0`, spark `#6EC8FF`, spark container `#12384F` / on it `#DDF1FF`.
  - Macros stay one colour each and never text: **protein moves to violet** (light `#7C4DDB`, dark `#B79BFF`) so it doesn't read as the sky spark; carbs, fat, fiber unchanged. Over-target stays neutral grey; error stays a muted brick; success/info re-checked against the new neutrals.
  - The spark is decoration and highlight only (logo's strong shape on the plate/dark, estimate chips, the "Add" pill, small accents), never text or thin data on a light background.
- **Type.** Titles, key numbers and the wordmark move from Nunito to **Outfit** (OFL, variable, bundled); body stays Inter; Noto Sans Arabic fallback stays. Key numbers need tabular figures (TD-076): if Outfit's variable font lacks `tnum`, numbers use Inter's tabular figures and the Outcome says so.
- **Wordmark/lockup.** "Fitness / Buddy" on two lines, Outfit ExtraBold, brand ink, next to the mark (as on the canvas boards).
- **Launcher icon.** Ink plate `#1E2A32`; shapes soft / mid / sky spark; themed (monochrome) icon = the three shapes in one colour; inside the adaptive-icon safe zone. Flavors stay told apart by plate colour: prod ink, **dev violet** (e.g. `#5B4A8F`; the old slate `#3F4A5A` is too close to ink), staging amber `#8A5A12` (keep).
- **Splash and first frame.** Light default (TD-107): window/splash background = light surface `#FAFAF8`; Android 12+ splash icon on its plate; the pre-read first frame matches.
- **Buddy avatar.** The mini Momentum mark on an ink disc (light) / brand-container disc (dark). The illustrated "Human Buddy" is **out** (deferred, owner undecided).
- Layouts, copy, flows, data: unchanged. No contract, sync or migration change.

## Inventory: every place the identity lives (the checklist; nothing ships unticked)
_Built by grep on `main` 7ca19ab5. The engineer re-runs the greps at the end (`Embrace|embrace|mint|Mint|Nunito|teal|0B6E5F|A8E3CB|FAF9F4|0C1412|Deep Forest|Mint Cream|avatarBackground|FbMarkPart`) and every remaining hit is either updated or listed as historical (old step cards, outcomes, decision history)._
1. **Tokens** `packages/fb_design_system/lib/src/tokens/palette.dart` (both brightnesses; `mint` and avatar roles become the new mark/spark roles), `colors.dart` (FbColors extension), `contrast.dart` (pairs incl. spark container), `typography.dart` (Outfit), `density.dart` (unchanged, check).
2. **Theme** `theme/fb_theme.dart` (ColorScheme mapping, component themes), `theme/component_themes.dart`, `theme/licenses.dart` (Outfit licence in, Nunito out).
3. **Brand** `brand/brand_geometry.dart` (new geometry as filled Bézier paths: skewing a pill is an affine map, so the four arcs become exact cubic Béziers; restricted path syntax M L C Q A Z), `brand_path.dart`, `brand_mark.dart`, `brand_lockup.dart`, `buddy_avatar.dart`, `FbBrandColors`, the mini mark for the avatar.
4. **Brand files** `packages/fb_design_system/brand/embrace-mark.svg`, `embrace-mini.svg` → Momentum SVGs (renamed), kept in sync by `apps/mobile/test/android/brand_sync_test.dart`.
5. **Fonts** `packages/fb_design_system/assets/fonts/` (add Outfit variable TTF + `OFL-Outfit.txt`, remove Nunito + its OFL), `pubspec.yaml` fonts/assets, `test/fonts_test.dart`, the licence page.
6. **Android** `res/drawable/ic_launcher_foreground.xml`, `ic_launcher_monochrome.xml`, `launch_background.xml`, `mipmap-anydpi-v26/ic_launcher.xml`, `values/colors.xml` (`ic_launcher_background`, `fb_window_background`), `values/styles.xml`, `values-v31/styles.xml` (splash background/icon/icon background, status bar), `src/dev/res/values/colors.xml`, `src/staging/res/values/colors.xml`, `raw/keep.xml`; notification small icon (`ic_launcher_monochrome` in `notification_platform.dart`; add the notification accent colour if the plugin supports it); `test/android/android_resources_test.dart`.
7. **App code using brand widgets/roles** `features/onboarding/presentation/welcome_screen.dart`, `features/settings/presentation/about_screen.dart`, `features/buddy/presentation/message_list.dart`, DS `components/input_bar.dart`, `message_bubble.dart`, `license_page.dart`, `lib/testing.dart`, `features/design_preview/application/token_roles.dart` (+ its screens); `app/app.dart` first-frame/status bar.
8. **Hard-coded colours** anywhere outside the tokens (only the Google button's brand colours may stay; they're Google's).
9. **Tests** DS `test/brand/*`, `test/tokens/contrast_test.dart`, `tokens_test.dart`, `components/license_page_test.dart`, `fonts_test.dart`, `brand_widgets_test.dart`; app `test/android/*`.
10. **Goldens** every app golden under `apps/mobile/test/**/goldens/ci/` (27 PNGs today): regenerate (owner exception: known visual change), view a sample of each screen family.
11. **Docs** new `technical-planning/design/momentum/README.md` (tokens, mark geometry, usage rules, the Codex reference image downsized); `technical-planning/12-decisions-and-questions.md` (TD-116; TD-098 status "amended by TD-116"); `spec/decisions.md` (D-098) and `spec/30-ux-principles.md` UX-040 wording; `technical-planning/09-cross-cutting.md` and any other current-state doc naming the old identity; `steps/README.md` board row.

## Exit criteria
1. No current-state code, resource, asset or doc names or shows the Embrace mark, teal/mint palette or Nunito (the final grep list in the Outcome; historical hits listed).
2. Light and dark palettes pass the AA contrast test; macros stay distinct from brand and spark; over-target stays neutral.
3. The mark renders from one geometry source; SVGs and Android VectorDrawables are verified copies (sync test green); themed icon is one colour; all three flavor plates differ.
4. Splash, window background and first frame match the light surface; no flash of the old colours on start.
5. Outfit bundled with its licence on the licence page; tabular numbers kept.
6. `make gen-app` clean, `make check` clean, goldens regenerated and viewed, CI green on the merge run.

## Low-level plan
_Written 2026-11-06 by the `flutter-engineer` (Opus) against `main` 7ca19ab5. **Tier: Normal** (tokens, assets, native resources; no user-data path, no contract, sync or migration change). One engineer builds WP0–WP6, one local commit each; one combined Codex review. Same architecture as A44 (one geometry source, test-checked copies, tokens read through the theme); only the content changes._

### 1. Role rename map (palette / `FbColors`)
| Old role | New role | Light | Dark | Use |
|---|---|---|---|---|
| `mint` | `spark` | `#6EC8FF` | `#6EC8FF` | the mark's strong shape on the plate and on dark, small accents; decoration only, never text or thin data on light |
| — | `sparkContainer` / `onSparkContainer` | `#DDF1FF` / `#06324D` | `#12384F` / `#DDF1FF` | a sky tint with text on it; mapped to `ColorScheme.secondaryContainer` / `onSecondaryContainer` (the input-bar badge, the chart highlight band) |
| — | `markSoft` | `#D3E3EA` | `#D3E3EA` | the mark's left (short) shape |
| — | `markMid` | `#8FB3C4` | `#8FB3C4` | the mark's middle shape |
| — (was `colorScheme.primary` in the mark) | `markStrong` | `#1E2A32` (= brand) | `#6EC8FF` (= spark) | the mark's right (tall) shape on the theme's surfaces |
| `avatarBackground` | `markPlate` | `#1E2A32` (ink) | `#0E1418` (= dark surface; changed from brandContainer `#22343F`, which had no edge on the input bar) | the Buddy avatar's disc; the mark on it is soft / mid / spark |
| `avatarForeground` | removed | | | (the plate colourway is soft / mid / spark in both themes) |
| `FbMarkPart {a, b}`, `FbMarkShape.part`, `strokeWidth` | `FbMarkTone {soft, mid, strong}`, `FbMarkShape.tone`; strokes removed (filled shapes only) | | | colour by position |
| `FbBrandColors.plate / reversedA / mint` | `FbBrandColors.plate / soft / mid / spark` | `#1E2A32 / #D3E3EA / #8FB3C4 / #6EC8FF` | | fixed launcher-icon colours (theme-independent) |
| `fbEmbraceMark/Mini/MarkCanvas/MiniCanvas/MarkFigure` | `fbMomentumMark/Mini/MarkCanvas/MiniCanvas/MarkFigure` | | | geometry consts |
| `brand/embrace-mark.svg`, `embrace-mini.svg` | `brand/momentum-mark.svg`, `momentum-mini.svg` | | | verified copies |
| `FbMarkColourway.reversed` | `FbMarkColourway.plate` | | | soft / mid / spark (the app icon) |

### 2. Design per inventory item
1. **Tokens.** `palette.dart`: consts `_inkSkyLight` / `_inkSkyDark` with the card's values; the new roles above. Roles the card doesn't fix, derived and AA-checked: light `outline #7E8A92` (3.12:1 on raised), `overTarget #666D72` (neutral blue-grey, 4.63:1 as text on raised), `inverseSurface #1A2329` / `inverseOnSurface #FAFAF8` / `inversePrimary #A9CDDC`; dark `outline #717F88` (3.27:1), `outlineVariant #2B3740`, `overTarget #8E989E` (4.58:1), `inverseSurface #EAF0F3` / `inverseOnSurface #0E1418` / `inversePrimary #1E2A32`. Protein → violet `#7C4DDB` / `#B79BFF`; carbs, fat, fiber, success, info, error and errorContainer keep their values (re-checked on the new neutrals: all pass). `colors.dart`: the new roles (`fromPalette`, `copyWith`, `lerp`). `contrast.dart`: pairs `onSparkContainer on sparkContainer` and `onSurface on sparkContainer` (text), `markSoft / markMid / spark on markPlate` (ui), wordmark = `brand on surface` (text); doc comment: spark, markSoft, markMid on the light surfaces are not pairs (decoration; the mark is a logo, WCAG 1.4.11 exempt). `density.dart` unchanged.
2. **Theme.** `fb_theme.dart`: `secondaryContainer`/`onSecondaryContainer` → the spark container roles; everything else maps as today. `component_themes.dart`: comments only (no recipe changes). `licenses.dart`: Outfit in, Nunito out.
3. **Brand.** `brand_geometry.dart`: the reference pills (card) skewed by `skewX(-22°)` and translated as the canvas does; each pill = M + 4 cubic Béziers (quarter circles, k = 0.5522847) + 1 line + Z, mapped through the same affine transform (Béziers are affine-invariant, so the skewed caps are exact images of the circle approximation). Then scaled about the centre of the mark's smallest enclosing circle: full mark on the 108 canvas with that circle at r = 31 (safe zone r 33), mini mark on the 28 canvas at r = 10.5 (the avatar disc is r 14). Figure rect (lockup, licence page) = the tight bounds, rounded out: `Rect.fromLTRB(28, 34, 80, 74)` (not square: `FbBrandMark(cropped: true)` sizes its box to the figure's aspect, `size` = height). `brand_mark.dart`: colourways `onSurface` (markSoft / markMid / markStrong), `plate` (FbBrandColors soft / mid / spark), `monochrome` (onSurface). `brand_lockup.dart`: mark + "Fitness / Buddy" on two lines (the name's first space becomes a line break, so the string stays `appTitle`; semantics still read the name once), Outfit 800, `colorScheme.primary` (brand ink; dark: the light brand), sizes retuned so the mark is ~0.8 of the two-line block. `buddy_avatar.dart`: `markPlate` disc + mini mark in soft / mid / spark.
4. **Brand files.** `git mv` to `momentum-*.svg`, content = the consts, on-light colourway (soft / mid / brand ink).
5. **Fonts.** `OutfitVariable.ttf` (`ofl/outfit/Outfit[wght].ttf`, 110,884 B, `wght` 100–900, default 100) + `OFL-Outfit.txt` from `google/fonts` at the same pinned commit `47d54ca1…` (identical to HEAD). **Outfit has `tnum`** (GSUB); its default digits are proportional (321–659 units) and its `tnum` digits are all 590, so `FbType.numeric`/`display` keep `tabularFigures()` and key numbers stay on Outfit. Nunito TTF + OFL deleted; `SOURCES.md`, pubspec, `testing.dart` updated.
6. **Android.** Foreground/monochrome VectorDrawables = the consts (plate colourway / white); prod plate `#1E2A32`, dev `#5B4A8F`, staging `#8A5A12`; window/splash background stays `@color/fb_window_background` = `#FAFAF8`; Android 12+ splash icon on its plate (unchanged wiring); status bar = window colour, dark icons. Notification: small icon stays `ic_launcher_monochrome`; `AndroidNotificationDetails(color: FbBrandColors.plate)` sets the accent (the plugin supports `color`). `raw/keep.xml` unchanged (same drawable name).
7. **App call sites.** welcome/about/message_list/input_bar/message_bubble/license_page keep their widgets (APIs unchanged); `token_roles.dart` lists the new roles; `app.dart` already maps the first frame to the light default; comments/doc names updated (`app_theme.dart`).
8. **Hard-coded colours.** Scan of `fb_design_system/lib` and `apps/mobile/lib`: only transparent/black in themes, the Google button's colours and `FbBrandColors` (fixed asset colours) remain.
9. **Tests** (spec IDs in names): tokens (`UX-042 protein is violet …`, macros differ from brand **and spark**), contrast (spark never text; spark container pairs), fonts (`UX-070 tabular figures … (Outfit w800)`, new `TD-116 the Outfit weight axis moves`), brand path (`A64 the Momentum paths are the reference pills skewed 22°`, safe zone, `FbBrandColors` = palette roles), brand widgets (semantics unchanged), license page (Outfit listed, Nunito not), Android (`brand_sync_test` on the renamed files and colourways, plates incl. dev violet, notification colour not testable on host).
10. **Goldens.** Regenerate all app goldens (`apps/mobile/test/**/goldens/ci/`) and any DS goldens; view Today, Progress, onboarding welcome, About, licences, Buddy.
11. **Docs.** `design/momentum/README.md` (+ downsized reference image), TD-116, D-098, UX-040, `02-tech-stack.md` fonts line, DS `README.md`, board row; `design/embrace/README.md` gets a "superseded by Momentum (TD-116)" banner (historical).

### 3. Risks
- **Variable Outfit default instance is Thin (100):** if `fontWeight` didn't drive `wght`, everything would render hairline. The new weight-axis test (width w100 < w400 < w800) catches it.
- **Spark on light is 1.8:1:** never used as text or thin data; the contrast doc comment and the README say so; `spark` is not in the text-role map.
- **Two-line lockup is taller:** the welcome page scrolls already; the About header grows by one line (accepted: owner-approved lockup).
- **Goldens:** every screen changes colour/font; a regenerated golden can hide a regression, hence the viewing list.
- **Flavor plates:** dev violet `#5B4A8F` vs prod ink differ clearly (and both differ from staging amber); the test keeps the three distinct.

## Outcome
- **Built:** Momentum mark (one geometry source, exact Bézier pills; full mark inside the adaptive safe zone, mini mark for the avatar), Ink & Sky palette in light and dark (AA proven; card hex values kept; open roles chosen and listed in TD-116), protein violet, Outfit for titles/numbers/wordmark with tabular figures on every Outfit style, two-line lockup, launcher + themed icon, splash (pre-12 and 12+), window/first frame, flavor plates (prod ink, dev violet, staging amber), a cropped 24 dp notification icon with the ink accent, Buddy avatar on the ink plate (dark: surface plate), spark on estimate markers. Docs: `design/momentum/README.md`, TD-116, D-098, UX-040; the Embrace folder marked superseded.
- **Deviations:** none from the owner's picks. Spark not applied to the Add/selection pills (backlog #299, owner judges after use). Human Buddy out (deferred).
- **Review:** one combined Codex review: 0 blockers, 0 majors, 1 minor (tabular figures on a few Outfit numbers), fixed with a guard + test; all 11 inventory groups covered; no current-state remnant of the old identity.
- **Owner checks:** backlog #155 (icon on the One UI squircle, themed icon, dev vs prod plate, splash light/dark, notification icon, avatar in dark). Native Android resources changed: the emulator nightly covers start-up.
- **Metrics:** size M–L as planned; 10 commits; 30 golden PNGs regenerated; 1 review round.

## Progress log
- 2026-11-06 — card + inventory (orchestrator); branch `step/A64-rebrand` from 7ca19ab5.
- 2026-11-06 — WP0–WP6 built (engineer, local commits, not pushed): tokens + Outfit, Momentum mark/lockup/avatar, Android icon/splash/notification icon, call sites, docs (TD-116, D-098, `design/momentum/README.md`), 27 app goldens regenerated and viewed; `make gen-app` clean, `make check-dart` green. Next: Codex review, merge.
- 2026-11-06 — Codex review: no blockers or majors; one minor (Outfit's default digits are proportional, so numbers in title/headline lost equal widths). Fixed: every Outfit style (display, headline, title, wordmark) now carries `tnum`, with a guard test; the PR values and the template set counts also go through `FbType.numeric`. Three goldens regenerated (weigh-in sheet, targets how sheet, entry amount sheet). Earlier the same day: spark container on the estimate markers, dark avatar plate = dark surface, backlog #155/#299.
- 2026-11-06 — outcome written; merging via merge-step (orchestrator).
