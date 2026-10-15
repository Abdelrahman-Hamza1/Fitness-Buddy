# tools/app_check (`fb_app_check`)

Architecture checks for the Flutter app that the analyzer can't express
(S06 plan D16, amendments A2, A3, A10): import boundaries between features
and layers, raw user-facing strings, left/right layout. Pure Dart with no
dependencies (regular expressions over the source, no parser), a member of
the pub workspace.

```sh
make app-check                                    # part of make check-dart (and so of CI)
dart run tools/app_check/bin/app_check.dart apps/mobile
```

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
| 3 | `io-package` | An I/O or platform package (`ioPackages` in `lib/src/checker.dart`: `dio`, `fb_api_client`, `http`, `shared_preferences`, `flutter_secure_storage`, `path_provider`, `package_info_plus`, `connectivity_plus`, and the families `drift*`, `sqlite3*`, `sentry*` by prefix) imported outside `features/*/data/` and `core/` | Wrap the I/O in a repository or service in `data/` or `core/` |
| 4 | `core-boundary` | `core/` imports `features/`, `app/` or `main.dart` | Move the shared part into `core/`, or react through a domain event |
| 5 | `feature-app` | `features/` imports `app/` or `main.dart` (A2) | Navigate with `AppNavigator` / `AppRoute` from `core/navigation` |
| 6 | `presentation-io` | `features/*/presentation/`, `app/shell/` or `app/update/` import `core/api/`, `core/db/` or `core/sync/` (A3) | Use a provider from `application/` or a `core/` service that hides the client |
| 7 | `go-router` | `package:go_router` outside `app/router/` (D2) | `AppNavigator` / `AppRoute` |
| 8 | `raw-string` | A string literal with a letter (any script) as a user-visible argument, in `features/*/presentation/`, `app/` or `main.dart` | Add the text to `lib/l10n/app_en.arb` and use `context.l10n.<key>` |
| 9 | `directional` | A left/right layout API anywhere in `lib/` | The start/end form (table below) |

Rules 1 to 7 look at `import` and `export` directives, including every URI of
a conditional import. Directives in comments and strings don't count.

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
only that rule, on that line only. Only the lexical rules can be allowed:
`raw-string` and `directional`. The import boundaries (rules 1 to 7) have no
exceptions: fix the import instead.

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
