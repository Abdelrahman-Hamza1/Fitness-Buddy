"""PROGRESS.md: the owner's progress page, generated from the step board.

Reads technical-planning/steps/README.md (§4 status board, §5 milestones) and
technical-planning/steps/backlog.md, and prints PROGRESS.md (plain Markdown,
phone-first, deterministic: no clock, no environment).

Usage (from the Makefile):
  python3 -I progress.py <repo-root>            print the page to stdout
  python3 -I progress.py <repo-root> --check    exit 1 if PROGRESS.md differs

Stdlib only. A board it can't read (a status without a known emoji, a missing
table) is an error, so a format change shows up in CI instead of a wrong page.
"""

import os
import re
import sys

PROG = "progress"
BOARD = "technical-planning/steps/README.md"
BACKLOG = "technical-planning/steps/backlog.md"
OUT = "PROGRESS.md"

# Board legend: ⬜ not started · 🟦 planning · 🟨 in progress · ✅ done · ⏸ blocked
STATUSES = {"✅": "done", "🟨": "doing", "🟦": "planning", "⏸": "blocked", "⬜": "todo"}
ID = r"[ABS]\d{2}[a-z]?"
ID_RE = re.compile(r"(?<![#\w])(" + ID + r")(?![\w])")
RANGE_RE = re.compile(r"(?<![#\w])([AB])(\d{2})[a-z]?\s*[–-]\s*\1?(\d{2})[a-z]?(?![\w])")
ISSUE_RANGE_RE = re.compile(r"#(\d+)(?:\s*[–-]\s*#?(\d+))?")
LINK_RE = re.compile(r"\[([^\]]*)\]\(([^)]*)\)")

MAX_OWNER_ITEMS = 10
MAX_NEXT = 5
MAX_OPEN_IDS = 6


class BoardError(Exception):
    pass


# --- Parsing -------------------------------------------------------------------


def cells(line):
    """Cells of a Markdown table row (no escaped pipes in these tables)."""
    return [c.strip() for c in line.strip().strip("|").split("|")]


def section(text, start_re, end_re):
    m = re.search(start_re, text, re.M)
    if not m:
        raise BoardError(f"heading not found: {start_re}")
    rest = text[m.end():]
    e = re.search(end_re, rest, re.M)
    return rest[: e.start()] if e else rest


def tables(text):
    """Yield (header, rows) for every Markdown table in text."""
    lines = text.splitlines()
    i = 0
    while i < len(lines):
        if lines[i].startswith("|") and i + 1 < len(lines) and re.match(r"^\|[\s:|-]+\|$", lines[i + 1].strip()):
            header = cells(lines[i])
            rows = []
            i += 2
            while i < len(lines) and lines[i].startswith("|"):
                rows.append(cells(lines[i]))
                i += 1
            yield header, rows
        else:
            i += 1


def plain(md):
    """Markdown cell → plain text (links to their text, no bold or code marks)."""
    s = LINK_RE.sub(r"\1", md)
    s = s.replace("**", "").replace("`", "").replace("~~", "")
    return re.sub(r"\s+", " ", s).strip()


def status_of(cell, step_id):
    s = cell.strip()
    for emoji, name in STATUSES.items():
        if s.startswith(emoji):
            return name
    raise BoardError(f"step {step_id}: status {cell!r} starts with none of {' '.join(STATUSES)} (board legend)")


def parse_board(text):
    """Steps in board order: dicts with id, name, link, track, deps, status, note."""
    board = section(text, r"^## 4\. ", r"^## 5\. ")
    steps = []
    tracks = {"4.0": "foundation", "4.1": "app", "4.2": "backend"}
    for num, track in tracks.items():
        sub = section(board, r"^### " + re.escape(num) + r" ", r"^###? ")
        found = list(tables(sub))
        if not found:
            raise BoardError(f"§{num}: no table")
        header, rows = found[0]
        col = {h: k for k, h in enumerate(header)}
        for need in ("ID", "Step", "Status"):
            if need not in col:
                raise BoardError(f"§{num}: no {need!r} column in {header}")
        for r in rows:
            if len(r) != len(header):
                raise BoardError(f"§{num}: row has {len(r)} cells, header {len(header)}: {r[0]}")
            m = LINK_RE.fullmatch(r[col["ID"]].replace("~~", "").strip())
            step_id = plain(r[col["ID"]])
            if not re.fullmatch(ID, step_id):
                raise BoardError(f"§{num}: bad step ID {r[col['ID']]!r}")
            status_cell = r[col["Status"]]
            steps.append(
                {
                    "id": step_id,
                    "name": plain(r[col["Step"]]),
                    "link": m.group(2) if m else None,
                    "track": track,
                    "deps_cell": plain(r[col["Depends on"]]) if "Depends on" in col else "",
                    "milestone_cell": plain(r[col["Milestone"]]) if "Milestone" in col else "",
                    "status": status_of(plain(status_cell), step_id),
                    "note": plain(status_cell)[1:].lstrip("️ ").strip(),
                }
            )
    seen = set()
    for s in steps:
        if s["id"] in seen:
            raise BoardError(f"step {s['id']} appears twice on the board")
        seen.add(s["id"])
    return steps


def parse_milestones(text):
    """§5 rows in order: dicts with id, name, gates (raw cell), issues."""
    sec = section(text, r"^## 5\. ", r"^## ")
    for header, rows in tables(sec):
        if header and header[0] == "Milestone":
            out = []
            for r in rows:
                name = plain(r[0])
                m = re.match(r"^([MR]\d+)\s*(.*)$", name)
                if not m:
                    raise BoardError(f"§5: milestone name {r[0]!r} doesn't start with M<n>/R<n>")
                issues = []
                for a, b in ISSUE_RANGE_RE.findall(r[1]):
                    issues.extend(range(int(a), int(b or a) + 1))
                out.append({"id": m.group(1), "name": m.group(2), "gates_cell": plain(r[1]), "issues": issues})
            if not out:
                raise BoardError("§5: milestone table is empty")
            return out
    raise BoardError("§5: no table with a 'Milestone' column")


def parse_backlog(text):
    """Backlog rows: dicts with num, item, severity, target, status."""
    for header, rows in tables(text):
        if header[:1] == ["#"]:
            col = {h: k for k, h in enumerate(header)}
            for need in ("Item", "Severity", "Target step", "Status"):
                if need not in col:
                    raise BoardError(f"backlog: no {need!r} column in {header}")
            out = []
            for r in rows:
                if len(r) < len(header) or not r[0].isdigit():
                    raise BoardError(f"backlog: bad row {r[:2]}")
                out.append(
                    {
                        "num": int(r[0]),
                        "item": r[col["Item"]],
                        "severity": plain(r[col["Severity"]]),
                        "target": plain(r[col["Target step"]]),
                        "status": plain(r[col["Status"]]),
                    }
                )
            return out
    raise BoardError("backlog: no table with a '#' column")


# --- Derivation ----------------------------------------------------------------


def num_of(step_id):
    return int(step_id[1:3])


def resolve_ids(text, by_id):
    """Step IDs named in free text, in order, deduplicated. "A15" means every
    split (A15a, A15b) when only those are on the board; "B10–B12" is a range."""
    out = []

    def add(i):
        if i in by_id:
            hits = [i]
        else:
            hits = [k for k in by_id if re.fullmatch(re.escape(i) + r"[a-z]", k)]
        for h in hits:
            if h not in out:
                out.append(h)

    for track, lo, hi in RANGE_RE.findall(text):
        for n in range(int(lo), int(hi) + 1):
            add(f"{track}{n:02d}")
    for i in ID_RE.findall(RANGE_RE.sub(" ", text)):
        add(i)
    return out


def hard_deps(step, by_id):
    """Dependencies before the first '·' ("soft: …", "code any time; …" follow it)."""
    return [d for d in resolve_ids(step["deps_cell"].split("·")[0], by_id) if d != step["id"]]


def closure(ids, deps):
    seen, todo = set(), list(ids)
    while todo:
        i = todo.pop()
        if i not in seen:
            seen.add(i)
            todo.extend(deps.get(i, []))
    return seen


def all_deps(step, by_id):
    """Every step the Depends-on cell names, soft ones included."""
    return [d for d in resolve_ids(step["deps_cell"], by_id) if d != step["id"]]


def assign_milestones(steps, milestones):
    """Each app/backend step belongs to the first milestone (§5 order) that needs it:
    a gate step of the milestone or a transitive dependency (soft ones too) of one.
    A step no gate needs goes to the milestone of the next gate below it in its own
    board table (or below the step its status says it runs "after"), else the last.
    Returns (milestone index per step, hard dependencies per step)."""
    by_id = {s["id"]: s for s in steps}
    deps = {s["id"]: all_deps(s, by_id) for s in steps}
    for m in milestones:
        m["gates"] = resolve_ids(m["gates_cell"], by_id)
    owner = {}
    for idx, m in enumerate(milestones):
        for i in closure(m["gates"], deps):
            owner.setdefault(i, idx)
    row = {s["id"]: k for k, s in enumerate(steps)}
    gate_rows = sorted((row[g], idx) for idx, m in enumerate(milestones) for g in m["gates"])
    for s in steps:
        if s["track"] == "foundation" or s["id"] in owner:
            continue
        pos = row[s["id"]]
        after = re.search(r"\bafter (" + ID + r")\b", s["note"])
        if after and after.group(1) in row:
            pos = row[after.group(1)]
        later = [idx for r, idx in gate_rows if r > pos and steps[r]["track"] == s["track"]]
        owner[s["id"]] = later[0] if later else len(milestones) - 1
    return owner, {s["id"]: hard_deps(s, by_id) for s in steps}


def bar(done, total, width):
    filled = (done * width) // total if total else 0
    return "▓" * filled + "░" * (width - filled)


def pct(done, total):
    return (100 * done) // total if total else 0


def short(text, limit):
    if len(text) <= limit:
        return text
    cut = text[: limit - 1]
    if " " in cut[limit // 2:]:
        cut = cut[: cut.rfind(" ")]
    return cut.rstrip(" ,;:.(—-") + "…"


def is_open(status):
    return not re.match(r"(done|closed)\b", status, re.I)


def owner_items(backlog):
    """Open backlog rows the owner has to act on: "owner" in severity or target."""
    def owner_named(b):
        meta = "owner" in b["severity"].lower() or "owner" in b["target"].lower()
        item = b["item"]
        # Owner actions sometimes live only in the item text ("Owner question…", "owner clicks…").
        lead = re.match(r"\W*owner\b", item, re.I)
        action = re.search(r"\bowner (clicks|question|check|action|decision|answer)", item, re.I)
        return meta or bool(lead or action)

    items = [b for b in backlog if is_open(b["status"]) and owner_named(b)]

    def rank(b):
        flagged = "⚠" in b["item"]
        sev = b["severity"].lower()
        kind = 0 if flagged else 1 if sev == "owner" else 2 if sev == "major" else 3 if "owner" in sev else 4
        return (kind, -b["num"])

    return sorted(items, key=rank)


# --- Rendering -----------------------------------------------------------------


def step_link(s, steps_dir):
    return f"[{s['id']}]({steps_dir}/{s['link']})" if s["link"] else s["id"]


def render(board_text, backlog_text):
    steps = parse_board(board_text)
    milestones = parse_milestones(board_text)
    backlog = parse_backlog(backlog_text)
    owner, deps = assign_milestones(steps, milestones)
    by_id = {s["id"]: s for s in steps}
    steps_dir = os.path.dirname(BOARD)
    work = [s for s in steps if s["track"] != "foundation"]
    done = lambda ss: sum(1 for s in ss if s["status"] == "done")  # noqa: E731
    app = [s for s in work if s["track"] == "app"]
    back = [s for s in work if s["track"] == "backend"]
    found = [s for s in steps if s["track"] == "foundation"]
    open_issues = {b["num"] for b in backlog if is_open(b["status"])}

    out = ["# Fitness Buddy: progress", ""]
    d, t = done(work), len(work)
    out.append(f"**{d} of {t} steps done** · `{bar(d, t, 10)}` {pct(d, t)}%")
    out.append("")
    out.append(f"App {done(app)}/{len(app)} · Backend {done(back)}/{len(back)} · Foundation {done(found)}/{len(found)}")
    out.append("")

    # Now
    out += ["## Now", ""]
    now = [s for s in work if s["status"] in ("doing", "planning")]
    if now:
        for s in now:
            phase = "🟨 building" if s["status"] == "doing" else "🟦 planning"
            out.append(f"- {phase} {step_link(s, steps_dir)} {s['name']} · {milestones[owner[s['id']]]['id']}")
    else:
        out.append("- Nothing marked in progress on the board.")
    out.append("")

    # Milestones
    out += ["## Milestones", "", "| | Milestone | Done | Open |", "|---|---|---|---|"]
    for idx, m in enumerate(milestones):
        mine = [s for s in work if owner[s["id"]] == idx]
        md, mt = done(mine), len(mine)
        gates_done = all(by_id[g]["status"] == "done" for g in m["gates"])
        pending_issues = [n for n in m["issues"] if n in open_issues]
        if md == mt and gates_done and not pending_issues:
            mark = "✅"
        elif any(s["status"] != "todo" and s["status"] != "blocked" for s in mine):
            mark = "🟨"
        else:
            mark = "⬜"
        open_ids = [s["id"] for s in mine if s["status"] != "done"]
        open_ids += [g for g in m["gates"] if by_id[g]["status"] != "done" and g not in open_ids]
        shown = open_ids[:MAX_OPEN_IDS] + ([f"+{len(open_ids) - MAX_OPEN_IDS}"] if len(open_ids) > MAX_OPEN_IDS else [])
        shown += [f"#{n}" for n in pending_issues]
        name = short(m["name"].split(":")[0], 22)
        out.append(f"| {mark} | **{m['id']}** {name} | `{bar(md, mt, 5)}` {md}/{mt} | {' '.join(shown) or '—'} |")
    out.append("")
    out.append("✅ reached · 🟨 in progress · ⬜ ahead. Each step counts toward the first milestone that needs it.")
    out.append("")

    # Next up
    ready = [
        s
        for s in work
        if s["status"] == "todo" and all(by_id[x]["status"] == "done" for x in deps[s["id"]])
    ]
    ready.sort(key=lambda s: (owner[s["id"]], s["track"] != "app", num_of(s["id"]), s["id"]))
    out += ["## Next up", ""]
    if ready:
        out.append("Not started, every dependency done; earliest milestone first:")
        out.append("")
        for s in ready[:MAX_NEXT]:
            out.append(f"- {step_link(s, steps_dir)} {s['name']} · {milestones[owner[s['id']]]['id']}")
    else:
        out.append("- No step is ready: every open step waits on another.")
    out.append("")

    # Waiting on you
    items = owner_items(backlog)
    out += ["## Waiting on you", ""]
    if items:
        for b in items[:MAX_OWNER_ITEMS]:
            out.append(f"- **#{b['num']}** {short(plain(b['item']), 90)}")
        if len(items) > MAX_OWNER_ITEMS:
            out.append(f"- …and {len(items) - MAX_OWNER_ITEMS} more owner items in the [backlog]({BACKLOG})")
    else:
        out.append("- Nothing open for you in the backlog.")
    out.append("")

    out += [
        "---",
        "",
        f"[Status board]({BOARD}#4-status-board) · [Milestones]({BOARD}#5-milestones) · [Backlog]({BACKLOG}) · "
        "[Tech decisions](technical-planning/12-decisions-and-questions.md) · [Product decisions](spec/decisions.md)",
        "",
        "_Generated by `make progress` from technical-planning/steps — don't edit by hand._",
    ]
    return "\n".join(out) + "\n"


def main(argv):
    if len(argv) not in (2, 3) or (len(argv) == 3 and argv[2] != "--check"):
        print(f"usage: {PROG}.py <repo-root> [--check]", file=sys.stderr)
        return 2
    root = argv[1]
    try:
        with open(os.path.join(root, BOARD), encoding="utf-8") as f:
            board = f.read()
        with open(os.path.join(root, BACKLOG), encoding="utf-8") as f:
            backlog = f.read()
        page = render(board, backlog)
    except (OSError, BoardError) as e:
        print(f"{PROG}: error: {e}", file=sys.stderr)
        return 1
    if len(argv) == 3:
        try:
            with open(os.path.join(root, OUT), encoding="utf-8") as f:
                current = f.read()
        except OSError:
            current = None
        if current != page:
            print(
                f"{PROG}: error: {OUT} is out of date with {BOARD} / {BACKLOG}: run `make progress` and commit {OUT}",
                file=sys.stderr,
            )
            return 1
        print(f"{PROG}: {OUT} is up to date")
        return 0
    sys.stdout.write(page)
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
