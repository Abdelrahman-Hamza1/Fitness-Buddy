# "Embrace" visual identity

_Source: the design canvas the owner reviewed on 2026-10-29 ("The UI looks amazing"; logo direction "B / The Embrace"). Copied from the canvas's shared spec so steps can reference it; the canvas artboards (static HTML mock-ups, 390×844) are in `artboards/`, and a downsized copy of the owner's logo draft is `logo-embrace-draft.png`. Implemented by step A44 (`../../steps/A44-brand-identity.md`); the decision is the identity TD in `../../12-decisions-and-questions.md`. Where the app's code and this page differ after A44, the A44 Outcome lists why._

_Artboards: `Main` (palette and type board), `TodayDark` / `TodayCompact` / `TodayLight`, `BuddyCard` / `BuddyReceipt` / `BuddyInline` (three proposal-card styles; the owner's pick belongs to A22b), `Weight`, `WeighIn`, `Setup`. The "Icons" and "Launcher" boards were never drawn; A44 designs the final mark._

## Product in one paragraph
Fitness Buddy is a calm, local-first nutrition and weight tracker (Android, Flutter) with an AI
assistant called **Buddy**. The user types or speaks what they ate ("2 eggs and a manakish
za'atar"); Buddy turns it into a **proposal card** the user confirms; nothing is saved without
confirmation. Tabs: **Today · Progress · Workouts · Me**. Tone: friendly, neutral, never judging.
Hard product rules that the visuals must respect:
- Going over a target is shown in a **neutral grey tone, never red/alarm**. No "you failed", no streaks, no badges, no scores.
- One colour per macro, the same on every screen (protein, carbs, fat, fiber). Macro colours are never used for text.
- Meaning never carried by colour alone (always a label or number too). WCAG AA text contrast (4.5:1).
- "Clean, not empty": few colours, large key numbers, secondary info quieter. Modern (the opposite of MyFitnessPal / Cronometer's dated look).
- AI estimates carry a small "≈ estimate" marker; food sources carry small source badges.
- English UI. Dishes are often Palestinian/Levantine.

## The brand (from the owner's logo "B / The Embrace")
Two friends: a deep-teal figure hugging a mint figure. Rounded geometric wordmark.

## Typefaces (Google Fonts)
`<link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&family=Nunito:wght@600;700;800;900&display=swap" rel="stylesheet">` inside `<helmet>`.
- **Nunito** (rounded, matches the logo wordmark): screen titles, card titles, big key numbers, the wordmark. Weights 700–900. Use `font-variant-numeric: tabular-nums` on numbers.
- **Inter**: everything else (body, labels, list rows, buttons, chips). 400/500/600.
- Type scale (px / line-height): display number 48/56 Nunito 800 · title 24/32 Nunito 800 · section 18/24 Nunito 700 · body 16/24 Inter 400 · label 14/20 Inter 500 · caption 12/16 Inter 500.

## Colour tokens
### Dark ("Deep Forest") — the owner prefers dark; it is the primary theme
| token | hex | use |
|---|---|---|
| surface | #0C1412 | screen background (green-black, never pure black) |
| surfaceContainer | #141E1B | cards, sheets |
| surfaceContainerHigh | #1D2925 | inputs, bar tracks, raised chips |
| onSurface | #E8EFEC | primary text |
| onSurfaceVariant | #9DAEA8 | secondary text |
| outline | #6C7C77 | control borders |
| outlineVariant | #24322E | dividers |
| brand | #6FD6B6 | primary buttons, selection, focus, calorie ring progress |
| onBrand | #04241D | text on brand |
| brandContainer | #123F36 | selected chips, Buddy bubble background |
| onBrandContainer | #BFEEDD | text on brandContainer |
| mint (logo accent) | #A8E3CB | small accents only (Buddy avatar second figure, highlights) |
| protein | #8EA8FF | macro (blue) |
| carbs | #F2BE5C | macro (amber) |
| fat | #F29AC0 | macro (rose) |
| fiber | #B5D86A | macro (lime) |
| overTarget | #8F9A96 | over-target fills/labels (neutral) |
| error | #F0B4A8 | fixable errors only (muted brick) |
| errorContainer | #3A1E19 | error banner background |

### Light ("Mint Cream")
| token | hex |
|---|---|
| surface | #FAF9F4 (cream, from the logo backdrop) |
| surfaceContainer | #FFFFFF |
| surfaceContainerHigh | #EFF2EC |
| onSurface | #13201D |
| onSurfaceVariant | #53625D |
| outline | #87938E |
| outlineVariant | #E2E7E1 |
| brand | #0B6E5F (logo deep teal) |
| onBrand | #FFFFFF |
| brandContainer | #D3F0E3 (logo mint, lighter) |
| onBrandContainer | #0A3B33 |
| mint | #A8E3CB |
| protein | #3D5FD9 |
| carbs | #B9760F |
| fat | #C2457A |
| fiber | #5E8A12 |
| overTarget | #8C918E |
| error | #A2402F |
| errorContainer | #FBEAE6 |

## Shape, spacing, density
- 4-pt spacing: 4 8 12 16 24 32 48. Screen side padding 16.
- Radii: chips/inputs 12, cards 20, sheets 28 (top corners), buttons pill (999).
- Cards: `background: surfaceContainer; border-radius: 20px;` NO shadows in dark; light theme may use `box-shadow: 0 1px 2px rgba(19,32,29,.06)` plus 1px outlineVariant border. Never a coloured left border. No gradients.
- **Comfortable density** (default): card padding 16, gap between cards 12, list rows 56 tall, display number 48.
- **Compact density**: card padding 12, gap 8, list rows 44, display number 40, macro row in one line.
- Touch targets ≥ 44px.

## Components (recipes)
- **Primary button**: pill, height 48, brand background, onBrand text, Inter 600 15px. Secondary: pill, 1px outline border, onSurface text. Text button: brand text.
- **Chip**: height 32, radius 12, surfaceContainerHigh bg, label 13px Inter 500; selected = brandContainer bg + onBrandContainer text + check icon.
- **Calorie summary**: big number = kcal LEFT (Nunito 800), caption "kcal left today"; a thin progress bar or ring in brand on a surfaceContainerHigh track; secondary line "1,240 / 2,150 kcal". Over target: the number becomes "120" with caption "kcal over today" and the fill turns overTarget grey (no red).
- **Macro bars**: 4 rows or 4 columns: label (onSurfaceVariant), "92 / 150 g", 6px bar track surfaceContainerHigh with the macro colour fill, radius 3.
- **Meal slot**: section label (Breakfast/Lunch/Snacks/Dinner) + kcal at the end; food rows: name (16px), portion caption (13px onSurfaceVariant), kcal at the end (tabular). Empty slot = "Nothing yet" in onSurfaceVariant.
- **Source badge**: tiny 18px-high pill, 11px Inter 600, surfaceContainerHigh bg, onSurfaceVariant text: "USDA", "Dish", "Label", "Mine".
- **Estimate marker**: "≈" prefix before the number plus a tiny "estimate" badge in the same badge style.
- **"To confirm" chip**: brandContainer pill "2 to confirm · +330 kcal".
- **Input bar** (bottom of Today, above the nav): pill field 52 tall, surfaceContainerHigh, placeholder "Tell Buddy what you ate…", mic icon button and a small Buddy avatar at the start.
- **Bottom nav**: 4 items Today, Progress, Workouts, Me; height 72; surfaceContainer; selected item = brandContainer pill behind the icon (64×32) + label onSurface 12px 600; others onSurfaceVariant.
- **Buddy avatar**: 28px circle brandContainer with the mini Embrace mark: two small dots (teal + mint) above two overlapping arcs. Simple inline SVG.
- Icons: inline stroke SVG, Lucide style (24 viewBox, stroke-width 2, round caps/joins, `stroke="currentColor"`, fill none). Never emoji.
- **Phone frame**: the artboard IS the screen, 390×844, no device bezel, no fake status bar time/battery. Leave a 24px top inset (plain surface) for the status area.

## Sample data (use these, keep numbers consistent)
- Date header: "Today · Thu 29 Oct" with chevrons for previous/next day.
- Budget 2,150 kcal · eaten 1,240 · **910 kcal left**. Week line: "This week: 640 kcal under".
- Protein 92 / 150 g · Carbs 130 / 220 g · Fat 48 / 70 g · Fiber 18 / 30 g.
- Breakfast 420: "Manakish za'atar" (1 piece · 110 g) 310 [Dish] ; "Labneh" (2 tbsp · 30 g) 110 [USDA].
- Lunch 610: "Chicken musakhan" (1 roll · 180 g) ≈610 [estimate].
- Snacks 210: "Coffee with milk" (1 mug) 45 [Mine]; "Medjool dates" (3 · 72 g) 165 [USDA].
- Dinner: Nothing yet.
- Pending: "2 to confirm · +330 kcal".
- Weight card: "82.4 kg" today, "82.1 kg trend · −0.4 kg/wk"; button "Log weight".
- Workout hint: "Upper body today".
- Weight history (trend, kg) for 8 weeks: 85.0, 84.6, 84.3, 83.7, 83.4, 82.9, 82.5, 82.1; daily weigh-ins scatter ±0.6 around the trend. Goal 78 kg, pace 0.5 kg/week.
- Buddy example: user message "2 eggs, labneh with olive oil and a cucumber" → proposal: Boiled eggs ×2 (100 g) 155 kcal [USDA]; Labneh (3 tbsp · 45 g) 160 kcal [USDA]; Olive oil (1 tbsp · 14 g) 120 kcal [USDA]; Cucumber (1 medium · 200 g) 30 kcal [USDA]; total 465 kcal · P 22 g · C 12 g · F 37 g. Assumption label on the oil row: "assumed 1 tbsp". Actions: "Add to Breakfast" (primary), "Edit", "Not now". Buddy reply text: "Got it. Here's breakfast — check the amounts and add it."

