#!/usr/bin/env python3
"""Gate deterministic endpoint regressions and B09b's engine-level AQ metrics; fixture replay is never model quality.

Usage: check-buddy-eval.py [--selftest] <report.json> [<report.json> ...]
Run from the repo root. Interpretation reports (B08-offline.json, B09-offline.json) name their case file (m3 = B08's M3
set, b09 = B09a's intents); the b09 per-case check sets come from tools/buddy_eval/cases/b09.yaml. AQ reports
(`kind: aq`, B09b-aq-m3.json, B09b-aq-b09.json) are gated with the spec/40 §2 thresholds below and the shrink-only
known-miss baseline tools/buddy_eval/cases/aq_known_misses.json (B09b PA19).

Every failure across all reports is collected, then printed as GitHub `::error` annotations (one per failing metric or
check group, because a step shows at most 10) naming case IDs, item indexes, metric names and closed reason codes, never
message content. `--selftest` runs first: built-in failing AQ reports must fail the gate.
"""
import json
import sys
from pathlib import Path

BASE = {"intents", "language", "script", "provenance"}
M3_CHECKS = BASE | {"foods", "amounts", "states", "dimensions", "hints", "weighIns", "shares", "explicit", "itemDimensions", "dimensionOptions"}
REQUIRED = {
    "m3": {f"T{n:02}" for n in range(1, 17)} | {"T19", "T39", "T40", "T41"},
    "b09": {"T03", "DY-045"} | {f"T{n}" for n in range(20, 30)},
}


# Per-kind floor: the fields every expected intent of that kind must grade (the ID-bearing and decision fields), so a case
# can't silently stop checking them. Cases may grade more (per-case sets), never less.
FLOOR = {
    "diaryEdit": {"targets"},
    "diaryDelete": {"targets"},
    "ambiguousReference": {"candidates", "operation"},
    "batchPortion": {"batchId"},
    "batchClose": {"batchId"},
    "savedMealLog": {"savedMealId"},
    "savedMealCreate": {"activeProposal", "targets", "source"},
    "personalFoodCreate": {"stated", "components"},
    "memoryChange": {"operation", "memoryKind"},
}

# B09b D22: the only copy of the spec/40 §2 thresholds, in percent of the overall eligible units (per-language values are
# reported only, AQ-11). AQ-08 "0 cases" = every case passes. Integer comparison passed*100 >= t*eligible: no rounding up.
AQ_THRESHOLDS = {"AQ-02": 95, "AQ-03": 98, "AQ-04": 95, "AQ-06": 90, "AQ-07": 90, "AQ-08": 100, "AQ-10": 100}
AQ_LANGUAGES = ("en", "ar", "arabizi")
# D25: the b09 AQ subset must contain these; eligibility itself is the plain-case rule below.
AQ_D25 = {"T03", "T24", "DY-045", "AR-E-food-yesterday"}
AQ_ASKS = {"state", "fat", "variant", "portion", "oilRetention", "share", "clarify"}
AQ_PLAIN_KINDS = {"foodLog", "weighIn", "clarify"}
AQ_CLASSES = {"authoring", "data", "resolver", "tooling", "policy", "interpretation"}
BASELINE = Path("tools/buddy_eval/cases/aq_known_misses.json")
NAMED = 8  # misses named per annotation before "+N more"


class Gate:
    """Collects failures; nothing is printed until the end, so every report is checked."""

    def __init__(self):
        self.errors, self.warnings, self.notices, self.lines = [], [], [], []

    def error(self, title, message):
        self.errors.append((title, message))

    def require(self, condition, title, message):
        if not condition:
            self.error(title, message)
        return condition

    def emit(self):
        def prop(text):
            return str(text).replace("%", "%25").replace("\r", "%0D").replace("\n", "%0A").replace(":", "%3A").replace(",", "%2C")

        def data(text):
            return str(text).replace("%", "%25").replace("\r", "%0D").replace("\n", "%0A")

        for line in self.lines:
            print(line)
        for title, message in self.notices:
            print(f"::notice title={prop(title)}::{data(message)}")
        for title, message in self.warnings:
            print(f"::warning title={prop(title)}::{data(message)}")
        for title, message in self.errors:
            print(f"::error title={prop(title)}::{data(message)}")


def named(items):
    items = list(items)
    if not items:
        return "none"
    head = ", ".join(items[:NAMED])
    return head + (f", +{len(items) - NAMED} more" if len(items) > NAMED else "")


def load_cases(case_file):
    return json.loads(Path(f"tools/buddy_eval/cases/{case_file}.yaml").read_text(encoding="utf-8"))["cases"]


def b09_checks(gate):
    """Per case: the base checks plus one check per expected top-level field (targets, candidates, patch, batchId, ...)."""
    cases = load_cases("b09")
    for case in cases:
        for intent in case["expected"]["intents"]:
            missing = FLOOR.get(intent["kind"], set()) - set(intent)
            gate.require(not missing, "eval b09 floor", f"{case['id']}: a {intent['kind']} expectation must grade {sorted(missing)}")
    return {c["id"]: BASE | {k for i in c["expected"]["intents"] for k in i if k != "kind"} for c in cases}


def check_interpretation(path, report, gate):
    case_file = report.get("caseFile", "m3")
    title = f"eval {case_file}"
    if not gate.require(case_file in REQUIRED, title, f"{path}: unknown case file"):
        return
    rows = report["rows"]
    ids = [row["id"] for row in rows]
    gate.require(report["mode"] == "fixture", title, "CI must use offline fixtures")
    gate.require(REQUIRED[case_file] <= set(ids) and len(ids) == len(set(ids)), title, f"Missing/duplicate {case_file} cases: {named(sorted(REQUIRED[case_file] - set(ids)))}")
    expected = b09_checks(gate) if case_file == "b09" else {row["id"]: M3_CHECKS for row in rows}
    if case_file == "b09":
        gate.require(set(ids) == set(expected), title, "The b09 report must run every case in the case file")
    sets, failed = [], []
    for row in rows:
        if set(row["checks"]) != expected.get(row["id"]):
            sets.append(row["id"])
        if not (all(isinstance(v, bool) for v in row["checks"].values()) and row["passed"] and row["status"] == 200 and all(row["checks"].values())):
            failed.append(f"{row['id']}:" + "+".join(sorted(k for k, v in row["checks"].items() if v is not True)) if row["status"] == 200 else f"{row['id']}:http{row['status']}")
    gate.require(report["cases"] == len(rows) == report["passed"] and not failed, f"{title} {report['passed']}/{report['cases']}", f"Regression failed: {named(failed)}")
    gate.require(not sets, title, f"Unexpected check sets: {named(sets)}")
    gate.require(sum(row["script"] in ("arabic", "arabizi") for row in rows) * 4 >= len(rows), title, "Arabic/Arabizi below a quarter")
    groups = report["byLanguage"]
    if gate.require(set(groups) == {"en", "ar", "arabizi"}, title, "Breakdown keys must be en, ar and arabizi"):
        breakdown = ", ".join(f"{key} {groups[key]['passed']}/{groups[key]['cases']}" for key in AQ_LANGUAGES)
        gate.lines.append(f"Buddy {case_file}: {report['passed']}/{len(rows)} offline parse/resolution regressions passed ({breakdown})")


def plain(case):
    """D25 eligibility for b09: expected and parsed intents only foodLog/weighIn/clarify, no active card or proposal."""
    return (all(i["kind"] in AQ_PLAIN_KINDS for i in case["expected"]["intents"])
            and all(i["kind"] in AQ_PLAIN_KINDS for i in case["parsed"]["intents"])
            and not (case.get("context") or {}).get("activeCard") and case.get("activeProposal") is None)


def rate(counts):
    return "n/a" if counts["eligible"] == 0 else f"{counts['passed']}/{counts['eligible']}"


def load_baseline(gate):
    if not BASELINE.exists():
        gate.error("AQ baseline", f"{BASELINE} is missing (start it with an empty entries list)")
        return []
    entries = json.loads(BASELINE.read_text(encoding="utf-8")).get("entries")
    if not gate.require(isinstance(entries, list), "AQ baseline", "entries must be a list"):
        return []
    keys = set()
    for entry in entries:
        key = (entry.get("report"), entry.get("metric"), entry.get("unit"), entry.get("code"))
        gate.require(entry.get("report") in ("m3", "b09") and entry.get("metric") in AQ_THRESHOLDS and entry.get("class") in AQ_CLASSES
                     and isinstance(entry.get("unit"), str) and isinstance(entry.get("code"), str) and isinstance(entry.get("fixingStep"), str),
                     "AQ baseline", f"Malformed entry {entry.get('report')} {entry.get('metric')} {entry.get('unit')}")
        gate.require(key not in keys, "AQ baseline", f"Duplicate entry {' '.join(map(str, key))}")
        keys.add(key)
    return entries


def aq_eligible(cases):
    """Case-defined eligible units per metric (D21/D25: eligibility comes from the aq blocks, never from the outcome).
    AQ-10 counts produced lines (estimate/reference sources, assumed amounts), so it can't be derived: None."""
    blocks = [c["aq"] for c in cases if "aq" in c]
    items = [i for b in blocks for i in b.get("items") or []]
    return {
        "AQ-02": len(items),
        "AQ-03": sum("amount" in i for i in items),
        "AQ-04": sum("weighed" in i for i in items),
        "AQ-06": sum(b.get("ambiguous") is True for b in blocks),
        "AQ-07": sum(b.get("ambiguous") is False for b in blocks),
        "AQ-08": len(blocks),
        "AQ-10": None,
        "components": sum(len(b.get("components") or []) for b in blocks),
    }


def count_problem(block, expected):
    """None when the block's counts are self-consistent and match the case file; else a content-free reason."""
    def valid(counts):
        return (isinstance(counts, dict) and all(isinstance(counts.get(k), int) and not isinstance(counts.get(k), bool) for k in ("passed", "eligible"))
                and 0 <= counts["passed"] <= counts["eligible"])
    if not all(valid(block.get(group)) for group in ("overall", *AQ_LANGUAGES)):
        return "counts must be integers with 0 <= passed <= eligible"
    overall = block["overall"]
    if expected is not None and overall["eligible"] != expected:
        return f"eligible {overall['eligible']} differs from the {expected} units the case file defines"
    if any(sum(block[group][key] for group in AQ_LANGUAGES) != overall[key] for key in ("passed", "eligible")):
        return "the en/ar/arabizi counts don't sum to the overall"
    misses = block.get("misses")
    if not isinstance(misses, list) or len(set(misses)) != len(misses) or len(misses) != overall["eligible"] - overall["passed"]:
        return f"misses must be unique and number eligible - passed ({overall['eligible'] - overall['passed']})"
    return None


def check_aq(path, report, gate, baseline, cases=None):
    case_file = report.get("caseFile")
    title = f"AQ {case_file}"
    if not gate.require(case_file in ("m3", "b09"), "AQ report", f"{path}: unknown case file"):
        return
    gate.require(report.get("mode") == "fixture", title, "CI must use offline fixtures")
    cases = load_cases(case_file) if cases is None else cases
    declared = []
    for case in cases:
        eligible = case_file == "m3" or plain(case)
        if not gate.require("aq" in case or not eligible, title, f"{case['id']}: an AQ-eligible case needs an aq block"):
            continue
        if "aq" not in case:
            continue
        gate.require(eligible, title, f"{case['id']}: only plain foodLog/weighIn/clarify b09 cases carry an aq block (D25)")
        aq = case["aq"]
        declared.append(case["id"])
        if not gate.require("ambiguous" in aq and aq["ambiguous"] in (True, False, None), title, f"{case['id']}: aq.ambiguous must be explicit (true/false/null)"):
            continue
        asks = aq.get("asks") or []
        if aq["ambiguous"] is True:
            gate.require(asks and set(asks) <= AQ_ASKS, title, f"{case['id']}: an ambiguous case lists asks from the closed vocabulary (PA17)")
            gate.require(not aq.get("savedDefaults"), title, f"{case['id']}: an ambiguous case has no saved defaults (AQ-06)")
        else:
            gate.require(not asks, title, f"{case['id']}: only ambiguous cases list asks")
    if case_file == "b09":
        gate.require(AQ_D25 <= set(declared), title, f"The b09 AQ subset misses D25 cases: {named(sorted(AQ_D25 - set(declared)))}")
    rows = report.get("rows", [])
    ids = [row["id"] for row in rows]
    gate.require(len(ids) == len(set(ids)) and set(ids) == set(declared), title,
                 f"Report rows must be exactly the cases with an aq block: missing {named(sorted(set(declared) - set(ids)))}; extra {named(sorted(set(ids) - set(declared)))}")
    harness = [f"{row['id']}:http{row['status']}" if row.get("status") != 200 else f"{row['id']}:" + "+".join(sorted(k for k, v in row["checks"].items() if v is not True))
               for row in rows if row.get("status") != 200 or not all(v is True for v in row.get("checks", {}).values())]
    gate.require(not harness, f"{title} harness", f"Rows failed before grading: {named(harness)}")
    catalog = report.get("catalog") or {}
    gate.require(isinstance(catalog.get("version"), int), title, "The report must name the imported catalog version")
    metrics = report.get("metrics") or {}
    aq05 = metrics.get("AQ-05") or {}
    gate.require(aq05.get("status") == "n/a" and aq05.get("reason") == "noReferenceDishes", title, "AQ-05 must be reported as n/a noReferenceDishes")
    if isinstance(catalog.get("dishes"), int) and catalog["dishes"] > 0:
        gate.notices.append((f"AQ-05 {case_file}", f"The release has {catalog['dishes']} dishes: add AQ-05 reference-dish cases (backlog)"))
    observed, failing = set(), []
    defined = aq_eligible([c for c in cases if c["id"] in set(declared)])
    for metric, threshold in AQ_THRESHOLDS.items():
        block = metrics.get(metric)
        if not gate.require(isinstance(block, dict) and {"overall", "misses", *AQ_LANGUAGES} <= set(block), title, f"{metric} block missing or incomplete"):
            continue
        # The report's counts and miss list must agree with each other and with the case file, so a metric can neither
        # lose eligible units (e.g. 0/0) nor worsen without a named miss, also in baseline mode.
        problem = count_problem(block, defined[metric])
        if problem:
            gate.error(f"{metric} {case_file} counts", problem)
            continue
        overall = block["overall"]
        passed, eligible = overall["passed"], overall["eligible"]
        for miss in block["misses"]:
            unit, _, code = miss.partition(" ")
            observed.add((metric, unit, code))
        languages = ", ".join(f"{group} {rate(block[group])}" for group in AQ_LANGUAGES)
        gate.lines.append(f"Buddy AQ {case_file} {metric}: {rate(overall)} (≥ {threshold}%; {languages})")
        if eligible == 0:
            # m3 must measure every gated metric; the small b09 subset may not reach some (e.g. no ambiguous case).
            gate.require(case_file != "m3", f"{metric} {case_file} not measured", "No eligible units: the M3 set must measure every gated metric")
            continue
        if passed * 100 < threshold * eligible:
            failing.append((metric, f"{metric} {case_file} {passed}/{eligible} < {threshold}%", named(block["misses"])))
    components = report.get("components") or {}
    problem = count_problem(components, defined["components"]) if components else "components block missing"
    gate.require(not problem, f"components {case_file} counts", problem or "")
    if components.get("misses"):
        gate.notices.append((f"components {case_file}", f"Generated component lines missing (reported, not gated): {named(components['misses'])}"))
    known = {(e["metric"], e["unit"], e["code"]) for e in baseline if e.get("report") == case_file}
    if known:
        # PA19 shrink-only baseline: no miss outside it, no entry that now passes; thresholds wait for an empty baseline.
        for metric in AQ_THRESHOLDS:
            new = sorted(f"{u} {c}" for m, u, c in observed - known if m == metric)
            gate.require(not new, f"{metric} {case_file} misses not in the baseline", named(new))
        fixed = sorted(f"{m} {u} {c}" for m, u, c in known - observed)
        gate.require(not fixed, f"AQ {case_file} baseline entries now pass", f"Remove them from {BASELINE}: {named(fixed)}")
        gate.warnings.append((f"{case_file.upper()} AQ gate", f"{case_file.upper()} AQ gate not met ({len(known)} known misses)"))
    else:
        for _, heading, misses in failing:
            gate.error(heading, misses)


def check(path, gate, baseline):
    """`baseline` is a one-slot cache: the known-miss file is read once, on the first AQ report."""
    try:
        report = json.load(open(path, encoding="utf-8"))
        if report.get("kind") == "aq":
            if not baseline:
                baseline.append(load_baseline(gate))
            check_aq(path, report, gate, baseline[0])
        else:
            check_interpretation(path, report, gate)
    except (OSError, ValueError, KeyError, TypeError, AttributeError) as error:
        gate.error("eval report", f"{path}: unreadable or malformed report ({type(error).__name__})")


def selftest():
    """The gate must be able to fail: a threshold miss, a miss outside a non-empty baseline, a fixed baseline entry and
    counts that disagree with the case file."""
    cases = load_cases("m3")
    ids = [c["id"] for c in cases if "aq" in c]
    defined = aq_eligible(cases)

    def block(eligible, misses):
        counts = {"passed": eligible - len(misses), "eligible": eligible}
        return {"overall": dict(counts), "en": dict(counts), "ar": {"passed": 0, "eligible": 0}, "arabizi": {"passed": 0, "eligible": 0},
                "misses": misses}

    def report(missing, aq04=None):
        metrics = {m: block(defined[m] if defined[m] is not None else 3, []) for m in AQ_THRESHOLDS}
        metrics["AQ-02"] = block(defined["AQ-02"], [f"T06#{n} decode:needsConversion" for n in range(missing)])
        if aq04 is not None:
            metrics["AQ-04"] = block(aq04, [])
        metrics["AQ-05"] = {"status": "n/a", "reason": "noReferenceDishes", "dishes": 0}
        return {"kind": "aq", "mode": "fixture", "caseFile": "m3", "catalog": {"version": 7, "dishes": 0}, "metrics": metrics,
                "components": block(defined["components"], []),
                "rows": [{"id": i, "status": 200, "checks": {"httpSuccess": True, "provenance": True}} for i in ids]}

    def errors(rep, baseline):
        gate = Gate()
        check_aq("selftest", rep, gate, baseline, cases)
        return [title for title, _ in gate.errors]

    def known(unit):
        return {"report": "m3", "metric": "AQ-02", "unit": unit, "code": "decode:needsConversion", "class": "tooling", "fixingStep": "selftest"}

    items = defined["AQ-02"]
    # The smallest miss count that breaks 95 % of the case-defined AQ-02 units.
    breaking = next(n for n in range(items + 1) if (items - n) * 100 < 95 * items)
    results = [
        errors(report(0), []) == [],
        errors(report(breaking), []) == [f"AQ-02 m3 {items - breaking}/{items} < 95%"],
        errors(report(2), [known("T06#0")]) == ["AQ-02 m3 misses not in the baseline"],
        errors(report(1), [known("T06#0"), known("T06#5")]) == ["AQ m3 baseline entries now pass"],
        errors(report(1), [known("T06#0")]) == [],
        errors(report(0, aq04=0), []) == ["AQ-04 m3 counts"],
    ]
    return all(results)


def main(arguments):
    gate = Gate()
    if arguments[:1] == ["--selftest"]:
        arguments = arguments[1:]
        if selftest():
            gate.lines.append("check-buddy-eval selftest: OK (the AQ gate fails on failing reports)")
        else:
            gate.error("check-buddy-eval selftest", "A built-in failing AQ report did not fail the gate")
    if not arguments and not gate.lines and not gate.errors:
        sys.exit(__doc__)
    baseline = []
    for argument in arguments:
        check(argument, gate, baseline)
    gate.emit()
    return 1 if gate.errors else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
