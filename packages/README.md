# packages/

Dart packages shared by the app and the tools. They are members of the pub
workspace declared in the root `pubspec.yaml`, so they share one resolution and
one `pubspec.lock`.

| Package | What it is |
|---|---|
| `fb_api_client/` | The API client, generated from `contracts/openapi.yaml` by `make gen` (dio + retrofit, freezed models). |
| `fb_design_system/` | Flutter design system: tokens, light/dark themes on `material_ui`, bundled Inter + Noto Sans Arabic fonts, components, its own ARB (A02). |
| `fb_domain/` | Pure Dart domain models, business rules and algorithms. |
| `fb_text/` | Pure Dart Arabic/Arabizi text normalization and unit and number parsing. |

`fb_api_client`, `fb_domain` and `fb_text` are pure Dart (no Flutter, no I/O in
`lib/`). `fb_design_system` is Flutter but pure presentation: no state
management, no I/O, no `fb_*` packages. A test in each package enforces that:
it checks the pubspec against a dependency allowlist and scans `lib/` for
forbidden imports (`technical-planning/03-architecture.md` §3.1).

To add a package: create it here, give it `resolution: workspace`, and list it
under `workspace:` in the root `pubspec.yaml`.
