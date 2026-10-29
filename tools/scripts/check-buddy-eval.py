#!/usr/bin/env python3
"""Gate deterministic endpoint regressions; never treat fixture replay as model quality.

Usage: check-buddy-eval.py <report.json> [<report.json> ...]
Each report names its case file (m3 = B08's M3 set, b09 = B09a's intents). Run from the repo root:
the b09 per-case check sets come from tools/buddy_eval/cases/b09.yaml.
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


def b09_checks():
    """Per case: the base checks plus one check per expected top-level field (targets, candidates, patch, batchId, ...)."""
    cases = json.loads(Path("tools/buddy_eval/cases/b09.yaml").read_text(encoding="utf-8"))["cases"]
    for case in cases:
        for intent in case["expected"]["intents"]:
            missing = FLOOR.get(intent["kind"], set()) - set(intent)
            assert not missing, f"{case['id']}: a {intent['kind']} expectation must grade {sorted(missing)}"
    return {c["id"]: BASE | {k for i in c["expected"]["intents"] for k in i if k != "kind"} for c in cases}


def check(path):
    report = json.load(open(path, encoding="utf-8"))
    case_file = report.get("caseFile", "m3")
    assert case_file in REQUIRED, f"{path}: unknown case file"
    rows = report["rows"]
    ids = [row["id"] for row in rows]
    assert report["mode"] == "fixture", "CI must use offline fixtures"
    assert REQUIRED[case_file] <= set(ids) and len(ids) == len(set(ids)), f"Missing/duplicate {case_file} cases"
    assert report["cases"] == len(rows) == report["passed"], f"{case_file} regression failed"
    expected = b09_checks() if case_file == "b09" else {row["id"]: M3_CHECKS for row in rows}
    if case_file == "b09":
        assert set(ids) == set(expected), "The b09 report must run every case in the case file"
    for row in rows:
        assert set(row["checks"]) == expected[row["id"]], f"{row['id']}: unexpected check set"
        assert all(isinstance(value, bool) for value in row["checks"].values())
        assert row["passed"] and row["status"] == 200 and all(row["checks"].values()), f"{row['id']} failed"
    assert sum(row["script"] in ("arabic", "arabizi") for row in rows) * 4 >= len(rows), "Arabic/Arabizi below a quarter"
    groups = report["byLanguage"]
    assert set(groups) == {"en", "ar", "arabizi"}, "Breakdown keys must be en, ar and arabizi"
    breakdown = ", ".join(f"{key} {groups[key]['passed']}/{groups[key]['cases']}" for key in ("en", "ar", "arabizi"))
    print(f"Buddy {case_file}: {len(rows)}/{len(rows)} offline parse/resolution regressions passed ({breakdown})")


if len(sys.argv) < 2:
    sys.exit(__doc__)
for argument in sys.argv[1:]:
    check(argument)
