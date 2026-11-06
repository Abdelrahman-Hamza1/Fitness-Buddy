# "Momentum" identity in "Ink & Sky"

_Source: the owner's pick on 2026-11-06 ("Let's take the 3 lines as codex drew it but with different color theme" → "Let's go with ink and sky. Let the rebranding begin!"). Decision: TD-116 (`../../12-decisions-and-questions.md`), spec D-098. Built by step A64 (`../../steps/A64-rebrand.md`). It replaces the Embrace identity (`../embrace/README.md`, kept as history). In this folder: `codex-reference.png` (Codex's drawing of the mark, downsized; its plum/lime colours are **not** the chosen ones) and `theme-board.dc.html` (the design canvas's theme board; the chosen theme is `inkSky` in its `T` table). Where the app's code and this page differ, the code is the truth and the A64 Outcome lists why._

## The mark
Three rounded pills, slanted 22° to the right, bottoms aligned, rising left to right: momentum, progress you can see.

- **Geometry (the reference, on a 100 × 100 canvas):** `translate(3.17, 3) skewX(-22)` of the rects `x 32.32 y 48 w 19 h 32`, `x 55.32 y 32 w 19 h 48`, `x 78.32 y 14 w 21 h 66`, each with corner radius = half its width (a pill). Heights ≈ 32 / 48 / 66, widths ≈ 19 / 19 / 21, gap ≈ 4.
- **In the app:** one source, `packages/fb_design_system/lib/src/brand/brand_geometry.dart`. Each pill is four quarter-circle cubic Béziers plus one straight side, mapped through the same skew (a Bézier's image under an affine map is exact), then scaled about the centre of the mark's smallest enclosing circle: r 31 on the 108-unit adaptive-icon canvas (the safe circle is r 33), r 10.5 on the 28-unit avatar canvas. The figure rect (the mark without padding, for the lockup) is `(28, 34)–(80, 74)` on the 108 canvas.
- **Copies, test-checked** (`apps/mobile/test/android/brand_sync_test.dart`): `packages/fb_design_system/brand/momentum-mark.svg` and `momentum-mini.svg` (on-light colourway), and the Android `ic_launcher_foreground.xml`, `ic_launcher_monochrome.xml` and `ic_notification.xml`.
- **Colour by position:** soft (short), mid (middle), strong (tall).

| Colourway | Soft | Mid | Strong | Where |
|---|---|---|---|---|
| On light surfaces | `#D3E3EA` | `#8FB3C4` | brand ink `#1E2A32` | lockup, licences page, SVG files |
| On dark surfaces | `#D3E3EA` | `#8FB3C4` | sky spark `#6EC8FF` | lockup and licences page in dark |
| On the plate | `#D3E3EA` | `#8FB3C4` | sky spark `#6EC8FF` | launcher icon (ink plate), splash, Buddy avatar |
| Monochrome | one colour | one colour | one colour | Android 13 themed icon, notification small icon |

- **Wordmark / lockup:** the mark, then "Fitness / Buddy" on two lines, Outfit ExtraBold (800), in the brand colour (ink on light, `#A9CDDC` on dark). The app passes its name; the first space becomes the line break; screen readers hear "Fitness Buddy" once.
- **Buddy avatar:** the mini mark on a disc: ink `#1E2A32` on light, the dark surface `#0E1418` on dark (an edge on the `#24303A` input bar and the `#1A242B` cards; the brand tint `#22343F` had none on the input bar).
- **Launcher icon:** the adaptive icon's plate is the flavor colour: prod ink `#1E2A32`, dev violet `#5B4A8F`, staging amber `#8A5A12`. The themed (monochrome) icon is the same three shapes in one colour.
- **Splash and first frame:** light by default (TD-107): window and Android 12+ splash background = the light surface `#FAFAF8`, the icon on its plate in the middle.

## Colour tokens (`packages/fb_design_system/lib/src/tokens/palette.dart`)
| Role | Light | Dark | Use |
|---|---|---|---|
| brand | `#1E2A32` | `#A9CDDC` | primary buttons, selection, focus, rings |
| onBrand | `#FFFFFF` | `#0E1418` | text on brand |
| brandContainer | `#E6EEF2` | `#22343F` | selected chips, tints |
| onBrandContainer | `#1E2A32` | `#D6E8F0` | text on brandContainer |
| surface | `#FAFAF8` | `#0E1418` | screen background |
| surfaceContainer | `#FFFFFF` | `#1A242B` | cards, sheets |
| surfaceContainerHigh | `#EEF1F3` | `#24303A` | inputs, bar tracks, raised areas |
| onSurface | `#1A2329` | `#EAF0F3` | primary text |
| onSurfaceVariant | `#57636B` | `#A7B3BA` | secondary text |
| outline | `#7E8A92` | `#717F88` | control borders (3:1) |
| outlineVariant | `#E5E9EC` | `#2B3740` | dividers (decoration) |
| spark | `#6EC8FF` | `#6EC8FF` | the mark's strong shape on the plate / dark, small highlights |
| sparkContainer | `#DDF1FF` | `#12384F` | a sky tint with text (`ColorScheme.secondaryContainer`): the estimate marker "~" and the estimate source badge, the input bar's count badge |
| onSparkContainer | `#06324D` | `#DDF1FF` | text on sparkContainer |
| markSoft | `#D3E3EA` | `#D3E3EA` | the mark's short shape |
| markMid | `#8FB3C4` | `#8FB3C4` | the mark's middle shape |
| markStrong | `#1E2A32` | `#6EC8FF` | the mark's tall shape on the theme's surfaces |
| markPlate | `#1E2A32` | `#0E1418` | the Buddy avatar's disc |
| protein | `#7C4DDB` | `#B79BFF` | macro (violet) |
| carbs | `#B9760F` | `#F2BE5C` | macro (amber) |
| fat | `#C2457A` | `#F29AC0` | macro (rose) |
| fiber | `#5E8A12` | `#B5D86A` | macro (lime) |
| overTarget | `#666D72` | `#8E989E` | over a target: neutral grey |
| success | `#14773A` | `#86EFAC` | calm green |
| info | `#0369A1` | `#7DD3FC` | information |
| error | `#A2402F` | `#F0B4A8` | fixable errors (muted brick) |
| errorContainer | `#FBEAE6` | `#3A1E19` | error banner |
| inverseSurface / inverseOnSurface / inversePrimary | `#1A2329` / `#FAFAF8` / `#A9CDDC` | `#EAF0F3` / `#0E1418` / `#1E2A32` | snackbar |

Every text and control pair is checked for WCAG AA in both themes by `test/tokens/contrast_test.dart` (`fbContrastPairs`).

## Type
- **Outfit** (OFL, variable `wght` 100–900, bundled): screen titles (24/32, 800), section titles (18/24, 700), the big numbers (`display`, 800, tabular figures through Outfit's `tnum` feature) and the wordmark (800).
- **Inter**: everything else (body, labels, buttons, chips). **Noto Sans Arabic** is the fallback in every style.

## Usage rules
- **The spark is decoration and highlight only.** On light it is about 1.8:1, so it is never text and never thin data (lines, small dots) on a light background. On dark and on the ink plate it may be a shape or a highlight.
- **Macro colours are never text**, one colour per macro on every screen; protein is violet so it never reads as the sky spark.
- **Over a target is neutral grey**, never red (SF-021); errors are a muted brick.
- The mark is a logo: it is excluded from screen readers, never mirrored in RTL, and exempt from contrast rules (its soft shape on the light surface is about 1.3:1 by design).
- Unchanged from TD-098: shapes (cards 20, chips/inputs 12, sheets 28, pill buttons), compact density, one palette, no gradients, no shadows in dark.
