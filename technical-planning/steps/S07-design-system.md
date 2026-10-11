# S07 — Design system v0 & key screen mockups

| Phase | Depends on | Size | Status |
|---|---|---|---|
| P0 Foundations | S06 | L | ⬜ Not started |

**Goal.** A token-based design system (`fb_design_system`) with the components every screen needs, plus static mockups of the key screens for the owner to react to (TQ-14). After this, feature steps build screens from components instead of inventing UI.

**Spec:** UX-040–044, UX-050, UX-051, UX-070, UX-071, SF-021, SF-022, SF-041, IN-020, AI-032 (estimate marker), FD-010 (badges) · **Decisions:** TD-014

## Scope
- **Tokens:** colour (brand, neutrals, one colour per macro, a **neutral over-target tone** never alarm red, success/info), type scale (bundled Latin + Arabic font pair), spacing, radii, elevation, motion durations. Light and dark themes.
- **Components:** buttons (primary/secondary/text), cards, list rows, section headers, **big number display** (HM-001), progress bar, macro bars, **chips** (assumption chip, answer chip, quick-add chip), **source badges** ⓓ ⓛ ⓡ ~ ⓨ + legend sheet (UX-044), estimate marker with a range sheet (AI-032), **number pad + unit picker**, text input bar shell, bottom-sheet shell, **undo snackbar** (UX-030), skeletons (UX-051), **empty state** (UX-050), inline error/offline banners (UX-052/053), date header with day navigation.
- **Chart wrappers** API (implementation in S22): line + points, bands, goal line, tooltips. Only the interface + a placeholder here.
- **Quality:** an automated **WCAG AA contrast test** over the token palette (UX-071). Goldens for every component in light/dark, text scale 1.0 and 2.0 (UX-070), LTR and RTL.
- **Gallery** screen (dev flavor only) listing all components and states.
- **Static mockups** built from the components with fake data: **Today** (as in `spec/16` §1), **food proposal card** (as in `spec/10` §4.1, with a question and chips), **edit proposal (before → after)**, **weight card + chart placeholder**, **Progress tab** overview.

## Out of scope
- Real data, navigation flows, real charts (S16, S22, S23, S33).

## Fixed by the plan
- `material_ui` as the base, wrapped. Screens only use `fb_design_system` components.
- No streaks, badges-as-gamification, scores or alarm-red states (IN-020, SF-021).

## Decide in the low-level plan
- The font pair (e.g. Inter + IBM Plex Sans Arabic) and licences.
- The colour palette (a proposal with 2 variants for the owner to pick).
- The icon set (Material Symbols vs an alternative).

## Exit criteria
- [ ] The gallery shows every component in light/dark. Goldens for all components pass in CI (light/dark × scale 1.0/2.0 × LTR/RTL).
- [ ] The contrast test passes for all text/background token pairs.
- [ ] The owner reviewed the mockups **on the A55**. Feedback is recorded in the Outcome and applied (or ticketed to a later step).

## Read first
`spec/30-ux-principles.md` · `spec/16-insights-and-home.md` §1 · `spec/10-ai-assistant.md` §4 · `09-cross-cutting.md` §3, §7

## Owner involvement
A ~30-minute review of the gallery and mockups on the phone. Pick a palette variant.

---

## Low-level plan
_Written in Phase B._

## Outcome
_Written in Phase E._
