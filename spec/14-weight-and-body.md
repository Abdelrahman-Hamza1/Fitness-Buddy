# 14 — Weight & Body

_Status: **Draft v1** · 2026-10-10 · Main decisions: D-024 to D-026, D-052, D-054, D-055, D-065._

## 1. Weigh-ins

- **WB-001** `[R1]` Log a weigh-in in **≤ 3 taps** from Today (D-060): tap weight card → number pad (prefilled with the last value) → save. A direct action with undo.
- **WB-002** `[R1]` Or by chat ("weighed 97.3 today", "yesterday 97.8") → weigh-in proposal (AI-052).
- **WB-003** `[R1]` A weigh-in has: value, unit, date and time (defaults to now, editable), and an optional short note ("after Eid"). Several weigh-ins on one day are allowed, and the earliest is used for the trend unless the user picks otherwise.
- **WB-004** `[R1]` Any cadence works: daily, weekly or irregular (D-054).
- **WB-005** `[R1]` Implausible values (e.g. change > 3% of body weight since the last weigh-in within 7 days, or a unit mix-up like 214 when the last was 97) ask for confirmation before saving.

## 2. Trend weight

- **WB-010** `[R1]` The app calculates a **smoothed trend weight** that handles irregular gaps between weigh-ins. A single weigh-in moves the trend only partly.
- **WB-011** `[R1]` The trend is the **main number** ("Trend 97.6 kg · −0.4 kg/week"). The latest raw weigh-in is shown next to it, smaller.
- **WB-012** `[R1]` With few weigh-ins, the app is honest about it ("based on 1 weigh-in per week — trend updates slowly"), and can gently suggest 2–3 weigh-ins a week, at most once a month and never as a nag (D-054).

## 3. Weight graph (replacing the owner's note, D-024)

- **WB-020** `[R1]` Graph with raw weigh-ins as points and trend as a line. Time ranges: 1 month, 3 months, 6 months, 1 year, all.
- **WB-021** `[R1]` Overlays: goal weight line, projected path to the goal (with a cone for uncertainty), shaded goal phases (TG-012), and shaded Ramadan periods (D-052).
- **WB-022** `[R1]` Tapping a point shows its value, date, note and the trend at that date.
- **WB-023** `[R1]` Summary stats: total change since phase start, change this month vs. the monthly target, average weekly rate.

## 4. Paste import (D-055)

- **WB-030** `[R1]` "Import from text": paste any text (e.g. the owner's note `oct 10 2025: 110k, oct 20 2025: 150kg...`). The AI pulls out dated weight entries.
- **WB-031** `[R1]` The result is shown as a **review table** (a proposal, D-079): date, value, unit, original text. Problem rows are flagged: unclear dates, missing units ("110k" → read as 110 kg), implausible jumps (e.g. 110 → 150 kg in 10 days), and duplicates of existing entries. Flagged rows are excluded until the user fixes or accepts them.
- **WB-032** `[R1]` The same import works for body measurements. Importing food history from text: **Later**.

## 5. Body measurements (D-025)

- **WB-040** `[R1]` Optional measurements: waist, chest, hips, arm, thigh, neck, plus custom ones. Logged via a form or chat (proposal).
- **WB-041** `[R1]` Each measurement has its own graph (same style as weight, without trend smoothing unless there are ≥ 5 points).
- **WB-042** `[R1]` Body fat %: manual entry with its own graph. Estimate from measurements (U.S. Navy method): **R2**.
- **WB-043** `[R1]` A measurement reminder is optional, default off (`17`).

## 6. Progress photos (D-026, D-065)

- **WB-050** `[R2]` Optional progress photos (front / side / back), **stored only on the device, never uploaded**, never sent to AI, and excluded from sync.
- **WB-051** `[R2]` Side-by-side comparison of two dates.
- **WB-052** `[R2]` The photo screen clearly states "Photos stay on this phone and are not backed up", and offers **"Export my photos"** (save to the phone's gallery/files).
- **WB-053** `[Later]` Optional end-to-end encrypted backup.

## Open questions

None currently.
