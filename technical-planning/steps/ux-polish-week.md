# UX polish week (A57–A61): from the Codex UI/UX audit

Source: [`../ux-audit-2026-10-31.md`](../ux-audit-2026-10-31.md), a deep Codex audit of main a78b6d6, run 2026-10-31 at the owner's request. It lists 80 action items (42 P1, 38 P2) with file:line, the fix and the effort. P1 items are committed scope; related P2 items are stretch.

The owner's priorities (verbatim, 2026-10-31):
- "I HATE when sizes change based on input."
- "Places for animations or transitions … when you minimize or maximize a meal's info, it's sudden."
- "Food names, some places still mix Arabic and English."

| Step | Work package | Audit items | Acceptance evidence |
|---|---|---|---|
| A57 | Stable logging and editing | A01–A08, A15, A65, A79 | Type, clear and replace values repeatedly. No field, footer or numeric-column moves at 1×, 1.3× or 2×, including digit-count boundaries and validation failures. |
| A58 | Food names everywhere | A30–A40 | Take the same food through search → log → diary → edit → Buddy → saved meal → barcode → feedback, in all four settings. Include missing Arabic names and mixed-script punctuation. |
| A59 | Recovery and unfinished work | A41–A49, A62–A64, A66–A71 | Inject provider errors, dismiss and reopen Buddy, return from barcode creation, retry. No false-empty screens, trapped loaders or lost drafts. |
| A60 | Consistent motion | A09–A14, A16–A29, A80 | One motion vocabulary (`FbMotion`, 200 ms local / 300 ms structural, M3 easing). Controls stay anchored, scroll position holds, and durations are zero under reduced motion. |
| A61 | Accessible charts and dense screens | A50–A61, A72–A78 | TalkBack pass; narrow-phone and 2× text screenshots; composited contrast checks; long-list profiling. |

How to run: one step at a time, or two lanes when the files don't overlap (A58 and A60 touch many shared widgets, so run them apart). Each step's agent reads the audit items it owns, writes a short plan into this card under its own heading, builds, and gets one review. The owner picks the models per step.

## Progress log
- 2026-10-31: card and board rows written from the audit (orchestrator).
