# fb_text

Pure Dart Arabic/Arabizi text normalization and unit and number parsing for
Fitness Buddy (see `technical-planning/03-architecture.md` §3.1).

- **`normalizeKey`**: the search key (Arabic and Latin folding, S08 D11).
  Its specification is `contracts/testdata/normalization_cases.yaml` and the
  pipeline and tables in `contracts/testdata/README.md`, which the C#
  Catalog module follows too (TD-030). The tables are in
  `lib/src/normalize/tables.dart`.
- **`identityKey`**: strict food identity (A07 D4 / FD-021), using the same
  folding pipeline but retaining Latin repeats (`coffee` differs from `cofe`).
  Arabic repeat folding, tashkeel and alef folding remain the same. This is a
  Dart-only identity policy, not a change to the shared search golden files.
- **`parseNumber`, `parseQuantity`**: numbers, units and portion words at
  the start or end of food text (S08 D12). The word tables are in
  `lib/src/parse/`. **A split is a hypothesis**: some food names look like
  quantities (حبة البركة, سبع بهارات, 7 Up, omega 3, chicken 65). Callers try
  a catalog match on the whole text (`ParsedQuantity.original`) before they
  trust `rest` and the quantity.

Rules for this package:

- Pure Dart: no Flutter, no I/O (`dart:io`, `dart:ui`, `dart:ffi`,
  `dart:isolate`, `dart:html`).
- No runtime dependencies unless they are added to the allowlist in
  `test/dependencies_test.dart`, which fails the build otherwise.

Run the tests with `make test-dart` from the repository root.

A07 pins parser regressions #28/#29/#31: adjacent glued quantities
(`2 x2 eggs`, `2 100g rice`) and `Coke 0` return null; an explicit suffix
(`cup of tea 2 tbsp`) wins over an implicit prefix. A null parse means the
caller searches the raw text.
