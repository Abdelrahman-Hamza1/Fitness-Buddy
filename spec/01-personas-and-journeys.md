# 01 — Personas & Journeys

_Status: **Draft v1** · 2026-10-10._

## 1. Personas

### P1 — The Owner `[R1]`
- Cutting. Trains strength 3–4×/week (Push/Pull/Legs), logs workouts after the session.
- Lives in the West Bank. Eats typical Palestinian food: some home-cooked, some family-cooked, some eaten out. Doesn't buy Israeli brands.
- Owns a kitchen scale but often doesn't use it. Weighs in weekly and keeps the weights in a phone note.
- Writes in English and Arabic, casually: short, lowercase, typos.
- Eats halal and fasts in Ramadan.
- Quit MyFitnessPal and Cronometer because logging was inconvenient. Wants to see what gets logged before it's saved.
- **Needs:** effortless logging that still gives trustworthy numbers, a weekly view of progress, a weight graph.

### P2 — The casual friend `[R2]`
- Wants to lose some weight. Doesn't train. Has never tracked food.
- Prefers the Arabic interface. Writes in Palestinian Arabic or Arabizi.
- **Needs:** onboarding that explains things simply, logging without learning nutrition, no guilt, hide the workouts module.

### P3 — The gym friend `[R2]`
- Bulking or recomping, trains 4–5×/week, cares about protein.
- **Needs:** protein target, quick repeat meals (shakes, chicken & rice), workout progress graphs, PRs.

### P4 — The detail-oriented public user `[R3]`
- Weighs everything, wants to know data sources, may come from MyFitnessPal or Cronometer.
- **Needs:** provenance badges, accurate weighed logging, export, no ads.

## 2. Key journeys

Each journey lists the main requirements involved.

### J1 — Home-cooked meal, weighed (P1)
1. Types `200g rice, 200g chicken breast raw, cooked with an onion`.
2. A proposal card appears in ≤ 5 s: rice, chicken, onion grouped as one dish. Two chips ask: *rice weighed raw or cooked?* and *oil used?*
3. Taps "raw" and "1 tbsp olive oil". The numbers update.
4. Buddy offers "Always treat rice as raw weight?" → yes (memory proposal).
5. Taps **Log it**. Today's numbers update.
→ AI-020–023, AI-030–036, AI-060–065, AI-055.

### J2 — Lazy family-cooked plate (P1, P2)
1. Types `akalt sahen maqlobe 3nd sitti`.
2. Card: maqluba (chicken), 1 plate, `~ 780 kcal` (estimated, range on tap). Chip shows the variant.
3. Taps Log it.
→ AI-021, AI-032, FD-050, AI-143.

### J3 — Eating out (P1)
1. Types `شاورما دجاج عربي وبيبسي`.
2. Card: shawarma arabi (reference, `~`) + Pepsi can (database). Reply in English in R1, in Arabic from R2 (AI-141).
3. Log it.
→ D-046, FD-011, AI-141, AI-143.

### J4 — Packaged product not in the database (P1)
1. Taps barcode → not found → "Scan the label instead".
2. Photographs an Arabic label → review screen → confirms name and values → saved as own food, linked to the barcode.
3. Chooses amount → logged.
4. Next time: the barcode is found instantly.
→ FD-030–033, FD-040–042.

### J5 — Fixing a mistake (P1)
1. Types `no the rice was 150g`.
2. Card shows before 200 g → after 150 g and the new totals. Log it.
→ AI-050, AI-090–092.

### J6 — Batch cooking (P1, P3)
1. Sunday: `cooked a pot: 1kg chicken, 500g rice dry, 2 onions, 3 tbsp oil. ate like a third`.
2. Card: batch + ⅓ portion. Log it. The batch stays open.
3. Monday: taps the "Chicken rice (leftover)" quick-add chip → logs a plate with undo.
4. Wednesday: `finished the chicken rice` → proposal logs the remaining amount and closes the batch.
→ DY-040–044, DY-030.

### J7 — Repeat breakfast (P1, P3)
1. Opens app → taps the "the usual breakfast" chip → logged with undo. Two taps total.
→ DY-030, DY-031, UX-004.

### J8 — Weekly weigh-in (P1)
1. Saturday 08:00 reminder → taps it → number pad prefilled with the last value → enters 97.3 → save.
2. Sees trend 97.6 (−0.4/week) and the graph with the monthly target.
→ NT-003, WB-001, WB-010–023.

### J9 — Weekly review (P1)
1. Week start: notification "Your weekly review is ready".
2. Reads the summary: average intake vs. budget, protein days, trend change, 3/4 workouts, 1 PR.
3. An adaptive target proposal is attached: "1,950 kcal (was 2,050)" → Accept.
→ AI-130–132, TG-034, IN-001.

### J10 — Logging a workout after the session (P1, P3)
1. Types `push day bench 3x8 80 ohp 3x10 40 dips 3x12 incline db 3x10 30`.
2. Card: 4 exercises matched. Bench 3×8 marked as a PR. Log it.
3. Buddy offers to update the Push template with the new exercise order (proposal) → skip.
→ WO-030–034, WO-042, WO-022.

### J11 — A Ramadan day (P1)
1. App proposed Ramadan mode two days before → accepted.
2. 45 min before Fajr: suhoor reminder. Types `suhoor 2 eggs ful bread` → slot Suhoor on the fasting day.
3. Iftar: `3 tamrat w laban w shorbet adas` → slot Iftar.
4. Weight chart shades Ramadan. Targets follow the Ramadan setting.
→ LC-030–034, DY-012, NT-008, TG-060.

### J12 — No signal at the gym (P1)
1. Logs the workout by form → works offline.
2. Types a protein shake message → pending "will process when online".
3. Back online → proposal appears → Log it.
→ AC-020, AI-047, OF-01/02.

### J13 — Asking Buddy (P1, P3)
1. `what can i eat w 600 kcal left` → 3 halal suggestions, including the open chicken-rice batch.
2. Taps one → proposal → Log it.
→ AI-120–121.

### J14 — Importing the weight note (P1, first setup)
1. Me → Import from text → pastes the note.
2. Review table: 24 rows read. 2 flagged ("110k" read as 110 kg; a +40 kg jump). Fixes one, removes the other.
3. Confirms → the graph shows the full history.
→ WB-030–031.
