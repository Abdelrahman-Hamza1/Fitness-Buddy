# Steps — How R1 Gets Built

R1 is built on **two tracks** (TD-063), both built by Claude since TD-085 (2026-10-28; Codex retired):

- **App track `A01–A50`**: the Flutter app, the Dart packages and tools, the food data. The **By** column records who built each finished step (Codex built some no-UI steps under TD-078).
- **Backend track `B01–B21`**: the API, the Buddy server, infrastructure and deploys (B01–B08 and B17 built by Codex; the rest by Claude).

**Within a track the number is the order.** The only waits are the dependencies on the other track, shown in **bold** on the board (§4) and listed in §6. The finished foundation steps keep their old IDs (`S01`–`S04`, `S06a/b`, `S08`); old `Sxx` IDs are never reused, so a commit called `S04: …` is always the old plan and `A01: …` / `B01: …` the new one (§8).

**Servers:** until the end of R1 the owner's **laptop is the test server** for the phone (B03, over Tailscale). Hetzner staging and production come last (B13, B14), by the owner's choice (TD-064). The app is local-first, so the owner can use it daily long before that (milestone M1).

Each step is one focused session (or a few): **low-level plan → implementation → verification → outcome**, recorded in its **card** in this folder.

## 1. Session protocol

Every step session follows these phases. The owner can stop the session at the end of any phase.

> **Who does what:** Claude runs both tracks (TD-085). The main Claude session is the **orchestrator** and runs this protocol with the **`run-step`** skill. It delegates to specialist agents (`.claude/agents/`): `tech-researcher` and `step-planner` + `architect` in Phase B, the engineers per work package in Phase C, the reviewers and `verifier` in Phase D. Owner gates: **plan approval** (end of B) and **step acceptance** (end of E). The same phases apply to both tracks. The full process (roles, decision rights, communication, quality gates) is in **`../13-delivery-process.md`**.

### Phase A: Orient (≈ 10 min)
1. Read this README's **status board** (§4) and pick the step per §7. Confirm its dependencies are ✅ (or, for "(contract)", that the contract commit is on `main`) and that `main` is green.
2. Read the step card, then the docs in its **Read first** list. Skim the **Outcome** sections of its dependencies, which may have changed assumptions.
3. If the card conflicts with reality (an earlier step deviated), note it and fix the card **before** planning.

### Phase B: Low-level plan (written into the card)
Fill the card's **Low-level plan** section:
- **Design:** types, interfaces, tables/migrations, endpoints (contract diff), screens, and how each "Decide in the low-level plan" item is resolved, with a one-line reason each. Number decisions `D1…` and review amendments `PA1…` (§8).
- **File list:** files to create or change.
- **Test list:** each test named with the spec ID it proves.
- **Task order:** a numbered checklist of small, committable tasks.
- **Risks / unknowns** and how the session will handle them.

**The owner reviews the plan** (approve, or comment and adjust) before implementation starts. For S-sized steps a quick skim is enough. Architecture-level choices become a TD entry in `12-decisions-and-questions.md`.

### Phase C: Implement
- Branch `step/<ID>-short-name` from `main` (e.g. `step/A01-local-data`).
- Work through the task list with small commits (Conventional Commits). Keep `make check test` green as you go.
- API changes: **contract first** → regenerate the client → implement the server → conformance green.
- Don't expand scope. Anything new goes into **Follow-ups** in the Outcome, or onto a later card.

### Phase D: Verify
- Tick every **Exit criteria** item, with evidence (test names, screenshots, a CI link, measured numbers).
- Run the full CI locally (`make check test`; `make eval` if AI-related).
- Demo to the owner when the card says so (e.g. on the A55).

### Phase E: Close
- Fill the card's **Outcome**: what was built, deviations from the plan (and why), follow-ups, new TDs, numbers measured.
- Update the **status board** (§4) and any planning doc the step changed (an outdated doc is a bug).
- Merge as one squash commit `<ID>: <step name>` through a CI-verified `merge/<ID>` branch (TD-036, TD-039, `../13-delivery-process.md` §3.E).

**If the step is bigger than planned:** split it at a natural seam (`A07a` done, `A07b` new card), close the finished part properly, and update the board.

**If the plan turns out to be wrong:** stop, write down why, propose the change (new TD or spec decision), and adjust later cards before continuing.

## 2. Card template

```markdown
# <ID> — <Title>

| Track | Depends on | Size | Owner | Status |
|---|---|---|---|---|
| App / Backend | A05, **B07** (contract) | S / M / L | Claude | ⬜ Not started |

**Goal.** One paragraph: what exists after this step that didn't before, and why it matters.

**Spec:** requirement IDs delivered (fully or partly) · **Decisions:** TD/D IDs that constrain this step

## Scope
- what's in

## Out of scope
- what's explicitly not in (and which step does it)

## Fixed by the plan
- design points already decided (don't re-litigate. If one seems wrong, raise it)

## Decide in the low-level plan
- open choices this session resolves

## Exit criteria
- [ ] verifiable checks

## Read first
- docs and sections

## Owner involvement
- what the owner provides or reviews

---

## Low-level plan
_Written in Phase B._

## Progress log
_One dated line per event, newest last (process §8a)._

## Outcome
_Written in Phase E: built · deviations · follow-ups · new TDs · measurements._
```

## 3. Owner prerequisites (accounts & inputs)

In the order they're needed:

| Needed by | What | Notes |
|---|---|---|
| **S01** ✅ | GitHub repository (public per TD-042), push via the laptop SSH key | Done 2026-10-12 |
| A02 | ~30 min to review the design gallery and mockups on the A55 (also covers S06b's deferred device check) | — |
| B02 | **OpenAI** project key only, GPT-6 Luna; a few small synthetic smoke prompts (TD-067) | Owner configured; no provider bake-off |
| B03 | A **Tailscale** account and the Tailscale app on the A55 (the phone reaches the laptop server through it) | Free |
| A03, dish batches | Skim each dish batch (≈ 15 min). Name family recipes to use (TQ-08) | — |
| A11 | A **Sentry** account (EU region) for crash reports | Free tier |
| B04 | A **Google Cloud** project with OAuth client IDs for Google sign-in (Android + web/server) | Free |
| B13 (near the end) | **Hetzner Cloud** account + API token. **A domain name** with DNS on **Cloudflare**. **Grafana Cloud** account | ≈ €10/mo staging + domain |
| B14 | A **second storage provider** for backup copies (e.g. Backblaze B2). An alert contact. An **email provider** account + DNS records (SPF/DKIM) for sign-in codes | Free tiers / a few € |
| A43 | **Google Play Console** ($25 once) | — |
| R2 (iOS, D-081) | Apple Developer Program ($99/yr), a Codemagic account | — |

## 4. Status board

**Owner** (TD-085, 2026-10-28): **Claude** builds both tracks and owns the whole repo. Codex owned the backend and the no-UI app steps until then (TD-059, TD-061, TD-078, TD-079); it is retired, and its finished steps keep their history.

**By column:** who built (✅) or builds (open) each app step. The open steps once marked Codex (A24, A34, A36, A43; TD-078) moved to Claude with TD-085.

**Depends on:** same-track IDs are plain, other-track IDs are **bold**. "**B09** (contract)" means the app step can start once B09's **contract handoff merge** is on `main` (`B09 (contract): …`: the contract, the regenerated client and `501` server stubs, TD-065), using the generated client + fakes; its end-to-end checks wait for the finished B step.

Legend: ⬜ not started · 🟦 planning · 🟨 in progress · ✅ done · ⏸ blocked

### 4.0 Foundation (done, old IDs)

| ID | Step | Owner | Status |
|---|---|---|---|
| [S01](S01-repo-tooling-ci.md) | Repo, tooling & CI foundation | Claude | ✅ |
| [S02](S02-api-contract-pipeline.md) | API contract pipeline | Claude | ✅ |
| [S03](S03-backend-host.md) | Backend host & HTTP conventions | Codex | ✅ |
| [S04](S04-backend-persistence.md) | Backend persistence, outbox & jobs | Codex | ✅ |
| [S06a](S06-app-shell.md) | App shell: skeleton | Claude | ✅ |
| [S06b](S06-app-shell.md) | App shell: Android builds & device | Claude | ✅ |
| [S08](S08-domain-primitives.md) | Domain primitives & text normalization | Claude | ✅ |

### 4.1 App track

| ID | Step | By | Depends on | Size | Was | Milestone | Status |
|---|---|---|---|---|---|---|---|
| [A01](A01-local-data-foundation.md) | Local data foundation | Claude | S06 ✅, S08 ✅ | M | S09 |  | ✅ |
| [A02](A02-design-system.md) | Design system v0 & key screen mockups | Claude | S06 ✅ | L | S07 |  | ✅ (phone review: backlog #72) |
| [A03](A03-spike-food-data.md) | Spike: food data | Claude | S08 ✅ | M | S11 |  | ✅ |
| [A04](dish-batches.md) | Dish batch 1: basics (breakfast & bread → A17, TD-074) | Claude | A03 | S | D1 |  | ✅ |
| [A05](A05-catalog-pipeline.md) | Catalog pipeline & offline pack v1 | Claude | A01, A03, A04 | L | S13 |  | ✅ |
| [A05b](A05b-exercises-cities-data.md) | Exercises & cities data | **Codex** | A05 | S | S13 part |  | ✅ |
| [A06](A06-diary-domain.md) | Diary domain & storage | Claude | A01 | M | S14 |  | ✅ |
| [A07](A07-food-search-add.md) | Food search & add flow | Claude | A02, A05, A06 | M | S15 |  | ✅ |
| [A08a](A08-today-diary-ui.md) | Today & diary view (split from A08, 2026-10-23) | Claude | A07 | L | S16 part |  | ✅ |
| [A08b](A08-today-diary-ui.md) | Diary editing & meal actions (split from A08) | Claude | A08a | M | S16 part |  | ✅ |
| [A09a](A09-personal-foods-quick-add.md) | Personal foods & guarded repeat-log ops (split from A09) | Claude | A08b | L | S17 part |  | ✅ |
| [A09b](A09-personal-foods-quick-add.md) | Saved meals & quick-add (split from A09) | Claude | A09a | M | S17 part |  | ✅ |
| [A10a](A10-settings-slots.md) | Settings, units & About (split from A10) | Claude | A08a | M | S18 part |  | ✅ |
| [A10b](A10-settings-slots.md) | Meal slot editor (split from A10) | Claude | A10a | M | S18 part |  | ✅ |
| [A11](A11-dogfood-1-readiness.md) | Dogfood 1 readiness: export, crash reports, daily build | **Codex** | A09b, A10a · soft: **B03** | M | S28 export part + new | **M1** | ✅ |
| [A12](A12-targets-engine.md) | Targets engine | **Codex** | A06 | M | S19 |  | ✅ |
| [A13a](A13-targets-ui-onboarding.md) | Targets storage & commands (split from A13, 2026-10-28) | Claude | A10a, A10b, A12 | L | S20 part |  | ✅ |
| [A13b](A13-targets-ui-onboarding.md) | Onboarding & Today numbers (split from A13) | Claude | A13a, A14 | M | S20 part |  | ✅ |
| [A13c](A13-targets-ui-onboarding.md) | Profile, goal & targets screens (split from A13) | Claude | A13b | M | S20 part |  | ✅ |
| [A14](A14-weigh-ins-trend.md) | Weigh-ins & trend | Claude | A08a | L | S21 |  | ✅ |
| [A15a](A15-weight-graph-measurements.md) | Weight graph (split from A15, 2026-10-28) | Claude | A12, A13a, A14 | L | S22 part |  | ✅ |
| [A15b](A15-weight-graph-measurements.md) | Weight history entry & measurements (split from A15; owner real-history sign-off pending, #213) | Claude | A15a | L | S22 part |  | ✅ |
| [A16](A16-progress-tab.md) | Progress tab v1 | Claude | A13c, A15 | L | S23 | **M2** | ✅ |
| [A17](dish-batches.md) | Dish batch 2: main dishes A | Claude | A04 | S | D2 |  | ✅ (ai-verified, D-087) |
| [A18](dish-batches.md) | Dish batch 3: out & street food | Claude | A17 | S | D3 |  | ✅ (ai-verified, D-087) |
| [A19](dish-batches.md) | Dish batch 4: main dishes B, salads & sides | Claude | A18 | S | D4 |  | ✅ (with A30, one combined step, built by Codex) |
| [A20](A20-api-session.md) | API session: anonymous identity & auth interceptor | **Codex** | **B04** (contract) | S | S25 part |  | ✅ |
| [A21](A21-proposal-engine.md) | ProposalEngine | **Codex** | A07, A12, **B08** | L | S32 |  | ✅ |
| [A22a](A22-chat-proposal-card.md) | Chat sheet, message storage & proposal card (split from A22, 2026-10-28) | Claude | A08b, A20, A21, **B08**, **B18**, **B09a** WP0 | L | S33 part |  | ✅ |
| [A22b](A22-chat-proposal-card.md) | Card adjustments & follow-up (split from A22) | Claude | A22a, **B09a** (contract) | M | S33 part |  |✅ |
| [A44](A44-brand-identity.md) | Brand identity & theme ("Embrace"; runs after A22a, owner 2026-10-29) | Claude | A22a | L | new |  | ✅ (phone checks: backlog #155) |
| [A23a](A23-message-lifecycle.md) | Durable proposals & restore (split from A23, 2026-10-30) | Claude | A22a, A22b, **B18** (contract) | L | S34 part |  | ✅ |
| [A23b](A23-message-lifecycle.md) | Message queue, failures & pending strip (split from A23) | Claude | A23a | L | S34 part | **M3** | ⬜ phase 2 (plan written) (TD-105) |
| [A24](A24-online-search-pack-updates.md) | Online search & pack updates (app) | Claude | A07, **B07** | M | S30 app part |  | ✅ |
| [A25](A25-diary-edits-by-chat.md) | Diary edits by chat (app) | Claude | A23, **B09a** (contract) | M | S35 app part |  | ⬜ phase 2 |
| [A26](A26-memory-user-model.md) | Memory & user model (app) | Claude | A23a, **B09a** (contract) | M | S36 app part |  | ⬜ phase 2 |
| [A27](A27-batches-chat-foods.md) | Batches, personal foods & saved meals by chat (app) | Claude | A09b, A23, **B09a** (contract) | L | S37 app part |  | ⬜ phase 2 |
| [A28a](A28-barcode-label-scan.md) | Barcode scanning (app, no AI; split from A28, 2026-10-30) | Claude | A09a, A24, **B10a** (contract) | M | S38 app part |  | ✅ closed, awaiting review/merge (built with B10a as one step, owner 2026-10-30) |
| [A28b](A28-barcode-label-scan.md) | Label scan (app; split from A28) | Claude | A28a, A23b, **B10b** (contract) | M | S38 app part |  | ⬜ phase 2 |
| [A29](A29-photo-body-import.md) | Photo logging, body data by chat & paste import (app) | Claude | A15, A23, **B10b** (contract) | M | S39 app part |  | ⬜ phase 2 |
| [A30](dish-batches.md) | Dish batch 5: sweets, drinks & Ramadan staples | Claude | A19 | S | D5 |  | ✅ (with A19) |
| [A31](A31-qa-suggestions-halal.md) | Q&A, suggestions & halal (app) | Claude | A26, **B11** (contract) | M | S40 app part |  | ⬜ phase 2 |
| [A32](dish-batches.md) | Dish batch 6: gap fill from dogfooding | Claude | A30 | S | D6 |  | ⏸ gap fill once dogfooding shows the misses (TD-105) |
| [A33](A33-sign-in-guest-app.md) | Sign-in & guest upgrade | Claude | A20, **B04** | M | S25 |  | ✅ |
| [A34](A34-sync-engine-app.md) | Sync engine (app) | Claude | A33, **B05**, **B17**, **B18**, **B19**, **B20**, **B21** | L | S27 |  | ✅ closed, awaiting review/merge (built with A35 as one step, owner 2026-10-30) |
| [A35](A35-account-deletion-app.md) | Account deletion (app) | Claude | A34, **B06** | S | S28 deletion part | **M5** | ✅ closed, awaiting review/merge (built with A34 as one step) |
| [A36](A36-workout-domain.md) | Workout domain, library & templates | Claude | A05b, A06, A12 | M | S41 |  | ✅ |
| [A37a](A37-workout-logging.md) | Workouts without AI: log & history (no plan needed, last-time numbers, autosave, Repeat, PRs, Today row; split from A37, 2026-10-30) | Claude | A36, A15a | L | S42 app part |  | ✅ |
| [A37c](A37-workout-logging.md) | Workouts without AI: plans, muscle map & progress (starter plans, templates, exercise page; split from A37) | Claude | A37a · soft: A16 (Progress entry) | M–L | S42 app part |  | ✅ |
| [A37b](A37-workout-logging.md) | Workout logging by chat (split from A37) | Claude | A37c, A23b, **B12** (contract) | M | S42 app part |  | ⬜ phase 2 |
| [A38](A38-adaptive-targets.md) | Adaptive targets & weekly check-in | Claude | A16, A23a (proposal storage) | M | S43 |  | ✅ closed, awaiting review/merge |
| [A39a](A39-weekly-review.md) | Weekly summary (numbers, no Buddy; split from A39, 2026-10-30) | Claude | A37c, A38 | M | S44 app part |  | ✅ closed, awaiting review/merge (with A40) |
| [A39b](A39-weekly-review.md) | Buddy weekly review (split from A39) | Claude | A39a, A23b, **B12** (contract) | S | S44 app part |  | ⬜ phase 2 |
| [A40](A40-notifications.md) | Notifications | Claude | A37c, A39a (TD-105; see card) | M | S45 |  | ✅ closed, awaiting review/merge (with A39a) |
| [A41a](A41-ramadan.md) | Ramadan mode without Buddy (split from A41, 2026-10-30) | Claude | A05b, A15, A38, A40 | L | S46 app part |  | ✅ closed, awaiting review/merge |
| [A41b](A41-ramadan.md) | Ramadan Buddy parts (split from A41) | Claude | A41a, A39b, **B12** (contract) | S | S46 app part | **M6** | ⬜ phase 2 |
| [A42](A42-performance-a11y-offline.md) | Performance, accessibility & offline acceptance | Claude | A41a, A35 (TD-105) | M | S48 | **M2b** · **R1** | ✅ closed, awaiting review/merge (A41a merged in, its screens swept) |
| [A43](A43-play-internal-release.md) | Play internal testing release | Claude | A42, **B14** | S | S29 app part | **M7** | ⬜ production |
| [A45](A45-ux-polish.md) | UX polish: steady chips, light default, slim weight row, tab reset | Claude | A15b, A44 | M | new (owner phone feedback) |  | ✅ |
| [A46](A46-test-diet.md) | Test diet (one-time cut, TD-104) | Claude | — | M | new |  | ✅ |
| [A47](A47-food-basics-expansion.md) | Food basics expansion (~250 → ~600) | Claude | A05 | M | new |  | ✅ |
| [A48](A48-local-brands.md) | Local brands & packaged foods | Claude | A47 | M | new |  | ⏸ postponed (owner, D-087) |
| [A49](A49-buddy-accuracy.md) | Buddy accuracy (backlog #148–#151) | Claude | A23b, **B09b** | M | new |  | ⬜ phase 2 |
| [A50](A50-google-sign-in.md) | Google sign-in on the phone (backlog #200) | Claude | A33 | S | new |  | ✅ closed, awaiting merge (pulled forward by the owner, 2026-10-30) |

**A44 runs right after A22 (owner request, 2026-10-29):** the "Embrace" identity (palette, fonts, icon) lands before the remaining screens are built, an exception to "the number is the order" like the dish batches below.

**Solid app first (TD-105, owner 2026-10-30):** no new Buddy/AI work until phase 1, the non-AI app, is done (milestone **M2b**); the Buddy features already built keep working. Phase 1 runs in waves, shown in the Status column: **wave 1** A46, A47, A17, A18, A16, A45 · **wave 2** B20, A37a, A37c, B21, A19, A30, A48 · **wave 3** A50, B10a, A28a, A38 · **wave 4** A39a, A40, A41a, A34, A35 · **wave 5** A42. Then **phase 2** (Buddy: A23b, A49, A25–A27, A28b, A29, A31, B10b, B11, B12, A37b, A39b, A41b), then **production** (B13, B14, A43). Steps with an AI half were split into a (no AI) and b (Buddy). The waves are an exception to "the number is the order". **A48 (local brands) is postponed by the owner (D-087);** A37b stays in phase 2.

**Dish batches (TD-074, amended by TD-105):** A17 and A18 are back in wave 1, A19 and A30 in wave 2; A32 stays the gap fill from dogfooding. The reference-dish pipeline (A03, A05) is unchanged.

### 4.2 Backend track (Claude since TD-085; B01–B08, B17 built by Codex)

| ID | Step | Depends on | Size | Was | Milestone | Status |
|---|---|---|---|---|---|---|
| [B01](B01-spike-sync.md) | Spike: sync | S04 ✅, S08 ✅ | M | S12 |  | ✅ |
| [B02](B02-spike-ai-bakeoff.md) | OpenAI interpretation spike & eval harness v0 | S03 ✅, S08 ✅ | L | S10 |  | ✅ |
| [B03](B03-laptop-test-server.md) | Laptop test server for the phone | S04 ✅ | S | new |  | ✅ (reboot follow-up#76) |
| [B04](B04-identity-backend.md) | Identity backend | S04 ✅ | L | S24 (real email sender → B14) |  | ✅ (Google owner check#78) |
| [B05](B05-sync-backend.md) | Sync backend | B01, B04 | L | S26 |  | ✅ |
| [B06](B06-account-deletion-backend.md) | Account deletion (backend) | B04, B05 | L | S28 server part |  | ✅ |
| [B07](B07-catalog-service.md) | Catalog service & online search | B04, **A05** | M | S30 server part |  | ✅ |
| [B08](B08-buddy-interpret-service.md) | Buddy interpret service | B02, B07 | L | S31 |  | ✅ |
| [B09a](B09-buddy-intents-edits-memory-batches.md) | Buddy intents server: contract, v2 grammar & resolver (split from B09) | B08, **A21** | L | S35–S37 server parts |  | ✅ (live smoke WP7: owner-gated, moved to B09b) |
| [B09b](B09-buddy-intents-edits-memory-batches.md) | Full AQ metrics with the real ProposalEngine (M3 eval half; split from B09) | B09a | M | S35–S37 server parts | **M3** eval | ✅ (AQ metrics built and measured; M3 gate not yet met: 25 known misses → density chore, estimate-portion policy, resolver match quality, A17, A32; live smoke WP7 owner-gated) |
| [B10a](B10-barcode-vision-import.md) | Barcode lookup (server, no AI; split from B10, 2026-10-30) | B07 | M | S38 server part |  | ✅ closed, awaiting review/merge (built with A28a as one step; migration `202610300001_OffCacheWrites`) |
| [B10b](B10-barcode-vision-import.md) | Label & meal photos, paste import (split from B10) | B10a, B08 | L | S38–S39 server parts |  | ⬜ phase 2 |
| [B11](B11-buddy-qa-suggestions.md) | Buddy Q&A & suggestions | B08 | M | S40 server part |  | ⬜ phase 2 |
| [B12](B12-buddy-workouts-review-ramadan.md) | Buddy workouts, weekly review & Ramadan | B08 | M | S42, S44, S46 server parts |  | ⬜ phase 2 |
| [B13](B13-staging-infrastructure.md) | Staging on Hetzner & deploy pipeline | S04 ✅ · code any time; provisioning (cost) starts when the app track reaches **A38** (TD-064) | L | S05 |  | ⬜ production |
| [B14](B14-production.md) | Production, backups & go-live | B13 | L | S29 server part | **M7** | ⬜ production |
| [B15](B15-eval-expansion.md) | AI eval expansion & tuning | B09a/B09b, B10–B12, B14, **A41** | M | S47 | **R1** | ⬜ R1 close |
| [B16](B16-security-restore-drill.md) | Security review & restore drill | B14, **A42** | M | S49 | **R1** | ⬜ R1 close |
| [B17](B17-personal-food-sync.md) | personalFood sync entity (server) | B05, **A09a** (contract) | M | new (A09 split) |  | ✅ |
| [B18](B18-chat-proposal-sync.md) | chatMessage & proposal sync entities (server) | B05, **A21** (WP4 codec shape and size budget) | M | new (A21 plan review) |  | ✅ |
| [B19](B19-body-targets-sync.md) | Body & targets sync entities (server) | B05, B18, **A13a** (contract), **A14** | M | new (A13 plan review) |  | ✅ |
| [B20](B20-measurement-sync.md) | Measurement sync entities (server) | B05, B19, **A15b** (contract) | M | new (A15b plan) |  | ✅ |
| [B21](B21-workout-sync.md) | Workout sync entities (server; backlog #189) | B05, B20, **A36**, **A37a** | M–L | new (A36 D6) |  | ✅ closed, awaiting merge (Codex APPROVE, 0 findings) |

```mermaid
flowchart LR
  subgraph P0["Done"]
    d1["A01–A15, A20–A24, A33, A36, A44<br/>B01–B09b, B17–B19"] --> M1{{"M1 Dogfood 1"}}
  end
  subgraph P1["Phase 1 · solid app, no AI (TD-105)"]
    w1["Wave 1<br/>A46 test diet · A47 basics<br/>A17, A18 dishes · A16 · A45 polish"] --> M2{{"M2"}}
    w1 --> w2["Wave 2<br/>B20 · A37a workouts · A37c muscle map &amp; plans · B21<br/>A19, A30"]
    w2 --> w3["Wave 3<br/>A50 Google · B10a + A28a barcode<br/>A38 adaptive targets"]
    w3 --> w4["Wave 4<br/>A39a summary · A40 · A41a Ramadan<br/>A34 sync · A35 deletion"] --> M5{{"M5 Accounts & sync"}}
    w4 --> w5["Wave 5<br/>A42 performance, a11y, offline"] --> M2b{{"M2b Solid app"}}
  end
  subgraph P2["Phase 2 · Buddy"]
    p1["A23b · A49 accuracy"] --> M3{{"M3 Buddy"}} --> p2["A25–A27 · A28b · A29 · A31<br/>B10b · B11"] --> M4{{"M4 Buddy-first"}}
    M4 --> p3["B12 · A37b · A39b · A41b"] --> M6{{"M6"}}
  end
  subgraph P3["Production"]
    b13["B13 staging<br/>B14 production"] --> a43["A43 Play release"] --> M7{{"M7"}}
    M7 --> fin["B15 eval · B16 security<br/>A32 gap fill"] --> R1{{"R1 done"}}
  end
  M1 --> w1
  M2b --> p1
  M6 --> b13
  w3 -. A38 reached: provision Hetzner .-> b13
```

### 4.3 Chores log

Chores and backlog sweeps that aren't steps (one combined branch, one Codex review, merged as `chore: …`). Details stay in `backlog.md` rows.

**Backlog sweep 1 (2026-10-31)**, branch `chore/backlog-sweep-1`: small non-AI fixes for daily use (TD-105 phase 1).
- Fixed: #66 catalog validation cascade, #70 mistyped `CATALOG_BASE_REF`, #100 Your foods counts unreadable rows, #102 `SaveMeal` rejects NUL, #103 DS icon buttons, #105 saved-meal RTL test, #107 "Go to Today" in the empty Saved meals, #108 "Log to {meal}", #118 halal hint line, #242 "update the app to sync" on a 426.
- Tests only: #221 (part), #224 (app ranker over the real coffee rows).
- Closed as already done or not reproducible: #28, #29, #31 (pinned by A07), #99, #101.
- Assessed and left open: #63 (needs a repair rule in the sync apply path).

## 5. Milestones

| Milestone | Reached when | Exit (the milestone is reached when…) | Server |
|---|---|---|---|
| **M1 Dogfood 1: offline food tracker** | A11 | OF-01 food parts pass. A day of food can be logged by search and quick-add in airplane mode. The owner uses the prod build daily and can export | None needed (the laptop for `/v1/config` only) |
| **M2 Targets & weight** | A16 | Targets property tests pass. The owner's weight-note history is entered and charted | None |
| **M5 Accounts & sync** | A35 (+ B05, B06, B20, B21); phase 1, wave 4 | OF-03 passes against the laptop server. Google sign-in, guest upgrade and account deletion work on the A55 | Laptop |
| **M2b Solid app (no AI)** | Phase 1 (TD-105), in waves: wave 1 A46, A47, A17, A18, A16, A45 · wave 2 B20, A37a, A37c, B21, A19, A30 · wave 3 A50, B10a, A28a, A38 · wave 4 A39a, A40, A41a, A34, A35 · wave 5 A42 | Every non-AI feature of R1 works offline and syncs: food (≈ 600 basics, the dish batches A17–A30, local brands, barcodes), weight, Progress, workouts without a plan or with a starter plan, weekly summary, notifications, Ramadan mode, sign-in (Google too), sync and deletion. A42's speed, accessibility and offline checks pass on the A55. The nightly emulator run is green | Laptop |
| **M3 Buddy on the laptop** | A23b + A49 (the known-miss fixes, backlog #148–#151) + B09b's eval run; phase 2 | T01–T16, T19, T39–T41 meet the AQ thresholds: the B09b `eval` AQ gate is green with an **empty** known-miss baseline (`tools/buddy_eval/cases/aq_known_misses.json`, TD-097). p90 ≤ 5 s measured from the owner's location | Laptop (B03) |
| **M4 Dogfood 2: Buddy-first** | A31 + B09b, A25–A27, A28b, A29 and B10b/B11's eval runs | T17–T29, T33, T36–T38 pass. OF-02 passes. The owner logs mostly through Buddy for a week | Laptop |
| **M6 Workouts, review & Ramadan by Buddy** | A37b, A39b, A41b (+ B12) | J9, J10, J11, T30–T35 pass. Every NT rule has a planner test (from A40/A41a) | Laptop |
| **M7 Production** | B14 + A43 | The restore drill is done. AT-006 passes on production. The app installs from Play. The laptop's data has moved in. Open option (TD-105): ship to Play before phase 2 with Buddy hidden; decided later | Hetzner (B13, B14) |
| **R1 done** | A42, A43 (M7), B15, B16, A32 (AT-003 green across the dish batches, TD-074) | AT-001 to AT-007 met. Every AQ threshold met on ≥ 150 cases. The owner uses it as the only tracker for 2 weeks. SC-1 checked at 4 weeks | Production |

**Emulator tests at milestones (TD-086, TD-104):** the Patrol emulator job runs only nightly on `main` and on manual runs; no `[it]`. A milestone counts as reached once the nightly after its last merge is green.

**Milestone order:** the table is in delivery order (TD-105): M5 and M2b come in phase 1, before the Buddy milestones M3, M4 and M6. The IDs keep their old numbers so history still reads.

**While the laptop is the server:** everything except Buddy, online search, sign-in and sync works with the laptop off (local-first). Online features work whenever the laptop runs the test-server stack + the Tailscale mapping (B03 runbook).

## 6. Cross-track handoffs

The only places one track waits for the other. The contract is the meeting point: a server step commits its contract change first, with a Progress-log line in its card, and the app builds against the generated client.

| From | To | What is handed over |
|---|---|---|
| **B03** laptop test server | A11 | The HTTPS URL the owner's daily build talks to |
| **A05** catalog pipeline | B07 | The catalog release format and server load files |
| **B08** Buddy interpret (contract) | A21 | The interpretation schema the ProposalEngine consumes |
| **B04** identity (contract, then done) | A20, A33 | Anonymous tokens and refresh; sign-in and linking |
| **B08** Buddy interpret | A22 | The interpret endpoint, end to end |
| **A21** ProposalEngine | B09 | The `fb_domain` entry point the eval uses for full AQ metrics |
| **A21** (WP4 codec shape, size budget) | B18 | The compact per-card/message codec the sync entities carry |
| **B18** chat & proposal sync (contract) | A22, A23, A34 | The `chatMessage` and `proposal` entities: built against first, uploaded later |
| **A13a** targets storage (contract), **A14** weigh-ins | B19 | The `profile`, `goalPhase`, `targetSettings` v1 entities and their wire rules; A14's deferred `weighIn` v2 fields |
| **B19** body & targets sync | A34 | Server admission of those entities before the app uploads them |
| **A15b** measurements (contract) | B20 | The `measurementType` and `measurement` v1 entities and their wire rules (`contracts/README.md` § Measurement semantic rules) |
| **B20** measurement sync | A34 | Server admission of the measurement entities before the app uploads them |
| **B07** catalog service | A24 | Online search and pack releases |
| **B09a** intents (contract) | A25, A26, A27 | Edits, memory, batches, personal foods, saved meals |
| **B10a** barcode lookup (contract) | A28a | Barcode lookup (no AI) |
| **B10b** label & vision (contract) | A28b, A29 | Label extraction, photos, import |
| **B11** Q&A & suggestions (contract) | A31 | QueryPlans and suggestions |
| **B05** sync, **B06** deletion | A34, A35 | Push/pull/history; `DELETE /v1/me` |
| **A36** workout tables | B21 | The workout entity shapes (A36 D6) for the sync contract |
| **B21** workout sync | A34 | Server admission of the workout entities before the app uploads them |
| **B12** workouts, review, Ramadan (contract) | A37b, A39b, A41b | The last Buddy intents |
| App track reaches **A38** | B13 | The signal to provision Hetzner (TD-064); the code can be written earlier |
| **A41b**, **A42** | B15, B16 | The finished app for the final eval and security review |
| **B14** production | A43 | The production URL and data for the Play release |

## 7. How to pick the next step

1. Take the **lowest-numbered open step of a track** (rule 4 says which track goes first).
2. If it waits on the other track, run that dependency first; if it waits on an owner input (§3), tell the owner and take the next ready step. Never start a step whose dependencies aren't met.
3. Steps marked 🟨 resume from their card's **Progress log**.
4. **Claude orders both tracks (TD-085):** chosen by the critical path: milestones first, then a step the other track waits on (e.g. B20 and B21 before A34), then the lowest-numbered ready step. The owner can reorder it.
5. **Phases (TD-105):** phase 1 (the solid non-AI app, waves 1–5 in §4.1's Status column, milestone M2b) comes first; no new Buddy/AI work starts before it's done. Then phase 2 (Buddy), then production. Within a wave, pick by rule 4.

Up to three lanes (TD-087: `~/work/fitness_buddy`, `_2`, `_3`), one step branch per lane: start from a clean `git status` on the latest `origin/main`, push the branch at every phase change (`../13-delivery-process.md` §10).

## 8. Old → new IDs (TD-063)

The plan used one sequence `S01–S49` + dish batches `D1–D6` until 2026-10-16. The finished steps keep their IDs. Every other step got a track ID; old `Sxx` IDs are never reused. Finished cards and evidence files still mention old IDs in their history: read them through this table. New IDs: `A` = app, `B` = backend; the dish batches are ordinary app steps (no more `Dn`, which also clashed with spec decision IDs `D-0xx`).

**Look-alikes:** "the A55" is the owner's phone, never a step (the app track skips that number if it ever gets there). Inside a card, plan decisions are `D1…` and plan-review amendments `PA1…` (finished cards used `A1…`, e.g. `S06 A11` is S06's eleventh amendment, not step A11); cite them with their step from anywhere else (`A07 D3`).

| Old | New |
|---|---|
| S05 | B13 |
| S07 | A02 |
| S09 | A01 |
| S10 | B02 |
| S11 | A03 |
| S12 | B01 |
| S13 | A05 |
| S14 | A06 |
| S15 | A07 |
| S16 | A08 |
| S17 | A09 |
| S18 | A10 |
| S19 | A12 |
| S20 | A13 |
| S21 | A14 |
| S22 | A15 |
| S23 | A16 |
| S24 | B04 (real email sender → B14) |
| S25 | A33 (A20 = its anonymous-session part) |
| S26 | B05 |
| S27 | A34 |
| S28 | A35 (export → A11, server → B06) |
| S29 | B14 (Play release → A43) |
| S30 | B07 (app side → A24) |
| S31 | B08 |
| S32 | A21 |
| S33 | A22 |
| S34 | A23 |
| S35 | A25 (server → B09) |
| S36 | A26 (server → B09) |
| S37 | A27 (server → B09) |
| S38 | A28 (server → B10) |
| S39 | A29 (server → B10) |
| S40 | A31 (server → B11) |
| S41 | A36 |
| S42 | A37 (server → B12) |
| S43 | A38 |
| S44 | A39 (server → B12) |
| S45 | A40 |
| S46 | A41 (server → B12) |
| S47 | B15 |
| S48 | A42 |
| S49 | B16 |
| D1 (dish batch) | A04 |
| D2 (dish batch) | A17 |
| D3 (dish batch) | A18 |
| D4 (dish batch) | A19 |
| D5 (dish batch) | A30 |
| D6 (dish batch) | A32 |
