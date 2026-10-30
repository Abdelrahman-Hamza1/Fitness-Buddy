# A47 — Food basics expansion

| Track | Depends on | Size | Owner | Status |
|---|---|---|---|---|
| App (data) | A05 ✅ | M | Claude | ⬜ Not started |

_New step (owner, 2026-10-30: "Bigger food list, it needs to be done soon"). Phase 1, wave 1 (TD-105). Tier: Data/docs._

**Goal.** The offline food list covers what people actually eat: the basics grow from about 250 to about 600, each findable by English, Arabic and Arabizi names with real portions.

**Spec:** FD-001, FD-004, FD-050, LC-050, LC-051, AT-003 (basics part) · **Decisions:** TD-010, TD-074, D-080

## Scope
- About 350 new basics through the existing USDA pipeline (A03/A05): fruit, vegetables, meat, fish, dairy, grains, legumes, nuts, oils, sauces, snacks, drinks.
- Each with an Arabic name and common Arabizi spellings, portions and servings (piece, cup, slice, local portion words), yields where cooked/raw differ.
- Densities for liquids where needed (helps backlog #148).
- `make catalog` validation, sanity checks and name resolution.

## Out of scope
- Reference dishes (the dish batches). Broader packaged/branded work remains A48.
  Owner-approved exception (2026-10-30): B3 imports the verified USDA packaged
  basics and Snickers, Kit Kat, Twix, M&M's and Toblerone.

## Exit criteria
- [x] About 600 basics in the offline pack; every new one validates and resolves by EN, AR and Arabizi.
- [x] Pack size and search speed stay within the A05/A07 budgets.

## Read first
`technical-planning/07-food-data.md` §4 · `spec/11-foods-and-data-quality.md` §6 · A03, A05 cards

## Owner involvement
Optional skim of the new list; name foods you miss.

---

## Low-level plan
Batches follow the verified 2026-10-30 research plan and candidate list supplied
by the orchestrator. B0–B3 are complete (+379 IDs, including the five owner-approved branded bars).
The B5 brief attempts delegated source review of seven local single foods and
fixes the falafel search fallback; unverifiable foods stay draft.

- **B0:** assign exact head-word aliases on released foods; correct existing
  Levantine/Arabizi names; narrow generic must-cover match lists before expansion.
  Compare the fixed eval/owner/head-word query list and every must-cover language
  against an untouched release and draft baseline. Build and validate locally;
  test evidence comes from CI (owner rule).
- **B1:** import the 118 protein/dairy candidates; confirm FDC serving weights
  and supported units against `portion_words.yaml`, then re-import and build.
  Compare all 115 must-cover rows and the frozen 153 queries with B0, in both
  release and draft packs. Save evidence under `a47-runs/B1/`; stop for commit.
- **B2:** import the 143 plants/staples candidates, auditing servings against
  retained USDA CSVs and `portion_words.yaml`. Transfer vegetable-ghee and fresh
  thyme aliases to the correct new rows. Compare coverage and the same frozen
  153 queries with B1 in release/draft packs; save `a47-runs/B2/` evidence and stop.
- **B3:** import all 113 packaged/drinks/fast-food candidates and five approved
  branded bars; audit servings against retained USDA CSVs and `portion_words.yaml`.
  Assign cake head words to plain cake; add the approved burger, pizza, broasted,
  halawa and tamarind coverage matches. Check the dried/fresh zaatar fallback.
  Compare all 115 must-cover rows and frozen 153 queries with B2 in release and
  draft packs; save `a47-runs/B3/` evidence and stop for orchestrator commit.

- **B5:** review the seven single foods against their cited sources, retained
  USDA analogues and portion ranges. Release only source-verified entries,
  recording Codex and the owner delegation date; transfer cheese/labneh
  ownership only after release. Fix the falafel partial match with a verified
  USDA basic if available. Compare B3 coverage and the unchanged 153 queries
  plus targeted local-food/falafel aliases; save `a47-runs/B5/` evidence.

Owner defaults (2026-10-30): chicken → skinless breast; bread → pita; juice →
orange juice; meat → beef mince (raw, consistent with the existing unqualified
mince aliases); fish → cooked white fish (the existing cooked tilapia entry).
Nabulsi remains draft, so released feta temporarily owns generic cheese aliases.
Move those aliases to Nabulsi when it is released, without duplicate owners.

## Progress log
_One dated line per event, newest last (process §8a)._
- 2026-10-30: card created (owner decisions 2026-10-30, TD-105).
- 2026-10-30: B0 implementation started from clean `step/A47-food-basics`;
  captured release/draft baselines and froze 153 queries (researcher's list,
  remaining M3/B09 mentions and head-word aliases). Evidence:
  `/tmp/claude-1000/-home-abood-work-fitness-buddy/de51d824-1e83-4dcb-8f57-796fffad28c4/scratchpad/a47-runs/B0/`.
- 2026-10-30: B0 aliases and generic must-cover match lists implemented; 246
  basics remain, with no new IDs. Peach owns دراق/durra2/dra2, plum owns
  خوخ/khokh, and nectarine owns نكتارين/nektarin. Feta is the temporary cheese
  default; cooked tilapia is the white-fish default. Vegetable-ghee aliases stay
  on margarine until B2 can move both AR and Arabizi atomically to shortening,
  preserving search in B0. Cake ownership waits for B3. Approved burger,
  pizza and broasted match lists wait for their B3 rows; halawa and tamarind
  will resolve by the existing ID-prefix rule. Zinger proxy was not approved.

- 2026-10-30: B0 checks passed: offline USDA re-import (unchanged extract),
  `make catalog`, `make catalog-check` and `git diff --check`. 48 foods have
  alias changes; 246 basics unchanged, no new IDs, lock and SQL fixture unchanged.
  Catalog v7→v9, names 1433→1550, pack 610304→614400 bytes; sanity unchanged
  (230 OK, 13 warnings, 3 reviewed overrides). All 115 must-cover rows preserve
  their EN/AR/Arabizi resolution (release 42 basic/73 missing; dev 10 draft/
  42 basic/63 missing). Fixed 153-query diff: 52 release top-1 changes, of which
  51 are approved defaults/corrections/new aliases; the existing release-only
  `chicken shawarma arabi` miss moves pita→breast, while its correct draft dish
  top-1 is unchanged. No correct top-1 lost. Full outputs and grouped before/
  after tables are in the B0 evidence folder above. No local tests run; CI
  supplies app/server/AQ evidence. Stopped after B0 for orchestrator commit.

- 2026-10-30: B1 implementation started from a clean working tree after the B0
  commit. Added all 118 candidate IDs and reviewed 57 suggested servings against
  retained USDA CSVs; mapped slices to `piece` and corrected state/portion
  mismatches. Preserved all 246 existing rows. Captured B0 release and draft
  packs and copied its frozen query/coverage baselines to `a47-runs/B1/`.

- 2026-10-30: B1 complete for orchestrator commit: 246→364 basics (+118),
  names 1550→2060, servings 199→256, pack 614400→745472 bytes, catalog v9→v12
  (new IDs first appear in v10). Offline import, `make catalog`,
  `make catalog-check`, ID/nutrient integrity and `git diff --check` passed;
  no new sanity warnings. Added exact Arabic حليب to whole milk after a
  top-five coverage regression; renamed the existing milk-chocolate bar so
  `chocolate milk` now finds the drink. All 508 new aliases resolve top-1.
  All 115 must-cover rows preserve every language/status/target in release
  and draft packs (0 losses/gains). Fixed 153-query diff: 6 release / 5 draft
  top-1 changes, no previously correct result lost. Four formerly empty
  queries now produce prototype partial matches (`my shake`, `pizza`,
  `protein shake`, `yesterday's lunch`); the existing release-only shawarma
  fallback shifts breast→pita while its correct draft top-1 stays unchanged.
  These partial matches need orchestrator CI/AQ triage; pizza itself is B3.
  Full final/intermediate outputs, serving audit and before/after tables:
  `/tmp/claude-1000/-home-abood-work-fitness-buddy/de51d824-1e83-4dcb-8f57-796fffad28c4/scratchpad/a47-runs/B1/`.
  No local tests or git mutations; no repository Dart changes. Stopped after B1.

- 2026-10-30: B2 started from a clean tree after the B1 commit; saved B1
  release/draft snapshots and its final 153-query/115-row coverage baselines.
  Added all 143 final candidate IDs, audited 135 servings against retained USDA
  CSVs (including supported slice→piece units), and moved vegetable-ghee and
  fresh-thyme AR/Arabizi aliases atomically. Dropped contradictory vegetable-ghee,
  canned-peach and jujube species aliases; all foods retained. No local tests.

- 2026-10-30: B2 complete for orchestrator commit: 364→507 basics (+143),
  names 2060→2699, servings 256→391, pack 745472→913408 bytes, catalog v12→v14
  (new IDs first appear in v13). Offline import, build, Arabic-required validation,
  `make catalog-check`, nutrient/ID integrity and `git diff --check` passed.
  All 364 old nutrient rows and lock records are identical; 642/642 new aliases
  resolve top-1. Sanity adds 12 researched warnings (sun-dried tomato and herbs/
  spices); no errors or new overrides. All 115 must-cover rows preserve every
  language/status/target in release and draft packs (0 losses/gains).
  Fixed 153-query diff: 7 release / 6 draft changes; no previously correct
  top-1 lost. New mixed nuts and the planned ghee aliases resolve correctly;
  release-only `zaatar` fallback shifts dried→fresh thyme while its correct
  draft mixture stays top-1. Three formerly empty cake spellings (`cake`,
  `Cake`, `كيك`) now partially match pancakes; B3 owns the actual cake rows.
  Orchestrator must triage these partial matches in CI/AQ. Removed the generic
  snack word from new butter crackers to restore `monday's snack` to no-hit.
  Final/intermediate outputs, serving audit, diffs and handoff:
  `/tmp/claude-1000/-home-abood-work-fitness-buddy/de51d824-1e83-4dcb-8f57-796fffad28c4/scratchpad/a47-runs/B2/`.
  No local tests, network or git mutations; no repository Dart changes.
  Stopped after B2; B3 untouched.

- 2026-10-30: B3 started from a clean tree after the B2 commit; saved B2
  release/draft snapshots and final 153-query/115-row coverage baselines. Added
  all 113 B3 candidates and five approved branded bars, with 114 servings
  audited against retained USDA portions. Corrected whole-cake, half-cup,
  cupcake and package/unit suggestions; preserved all existing foods. Added
  the five approved coverage match lists, cake head words and qualified dried
  thyme fallback aliases. No local tests, network or Git write commands.

- 2026-10-30: B3 complete for orchestrator commit: 507→625 basics (+113
  candidates +5 branded bars), names 2699→3234, servings 391→505, pack
  913408→1044480 bytes, catalog v14→v16 (new IDs first appear in v15).
  Offline import, build, Arabic-required validation, `make catalog-check`,
  nutrient/ID/serving integrity and `git diff --check` passed. All 507 old
  nutrient rows and lock records identical; 532/532 new aliases resolve top-1.
  Three source-preserving sanity warnings added (two vinegars, sugarless gum),
  zero new errors/overrides. Coverage: zero losses across 115 rows in either
  pack; burger, pizza slice, broasted chicken, halawa and tamarind each gain
  EN/AR/Arabizi resolution (42→47 basic). Other 110 rows identical.
  Fixed 153-query diff: 9 release /7 draft changes; no previously correct
  top-1 lost after exact `Chicken thigh` restored its skinless default.
  Cake spellings now find plain cake; pizza, Snickers and zinger find the
  appropriate new foods. Release zaatar restores dried-thyme fallback via
  qualified aliases; the correct draft mixture remains unchanged. One strict
  no-hit-preservation exception needs CI/AQ triage: release `falafel sandwich`
  now partially matches crispy chicken sandwich, while its correct draft
  top-1 stays unchanged. No false alias, food deletion or ranking-code change.
  Final/intermediate outputs, portion audit, counts and handoff:
  `/tmp/claude-1000/-home-abood-work-fitness-buddy/de51d824-1e83-4dcb-8f57-796fffad28c4/scratchpad/a47-runs/B3/`.
  No local tests, network, Git write commands or repository Dart changes.
  CI supplies app/server/AQ evidence; orchestrator must triage the single
  release partial match and any newly passing shrink-only AQ known misses.
  Stopped after B3; bonus batch untouched.

- 2026-10-30: B5 started from the clean B3 tree. Owner delegated source review
  of seven local single foods to Codex. Cited labels/table pages are not retained
  locally; the supplied USDA datasets exclude the cited branded freekeh record.
  Offline analogue/macro/portion checks are recorded per food, but none can be
  source-verified under this batch's no-network rule, so all seven remain draft.
  Cheese stays on released feta and labaneh's exact aliases stay on its draft.
  Found USDA SR Legacy 172455 home-prepared falafel in the retained CSVs; adding
  this balls-only basic (17 g patty, no sandwich fillings) to fix the release
  chicken partial match without editing any of the five composite dishes.
  B5 evidence is saved under `a47-runs/B5/` beside the B0–B3 handoffs.

- 2026-10-30: B5 stopped for orchestrator handoff with source release blocked:
  625→626 basics (+USDA home-prepared falafel), 0 released/12 draft refs unchanged,
  names 3234→3241, servings 505→506, pack 1044480→1048576 bytes, v16→v17.
  Offline USDA import, `make catalog`, Arabic-required validation,
  `make catalog-check`, ID/nutrient/portion integrity and `git diff --check`
  passed; no new sanity warnings (595 OK/28 warn/3 overrides). All 625 existing
  USDA rows and lock records unchanged; all five composite YAML files untouched.
  Coverage: 0 losses across 115 rows in release and dev; release falafel gains
  EN/AR/Arabizi resolution (47→48 basic, 68→67 missing); dev unchanged.
  Frozen 153 queries: exactly 1 release top-1 change, `falafel sandwich` crispy
  chicken→USDA falafel balls; 0 dev changes. Targeted `falafel`/`فلافل` no-hit→
  falafel balls; correct draft falafel top-1 retained. All 7 new aliases resolve
  top-1 in release. This basic excludes bread/fillings and is not a released
  sandwich; the prototype ranker can still show chicken as a lower partial hit.
  Seven local foods remain draft with per-food offline review notes: cited
  primary-source content is unavailable, including Branded FDC 2553773; no
  network used. No source values were guessed or replaced by USDA analogues.
  Cheese stays on feta and labneh remains absent from release. Orchestrator
  needs retained source snapshots or a source-access exception to finish the
  delegated review; sumac also needs a fibre source. On successful review,
  extend reviewed_by's source-schema enum to Codex rather than claim owner
  review (currently only owner/claude-draft are allowed). Evidence, numeric
  review table and handoff: `a47-runs/B5/README.md` and `reference_review.md`.
  No local tests, Git write commands or repository Dart changes. CI remains
  the evidence for app/server/AQ; check shrink-only known misses for falafel.
- 2026-10-30 B6: 7 local single foods (Nabulsi, Akkawi, halloumi, labaneh, zaatar, freekeh, sumac) checked against their cited sources by an AI (owner-delegated), now `reviewed` / `ai-verified` and in the release pack (catalog v18). Schema gained `ai-verified`. Generic cheese/jibneh words moved from feta to Nabulsi. Sumac fibre stays 0 (unlisted) with a note.


- 2026-10-30 B7 review fixes: removed `مشط مقلي` from dry-heat tilapia and
  `فوارغ`/`fawareh` from plain tripe (kept `كرشة`/`kirsheh`). Red cabbage
  now offers the sourced chopped cup (89 g), replacing the ambiguous 23 g leaf
  labelled as a piece. Added Baladna, Steenbergs and Sligro/PS in Foodservice
  attribution; expanded existing Matvaretabellen and USDA records, including
  Branded freekeh checked via API. Unrecorded reuse terms remain explicitly
  unconfirmed, following the existing Matvaretabellen style; no licence was
  guessed; no source pages were fetched.
- 2026-10-30 B7 PA12: the new foods legitimately add 20 raw/cooked pairs
  (22→42 pairs / 44→84 directed links). Updated the real-pack pin and replaced
  the obsolete 90/10 no-switch assertion with an explicit 90/10-only partner
  assertion. Ratios and qualifiers remain in the identity comparison; no yield
  groups, state labels or production code changed.
- 2026-10-30 B7 AQ T05: the fixture actually says **white cheese**, not egg
  whites. Replaced its obsolete estimate expectation with Nabulsi/brined or
  feta keys, both white cheeses. Added the truthful qualified alias `Feta white
  cheese` so a USDA substring hit outranks fuzzy egg white on the current
  server. Exact generic cheese/white-cheese ownership stays on Nabulsi; the
  server default still needs the A49 ranking fix (backlog #218).
- 2026-10-30 B7 AQ T12: plain skinless chicken is not chicken shawarma arabi;
  retained the estimate expectation. No truthful alias can make the missing
  released shawarma sandwich exist. Removed the stale conversion-code baseline
  entry identified by CI; the new wrong-key miss remains unresolved in this
  data-only batch (A49/#218), without adding a known miss.
- 2026-10-30 B7 AQ T13: crispy chicken and falafel balls are neither a complete
  falafel sandwich. Retained the estimate expectation and removed CI's stale
  conversion-code baseline entry. USDA falafel remains balls-only; the new
  wrong-key miss requires A49/#218 or a properly released sandwich, not a false
  alias or a widened expectation.
- 2026-10-30 B7 AQ T14: owner-approved USDA cheese pizza now covers pizza;
  replaced the obsolete estimate expectation with `usda:pizza_cheese`, keeping
  the explicit two-piece amount. Removed the stale conversion baseline entry.
- 2026-10-30 B7 AQ T16: crispy chicken sandwich is the existing sourced zinger
  proxy (lettuce/mayo; local size/spice may vary). Replaced the obsolete estimate
  expectation with `usda:chicken_sandwich_crispy`. Added a 152 g `piece` serving
  equal to the sourced whole-sandwich portion so the fixture's explicit unit
  resolves. Removed its stale conversion entry; the soft-drink density miss is
  separate and remains in the baseline.
- 2026-10-30 B7 AQ T19: owner-approved Snickers is a real released food;
  replaced the estimate expectation with `usda:snickers_bar`, retaining one
  piece. Removed CI's stale AQ-02/AQ-03 unmatchedFood and AQ-07 clarify entries.
  In total the known-miss list only shrinks (25→17, eight removed); no threshold
  changes. B6's additional reference releases still need fresh real-catalog CI
  triage; existing labaneh/zaatar resolver misses are not assumed fixed.

- 2026-10-30 B7 checks/handoff: `make catalog` and `make catalog-check`
  passed under the shared heavy lock; v18→v19, 626 basics/7 released refs
  unchanged, zero new IDs, lock/extract/nutrients/SQL fixture unchanged. Pack
  remains 1,064,960 bytes; names 3324→3322, servings 518→519; sanity unchanged
  (602 OK/28 warnings/3 overrides). All 115 coverage rows and all 153 fixed
  query top-1 results are identical in release/dev (zero changes/losses).
  `make progress` passed with unchanged PROGRESS.md; `git diff --check` passed.
  `make check-dart` passed formatting but the workspace analyzer crashed;
  focused analysis then exposed plugin setup failing to write `pubspec.lock`
  under sandbox-read-only `~/.dartServer/.plugin_manager/` (automatic pub
  upgrade, exit 66; analyzer exit 4). No app/server/AQ suites ran. CI must
  verify PA12 and AQ; T12/T13 wrong-key misses and the deferred server default
  remain unresolved, not hidden in a new baseline. Short report and before/
  after evidence: `a47-runs/B7/README.md` under the supplied scratchpad.
  Stopped after B7 without Git write operations.

- 2026-10-30 Close (orchestrator): CI on 7ae103d1 was red on two expected
  items. (1) PA24: T14 (pizza) and T16 (zinger sandwich) now resolve to new
  basics, so their parsed fixtures drop the model estimate (`estimate: null`).
  (2) Eval: T12#0/T13#0 are back in the known-miss baseline with their new
  resolver codes (fixing step A49). Local `aq_cases_test.dart` 8/8, gate
  selftest OK. Merge CI is the evidence (no further branch push, owner rule).

## Follow-ups
- **A49, phase 2 — backlog #218:** server retrieval and resolver score must
  prefer exact aliases before weaker source tiers; verify `cheese`/`جبنة` →
  `ref:nabulsi_cheese/brined` through the real server. T12/T13 fuzzy-only
  sandwich matches remain unresolved without code or correctly released dishes.
- Confirm Baladna, Steenbergs and Sligro/PS reuse terms before R2/R3; keep the
  existing Matvaretabellen licence question (#64).

## Outcome
**Built (Codex-coded, owner experiment; reviewed by a separate Codex task):**
basics 246 → 626 in the offline pack (batches B0–B7), each with Arabic names,
Arabizi spellings and portions; owner-approved generic defaults (chicken →
skinless breast, bread/5obez → pita, juice → orange, cheese/jbneh → Nabulsi,
meat → beef mince, fish → white fish; peach = دراق, plum = خوخ); verified USDA
packaged basics plus five branded bars (owner exception); the 7 local single
foods released as `ai-verified` (new `reviewed_by` value in
`reference_dish.v1.schema.json`) after an AI number check.

**Measurements:** pack 1,064,960 bytes (inside the A05 budget); names 3,322,
servings 519; sanity 602 OK / 28 warnings / 3 overrides; all 153 fixed search
queries keep their top-1 result; raw/cooked pins in `food_search_test.dart`
22 → 42 pairs; AQ known misses 25 → 17.

**Deviations:** size grew past "about 350 new" to 380; the branded bars were
pulled in from A48 with the owner's OK. T14/T16 parsed fixtures lost their
model estimate because the foods now resolve (PA24).

**Follow-ups:** A49 / backlog #218 (exact-alias ranking on the server, the
T12/T13 sandwich misses); brand-reuse terms before R2/R3 (#64).

**Metrics:** 8 batch commits + 1 close fix; 1 Codex review round (changes
requested, fixed in B7); 2 CI-only fixes at close. No new TDs.
