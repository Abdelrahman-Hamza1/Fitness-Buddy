# tools/app_check (`fb_app_check`)

Architecture checks for the Flutter app that the analyzer can't express
(S06 plan D16, amendments A2, A3, A10; A01 D12): import boundaries between
features and layers, the single-writer write path, raw user-facing strings,
left/right layout. Pure Dart with no
dependencies (regular expressions over the source, no parser), a member of
the pub workspace.

```sh
make app-check                                    # part of make check-dart (and so of CI)
dart run tools/app_check/bin/app_check.dart apps/mobile
dart run tools/app_check/bin/app_check.dart --package packages/fb_design_system
```

`--package <dir>` (A02 D17) checks a UI package instead of the app: only rules 8
(`raw-string`) and 9 (`directional`), on every file of its `lib/` (not just
`presentation/`). The import-boundary and write-path rules (1 to 7, 10 to 13)
never run in package mode; the package's own dependency test covers its
imports. A raw string there is fixed with a parameter or
`lib/l10n/fb_ds_en.arb` (`FbLocalizations`). The OK line says `package mode`.

It reads `apps/mobile/lib/**.dart` (the package name comes from
`apps/mobile/pubspec.yaml`) and prints one line per problem to stderr:

```
apps/mobile/lib/features/today/presentation/today_screen.dart:12: raw-string: raw string 'Today' in Text(…); user-facing text comes from the ARB file (lib/l10n/app_en.arb, context.l10n.<key>)
```

| Exit code | Meaning |
|---|---|
| 0 | No problems (`app-check: OK, …` on stdout, with the number of allow comments). |
| 1 | Problems, listed on stderr with a summary line. |
| 64 | Bad command line, or the folder has no `pubspec.yaml` / `lib/`. |

Skipped: generated code, by path only (`*.g.dart`, `*.freezed.dart`,
`lib/l10n/gen/`; a `GENERATED CODE` header doesn't exempt a file), and anything
outside `lib/` (tests may do what they need).

## The rules

Folder names follow `technical-planning/03-architecture.md` §3.2: `app/` is the
composition root, `core/` the shared infrastructure, `features/<name>/` one
feature with its barrel `<name>.dart`, `presentation/`, `application/` and
`data/`.

| # | Rule id | What fails | Fix |
|---|---|---|---|
| 1 | `feature-barrel` | A file outside feature *X* (another feature, `app/`, `main.dart`) imports anything of *X* except its barrel `features/X/X.dart` | Import the barrel; export what's needed from it |
| 2 | `presentation-data` | `features/*/presentation/` imports `features/*/data/` | Go through `application/` (view models, providers) |
| 3 | `io-package` | An I/O or platform package (`ioPackages` in `lib/src/checker.dart`: `dio`, `fb_api_client`, `http`, `shared_preferences`, `flutter_secure_storage`, `path_provider`, `package_info_plus`, `connectivity_plus`, and the families `drift*`, `sqlite3*`, `sentry*` by prefix) imported outside `features/*/data/` and `core/`. The libraries that open a database connection are narrower still: `core/db/` only (rule 11) | Wrap the I/O in a repository or service in `data/` or `core/` |
| 4 | `core-boundary` | `core/` imports `features/`, `app/` or `main.dart` | Move the shared part into `core/`, or react through a domain event |
| 5 | `feature-app` | `features/` imports `app/` or `main.dart` (A2) | Navigate with `AppNavigator` / `AppRoute` from `core/navigation` |
| 6 | `presentation-io` | `features/*/presentation/`, `app/shell/` or `app/update/` import `core/api/`, `core/db/` or `core/sync/` (A3) | Use a provider from `application/` or a `core/` service that hides the client |
| 7 | `go-router` | `package:go_router` outside `app/router/` (D2) | `AppNavigator` / `AppRoute` |
| 8 | `raw-string` | A string literal with a letter (any script) as a user-visible argument, in `features/*/presentation/`, `app/` or `main.dart` | Add the text to `lib/l10n/app_en.arb` and use `context.l10n.<key>` |
| 9 | `directional` | A left/right layout API anywhere in `lib/` | The start/end form (table below) |
| 10 | `db-write-api` | Anything but `core/changes/change_set_applier.dart` (and `core/db/write/` itself) imports `core/db/write/` (the row writer, A01 D12) | Write user data with a change set (`ChangeSetApplier.apply`); an op handler returns `RowOp`s |
| 11 | `db-write-call` | In a file that imports any `package:drift/` library or anything under `core/db/`, outside `core/db/` and the applier: a drift write call (`driftWriteCalls` in `lib/src/checker.dart`: `into(`, `update(`, `delete(`, `batch(`, `transaction(`, `customStatement(`, `customInsert(`, `customUpdate(`, `customWriteReturning(`, `insert(`, `insertAll(`, `insertOne(`, `insertOnConflictUpdate(`, `insertReturning(`, `insertReturningOrNull(`, `replace(`, `deleteWhere(`, `deleteAll(`, the raw executor's `runInsert(`, `runUpdate(`, `runDelete(`, `runCustom(`, `runBatched(`, and sqlite3's `execute(`), or a `customSelect(` whose SQL literal starts with `INSERT`/`UPDATE`/`DELETE`/`REPLACE`, contains `RETURNING`, or starts with `WITH` and contains one of those four words. Also: importing `core/db/write_guard.dart` (`runAuthorizedWrite`) or `core/db/seed_rows.dart` (`seedRows`) outside `core/db/`, and importing a library that opens a connection (`connectionLibraries` in `lib/src/checker.dart`: `package:sqlite3*`, `drift/native.dart`, `drift/isolate.dart`, `drift/remote.dart`, `drift/backends.dart`, `drift/wasm.dart`, `drift/web.dart`, `drift/web/…`, `drift_flutter`, `drift_sqflite`) outside `core/db/` (only `connection.dart` opens one). Sync's writes (A34) live in `core/db/` too | Same as rule 10. Reads (`select(`, `customSelect('SELECT …')`, `watch`) pass |
| 12 | `application-db` | `features/*/application/` imports `core/db/` (A01 D12, backlog #38) | Read and write through the feature's `data/` repositories |
| 13 | `presentation-changes` | `features/*/presentation/`, `app/shell/` or `app/update/` import `core/changes/` (A01 D12) | Change data through `application/` commands (undo is `core/undo/`) |

Rules 1 to 7, 10, 12, 13 and rule 11's write-guard and seed parts look at `import` and
`export` directives, including every URI of a conditional import. Directives
in comments and strings don't count.

**Rule 11 is a lint, not the guarantee.** The runtime write guard (A01 D11:
`WriteGuard` in `core/db/write_guard.dart`, which wraps the app's only
connection and rejects any write outside `runAuthorizedWrite`) is the backstop
for what the lint can't see: a write hidden in SQL it doesn't parse (a
`customSelect` with a write after a comment, SQL built in a variable),
`PRAGMA x = y`, drift's statement classes constructed directly, the
`Migrator`, and anything reached through a re-export. A gap in the lint fails
at runtime (and in the tests), not silently.

Rule 11 is lexical and has no types: dart:io file deletion in such files uses `deleteSync`. In a file that imports drift or
`core/db/`, any call with one of those names counts, so `map.update(…)` or a
method named `update(` fails there too (rename it, or keep the code out of
that file). A file with neither import passes. `customSelect(` is judged by
the string literals of its first argument only (SQL built in a variable isn't
seen; the runtime write guard still rejects it). drift's manager API is off
(`generate_manager: false` in `apps/mobile/build.yaml`), so its write methods
don't exist. `part` files aren't linked to
their library's imports, so a hand-written `part` that calls drift isn't
seen (generated parts are skipped anyway).

**Rule 3's list is maintained by hand:** a step that adds an I/O or platform
plugin adds it to `ioPackages` (a `*` suffix covers a package family).

**Rule 8** looks at the first positional argument of `Text(`, `Text.rich(`,
`SelectableText(` and the named arguments `title:`, `subtitle:`, `label:`,
`labelText:`, `hint:`, `hintText:`, `helperText:`, `errorText:`,
`counterText:`, `prefixText:`, `suffixText:`, `tooltip:`, `message:`,
`text:`, `semanticLabel:`, `semanticsLabel:`. Only literals at the top level of
the argument count, so both branches of `cond ? 'On' : 'Off'` and `'Hi ' + name`
fail, but `DateFormat('yMMMd').format(d)` and `l10n.greet('x')` pass.
Interpolation-only strings pass (`'$count'`, `'${a} / ${b}'`, `' · '`, `'42'`).

**Rule 9** flags:

| Physical | Use instead |
|---|---|
| `left:` / `right:` named arguments (`EdgeInsets.only`, `Positioned`, `Border`, `BorderRadius.horizontal`, …) | `start:` / `end:` (`EdgeInsetsDirectional.only`, `PositionedDirectional`, `BorderDirectional`, …) |
| `topLeft:`, `topRight:`, `bottomLeft:`, `bottomRight:` (`BorderRadius.only`) | `topStart:` … (`BorderRadiusDirectional.only`) |
| `EdgeInsets.fromLTRB` | `EdgeInsetsDirectional.fromSTEB` |
| `Alignment.centerLeft` etc., `FractionalOffset.topLeft` etc. | `AlignmentDirectional.centerStart` etc. |
| `TextAlign.left` / `TextAlign.right` | `TextAlign.start` / `TextAlign.end` |
| `Icons.*_left*` / `Icons.*_right*` | A direction-neutral icon (`Icons.arrow_back`, `Icons.adaptive.*`). Some `_left`/`_right` icons mirror in RTL (`matchTextDirection`), e.g. `chevron_left`: allow those (`directional`) with a reason |

`EdgeInsets.only(top:, bottom:)`, `EdgeInsets.symmetric` and `Alignment.center`
pass. A ternary such as `isFirst ? left : right` is not a named argument and
passes.

## Exceptions

Put `// app-check: allow <rule-id> <reason>` on the reported line. It silences
only that rule, on that line only. Only the lexical UI rules can be allowed:
`raw-string` and `directional`. The import boundaries and the write-path
rules (1 to 7, 10 to 13) have no exceptions (TD-052): fix the code instead.

An allow comment without a rule id, with an unknown rule id, naming a boundary
rule, or without a reason is itself reported (`invalid-allow`) and silences
nothing. The OK line prints how many allow comments the app has, so a growing
count shows up in review.

```dart
Icon(Icons.chevron_left), // app-check: allow directional mirrors in RTL (matchTextDirection)
Text('Debug build'), // app-check: allow raw-string developer-only banner
```

## Limits

No parser: the check scans text with comment and string awareness. It doesn't
follow re-exports (a barrel exporting another feature's internals passes rule
1), and rule 8 sees only the listed argument names. Code review covers the
rest.

## Tests

`dart test` in this folder (also `make test-dart`). Fixtures are `.txt` files
in `test/fixtures/` (so neither the analyzer nor `tools/trace` reads them):
each line of a `*_bad.txt` fixture marked `// expect: <rule-id>` must be
reported with that rule and nothing else may be; the `*_ok.txt` fixtures must
pass. One test also runs the check on the real `apps/mobile`.
