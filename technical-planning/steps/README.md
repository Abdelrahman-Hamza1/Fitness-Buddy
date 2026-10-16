# Steps — How R1 Gets Built

R1 is delivered in **49 steps (S01–S49)** plus **6 data batches (D1–D6)**. Each step is one focused session: **low-level plan → implementation → verification → outcome**. A step is small enough to finish and review, and always ends with something working and merged.

Each step has a **card** in this folder. The card is the session's brief, and later its record.

## 1. Session protocol

Every step session follows these phases. The owner can stop the session at the end of any phase.

> **Who does what:** the main session is the **orchestrator** and runs this protocol with the **`run-step`** skill. It delegates to specialist agents (`.claude/agents/`): `tech-researcher` and `step-planner` + `architect` in Phase B, the engineers per work package in Phase C, the reviewers and `verifier` in Phase D. Owner gates: **plan approval** (end of B) and **step acceptance** (end of E). The full process (roles, decision rights, communication, quality gates) is in **`../13-delivery-process.md`**.

### Phase A: Orient (≈ 10 min)
1. Read this README's **status board** (§4). Confirm the step's dependencies are ✅ and that `main` is green.
2. Read the step card, then the docs in its **Read first** list. Skim the **Outcome** sections of its dependencies, which may have changed assumptions.
3. If the card conflicts with reality (an earlier step deviated), note it and fix the card **before** planning.

### Phase B: Low-level plan (written into the card)
Fill the card's **Low-level plan** section:
- **Design:** types, interfaces, tables/migrations, endpoints (contract diff), screens, and how each "Decide in the low-level plan" item is resolved, with a one-line reason each.
- **File list:** files to create or change.
- **Test list:** each test named with the spec ID it proves.
- **Task order:** a numbered checklist of small, committable tasks.
- **Risks / unknowns** and how the session will handle them.

**The owner reviews the plan** (approve, or comment and adjust) before implementation starts. For S-sized steps a quick skim is enough. Architecture-level choices become a TD entry in `12-decisions-and-questions.md`.

### Phase C: Implement
- Branch `step/Sxx-short-name` from `main`.
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
- Open the PR (title `Sxx: <step name>`, body = the Outcome) and merge once CI is green.

**If the step is bigger than planned:** split it at a natural seam (`Sxxa` done, `Sxxb` new card), close the finished part properly, and update the board.

**If the plan turns out to be wrong:** stop, write down why, propose the change (new TD or spec decision), and adjust later cards before continuing.

## 2. Card template

```markdown
# Sxx — <Title>

| Phase | Depends on | Size | Status |
|---|---|---|---|
| Px <name> | Sxx, Sxx | S / M / L | ⬜ Not started |

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

| Needed by | What | Notes |
|---|---|---|
| **S01** ✅ | GitHub repository (public per TD-042), push via the laptop SSH key | Done 2026-10-12 |
| S05 (start of P3) | **Hetzner Cloud** account + API token. **A domain name** (e.g. from Cloudflare Registrar) with DNS on **Cloudflare**. **Tailscale** account. **Grafana Cloud** and **Sentry** accounts (free tiers) | ≈ €10/mo staging + domain |
| S06 | Android phone (A55) with "install unknown apps" allowed for early APKs | — |
| S07 | ~30 min to review the design gallery and mockups on the phone | — |
| S10 | API keys with spend caps: **Anthropic**, **OpenAI**, **Google AI Studio**. Run one latency script from home (~10 min) | A few dollars total |
| S11 | Barcodes (type them, or photos) of **~30 products from your kitchen**. Skim 5 sample dishes | — |
| S24 | **Google Cloud** project (OAuth client IDs for Google sign-in, free). An **email provider** account + DNS records (SPF/DKIM) for sign-in codes | Free tiers |
| S29 | **Google Play Console** ($25 once). An account at a **second storage provider** for backup copies (e.g. Backblaze B2). Alert contact (email/phone app) | — |
| D1–D6 | Skim each dish batch (≈ 15 min). Name family recipes to use (TQ-08) | — |
| R2 (iOS, D-081) | Apple Developer Program ($99/yr), a Codemagic account | — |

## 4. Status board

**Owner** (TD-059): who plans and implements the step. **Codex** owns `backend/`, `infra/`, the server side of `contracts/`, server CI jobs, deploys and integration steps. **Claude** owns `apps/mobile/`, `packages/`, Dart `tools/`, `data/` and the planning docs. "A + B": A leads the card, B plans and builds its side's work packages in the same card.

Legend: ⬜ not started · 🟦 planning · 🟨 in progress · ✅ done · ⏸ blocked

| ID | Step | Phase | Depends on | Size | Owner | Status |
|---|---|---|---|---|---|---|
| [S01](S01-repo-tooling-ci.md) | Repo, tooling & CI foundation | P0 | — | M | Claude | ✅ |
| [S02](S02-api-contract-pipeline.md) | API contract pipeline | P0 | S01 | M | Claude | ✅ |
| [S03](S03-backend-host.md) | Backend host & HTTP conventions | P0 | S02 | L | Codex | ✅ |
| [S04](S04-backend-persistence.md) | Backend persistence, outbox & jobs | P0 | S03 | M | Codex | ✅ |
| [S05](S05-staging-infrastructure.md) | Staging infrastructure & deploy pipeline | P0 | S04 | L | Codex | ⬜ |
| [S06a](S06-app-shell.md) | App shell: skeleton | P0 | S02 | M | Claude | ✅ |
| [S06b](S06-app-shell.md) | App shell: Android builds & device | P0 | S06a | M | Claude | ✅ |
| [S07](S07-design-system.md) | Design system v0 & key screen mockups | P0 | S06 | L | Claude | ⬜ |
| [S08](S08-domain-primitives.md) | Domain primitives & text normalization | P0 | S01 | M | Claude | ✅ |
| [S09](S09-local-data-foundation.md) | Local data foundation | P0 | S06, S08 | M | Claude | ⬜ |
| [S10](S10-spike-ai-bakeoff.md) | Spike: AI bake-off & eval harness v0 | P0 | S03, S08 | L | Codex | ⬜ |
| [S11](S11-spike-food-data.md) | Spike: food data | P0 | S08 | M | Claude | ⬜ |
| [S12](S12-spike-sync.md) | Spike: sync | P0 | S04, S09 | M | Codex | ⬜ |
| [S13](S13-catalog-pipeline.md) | Catalog pipeline & offline pack v1 | P1 | S11, D1 | M | Claude | ⬜ |
| [S14](S14-diary-domain.md) | Diary domain & storage | P1 | S09 | M | Claude | ⬜ |
| [S15](S15-food-search-add.md) | Food search & add flow | P1 | S07, S13, S14 | M | Claude | ⬜ |
| [S16](S16-today-diary-ui.md) | Today screen & diary UI | P1 | S15 | L | Claude | ⬜ |
| [S17](S17-personal-foods-quick-add.md) | Personal foods, saved meals & quick-add | P1 | S16 | M | Claude | ⬜ |
| [S18](S18-settings-slots.md) | Settings & meal slots | P1 | S16 | M | Claude | ⬜ |
| [S19](S19-targets-engine.md) | Targets engine | P2 | S08, S14 | M | Claude | ⬜ |
| [S20](S20-targets-ui-onboarding.md) | Goals & targets UI, R1 onboarding | P2 | S18, S19 | M | Claude | ⬜ |
| [S21](S21-weigh-ins-trend.md) | Weigh-ins & trend | P2 | S16 | M | Claude | ⬜ |
| [S22](S22-weight-graph-measurements.md) | Weight graph & measurements | P2 | S19, S21 | L | Claude | ⬜ |
| [S23](S23-progress-tab.md) | Progress tab v1 | P2 | S20, S22 | M | Claude | ⬜ |
| [S24](S24-identity-backend.md) | Identity backend | P3 | S05 | L | Codex | ⬜ |
| [S25](S25-sign-in-guest-app.md) | Sign-in & guest mode (app) | P3 | S18, S24 | M | Claude | ⬜ |
| [S26](S26-sync-backend.md) | Sync backend | P3 | S12, S24 | M | Codex | ⬜ |
| [S27](S27-sync-engine-app.md) | Sync engine (app) | P3 | S25, S26 | L | Claude | ⬜ |
| [S28](S28-export-deletion.md) | Export & account deletion | P3 | S27 | M | Claude + Codex | ⬜ |
| [S29](S29-production-dogfood-1.md) | Production environment & Dogfood 1 release | P3 | S27, S28 | L | Codex | ⬜ |
| [S30](S30-catalog-service.md) | Catalog service & online search | P4 | S13, S24 | M | Codex | ⬜ |
| [S31](S31-buddy-interpret-service.md) | Buddy interpret service | P4 | S10, S30 | L | Codex | ⬜ |
| [S32](S32-proposal-engine.md) | ProposalEngine | P4 | S10, S15, S19 | L | Claude | ⬜ |
| [S33](S33-chat-proposal-card.md) | Chat sheet & proposal card | P4 | S16, S31, S32 | L | Claude | ⬜ |
| [S34](S34-message-lifecycle.md) | Message lifecycle, pending & failures | P4 | S33 | M | Claude | ⬜ |
| [S35](S35-diary-edits-by-chat.md) | Diary edits by chat | P5 | S34 | M | Claude + Codex | ⬜ |
| [S36](S36-memory-user-model.md) | Memory & user model | P5 | S34 | M | Claude + Codex | ⬜ |
| [S37](S37-batches-chat-foods.md) | Batches, personal foods & saved meals by chat | P5 | S17, S34 | L | Claude + Codex | ⬜ |
| [S38](S38-barcode-label-scan.md) | Barcode & label scan | P5 | S30, S34 | L | Claude + Codex | ⬜ |
| [S39](S39-photo-body-import.md) | Photo logging, body data by chat & paste import | P5 | S22, S34 | M | Claude + Codex | ⬜ |
| [S40](S40-qa-suggestions-halal.md) | Q&A, suggestions & halal | P5 | S36 | M | Claude + Codex | ⬜ |
| [S41](S41-workout-domain.md) | Workout domain, library & templates | P6 | S13, S14, S19 | M | Claude | ⬜ |
| [S42](S42-workout-logging.md) | Workout logging, history & PRs | P6 | S34, S41 | L | Claude | ⬜ |
| [S43](S43-adaptive-targets.md) | Adaptive targets & weekly check-in | P7 | S23, S34 | M | Claude + Codex | ⬜ |
| [S44](S44-weekly-review.md) | Weekly summary & Buddy review | P7 | S42, S43 | M | Claude + Codex | ⬜ |
| [S45](S45-notifications.md) | Notifications | P7 | S37, S42, S44 | M | Claude | ⬜ |
| [S46](S46-ramadan.md) | Ramadan mode | P7 | S22, S43, S45 | L | Claude + Codex | ⬜ |
| [S47](S47-eval-expansion.md) | AI eval expansion & tuning | P8 | S46 | M | Codex | ⬜ |
| [S48](S48-performance-a11y-offline.md) | Performance, accessibility & offline acceptance | P8 | S46 | M | Claude | ⬜ |
| [S49](S49-security-r1-signoff.md) | Security review, restore drill & R1 sign-off | P8 | S47, S48 | M | Codex + Claude | ⬜ |
| [D1–D6](D-reference-dish-batches.md) | Reference dish batches | P1–P5 | S11 | S each | Claude | ⬜ |

**Suggested order:** S01 → S02 → S08 → S06 → S03 → S04 → S09 → S07 → S11 → D1 → S10 → S12 → **P1 (S13–S18) → P2 (S19–S23)** → **S05** → S24 → … Any order that respects the dependencies works.

**Hetzner is deferred until it's needed** (owner, 2026-10-11): everything up to the end of P2 runs locally (API + Postgres in Docker via `make up`), and the phone uses offline features only. S05 (staging on Hetzner) runs at the start of P3, right before sign-in and sync, which are the first features the phone needs a reachable server for. Spikes S10/S12 use the local API.
