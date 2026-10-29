# Fitness Buddy — Specification

> The single source of truth for what Fitness Buddy is and isn't.
> If it's not in `spec/`, it's not decided. If code disagrees with `spec/`, either the code is wrong or the spec gets updated first, with an entry in `decisions.md`.

## Status

| Phase | State |
|---|---|
| Research | Round 1 done (`research/`) |
| Requirements Q&A | Rounds 1–3 ✅ processed. No broad rounds planned |
| Decisions | 82 recorded (`decisions.md`) |
| Product spec | **Draft v1 complete. Awaiting owner review & sign-off** |
| Technical planning | **Plan v2 in `technical-planning/`** (outside `spec/`, D-005): architecture, decisions, and 49 step cards |

_Last updated: 2026-10-11_

## Vision

See `00-vision-and-scope.md`. In short: a Flutter mobile app (iOS + Android) focused on **nutrition and weight tracking**. You log food the way you'd tell a friend, in English, Arabic or Arabizi. Buddy, the AI assistant, turns that into a **proposal built from real food data**, which you confirm with one tap. Nothing is logged behind your back. Simple strength-workout logging, a weight trend graph and a weekly review are included. It's built for the owner first, then friends, then possibly the public: no ads, a solid free tier, clean UI, no bloat.

## How we work

1. **Research**: findings go in `research/`.
2. **Question rounds**: `questions/round-NN.md`, answered inline by the owner.
3. **Decisions**: every settled answer gets an entry in `decisions.md` (append-only, never rewritten).
4. **Spec files**: decisions are turned into numbered requirements.
5. **Sign-off**: the owner reviews the drafts. Changes go through new decisions. Then technical planning starts.

Rules:
- Every requirement has an ID (e.g. `AI-030`) and a release tag: **R1** (owner) / **R2** (friends) / **R3** (public) / **Later** (D-042).
- Changing a requirement = a new decision in `decisions.md` + an edit to the spec file that references it.
- The spec says **what** and **why**, never **how** (D-005).

## Requirement ID prefixes

| Prefix | File | Prefix | File |
|---|---|---|---|
| SC, PR, NG, C | `00-vision-and-scope.md` | HM, IN | `16-insights-and-home.md` |
| MN | `02-monetization.md` | NT | `17-notifications.md` |
| AI | `10-ai-assistant.md` | LC | `18-localization-and-culture.md` |
| FD | `11-foods-and-data-quality.md` | AC | `20-accounts-and-data.md` |
| DY | `12-diary-meals-recipes.md` | SF | `21-safety-and-wellbeing.md` |
| TG | `13-targets-and-goals.md` | UX | `30-ux-principles.md` |
| WB | `14-weight-and-body.md` | AT, AQ, T, OF | `40-acceptance-criteria.md` |
| WO | `15-workouts.md` | | |

## File map

| File | Purpose | State |
|---|---|---|
| `README.md` | This index | ✅ |
| `decisions.md` | Decision log (append-only) | ✅ D-001 to D-082 |
| `glossary.md` | Shared vocabulary | ✅ |
| `research/competitive-analysis.md` | Existing apps: what they do well and badly, what we take from them | ✅ |
| `research/domain-pitfalls.md` | Hard problems in nutrition, weight and AI logging | ✅ |
| `questions/round-01.md` … `round-03.md` | Q&A rounds | ✅ processed |
| `00-vision-and-scope.md` | Vision, success criteria, principles, scope per release, non-goals | ✅ draft v2 |
| `01-personas-and-journeys.md` | Personas and 14 step-by-step journeys | ✅ draft v1 |
| `02-monetization.md` | Free forever + AI allowance + paid tier (R3) | ✅ draft v1 |
| `10-ai-assistant.md` | Buddy: inputs, **proposal cards & confirmation**, questions, sources, memory, corrections, Q&A, suggestions, weekly review | ✅ draft v1 |
| `11-foods-and-data-quality.md` | Food data, provenance, search, barcode, label photos, **local dish must-cover list**, cooking conversions, halal | ✅ draft v1 |
| `12-diary-meals-recipes.md` | Days, slots, diary, quick re-logging, batches, recipes | ✅ draft v1 |
| `13-targets-and-goals.md` | Goals, formula + adaptive targets, weekly budget, macros, Ramadan targets | ✅ draft v1 |
| `14-weight-and-body.md` | Weigh-ins, trend, graph, paste import, measurements, photos | ✅ draft v1 |
| `15-workouts.md` | Exercise library, templates, chat/form logging, history, PRs | ✅ draft v1 |
| `16-insights-and-home.md` | Today screen, progress tab, weekly summary | ✅ draft v1 |
| `17-notifications.md` | Reminder types, defaults, rules | ✅ draft v1 |
| `18-localization-and-culture.md` | Languages, units, Ramadan mode, halal, regional food | ✅ draft v1 |
| `20-accounts-and-data.md` | Sign-in, guest mode, sync, offline, export, deletion, privacy promises | ✅ draft v1 |
| `21-safety-and-wellbeing.md` | Age gate, calorie floor, rate limits, language, Buddy's limits | ✅ draft v1 |
| `30-ux-principles.md` | Speed targets, navigation, proposal card pattern, visuals, states, onboarding | ✅ draft v1 |
| `40-acceptance-criteria.md` | R1 done criteria, AI quality thresholds, 41-case test set, offline scenarios | ✅ draft v1 |
