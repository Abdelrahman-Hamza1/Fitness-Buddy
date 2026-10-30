import contextlib
import io
import os
import tempfile
import unittest

import progress as p

BOARD = """# Steps

## 4. Status board

### 4.0 Foundation (done, old IDs)

| ID | Step | Owner | Status |
|---|---|---|---|
| [S01](S01-repo.md) | Repo | Claude | ✅ |
| [S06a](S06-shell.md) | Shell a | Claude | ✅ |
| [S06b](S06-shell.md) | Shell b | Claude | ✅ |

### 4.1 App track

| ID | Step | By | Depends on | Size | Was | Milestone | Status |
|---|---|---|---|---|---|---|---|
| [A01](A01-data.md) | Data | Claude | S06 ✅ | M | S09 |  | ✅ |
| [A02](A02-ui.md) | UI | Claude | A01 · soft: **B01** | M | S10 | **M1** |✅ (phone check: backlog #3) |
| [A03](A03-dish.md) | Dish batch | Claude | A01 | S | D1 |  | ⏸ deferred: after A06 |
| [A04a](A04-chat.md) | Chat a | Claude | A02, **B02** (contract) | L | S11 |  | 🟨 |
| [A04b](A04-chat.md) | Chat b | Claude | A04a | M | S11 | **M2** | ⬜ |
| [A05](A05-extra.md) | Extra | Claude | A02 | M | new |  | ⬜ |
| [A06](A06-polish.md) | Polish | Claude | A04, A05 | M | S12 | **R1** | ⬜ |

### 4.2 Backend track

| ID | Step | Depends on | Size | Was | Milestone | Status |
|---|---|---|---|---|---|---|
| [B01](B01-server.md) | Server | S01 ✅ | S | new |  | ✅ |
| [B02](B02-buddy.md) | Buddy | B01 | L | S20 |  | 🟦 |
| [B03](B03-prod.md) | Prod | B02 · code any time; provisioning when **A05** | L | S05 |  | ⬜ |

## 5. Milestones

| Milestone | Reached when | Exit | Server |
|---|---|---|---|
| **M1 First: offline** | A02 | x | None |
| **M2 Second** | A04b + the fixes (backlog #7–#8) | x | Laptop |
| **R1 done** | A06, B03, the dish batches | x | Prod |

## 6. Next
"""

BACKLOG = """# Backlog

| # | From | Item | Severity | Target step | Status |
|---|---|---|---|---|---|
| 3 | A02 | Phone check of the **UI** on the A55 | owner check | owner | open |
| 5 | A02 | A tech-debt thing nobody waits for | minor | A05 | open |
| 6 | A02 | Done owner thing | owner | owner | done (A04a) |
| 7 | A04 | Fix one | major | A04b | open |
| 8 | A04 | Fix two | major | A04b | done (A04a) |
| 9 | A04 | ⚠️ Owner: create the [account](https://example.com) | owner | owner | open |
"""


class ProgressTest(unittest.TestCase):
    def setUp(self):
        self.page = p.render(BOARD, BACKLOG)

    def test_counts_and_bar(self):
        self.assertIn("**3 of 10 steps done** · `▓▓▓░░░░░░░` 30%", self.page)
        self.assertIn("App 2/7 · Backend 1/3 · Foundation 3/3", self.page)

    def test_now_lists_planning_and_building(self):
        self.assertIn("- 🟨 building [A04a](technical-planning/steps/A04-chat.md) Chat a · M2", self.page)
        self.assertIn("- 🟦 planning [B02](technical-planning/steps/B02-buddy.md) Buddy · M2", self.page)

    def test_milestones(self):
        # M1: A02 and its closure (A01, soft B01) are done.
        self.assertIn("| ✅ | **M1** First | `▓▓▓▓▓` 3/3 | — |", self.page)
        # M2: open steps plus the open backlog item the gate cell names (#8 is done).
        self.assertIn("| 🟨 | **M2** Second | `░░░░░` 0/3 | A04a A04b B02 #7 |", self.page)
        # R1: the deferred batch runs "after A06", so it falls past every earlier gate.
        self.assertIn("| ⬜ | **R1** done | `░░░░░` 0/4 | A03 A05 A06 B03 |", self.page)

    def test_next_up_needs_hard_deps_done(self):
        nxt = self.page.split("## Next up")[1].split("## Waiting")[0]
        self.assertIn("[A05]", nxt)  # A02 done
        self.assertNotIn("[A04b]", nxt)  # A04a in progress
        self.assertNotIn("[B03]", nxt)  # B02 not done; A05 after "·" is not a hard dep
        self.assertNotIn("[A03]", nxt)  # deferred

    def test_waiting_on_you(self):
        waiting = self.page.split("## Waiting on you")[1].split("---")[0]
        lines = [line for line in waiting.splitlines() if line.startswith("- ")]
        self.assertEqual(lines, ["- **#9** ⚠️ Owner: create the account", "- **#3** Phone check of the UI on the A55"])

    def test_deterministic(self):
        self.assertEqual(self.page, p.render(BOARD, BACKLOG))

    def test_unknown_status_is_an_error(self):
        with self.assertRaisesRegex(p.BoardError, "A05: status"):
            p.render(BOARD.replace("| new |  | ⬜ |", "| new |  | 🟥 |"), BACKLOG)

    def test_ranges_and_splits(self):
        by_id = {i: {} for i in ("A04a", "A04b", "B10", "B11", "B12")}
        self.assertEqual(p.resolve_ids("A04 and B10–B12, not #10–#12", by_id), ["B10", "B11", "B12", "A04a", "A04b"])

    def test_check_mode(self):
        with tempfile.TemporaryDirectory() as root:
            os.makedirs(os.path.join(root, "technical-planning", "steps"))
            for rel, text in ((p.BOARD, BOARD), (p.BACKLOG, BACKLOG)):
                with open(os.path.join(root, rel), "w", encoding="utf-8") as f:
                    f.write(text)
            err, out = io.StringIO(), io.StringIO()
            with contextlib.redirect_stderr(err), contextlib.redirect_stdout(out):
                self.assertEqual(p.main(["progress.py", root, "--check"]), 1)  # no PROGRESS.md yet
                with open(os.path.join(root, p.OUT), "w", encoding="utf-8") as f:
                    f.write(self.page)
                self.assertEqual(p.main(["progress.py", root, "--check"]), 0)
            self.assertIn("run `make progress`", err.getvalue())


if __name__ == "__main__":
    unittest.main()
