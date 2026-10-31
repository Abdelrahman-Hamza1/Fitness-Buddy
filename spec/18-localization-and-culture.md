# 18 — Localization & Culture

_Status: **Draft v1** · 2026-10-10 · Main decisions: D-006, D-022, D-051, D-052, D-063, D-064, D-070, D-073, D-074, D-080._

## 1. Languages

- **LC-001** `[R1]` Buddy understands English, Arabic (all dialects, Palestinian/Levantine first), Arabizi, and mixed messages (D-063, AI-010).
- **LC-002** `[R1]` Interface language: **English** in R1.
- **LC-003** `[R2]` Full **Arabic interface** with right-to-left layout: mirrored navigation, charts read right-to-left where it makes sense (time axes stay chronological, oldest → newest in reading direction), and fonts suited to Arabic.
- **LC-004** `[R2]` Digit style setting for the Arabic interface: Western digits (0–9, default) or Arabic-Indic digits (٠–٩).
- **LC-005** `[R1]` Food names show in the **Food names** language (LC-007), with both names and the other names visible on the food page (e.g. "Maqluba (chicken)" / "مقلوبة دجاج" / "Also called: maqlooba", D-091).
- **LC-007** `[R1]` **Food names** setting (D-091): Match my phone (default: Arabic when the phone's language list prefers Arabic, else English) / English / Arabic / Both (English with the Arabic name underneath). It applies to search results, recents, diary rows, quick add, saved meal items and your foods. A missing name falls back to the other language; names the user typed stay as typed. A search hit on the other language's name or an alias says "Matched <name>".
- **LC-006** `[R1]` What's Arabic in R1 and what waits for R2 is summarised in D-080: Buddy **understands** Arabic and Arabizi from R1, but **replies** in Arabic (AI-141) and full Arabic food and exercise names (FD-005, WO-006) come with the Arabic interface in R2.

## 2. Units (D-006)

- **LC-010** `[R1]` Unit system setting: **metric (default)** or imperial (lb, oz, ft/in, fl oz).
- **LC-011** `[R1]` Input in any unit is always accepted, whatever the setting ("8 oz chicken" works in metric mode). Display follows the setting.
- **LC-012** `[R1]` Energy in **kcal**. kJ: Later.

## 3. Calendar & week

- **LC-020** `[R1]` Gregorian calendar throughout. The Hijri date is shown alongside during Ramadan.
- **LC-021** `[R1]` Week start: user setting, default **Saturday** (D-070).

## 4. Ramadan mode (D-052)

- **LC-030** `[R1]` Ramadan dates are detected automatically from the Hijri calendar. Because the start depends on moon sighting and varies by country, the user can shift the start and end by ±1 day. Ramadan mode can also be switched on or off manually.
- **LC-031** `[R1]` Shortly before Ramadan, the app proposes switching on Ramadan mode. It's a proposal, not a silent switch.
- **LC-032** `[R1]` In Ramadan mode:
  - meal slots become Iftar / Suhoor / Snacks (DY-012),
  - Ramadan targets apply (TG-060),
  - suhoor counts toward the calendar day it's eaten on, i.e. the fasting day (DY-001),
  - suhoor and iftar reminders are available (NT-008, NT-009),
  - weight confidence is lower and charts are shaded (WB-021, TG-037),
  - suggestions favour suhoor-appropriate options (protein, fiber) and iftar staples (AI-120),
  - Ramadan comparison insight (IN-008).
- **LC-033** `[R1]` Prayer times (Fajr, Maghrib) come from the user's chosen city by default, or the phone's location if they opted in (D-074).
- **LC-034** `[R1]` A user who is not fasting on a given day (illness, travel, etc.) can mark that day "not fasting". Normal slots and reminders apply for that day.

## 5. Halal (D-064)

- **LC-040** `[R1]` See FD-080 to FD-082. On by default for the owner, offered as an onboarding choice for others (R2).

## 6. Regional food

- **LC-050** `[R1]` Food coverage prioritises Palestinian and Levantine dishes and products available in the West Bank (FD-031, §6 of `11`).
- **LC-051** `[R1]` Local portion words (رغيف, صحن, حبة, كاسة, سندويشة) are understood and mapped to gram weights per food (FD-003).

## Open questions

None currently.
