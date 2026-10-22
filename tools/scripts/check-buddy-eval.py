#!/usr/bin/env python3
"""Gate deterministic endpoint regressions; never treat fixture replay as model quality."""
import json
import sys

report = json.load(open(sys.argv[1], encoding="utf-8"))
required = {f"T{n:02}" for n in range(1, 17)} | {"T19", "T39", "T40", "T41"}
rows = report["rows"]
ids = [row["id"] for row in rows]
assert report["mode"] == "fixture", "CI must use offline fixtures"
assert required <= set(ids) and len(ids) == len(set(ids)), "Missing/duplicate M3 cases"
assert report["cases"] == len(rows) == report["passed"], "M3 regression failed"
checks = {"intents", "language", "script", "foods", "amounts", "states", "dimensions", "hints", "weighIns", "shares", "explicit", "itemDimensions", "dimensionOptions"}
assert all(set(row["checks"]) == checks and all(isinstance(value, bool) for value in row["checks"].values()) for row in rows)
assert all(row["passed"] and row["status"] == 200 and all(row["checks"].values()) for row in rows)
assert sum(row["script"] in ("arabic", "arabizi") for row in rows) * 4 >= len(rows)
print(f"Buddy M3: {len(rows)}/{len(rows)} offline parse/resolution regressions passed")
