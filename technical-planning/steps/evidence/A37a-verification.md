# A37a verification (2026-10-30)

- **CI:** the group-merge run on the squash commits is the test evidence (TD-108). Local: `make check-dart`, `make catalog-check`, codegen current; every touched test file run singly via `heavy.sh` (controller 25, visit undo 8, op handler 25, screens 3, picker 2, app_tabs 3, app_router 10, app_shell 5, today_screen 6, migration, export, catalog tests), all green.
- **Codex code + UX review:** request changes: 3 majors (failed saves closed the form as success; edit during final flush dropped; clearing a checked set kept old numbers), 2 minors (set removal target; alias errors). D13 deviation (result-returning picker/form pages) judged acceptable.
- **Codex security + data-integrity review:** request changes: 2 majors (conflict on exit discarded the form; failed saves completed the exit), 1 minor (delete-only-while-unused outside the transaction). Migration v10→v11, D25 owned-tombstone revival, compensation and ChangeSetApplier-only writes judged sound; no user-content logging.
- **Fix-check 1 (a7cbf58):** 5 of 7 fixed; 2 new majors (Retry→discard race; re-check during the final delete).
- **Fix-check 2 (cf80150 + main merge 7f6c96b):** 2 new P1s (tab navigation bypassed the visit exit; discard drain loop) and 1 P2 (restore failure stranded the form).
- **Fix-check 3 (753d2fc, focused):** all fixed; no blockers or majors. APPROVE.
- **Exit criteria:** log by picking exercises, last-time numbers, autosave + undo, auto names, Repeat, history, week strip of trained days, Today row after logging, custom exercises with muscles: met by tests (§5). Owner device week of real sessions: optional (D-087).
