# tools/trace (`fb_trace`)

Requirement traceability report (AT-001): which spec requirements have a test
that claims to cover them, per release. Pure Dart, a member of the pub
workspace.

```sh
make trace                 # R1 (default)
make trace RELEASE=all     # every release, plus the untagged IDs
dart run tools/trace/bin/trace.dart --root . --release R2 --out trace.md
```

The Markdown report goes to stdout (or `--out <file>`). One summary line per
release goes to stderr, e.g. `trace: R1: 319 total, 0 covered, 319 missing`.
The output has no timestamps, so the same repo always gives the same report.

| Exit code | Meaning |
|---|---|
| 0 | Report written, whatever the coverage. |
| 2 | The spec is invalid (a duplicate ID); errors on stderr, no report. |
| 64 | Bad command line. |

## Where requirements come from

Top-level `spec/*.md` files only (not `research/` or `questions/`), skipping
`README.md`, `decisions.md` and `glossary.md`.

- **Bullets:** ``- **AI-012** `[R1]` Text``. The release tag counts only
  right after the bold ID. A tag later in the line is prose. A bullet without
  a tag is *untagged*. An unknown tag value is untagged plus a warning.
- **Table rows** whose first cell is an ID (`| NT-001 | … |`). The release
  comes from the table's `Release` column. Without one, the row is untagged.
- IDs anywhere else (prose, other cells) are references, not definitions.
  Test cases like `T01` aren't IDs. A duplicate ID is an error.
- `lib/src/release_overrides.dart` gives a release to table IDs the spec
  leaves untagged, each with its reason: `UX-001`…`UX-007` and `AQ-01`…`AQ-12`
  are R1 (AT-004, AT-002), except `AQ-11`, which is R2. An override on a tagged
  or unknown ID is ignored with a warning.

## How tests claim coverage

Scanned: Dart files under any `test/` or `integration_test/` folder in `apps/`,
`packages/` and `tools/`, and C# files under `backend/tests/`. Skipped:
`.dart_tool`, `build`, `bin`, `obj` and `tools/trace/test/fixtures`.

- **Dart test names:** the IDs at the *start* of the first string literal of
  `test`, `testWidgets`, `group`, `patrolTest` or `goldenTest`:
  `test('DY-011 DY-012 assigns the slot by time window', …)`. An ID later in
  the name doesn't count.
- **Comments (Dart and C#):** `// covers: DY-011, DY-012`.
- **C#:** `[Trait("Req", "AC-012")]`.

Test calls and Traits inside comments (`// test('DY-011 …')`, `/* … */`,
`// [Trait("Req", …)]`) don't count: commented-out tests cover nothing. A `//`
or `/*` inside a string literal is not a comment.

An ID referenced by a test but missing from the spec is listed under
"Warnings" (usually a typo).

## Limitations

- **Skipped tests still count as covered.** v0 doesn't look at `skip:` (or
  C# `[Fact(Skip = …)]`), so a skipped test with a leading ID still covers it.
- A test call written inside a string literal (`'test("DY-011 …")'`) counts.
- C# interpolation holes aren't parsed: a string inside a hole (`$"{"//"}"`)
  can end the outer string early, so a test after it on the same line may be
  missed (a false *negative*).

## Tests

`make test-dart`, or `dart test` in this folder. The tests build temporary
repos in the system temp folder. The fake test sources in `test/fixtures/` use
the `.txt` extension and `ZZ-` IDs, so they are never analysed, run or counted.
