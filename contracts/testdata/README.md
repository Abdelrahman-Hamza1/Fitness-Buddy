# contracts/testdata/

Golden files that **both** test suites run: the Dart packages and the C# backend. Where the same behaviour is implemented twice (TD-030), or where both sides must agree on a wire format, the expected behaviour is written down once, here, as data. Each side has a test that loads the file and checks every case. A bug fix on either side starts with a new case.

Empty for now. Planned files:

| File | Content | Used by | Arrives in |
|---|---|---|---|
| `problems/*.json` | Example `application/problem+json` bodies, one per error type in the catalogue (`../README.md`) | C# problem mapping tests, Dart `Failure` mapping tests | S03 |
| `normalization_cases.yaml` | Text normalization cases (input → normalized key), at least 100 | `fb_text` (Dart), Catalog module (C#) | S08 (Dart), S30 (C#) |
| `sync/*.json` | Sync push/pull payload examples | the app's sync code (Dart), UserData module (C#) | the sync steps |

## Rules

- **One concern per file or folder**, named after it (`snake_case`). The README of a new file's folder (or this one) documents its format: fields, units, what counts as a pass.
- **Data only**, no code. YAML for hand-written case lists (comments allowed), JSON for wire examples (exactly what goes over HTTP).
- **Stable case IDs.** Every case has an `id` (or the file name is the ID), so a failing test names the case and a renamed case shows up in review.
- **Both sides read the same bytes.** Tests load the file from this folder. Never copy it into a package.
- **No user content and no secrets.** Use invented examples. These files are public in the repository.
- **Wire examples follow the contract.** A JSON example here must be valid against `../openapi.yaml` (the test that uses it checks that, where practical).
