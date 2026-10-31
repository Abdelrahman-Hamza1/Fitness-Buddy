# 16 — Home (Today) & Insights

_Status: **Draft v1** · 2026-10-10, amended 2026-10-30 · Main decisions: D-031, D-043, D-052, D-068, D-070, D-071, D-084, D-085._

## 1. Today screen (home, D-043, D-071)

Top to bottom:

```
┌─────────────────────────────────────────┐
│  Sat 10 Oct                     ‹  ›    │
│                                         │
│        1,240  kcal left today           │  ← big (D-071)
│   ███████████████░░░░░  1,560 / 2,800   │
│   This week: 350 under                  │  ← small
│   P 110/180  C 140/250  F 45/80  Fib 18 │
│ ─────────────────────────────────────── │
│ ⏳ 1 to confirm · +640 kcal          ›  │  ← only when pending (AI-045)
│ 97.6 kg · trend −0.4/wk              ＋ │  ← slim once weighed today (D-084)
│ Push ✓ · 5 exercises · 1 PR          ›  │  ← planned day or after logging
│ ─────────────────────────────────────── │
│ Breakfast                       420     │
│   Fried egg · Labaneh · Taboon …        │
│ Lunch                           780     │
│ Snacks                          360     │
│ Dinner                            —     │
│ ─────────────────────────────────────── │
│ [the usual bfast] [coffee w milk] [+]   │  ← quick-add chips (DY-030)
│ [ Tell Buddy what you ate…   📷  ▥ ]    │  ← input bar, camera, barcode
└─────────────────────────────────────────┘
```

- **HM-001** `[R1]` Today's remaining calories is the largest element, with a progress bar. If over, it shows "X over" in a neutral colour, never alarm red (PR-12).
- **HM-002** `[R1]` A small weekly line: "This week: X under / over" against the weekly budget (TG-045).
- **HM-003** `[R1]` Macro progress for protein, carbs, fat (with targets) and fiber (smaller).
- **HM-004** `[R1]` A "to confirm" strip appears only when proposals are pending (AI-045).
- **HM-005** `[R1]` Today’s top is a card with slides: Nutrition, Weight, Workout (D-092). The Weight slide shows the as-of trend, weekly rate, last weigh-in and a small raw-value sparkline; tap the value area for the graph, or “+ Weigh in” to log on the viewed day (WB-001, two taps including Save). The last weigh-in remains editable; sparse-history and cadence notes remain.
- **HM-006** `[R1]` The Workout slide always appears (D-092): the day’s logged session and counts, otherwise today’s planned workout (WO-021), otherwise the last session before the viewed day, otherwise “No workout logged”. “Log” starts the planned template; “Log a workout” starts a free session on the viewed day. Tapping a logged or last session opens it. Past days never show a missed-plan note.
- **HM-007** `[R1]` Diary by slot (DY-020).
- **HM-008** `[R1]` Quick-add chips and the input bar with camera and barcode buttons are always at the bottom.
- **HM-009** `[R1]` Swiping left or right below the summary card changes the day. A drag starting on the card changes its slide, including at the edges; the day buttons and date picker still change the day. The slide selection follows across days for the session and resets to Nutrition on cold start (D-092). The same layout shows past days.
- **HM-010** `[R2]` Steps for today shown as information only, read from Apple Health / Health Connect (D-068). They never affect the budget.

## 2. Progress tab

- **IN-001** `[R1]` **Weekly summary** for the current week and any past week: average calories vs. budget, days within target, protein target hit days, fiber average, trend weight change, workouts done (vs. planned, when there is a plan), PRs, and the Buddy weekly review on top (AI-130).
- **IN-002** `[R1]` **Calories chart**: daily intake vs. daily target, by week or month, with incomplete days marked differently.
- **IN-003** `[R1]` **Macros chart**: protein, carbs, fat, fiber per day vs. targets.
- **IN-004** `[R1]` **Weight chart** (WB-020 to WB-023).
- **IN-005** `[R1]` **Expenditure chart**: estimated expenditure over time, with confidence, once adaptive targets are active (TG-030 to TG-033).
- **IN-006** `[R1]` **Measurements charts** (WB-041) and **exercise progress** (WO-041), each reachable from the Progress tab.
- **IN-007** `[R1]` Goal progress: current phase, progress toward the target weight, this month vs. monthly target (TG-011).
- **IN-008** `[R1]` **Ramadan comparison**: average intake, weight trend and workouts during Ramadan vs. the month before (D-052). Shown during and after Ramadan.
- **IN-009** `[R1]` Every chart can be filtered by goal phase (TG-012).

## 3. What we deliberately don't show

- **IN-020** `[R1]` No streaks, badges, scores, or "you failed" states (D-033, PR-12).
- **IN-021** `[R1]` No micronutrient dashboards (D-019). Extra nutrients appear only on item details.

## Open questions

None currently.
