# A16 verification (2026-10-30)

- **CI:** the merge run on the squash commit is the test evidence (owner rule: no branch pushes; `merge-step.sh`). Local: `make check-dart` green; `dart analyze` on the app and packages clean after the main merge; touched test files run singly via `heavy.sh` (bar chart, first diary date, day menu, Progress screen + golden) all green.
- **Codex security/data-integrity review (read-only, fresh task):** approve. "Both UI paths use `DiaryActionsController` → `ChangeSetApplier`, with direct-action Undo … A16 introduces no migration or contract change … No new user-content logging or telemetry." One minor (earliest navigable date ignored day marks) fixed in 541dfc3.
- **Codex code + UX review (read-only, fresh task):** request changes: 1 major (macro charts unreadable by screen readers), 2 minors (error states, T12 coverage). Fixed in 541dfc3.
- **Fix-check 1:** items 1, 3, 4 fixed; two minors left (retry reused failed upstream providers; stale semantics labels). Fixed in 91675d8, which also fixed a hanging T11.
- **Fix-check 2:** semantics implementation fixed; its regression test tightened by the orchestrator (description callback changes alone). Retry scope still partial → backlog #220 (minor; cap of two rounds reached, per `PROCESS.md` A4).
- **Exit criteria:** phase filter changes every chart, met (T10, T18); incomplete day distinct, met (T11, golden T13); "how did this week go?" in one tap and charts < 300 ms on the A55 are owner device checks (#219, #213), collected and non-blocking.
