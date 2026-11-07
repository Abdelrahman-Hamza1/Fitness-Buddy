# A67 security verification (Buddy records by chat, app)

- **Review:** Codex security + privacy + data-integrity task, 2026-11-07. Verdict: changes requested, 2 majors, 1 minor.
- **Majors:** batch remainder not protected against concurrent portions; memory confirmation could overwrite a newer value or revive a deleted item. Minor: a re-planned card stayed in "confirming".
- **Fixes:** 45e3009a (consumption IDs/versions pinned and checked in the confirm transaction), d4364d1e (expected version/absence enforced for memory card saves), 9d2fe80b (re-planned card opens with "changed meanwhile").
- **Fix-check:** Codex, 2026-11-07: all resolved, no new blockers or majors.
- **Checked clean:** foreign/missing IDs from the server, cross-kind replacements, learned-habit writes inside the food confirm, memory disclosure caps and nudge exclusion, memoryItem sync mapping, no added logging.
