# fb_text

Pure Dart Arabic/Arabizi text normalization and unit and number parsing for
Fitness Buddy (see `technical-planning/03-architecture.md` §3.1).

Rules for this package:

- Pure Dart: no Flutter, no I/O (`dart:io`, `dart:ui`, `dart:ffi`,
  `dart:isolate`, `dart:html`).
- No runtime dependencies unless they are added to the allowlist in
  `test/dependencies_test.dart`, which fails the build otherwise.

Run the tests with `make test-dart` from the repository root.
