# 16 — Home (Today) & Insights

_Status: **Draft v1** · 2026-10-10, amended 2026-11-05 · Main decisions: D-031, D-043, D-052, D-068, D-070, D-071, D-084, D-085, D-093, D-094._

## 1. Today screen (home, D-043, D-071)

Top to bottom:

```
┌─────────────────────────────────────────┐
│  Sat 10 Oct                     ‹  ›    │
│ ┌─────────────────────────────────────┐ │
│ │      1,240  kcal left today         │ │  ← big (D-071)
│ │ ███████████████░░░░░  1,560 / 2,800 │ │
│ │ This week: 350 under                │ │  ← small
│ │ P 110/180  C 140/250  F 45/80  Fib 18│ │
│ └─────────────────────────────────────┘ │
│ ⚖ 97.6 kg · −0.4 kg/week │ 🏋 Push today │  ← one slim line, fixed height (D-093)
│ ─────────────────────────────────────── │
│ Breakfast                       420     │
│   Fried egg · Labaneh · Taboon …        │
│ Lunch                           780     │
│ Snacks                          360     │
│ Dinner                            —     │
│ ─────────────────────────────────────── │
│ [the usual bfast] [coffee w milk] [+]   │  ← quick-add chips (DY-030)
│ [ Tell Buddy…  (2 waiting)   📷  ▥ ]    │  ← input bar; count only when pending (D-094)
└─────────────────────────────────────────┘
```

- **HM-001** `[R1]` Today's remaining calories is the largest element, with a progress bar. If over, it shows "X over" in a neutral colour, never alarm red (PR-12).
- **HM-002** `[R1]` A small weekly line: "This week: X under / over" against the weekly budget (TG-045).
- **HM-003** `[R1]` Macro progress for protein, carbs, fat (with targets) and fiber (smaller).
- **HM-004** `[R1]` While proposals are pending, Today's Buddy bar shows "{n} waiting"; one tap opens Buddy at them (AI-045, D-094). There is no strip.
- **HM-005** `[R1]` Today's top is the calories card only, with no slides (D-093). Under it, one slim line is always visible with the same height in every state. Its weight half shows the as-of trend and weekly rate ("Weigh in" before the first weigh-in); tapping it weighs in on the viewed day (WB-001, two taps including Save). The sparse-history note and the weigh-in tip live in Progress; the last weigh-in is edited from the weight graph.
- **HM-006** `[R1]` The line's workout half (D-093): the day's logged session ("… done", tap opens it), otherwise today's planned workout ("… today", WO-021, tap starts it), otherwise "Log workout", which starts a free session on the viewed day. Past days never show a missed-plan note or a last session.
- **HM-007** `[R1]` Diary by slot (DY-020).
- **HM-008** `[R1]` Quick-add chips and the input bar with camera and barcode buttons are always at the bottom.
- **HM-009** `[R1]` Swiping left or right anywhere on Today changes the day, including on the calories card (D-093); the day buttons and date picker also change the day. The same layout shows past days.
- **HM-010** `[R2]` Steps for today shown as information only, read from Apple Health / Health Connect (D-068). They never affect the budget.

## 2. Progress tab

- **IN-001** `[R1]` **Weekly summary** for the current week and any past week: average calories vs. budget, days within target, protein target hit days, fiber average, trend weight change, workouts done (vs. planned, when there is a plan), PRs, and the Buddy weekly review on top (AI-130). On the Progress tab the week lives in the calories chart card (average vs target and a line of key numbers); the full summary opens from it and from the weekly notification (D-097).
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
