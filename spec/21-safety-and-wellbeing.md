# 21 — Safety & Wellbeing

_Status: **Draft v1** · 2026-10-10 · Main decisions: D-034, D-001._

Fitness Buddy is not a medical product (NG-9). These rules protect users from harm, especially once people other than the owner use it (R2+). Rules marked R1 apply from the start because they shape the core logic.

## 1. Who can use it

- **SF-001** `[R2]` Users must be **18 or older**. The birth year entered during setup (TG-001) is checked, and under-18s can't continue.
- **SF-002** `[R2]` Onboarding asks whether the user is pregnant or breastfeeding, or has a medical condition affecting diet. If yes, the app recommends consulting a professional and **disables deficit goals** (maintain only), while still allowing logging.

## 2. Limits on targets

- **SF-010** `[R1]` **Calorie floor**: the app never *generates* a daily target below the higher of the user's estimated resting energy (TG-020) and **1,200 kcal** (or 1,500 kcal if the user's sex is male). Rebalancing (TG-042) and adaptive changes (TG-034) respect the floor too.
- **SF-011** `[R1]` **Maximum loss rate**: generated plans never exceed **1% of body weight per week**. Higher requested rates show a warning and are capped.
- **SF-012** `[R1]` **Manual override below limits** is possible (the owner is an adult who knows what they're doing), but needs an explicit acknowledgement on a clear warning screen. In R3, manual targets below 1,000 kcal are not allowed.
- **SF-013** `[R2]` **Goal weight floor**: the app doesn't accept goal weights that put the user's BMI below 18.5. It explains why, kindly.

## 3. Language & presentation (PR-12)

- **SF-020** `[R1]` No moral words about food or eating: no "good/bad food", "cheat", "guilt", "sinful", "clean eating", "junk".
- **SF-021** `[R1]` Being over target is shown neutrally ("150 over today"), never in alarm red and never with warning icons.
- **SF-022** `[R1]` No shaming or comparison with others (also D-033).

## 4. Buddy's limits

- **SF-030** `[R1]` Buddy doesn't give medical, clinical or supplement-dosing advice. For such questions it gives general information at most, plus a recommendation to see a professional.
- **SF-031** `[R2]` If messages or patterns suggest possible disordered eating (e.g. talk of purging, or several days of intake far below the floor), Buddy responds with care, doesn't encourage restriction, and points to help resources. No diagnosis.
- **SF-032** `[R2]` Repeated very low intake (e.g. 5+ complete days below the floor in 2 weeks) leads to one gentle, private check-in message, not a recurring alert.

## 5. Disclaimers

- **SF-040** `[R2]` Onboarding states briefly: "Fitness Buddy gives estimates for tracking, not medical advice." The same line is in settings → About.
- **SF-041** `[R1]` Estimated values are always marked (D-045), which is itself a safety measure: users know when a number is approximate.

## Open questions

None currently.
