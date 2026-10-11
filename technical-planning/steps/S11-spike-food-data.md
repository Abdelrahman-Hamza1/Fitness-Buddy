# S11 — Spike: food data

| Phase | Depends on | Size | Status |
|---|---|---|---|
| P0 Foundations | S08 | M | ⬜ Not started |

**Goal.** Prove the food-data strategy (TD-010) before building on it: can USDA basics + our reference dishes + Open Food Facts + label scan cover the owner's real food? Freeze the reference-dish format and measure how long authoring takes.

**Spec:** FD-001, FD-004, FD-031, FD-050, FD-051, AT-003 (feasibility), C-5 · **Decisions:** TD-010

## Scope
- **USDA FDC import prototype** (`tools/catalog`): download the bulk data, select a draft basics list, map nutrients to our model (kcal, P, C, F, fiber + extras), keep FDC IDs.
- **Reference dish format v1:** a JSON Schema for the YAML (`07` §4), validated by the tool.
- **5 dishes end to end:** maqluba, musakhan, falafel sandwich, chicken shawarma arabi, mloukhiyeh with rice. Recipe → per-100 g → portions with ranges → variants, each with ≥ 1 cited source.
- **Prototype `catalog.db`** with FTS5 (trigram) over normalized names, proving T07/T08/T12-style queries find them by EN, AR and Arabizi.
- **OFF hit-rate measurement:** a script that looks up the owner's ~30 barcodes on Open Food Facts and records found / complete (has kcal, P, C, F, fiber) / missing.
- **Time per dish** measured, for planning D1–D6.

## Out of scope
- The production pipeline, CI workflow, full basics list (S13). Server catalog (S30).

## Fixed by the plan
- USDA (CC0) can be merged. OFF stays licence-isolated and is never merged (`07` §3). Unreviewed dishes don't ship.

## Decide in the low-level plan
- USDA dataset choice (Foundation vs SR Legacy vs Survey/FNDDS) for basics.
- How ingredient references in dish YAML point to catalog foods (stable IDs vs slugs).

## Exit criteria
- [ ] 5 dishes validate, compute sane per-100 g values (sanity check passes), and resolve by EN, AR and Arabizi in the prototype pack.
- [ ] The OFF hit rate for the owner's products is recorded (found %, complete %) → a decision on how central the label-scan path is (`07` §7).
- [ ] **TD-010 decided** (accepted or adjusted). The dish format v1 is frozen (JSON Schema committed).
- [ ] An authoring time estimate per dish and a revised D1–D6 plan are in the Outcome.

## Read first
`07-food-data.md` (all) · `spec/11-foods-and-data-quality.md` §1–6

## Owner involvement
Send ~30 barcodes from your kitchen (typed numbers or photos). Skim the 5 sample dishes ("does a plate look right?").

---

## Low-level plan
_Written in Phase B._

## Outcome
_Written in Phase E._
