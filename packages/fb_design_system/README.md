# fb_design_system

Fitness Buddy's design system (A02): tokens (colour, type, spacing, radii,
elevation, motion), the "Warm" palette, light and dark `ThemeData` built on
`material_ui`, a bundled Latin + Arabic font pair, the component set and
chart-wrapper interfaces. Pure presentation: no state management, no I/O, no
domain types (the allowlist is enforced by `test/dependencies_test.dart`).

- `FbTheme.light()` / `FbTheme.dark()`: the themes. Product
  colours Material lacks (macros, over-target, success, info) are on
  `context.fbColors`.
- Spacing, radii, elevation and motion are consts: `FbSpace`, `FbRadius`,
  `FbElevation`, `FbMotion`. Icons are named only in `FbIcons`.
- Built-in component strings are in `lib/l10n/fb_ds_en.arb`
  (`FbLocalizations`); everything content-like is a parameter. Add
  `FbLocalizations.delegate` to the app's delegates.
- Call `registerFbFontLicenses()` once at startup (lazy: nothing is read
  until the licence page opens).
- Fonts and their licences: `assets/fonts/SOURCES.md`.
- Goldens: alchemist CI variant (text drawn as blocks, real font metrics).
  `make goldens` regenerates them; review the PNGs before committing.
