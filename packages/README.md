# packages/

Dart packages shared by the app and the tools. They are members of the pub
workspace declared in the root `pubspec.yaml`, so they share one resolution and
one `pubspec.lock`.

| Package | What it is |
|---|---|
| `fb_domain/` | Pure Dart domain models, business rules and algorithms. |
| `fb_text/` | Pure Dart Arabic/Arabizi text normalization and unit and number parsing. |

Both are pure Dart (no Flutter, no I/O). A test in each package enforces that:
it checks the pubspec against a dependency allowlist and scans `lib/` for
forbidden imports. Later steps add `fb_api_client` and `fb_design_system` here
(`technical-planning/03-architecture.md` §3.1).

To add a package: create it here, give it `resolution: workspace`, and list it
under `workspace:` in the root `pubspec.yaml`.
