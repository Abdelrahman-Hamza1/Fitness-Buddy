# 01 — Architectural Drivers, Scope & Risks

_What the product spec means for engineering. Everything here traces back to spec IDs._

## 1. Architectural drivers (ranked)

When two technical options compete, the higher driver wins. This mirrors the product principles (PR-1 to PR-12).

| # | Driver | Comes from | What it forces in the design |
|---|---|---|---|
| D1 | **Trustworthy numbers** | SC-3, SC-4, D-011, AI-070–072, AQ-02–05/09/10 | AI never produces nutrition numbers. A deterministic engine on the phone computes everything from food data. Every logged item stores its source and assumptions |
| D2 | **Nothing written without confirmation** | D-079, AI-036, AQ-01 (100%) | One write path (`ChangeSetApplier`) triggered only by user taps. AI responses are data, never commands |
| D3 | **Nothing is lost** | SC-6, AC-010–012, UX-052 | The local DB is the source of truth. Sync to the account. 30-day server history. Messages saved before sending. Tested migrations. **Point-in-time backups with weekly restore tests** |
| D4 | **Offline for everything except AI** | D-007, D-049, AC-020, OF-01–03 | Local-first. An offline food pack. Queued AI messages and barcode lookups |
| D5 | **Fast** | UX-001–007, AQ-12, D-060 | Local reads. No network work at startup. AI latency budget (≤ 5 s p90) with a skeleton UI. Local card recomputation |
| D6 | **Cheap to run** | C-3, D-041, MN-021 | A small model per task. Prompt caching. No AI for repeat logging. Small VMs. One stateful component |
| D7 | **Private** | AC-040–043, D-018, WB-050 | Minimum context to the AI, no identity. No-training providers. No user content in logs. Authorization in the API **plus** RLS |
| D8 | **Evolvable from R1 → R3 and beyond** | D-001, D-042, owner's direction (2026-10-11) | **A versioned API contract that decouples app and backend.** A modular backend. RTL/i18n-ready app. Multi-user from day one. Feature flags. A clear scale path for the servers |
| D9 | **Maintainable by one person** | C-2 | Two languages, each in its natural place (Dart app, C# backend), joined by one generated contract. Few vendors. Boring, well-supported tech. Strong automated tests and enforced architecture rules |

## 2. Scope reality check

| Release | Tagged requirements (after D-080) |
|---|---|
| **R1** | **291** (AI 74 · TG 30 · FD 30 · UX 24 · WO 22 · DY 22 · WB 19 · AC 17 · LC 17 · IN 11 · HM 9 · SF 8 · NT 7 · MN 1) + the 10 notification types in the NT table + UX-001–007 speed targets |
| R2 | 27 |
| R3 | 10 |
| Later | 2 |

**R1 is large for a solo developer**: about 90% of the product. The spec defines R1 as "what the owner needs to replace their current apps", so delivery is cut into steps on two parallel tracks (app `A01–A43`, backend `B01–B16`, TD-063) with usable milestones along the way (Dogfood 1 as an offline tracker at A11, Dogfood 2 with Buddy at A32). The owner starts using the app months before R1 is complete (`11`).

Besides code, there's **a large data workload**: about 120 must-cover dishes and foods with variants and portion words, each reviewed, with EN, AR and Arabizi names (AT-003). It runs as dish-batch steps on the app track (A04, A17–A19, A30, A32, `07` §4).

## 3. Top technical risks

| ID | Risk | Likelihood / impact | Mitigation | Where |
|---|---|---|---|---|
| TR-01 | **AI quality on the owner's Arabic and Arabizi messages** is poor (the AQ-11 parity gate itself is R2, D-080) | Medium / Medium | B02 bake-off with AR/Arabizi cases. Canonical English names from the model for matching. Curated aliases. Eval in CI | `06` §11, B02 |
| TR-02 | **Local food coverage**: West Bank products missing from open barcode DBs, and reference dishes take long to author | High / High | Measure OFF coverage for the region from the OFF data export (A03) and the real hit rate with an on-device counter (A28). Label scan as a first-class path. Claude drafts dishes, the owner skims | `07`, A03, A28, dish batches |
| TR-03 | **Sync bugs → data loss** | Medium / Critical | Simple single-owner LWW protocol. Server history. Convergence simulation tests. Timeboxed spike with PowerSync as plan B. Backups | `05` §5, B01 |
| TR-04 | **Latency** ≤ 5 s p90 from the West Bank to the AI provider | Medium / Medium | Measured in B02. One model call on the hot path. Prompt caching. Low reasoning effort. Optional streaming | `06` §10 |
| TR-05 | **Scope/time overrun** (≈ 300 R1 requirements) | High / High | Small steps with exit criteria. Dogfood milestones. No gold-plating. Traceability shows progress | `11`, `steps/` |
| TR-06 | **Food data licensing** (ODbL share-alike) blocks R3 plans | Low (R1) → Medium (R3) / Medium | OFF data isolated in its own table, attribution, legal check before R3 | `07` §3 |
| TR-07 | **AI provider policy or price changes** | Medium / Medium | `ILlmClient` port. The eval suite makes switching a measured change | `06` §9 |
| TR-08 | **Flutter platform churn** (Material moved to packages, go_router in maintenance) | Low / Low | New packages from day one. Thin wrappers | `02` §1 |
| TR-09 | **Mobile background limits** (offline AI queue, conditional notifications) | Certain / Low | Process on foreground. A planner that schedules ahead and reschedules on every change | `09` §1 |
| TR-10 | **Running our own servers and database** (patching, disk, failed backups) causes an outage or data loss | Medium / High | Infrastructure as code. Kamal rollbacks. Point-in-time backups to two providers. **Automated weekly restore tests**. Alerts on backup age, disk and errors. Runbooks. Fallback: managed Postgres (`02` App. A) | `08`, B13, B14 |
| TR-11 | **Security bugs in our own auth** | Low–Medium / High | Narrow flows (verified Google/Apple tokens, email codes, no passwords). Vetted libraries for JWT and OIDC. Refresh-token reuse detection. RLS as a second wall. Security tests. A dedicated review in B16 | `04` §5, B04, B16 |
| TR-12 | **The laptop period** (TD-064): until A34 + B14 the owner's data lives on the phone (+ manual exports, and from A34 a copy on the laptop); infrastructure risk (TR-10) is retired late | Medium / High | Export with a registry test (A11), release-key backup (A11), a separate laptop stack with nightly dumps (B03), the sync dataset id (TD-066), a rehearsed move-in (B14) | `11` §3, A11, B03, B14 |
| TR-12 | **Contract drift between the Dart app and the C# API** | Medium / Medium | Contract-first OpenAPI, a generated client, server conformance in CI, oasdiff, shared golden test data | `04` §4, S02 |
| TR-13 | **iOS drifts while R1 is Android-only** | Medium / Low | Cross-platform Flutter code and iOS-capable plugins only. No Android-only shortcuts in shared code. iOS enablement is the first R2 item (D-081) | TD-034 |

## 4. Spec gaps and how they're handled

| # | Where | Issue | Handling |
|---|---|---|---|
| G1 | NT-004 / AI-130 | "Weekly review ready" at 09:00, but the narrative needs the network | The numbers part is always ready offline. The narrative is generated on the next online open and cached (TQ-04 ✅) |
| G2 | AI-047 / AC-020 | "Processed automatically when back online" can't run reliably in the background | Processed on the next foreground (TQ-03 ✅) |
| G3 | AC-010 | Do pending proposals sync? | Yes. They're rows like any other. Confirming re-validates against current data (`03` §5) |
| G4 | AC-002 + AI | Guests use Buddy, but the API needs an identity for abuse protection | Anonymous accounts without sync (TQ-05 ✅, `04` §5) |
| G5 | AC-042 | "Not kept longer than needed" vs provider abuse logs | Paid no-training terms for R1/R2, zero data retention before R3 (TQ-06 ✅) |
| G6 | AC-012 | "Latest change wins" by which clock? | HLC with server clamping of future timestamps (`05` §5) |
| G7 | AC-012 | Recovering an overwritten version needs a UI | "Earlier versions" on the item detail (A34) |
| G8 | WB-050 | OS cloud backups would upload photos | Photo files excluded from OS backups (R2) |
| G9 | FD-051 | Who reviews reference dishes? | Claude drafts with sources, CI validates, the owner skims (the dish batches A04, A17–A19, A30, A32; TQ-08) |
| G10 | TG rebalancing | Past daily targets depend on editable history | Past targets are recomputed, not stored |
| G11 | DY-001 vs travel | Day boundaries when travelling | Each entry stores its own `local_date` and offset |
| G12 | LC-033 | Prayer calculation method for Palestine isn't specified | A setting with a regional default, checked against a local timetable in A41 |
| G13 | AT-004 | "Mid-range Android phone" | Samsung A55 (TQ-02 ✅) |
| G14 | C-1, AC-001, AT-004 | iOS in R1 while the owner is on Android with no Mac | Resolved: Android-only R1, iOS in R2 (spec D-081, TD-034) |
| G15 | AI-080–084 | The owner wants Buddy to build a "mental model" of each user (TQ-07) | A structured, visible user model (TD-032, `06` §5). No spec change needed: it implements AI-080–084 more fully |
