# A05b verification

## Scope and source evidence

Normal tier: author-owned exercise names and public GeoNames city data, local
catalog tooling only. No runtime UI, user-data writes, HTTP API changes, paid
calls, secrets, or new package dependencies. Pack schema remains v1.

- Contract-first commit `6ae7879` adds WO-004's missing `assisted`/`reps_only`
  types; the backend's embedded release schema is regenerated in that commit.
- `data/geonames/sources.yaml`: 2026-10-22 downloads; archive and extracted-text
  SHA256 pins. Bulk downloads retained outside git. Import verifies text pins;
  explicit fetch helper verifies archive/text pins and fails on changed URLs.
- IANA tzdata2026e: 598 Zone/Link names, including `backward`; archive URL/hash
  recorded with the snapshot. Build validation is independent of host tzdata.
- PS/JO and all 13 regional countries use pinned language-tagged alternates,
  preferred/current-name ranking and normalized Arabic letter forms. Reviewed
  missing-name exceptions and explicit ID exclusions are recorded in sources/data.
  GeoNames attribution is active; A10 displays only credit, never internal note.

## Release measurements

Catalog v6 after app-review remediation, pack schema v1:

| Kind | Count |
|---|---:|
| Basics | 246 |
| Reviewed dishes / variants | 0 / 0 (existing drafts remain excluded) |
| Exercises | 100 |
| Cities | 2,276 |
| Names | 1,429 |
| Servings / yield rows | 198 / 12 |
| Pack bytes | 598,016 (<10,000,000) |

All six WO-004 exercise types ship. Equipment variants use separate stable
IDs, and every EN display name/alias resolves to its exercise in the real
pack. Cities include Hebron (`city:285066`, Asia/Hebron), Amman, Ramallah and
Nablus. The owner chose Ramallah: `city:282239`, 31.89964 / 35.20422,
Asia/Hebron (a valid IANA identifier for this location). The runtime location
chooser/prayer calculation stays in A41.

## Tests and gates

- WP1 and WP2 `make check test`: green; 361 backend tests and all Dart suites.
- Eight new `library_data_test.dart` tests: source-schema/type/ID/equipment
  failures; normalized alias collisions; deterministic pack/load IDs and bytes;
  city country/population filtering; Arabic display ordering; invalid/missing
  coordinates, unknown zones, backward aliases, negative population, duplicate
  IDs; valid and malformed metadata/checksum paths.
- Three new real-data tests: every exercise alias searchable, distinct bench
  equipment variants and all six types, city counts/IDs/zones.
- New app `OfflineCatalog` regression: exercise target/alias yields no food;
  an ordinary food query still works.
- Existing backend full-release isolated-database test extended: imports 100
  exercises/2,322 cities, validates all six types, checks exercise aliases have
  no food FK and cannot be returned as exercise IDs in food search.
- Offline download-helper smoke with mocked HTTP and the retained real archives:
  matching pins reproduce the original extracts; corrupt archive rejected before
  unzip; repository-internal bulk output rejected. No network used by this smoke.
- A second city import reproduced the committed TSV byte for byte. Matching raw
  archives/extracts are retained in `~/.cache/fitness-buddy/geonames/A05b-20261022`.
- Food-only generated fixture SQL is unchanged.
- Final `make check test catalog-check`: green (361 backend, zero failures;
  mobile 325 passed/one existing live-config skip; catalog 133; other Dart
  suites green). Branch CI is checked on the final pushed commit before handover.
  [Branch Actions](https://github.com/Abdelrahman-Hamza1/Fitness-Buddy/actions?query=branch%3Astep%2FA05b-exercises-cities-data).

Private local logs: `~/.local/state/a05b-{wp1,wp2,final}-check.log`,
`a05b-{library,real}-tests.log`, `a05b-release.log`, `a05b-catalog-check.log`.
These contain synthetic/public catalog data only.

## Independent review

Fresh GPT-6.1 Sol plan review: 0 blockers/majors, two recommendations added
(nonempty exercise food isolation coverage and IANA backward-alias regression).
Fresh GPT-6.1 Sol early code review: 0 blockers/majors; one minor (malformed
source metadata gave TypeError) fixed with regression and rechecked.
Final whole-diff/exit review: 0 blockers, 0 majors, 0 open minors. Reviewer
independently checked city coordinates/zones/filter, exercise types/names, lock
entries, pack/checksum and active attribution. Local CA1861 analyzer failure in
the extended test was corrected (static readonly expected type array); final
checks passed. Claude app-architecture review subsequently completed; see the
remediation evidence below.


## 2026-10-22 app-review remediation verification

The Tests and gates / Independent review sections above describe earlier
implementation passes. Current working-tree evidence supersedes their city
counts and pending-review status:

- `make check`: PASS (exit 0), including contract and hardening checks.
- `make test-dart`: PASS (exit 0), 10 workspace packages; catalog 135 tests;
  mobile 325 and one existing skip; fb_domain and fb_text coverage both 100%.
- `make catalog`: PASS; v5, schema v1, 2,276 cities, 602,112-byte pack.
- `make catalog-check`: PASS (exit 0), including append-only lock/freshness checks.
- `make check-dotnet`: PASS after adjusting the backend full-release test count.
- `make test-dotnet`: NOT RUN by explicit orchestrator instruction; Claude runs it.
- Amman عمّان, Tulkarm طولكرم, both Karak IDs Karak / الكرك, full unchanged
  Ramallah row, six regional centres' Arabic names, preferred/current-language
  selection, letter normalization and deterministic tie/fallback tests pass.
- All 46 explicit exclusions absent; 46 active-to-retired lock changes only,
  with no deleted IDs or changed kind/first-version. Palestinian Battir 284376,
  Beit Hanina, Shu'fat, al-Eizariya and Abu Dis remain. Complete classification
  and two retained identity questions (‘Atarut/Nayot) are in the card.
- Same-input `fb_catalog import-cities` re-import is byte-identical:
  TSV SHA256 `65400c58ad9cca3e148ff969966159ab2111a7aa6107caad91ae183b849ac227`.
- Updated fetch helper: mocked-HTTP smoke verifies all 17 real pinned archives
  and text extracts; corrupt archive and repository-internal output rejected.
- New raw archives/extracts retained at `/tmp/a05b-city-review` (outside git);
  original city archives also remain in the earlier cache path.
- Claude app review is complete; fixes address its major and cheap minors.
  Its log authorizes merge after fixes/tests/green CI without another app round.
  No commit/push/merge attempted here; Claude owns the working-tree handoff.

Current session logs: `/tmp/a05b-{check,test-dart,catalog,catalog-check,check-dotnet}.log`.


## 2026-10-22 follow-up: display-script regression corrections

English now uses a usable preferred `en`, otherwise GeoNames `asciiname`;
apostrophe/dash variants normalize to allowed simple punctuation. Invalid
preferred forms fall back to asciiname. Arabic selection skips mislabeled Latin
transliterations before preferred-name ranking and leaves an empty name when
no usable Arabic-script candidate exists. Both constraints are enforced by
`parseCity` on every imported/committed row and therefore by catalog checks.
Loader negatives cover accented/non-Latin English and Latin/mixed/non-Arabic
names; positive Arabic includes spaces, diacritics and shadda. Source tests prove
invalid preferred candidates cannot outrank valid candidates or prevent fallback.
Real-data tests assert all rows and Tulkarm's ASCII spelling.

Audit: **non-ASCII English = 0; invalid English whitelist = 0;
Latin-in-Arabic = 0**. All 2,276 city IDs/exclusions/lock entries and owner-question
retention unchanged; release v6 pack is 598,016 bytes.

| Country | Cities with Arabic name | Total cities |
|---|---:|---:|
| AE | 39 | 63 |
| BH | 8 | 8 |
| EG | 199 | 242 |
| IL | 62 | 104 |
| IQ | 97 | 105 |
| JO | 140 | 146 |
| KW | 18 | 18 |
| LB | 17 | 18 |
| OM | 23 | 28 |
| PS | 323 | 334 |
| QA | 22 | 26 |
| SA | 72 | 98 |
| SY | 89 | 89 |
| TR | 101 | 436 |
| YE | 24 | 25 |

Arabic names total: **1234 / 2276**. Each other represented country has **0** Arabic names: AF, AM, AO, AR, AT, AU, AZ, BD, BE, BF, BG, BO, BR, BY, CA, CD, CG, CI, CL, CM, CN, CO, CU, CZ, DE, DK, DO, DZ, EC, ES, ET, FR, GB, GE, GH, GN, HK, HT, HU, ID, IE, IN, IR, IT, JP, KE, KH, KP, KR, KZ, LR, LY, MA, MG, ML, MM, MR, MW, MX, MY, MZ, NE, NG, NO, NP, NZ, PE, PH, PK, PL, PY, RO, RS, RU, RW, SD, SE, SG, SN, SO, TD, TG, TH, TM, TW, TZ, UA, UG, US, UY, UZ, VE, VN, ZA, ZM, ZW.

Follow-up gates:

- `make check`: PASS (exit 0); format/analyzers, app rules, .NET build, contracts,
  hardening self-test.
- `make test-dart`: PASS (exit 0); all 10 packages; catalog 137; mobile 325 plus
  one existing skip. Domain/text coverage 100%.
- `make catalog`: PASS; v6, 2,276 cities, 598,016 bytes.
- `make catalog-check`: PASS (exit 0); freshness, source-row validation,
  stable-ID checks, schemas and fixture checks.
- `make check-dotnet`: PASS (exit 0), zero warnings/errors.
- `make test-dotnet`: NOT RUN, explicitly delegated to Claude.
- Same-input city re-import: PASS, byte-identical SHA256
  `176c719469254fed049a765504625add8cfc9fe2ac373500abb6cedbe8d4c4a8`.
- `git diff --check`: PASS. No project git writes.
Logs: `/tmp/a05b-r2-{check,test-dart,catalog,catalog-check,check-dotnet,focused}.log`.
