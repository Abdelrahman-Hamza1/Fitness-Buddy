# contracts/testdata/

Golden files that **both** test suites run: the Dart packages and the C# backend. Where the same behaviour is implemented twice (TD-030), or where both sides must agree on a wire format, the expected behaviour is written down once, here, as data. Each side has a test that loads the file and checks every case. A bug fix on either side starts with a new case.

Files (present and planned):

| File | Content | Used by | Arrives in |
|---|---|---|---|
| `problems/*.json` | Example `application/problem+json` bodies, one per error type in the catalogue (`../README.md`) | C# problem pipeline tests (Host.Tests), Dart `Failure` mapping tests | S03 ✅ |
| `normalization_cases.yaml` | Text normalization cases (input → normalized key), at least 100 | `fb_text` (Dart), Catalog module (C#) | S08 (Dart) ✅, S30 (C#) |
| `sync/*.json` | Sync push/pull payload examples | the app's sync code (Dart), UserData module (C#) | the sync steps |

## Rules

- **One concern per file or folder**, named after it (`snake_case`). The README of a new file's folder (or this one) documents its format: fields, units, what counts as a pass.
- **Data only**, no code. YAML for hand-written case lists (comments allowed), JSON for wire examples (exactly what goes over HTTP).
- **Stable case IDs.** Every case has an `id` (or the file name is the ID), so a failing test names the case and a renamed case shows up in review.
- **Both sides read the same bytes.** Tests load the file from this folder. Never copy it into a package.
- **No user content and no secrets.** Use invented examples. These files are public in the repository.
- **Wire examples follow the contract.** A JSON example here must be valid against `../openapi.yaml` (the test that uses it checks that, where practical).

## `problems/`

One file per type in the error catalogue (`../README.md`), named after its slug: `/errors/validation-failed` → `validation-failed.json`. Each is exactly the `application/problem+json` body the server sends for that type (no extra fields, JSON key order as the server writes it):

- `type`, `title`, `status` always; `detail` where the server sets one; `errors` (field → messages) for `validation-failed`.
- `traceId` is an example value (32 lowercase hex). It differs on every request.

**A body passes** when the server's body for that type has the same `type`, `title`, `status` and `detail` (or both have none), the same set of `errors` keys (messages are not compared: they come from the validation framework), the same set of members, and a `traceId` matching `^[0-9a-f]{32}$`. The Dart side maps each file to its `Failure`.

## `normalization_cases.yaml`

The specification of the **search key** (`normalizeKey` in `packages/fb_text`, S08 D11 + A1–A3, TD-030): the text that both the search index and the query are reduced to before they are compared. The C# Catalog module (S30) must give the same key, byte for byte. Don't use Unicode normalization (`string.Normalize(FormD)`), `ToLower`/`ToLowerInvariant` or culture APIs on either side: use the steps and tables below, nothing else.

### Format

```yaml
version: 1
cases:
  - id: ar-tashkeel-damma     # required, unique, stable
    input: "فُول"              # required, double-quoted string
    key: "فول"                 # required, double-quoted string
    note: "why this case"      # optional string
```

- `version` is `1`. A change to the meaning of the fields (not a new case) bumps it.
- `id`: kebab-case with a category prefix: `ar-` (Arabic script), `lat-` (Latin script), `digit-`, `space-` (whitespace, invisibles, symbols, emoji), `mixed-` (several scripts), `arabizi-` (Arabic in Latin letters and digits). Never renamed or reused.
- `input` and `key` are always **double-quoted** (so `"100"`, `"yes"` or `""` stay strings; the Dart loader fails with the case `id` otherwise). Invisible and look-alike characters (ZWNJ, RLM, BOM, presentation forms, Cyrillic look-alikes) are written as `\uXXXX` escapes.
- No other fields.

**A case passes** when `normalizeKey(input) == key` byte for byte **and** `normalizeKey(key) == key` (every key is a fixed point). The file has at least 100 cases.

### Pipeline (fixed order)

Every step works on Unicode code points (a character outside the BMP, such as an emoji, is one code point).

1. **Compatibility folds, then deletions.** First fold the fullwidth ASCII forms U+FF01–U+FF5E (`！`–`～`) to ASCII U+0021–U+007E (subtract U+FEE0, so `ＲＩＣＥ` → `RICE`, `１００` → `100`, `＇` → `'`) and the Latin ligatures to their letters: ﬀ U+FB00 → `ff`, ﬁ U+FB01 → `fi`, ﬂ U+FB02 → `fl`, ﬃ U+FB03 → `ffi`, ﬄ U+FB04 → `ffl`, ﬅ U+FB05 → `st`, ﬆ U+FB06 → `st`. Then **delete** invisible format characters and apostrophes (including any the fold just produced): U+00AD soft hyphen, U+061C Arabic letter mark, U+200B–U+200F (zero width space, ZWNJ, ZWJ, LRM, RLM), U+202A–U+202E (bidi embeddings and overrides), U+2060 word joiner, U+2066–U+2069 (bidi isolates), U+FEFF BOM, and the apostrophes U+0027 `'`, U+0060 `` ` ``, U+02BC `ʼ`, U+2018 `‘`, U+2019 `’`.
2. **Digits:** Arabic-Indic U+0660–U+0669 (٠–٩) and Persian U+06F0–U+06F9 (۰–۹) → ASCII `0`–`9`.
3. **Delete Arabic marks:** tashkeel U+064B–U+065F (includes the combining hamza above/below and madda), superscript alef U+0670, Quranic marks U+06D6–U+06ED, tatweel U+0640.
4. **Fold Arabic letters:**

   | From | To |
   |---|---|
   | lam-alef ligatures U+FEF5–U+FEFC (ﻵ ﻶ ﻷ ﻸ ﻹ ﻺ ﻻ ﻼ) | لا (U+0644 U+0627) |
   | آ U+0622, أ U+0623, إ U+0625, ٱ U+0671 | ا U+0627 |
   | ة U+0629 | ه U+0647 |
   | ى U+0649 | ي U+064A |
   | ئ U+0626 | ي U+064A |
   | ؤ U+0624 | و U+0648 |
   | ک U+06A9 (keheh), گ U+06AF (gaf) | ك U+0643 |
   | ی U+06CC (Farsi yeh) | ي U+064A |
   | ڤ U+06A4 (veh) | ف U+0641 |
   | پ U+067E (peh) | ب U+0628 |
   | چ U+0686 (tcheh) | ج U+062C |

   A standalone ء U+0621 is kept (so شيء ≠ شي, while شئ = شي).
5. **Latin:** ASCII `A`–`Z` → `a`–`z`. Delete combining marks U+0300–U+036F. Fold every letter of Latin-1 Supplement and Latin Extended-A (U+00C0–U+017F except × U+00D7 and ÷ U+00F7) with this table (each character on the right → the ASCII on the left):

   | To | From |
   |---|---|
   | a | ÀÁÂÃÄÅàáâãäåĀāĂăĄą |
   | ae | Ææ |
   | c | ÇçĆćĈĉĊċČč |
   | d | ÐðĎďĐđ |
   | e | ÈÉÊËèéêëĒēĔĕĖėĘęĚě |
   | g | ĜĝĞğĠġĢģ |
   | h | ĤĥĦħ |
   | i | ÌÍÎÏìíîïĨĩĪīĬĭĮįİı |
   | ij | Ĳĳ |
   | j | Ĵĵ |
   | k | Ķķĸ |
   | l | ĹĺĻļĽľĿŀŁł |
   | n | ÑñŃńŅņŇňŉŊŋ |
   | o | ÒÓÔÕÖØòóôõöøŌōŎŏŐő |
   | oe | Œœ |
   | r | ŔŕŖŗŘř |
   | s | ŚśŜŝŞşŠšſ |
   | ss | ß |
   | t | ŢţŤťŦŧ |
   | th | Þþ |
   | u | ÙÚÛÜùúûüŨũŪūŬŭŮůŰűŲų |
   | w | Ŵŵ |
   | y | ÝýÿŶŷŸ |
   | z | ŹźŻżŽž |

6. **Allowed set:** every code point that isn't in the allowed set becomes a space U+0020. The allowed set is `a`–`z` (U+0061–U+007A), `0`–`9` (U+0030–U+0039), the space U+0020, and the Arabic letters U+0621–U+063A and U+0641–U+064A. (After step 4, آ أ ؤ إ ئ ة ى can't occur, so a key never contains them.) Everything else, including punctuation, symbols, other whitespace, Cyrillic, Greek, emoji and presentation forms other than lam-alef and the Latin ligatures of step 1, becomes a space.
7. **Collapse repeated letters** (a run is a sequence of the same code point):
   - Latin `a`–`z`: a run of 2 or more → one (`chiiicken` → `chicken`, `coffee` → `cofe`).
   - Arabic long vowels ا U+0627, و U+0648, ي U+064A: a run of 2 or more → one (فوول → فول).
   - Any other Arabic letter: a run of **3** or more → one. A run of 2 stays, so real doubles survive (اللبن ≠ البن, مملح ≠ ملح).
   - Digits and spaces are untouched here (`100` stays `100`).
8. **Spaces:** runs of spaces → one space, then trim both ends.

The tables live in `packages/fb_text/lib/src/normalize/tables.dart`. Change the code, this section and the cases together.
