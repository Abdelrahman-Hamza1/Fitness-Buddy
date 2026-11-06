#!/usr/bin/env python3
"""Fail if pubspec.lock pulls a package from anywhere but pub.dev (backlog #9).

pubspec.lock is marked linguist-generated, so GitHub collapses it in diffs and a
changed source is easy to miss in review. Every package must be `hosted` on
https://pub.dev with a sha256, or come from the Flutter `sdk`. Git and path
sources, other hosts and missing hashes are rejected.

Usage: check-pub-lock.py [pubspec.lock ...]   (default: ./pubspec.lock)
"""

from __future__ import annotations

import re
import sys

ALLOWED_URL = "https://pub.dev"
ALLOWED_SOURCES = {"hosted", "sdk"}

_PACKAGE = re.compile(r"^  ([A-Za-z0-9_]+):\s*$")
_FIELD = re.compile(r"^\s+(source|url|sha256):\s*\"?([^\"]*)\"?\s*$")


def check(text: str) -> list[str]:
    """Returns one message per problem; empty when the lock is clean."""
    problems: list[str] = []
    packages: dict[str, dict[str, str]] = {}
    in_packages = False
    current: str | None = None
    for line in text.splitlines():
        if not line.strip() or line.lstrip().startswith("#"):
            continue
        if not line.startswith(" "):
            in_packages = line.rstrip() == "packages:"
            current = None
            continue
        if not in_packages:
            continue
        m = _PACKAGE.match(line)
        if m:
            current = m.group(1)
            packages[current] = {}
            continue
        f = _FIELD.match(line)
        if f and current is not None:
            packages[current][f.group(1)] = f.group(2)
    if not packages:
        return ["no packages found (not a pubspec.lock?)"]
    for name, fields in sorted(packages.items()):
        source = fields.get("source")
        if source not in ALLOWED_SOURCES:
            problems.append(f"{name}: source {source!r} (only hosted on {ALLOWED_URL} or sdk)")
            continue
        if source == "hosted":
            if fields.get("url") != ALLOWED_URL:
                problems.append(f"{name}: hosted url {fields.get('url')!r}, expected {ALLOWED_URL!r}")
            if not re.fullmatch(r"[0-9a-f]{64}", fields.get("sha256", "")):
                problems.append(f"{name}: missing or malformed sha256")
    return problems


def main(argv: list[str]) -> int:
    paths = argv[1:] or ["pubspec.lock"]
    failed = False
    for path in paths:
        with open(path, encoding="utf-8") as handle:
            problems = check(handle.read())
        for problem in problems:
            print(f"{path}: {problem}", file=sys.stderr)
        failed = failed or bool(problems)
    if not failed:
        print(f"pub lock sources OK ({', '.join(paths)}: pub.dev + sdk only)")
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
