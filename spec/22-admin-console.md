# 22 — Admin console

> Owner-only web console to monitor and control the service (D-099). Not a user-facing web app (D-004 stays). Designs: https://claude.ai/artifact/9JHiZLSwJBR7PYpzWDQAZv

## Rules
- **AD-001** `[R1]` The console never shows user content: no food names, diary entries, chat text, prompts or replies, weights, notes or measurements. Only counts, sizes, timings, error types and pseudonymous account IDs.
- **AD-002** `[R1]` Emails show masked (first letter + domain) and an account can be found by exact email match only; no listing or partial search by email.
- **AD-003** `[R1]` Reachable only on the private network (Tailscale); no public URL. Sign-in with Google against an allow-list of admins.
- **AD-004** `[R1]` Two roles: **viewer** (read everything) and **operator** (also change). R1 has one admin, the owner, as operator.
- **AD-005** `[R1]` Every change is recorded in an append-only audit log: who, when, window, action, before → after, an optional reason. Sign-ins and failed sign-ins too. Entries can't be edited or deleted from the console.
- **AD-006** `[R1]` Config changes are drafts: the console shows the diff and the reach (e.g. "shows 'Update the app' to 7 installs") before publish; every published version can be rolled back in one step.
- **AD-007** `[R1]` Destructive actions (delete an account, revoke all devices, disable an account) need the account ID typed and a sign-in less than 15 minutes old.
- **AD-008** `[R1]` Status shows as icon + word, never colour alone; works at phone width (menu stacks, tables scroll); the app's Ink & Sky look.

## Windows
- **AD-010 Overview** `[R1]`: health of API, database, workers, backups, catalog, Buddy; active installs (1/7/30 days); accounts by type; server errors (24 h); AI spend vs cap; app versions in use; open alerts with a link to the window behind them; links to Grafana and Sentry.
- **AD-011 Accounts** `[R1 read, R2 controls]`: list with type, masked email, created, last seen, app version, devices, document count, storage, sync health, AI uses; filters by type and "sync issues". Detail: summary counts per entity type, devices; controls (B24): revoke one device or all, disable/enable, Buddy daily limit override, delete account (the same deletion as the app, AC-031).
- **AD-012 Remote config & flags** `[R1]`: everything `GET /v1/config` serves (minimum app version = the 426 kill switch, feature flags, client thresholds) plus server-only switches (AI on/off, maintenance message). Draft → diff → publish with a reason → history → roll back.
- **AD-013 Buddy & AI** `[phase 2]`: requests, cost (per day, by model), latency p50/p95, outcomes (proposal, clarify, answer, failed, truncated), confirm rate; last buddy_eval run; monthly cap, per-account daily limit, "pause Buddy for everyone".
- **AD-014 Jobs & sync** `[R1]`: queues (state, pending, running, done, failed, oldest), failed jobs with error type (retry, cancel), pause/resume a queue; sync pushes, pulls, rejects by reason, deferred documents by entity and version.
- **AD-015 Catalog** `[R1]`: releases (version, status, foods, change, size, installs), publish a ready release, roll back to the previous; Open Food Facts lookups (found complete/partial, not found, errors), cached products, sanity flags (B22).
- **AD-016 Audit log** `[R1]`: filter by window, person, time; export CSV.
