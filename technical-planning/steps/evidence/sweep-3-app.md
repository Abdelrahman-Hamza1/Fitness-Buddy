# Backlog sweep 3: app lane (2026-11-06)

Branch `chore/backlog-sweep-3-app`. Every open row of `steps/backlog.md` as of `c520ea35`. Rows whose fix lives in the backend, infra, CI, shell scripts or contracts are left to the other lane (marked "other lane"). `backlog.md` itself is not edited here (the orchestrator moves these decisions into it).

Counts (app lane): fixed 8, closed 10, kept open 137 (of which owner checks 36); other lane 43.

Commits: `12753dee` #275 · `8c3f22d8` #135 · `0e7438f5` #37 · `2b56327e` #281 #282 #291 #297 · `df5a0dec` nightly OF-01 · `3c828e65` #290. Tests were written, not run (owner rule); `make check-dart` and `make gen-app` green before each commit.

**Round 2 (2026-11-06, owner "rec is fine").** Fixed 19 (#88 #117 #119 #136 #198 #205 (reverted in `e373f6d9`, back to open) #210 #236 part #271 #272 #284 #286 #294, the dead training-day setting; #276 non-Buddy already done), closed with no code 5 (#60 #262 #274 #298, #276 non-Buddy), kept 7 with reasons (#106 #203 #222 #255 #268 #280; #236 rest). Commits: `6d3495e3` #119 · `1b44f035` #136 · `b4b60d3d` #205 (reverted: `e373f6d9`) · `1b3b227a` dead setting · `4d973ca4` #88 · `b2273eac` #117 · `bdf9e555` #198 · `ff20cb53` #210 · `c5018241` #236 · `04b0c17d` #271 · `e6b4d683` #272 · `19a5e4cd` #284 · `7323ecdb` #286 · `3a715e71` #294 (+ goldens). Tests written, not run (owner rule), except the golden regeneration (`heavy.sh make goldens`: 27 passed, 4 PNGs changed and reviewed). `make check-dart` and `make gen-app` green before each commit; `catalog validate` on the real data green.

| # | decision | note |
|---|---|---|
| 1 | other lane | backend/infra/CI/scripts/contract area: not assessed here |
| 3 | other lane | backend/infra/CI/scripts/contract area: not assessed here |
| 4 | other lane | backend/infra/CI/scripts/contract area: not assessed here |
| 5 | other lane | backend/infra/CI/scripts/contract area: not assessed here |
| 7 | open | tools/trace: needs call-argument parsing for `skip:`; with B15 (trace gate) |
| 8 | other lane | backend/infra/CI/scripts/contract area: not assessed here |
| 9 | other lane | backend/infra/CI/scripts/contract area: not assessed here |
| 10 | other lane | backend/infra/CI/scripts/contract area: not assessed here |
| 11 | other lane | backend/infra/CI/scripts/contract area: not assessed here |
| 12 | other lane | backend/infra/CI/scripts/contract area: not assessed here |
| 13 | open | owner, spec tidy (spec change) |
| 14 | other lane | backend/infra/CI/scripts/contract area: not assessed here |
| 15 | other lane | backend/infra/CI/scripts/contract area: not assessed here |
| 16 | other lane | backend/infra/CI/scripts/contract area: not assessed here |
| 17 | other lane | backend/infra/CI/scripts/contract area: not assessed here |
| 18 | other lane | backend/infra/CI/scripts/contract area: not assessed here |
| 19 | other lane | backend/infra/CI/scripts/contract area: not assessed here |
| 21 | other lane | backend/infra/CI/scripts/contract area: not assessed here |
| 23 | other lane | backend/infra/CI/scripts/contract area: not assessed here |
| 24 | other lane | backend/infra/CI/scripts/contract area: not assessed here |
| 25 | other lane | backend/infra/CI/scripts/contract area: not assessed here |
| 34 | other lane | backend/infra/CI/scripts/contract area: not assessed here |
| 36 | open | A43: no release channel yet; the owner installs from the CI artifact |
| 37 | fixed | `0e7438f5`: app_check rule 15 `system-source` (`tools/app_check/lib/src/checker.dart`, README, `import_rules_test.dart`) |
| 39 | open | no presentation consumer yet: `clientConfigProvider` is read only in `app/update`, `core/config` and Buddy `data/` |
| 40 | other lane | backend/infra/CI/scripts/contract area: not assessed here |
| 42 | open | standing rule; audited 2026-11-06: `core/navigation/app_route.dart` carries IDs, dates, slot IDs and measurement-type keys only |
| 44 | open | platform/Gradle (other lane's area); the x86_64 emulator job needs its ABI, so a plain arm64 `abiFilters` would break android-it. Before R2/A43 |
| 45 | open | owner decision (rec: as written in the row) |
| 46 | other lane | backend/infra/CI/scripts/contract area: not assessed here |
| 47 | other lane | backend/infra/CI/scripts/contract area: not assessed here |
| 48 | open | owner (key backup reminder; see #127) |
| 49 | other lane | backend/infra/CI/scripts/contract area: not assessed here |
| 50 | other lane | backend/infra/CI/scripts/contract area: not assessed here |
| 51 | other lane | backend/infra/CI/scripts/contract area: not assessed here |
| 52 | other lane | backend/infra/CI/scripts/contract area: not assessed here |
| 60 | closed | owner 2026-11-06 ("rec is fine"): keep four badges (yours, database, reference, estimate); a label scan shows ⓨ. No code |
| 62 | open | A27 (phase 2, AI-072 override step) |
| 63 | open | sync apply-path repair rule (A34 area, risky) |
| 64 | open | owner (licence mail) |
| 65 | open | catalog schema change (yield_group on ref items, fiber unknown): data-curator step, not before tomorrow's build |
| 67 | open | Makefile/CI dependency (other lane's area); Patrol covers it |
| 68 | open | Makefile/scripts (other lane's area) |
| 69 | open | catalog attach race at a pack update: risky, needs a dedicated test harness |
| 71 | closed | done: `FbProposalActions` is in `packages/fb_design_system/lib/src/components/proposal_card.dart` |
| 73 | closed | obsolete: the real Today (A57 D-093) has no to-confirm row; only `design_preview/.../today_mockup.dart` uses `todayConfirmAll` (Buddy pending moved to the input-bar badge) |
| 74 | open | owner use feedback (A44/A56/A57 already condensed Today) |
| 76 | open | owner check (checklist below) |
| 77 | other lane | backend/infra/CI/scripts/contract area: not assessed here |
| 78 | open | owner check (checklist below) |
| 79 | open | owner check (checklist below) |
| 80 | other lane | backend/infra/CI/scripts/contract area: not assessed here |
| 81 | open | owner check (checklist below) |
| 82 | open | catalog data with sourced fat-% variants + paid recheck |
| 83 | other lane | backend/infra/CI/scripts/contract area: not assessed here |
| 88 | fixed | `4d973ca4`: `catalogUnitCodes` (`tools/catalog/lib/src/model/unit_codes.dart`) checked for USDA servings, dish and variant portions and portion words; a test keeps it in step with the app's `knownUnitLabel`; `catalog validate` on the real data passes (2282 basics, 72 dishes) |
| 89 | open | owner check (checklist below) |
| 91 | open | after owner feedback (ready fix noted in row) |
| 93 | open | native plugin logging; pseudonymous key names only. Wrap before R2 friends |
| 94 | open | native kill matrix (device/JDWP harness), before R2 |
| 95 | open | owner check (checklist below) |
| 96 | open | owner check (checklist below) |
| 97 | open | owner call after use |
| 104 | open | owner check (checklist below) |
| 106 | open | "Edit items" on saved meals still doesn't exist; the ⋯ menu keeps its one row until it does |
| 109 | closed | accepted by design: the chip row grows in through `AnimatedSize`/`AnimatedSwitcher` (A57) from a local read; no skeleton wanted |
| 110 | other lane | backend/infra/CI/scripts/contract area: not assessed here |
| 112 | other lane | backend/infra/CI/scripts/contract area: not assessed here |
| 113 | other lane | backend/infra/CI/scripts/contract area: not assessed here |
| 114 | open | owner check (checklist below) |
| 115 | open | owner check (checklist below) |
| 117 | fixed | `b2273eac`: UX call (conservative): a muted "That's 120 g" line under the typed amount in the food sheet and the entry amount sheet, only for foods offering a portion, kitchen or cross-dimension unit; the line keeps its room while typing (UX-045); the typed value stays as it is. `amountEditorCanonical` in `core/l10n/amount_text.dart` |
| 119 | fixed | `6d3495e3`: owner 2026-11-06: `countryLabel` returns null for a country without a name, so those rows show the city name only |
| 120 | open | A49 Buddy accuracy (cooking-fat IDs feed the A21 loader only) |
| 121 | open | phase 2 (A23b/A49): Buddy proposal preview has no targets yet (`proposal_input_loader.dart` builds `ProposalDayContext` without them) |
| 122 | open | phase 2 (A23b): Buddy trust boundary, Buddy frozen (TD-105) |
| 123 | open | owner check (checklist below) |
| 124 | open | owner check (checklist below) |
| 125 | open | owner check (checklist below) |
| 126 | open | owner check (checklist below) |
| 127 | open | owner check (checklist below) |
| 128 | open | device restore evidence (owner/Claude at the A55) |
| 130 | open | owner check (checklist below) |
| 131 | open | owner check (checklist below) |
| 132 | other lane | backend/infra/CI/scripts/contract area: not assessed here |
| 133 | other lane | backend/infra/CI/scripts/contract area: not assessed here |
| 134 | open | phase 2 (A23b): Buddy card codec limits |
| 135 | fixed | `8c3f22d8`: `FbUnitOption.semanticLabel`; weigh-in sheet and weight history chips read "kilograms"/"pounds" (`weightUnitSpoken`, new ARB `weightUnitKgSpoken`/`weightUnitLbSpoken`); test in `choice_chip_test.dart` |
| 136 | fixed | `1b44f035`: owner 2026-11-06. `TombstoneRow(scrub:)` clears kg, typed value and note in the same write as the tombstone (one version); Undo restores them from the applier's snapshot, so no wait for the undo window is needed (stricter than "after the window"). Test proves the scrubbed row equals corpus `weighIn2-tombstone-scrubbed`, which B19 admits (`serverAccepts: true`); a pulled scrubbed tombstone passes the local CHECKs (kg ≥ 0). Gap (Codex minor): only `DeleteWeighIn` scrubs; see the new row "#136 gap" below |
| 137 | open | owner check (checklist below) |
| 138 | other lane | backend/infra/CI/scripts/contract area: not assessed here |
| 139 | other lane | backend/infra/CI/scripts/contract area: not assessed here |
| 140 | other lane | backend/infra/CI/scripts/contract area: not assessed here |
| 143 | open | phase 2 (A23b): Buddy composer |
| 146 | other lane | backend/infra/CI/scripts/contract area: not assessed here |
| 147 | open | owner check (checklist below) |
| 148 | open | A49 (phase 2) |
| 149 | open | A49 (phase 2) |
| 150 | open | A49 (phase 2) |
| 151 | open | A49 (phase 2) |
| 152 | open | A49/phase 2: Buddy eval cases and aliases |
| 153 | closed | done: `usda:snickers_bar` in `data/usda_selection.yaml`, `data/reference_dishes/zaatar_mix.yaml` reviewed (A47/A54) |
| 154 | open | owner check (checklist below) |
| 155 | open | owner check (checklist below) |
| 156 | open | watch only; recurs → fix |
| 164 | open | owner check (checklist below) |
| 165 | open | UX pass on the weight graph: fold into the next Codex UX review |
| 166 | open | owner, after the A55 check |
| 185 | open | owner check (checklist below) |
| 186 | open | owner use (stale packs not seen yet) |
| 187 | open | B14 |
| 188 | closed | obsolete: D-090 retired training-day shifting (WO-061 removed); TG-043 per-weekday numbers built in A53. `targets.trainingDayWeight` setting is dead (new row below) |
| 191 | open | phase 2 (A23b): Buddy Patrol journey |
| 192 | open | owner check (checklist below) |
| 193 | other lane | backend/infra/CI/scripts/contract area: not assessed here |
| 194 | closed | done: `packages/fb_domain/lib/src/proposals/proposal_codec.dart` writes and reads `assumed` and `removedComponents` (A23a) |
| 195 | open | owner check (checklist below) |
| 196 | closed | obsolete: A53 replaced shift weights with per-weekday numbers; the Higher-calorie days chips are gone (`targetsShifting*` ARB keys unused) |
| 198 | fixed | `bdf9e555`: `targets_screen_test.dart` TG-042 journey: 7,500 kcal logged on Saturday through the applier, Sunday shows the carry note |
| 200 | closed | done: A50 Google sign-in merged (owner A55 check stays in #78) |
| 201 | open | needs an isolated profiles root for Patrol |
| 202 | open | two-database merge (big, risky) |
| 203 | open | kept: no account-only action is reachable by a guest (sync, backups and sign-out rows are hidden for guests, `MeAccountScreen`/`AccountRows`); the only guest-visible candidates (delete data, export) live in Me › Account & data and the delete screen, which the A65 lane is editing now. Conservative call: wire it at the delete screen after A65 merges, or close the row (AC-002 is met by hiding plus the routine prompt) |
| 204 | open | owner check (checklist below) |
| 205 | open | Fix `b4b60d3d` reverted in `e373f6d9` (Codex review, 2026-11-06). Majors: `ProfileRegistry.copyWith` drops `unreadable` and account transitions write through `ProfileRegistry.write`, so a sign-in replaced the corrupt registry; the reset set `guestSeq` back to 1 while old `guest-N` directories remain, so `nextGuest()` could open old data. Minor: structurally invalid registries (`{"active":"local","profiles":[]}`) still counted as readable. Needs its own step: block all registry mutations and account transitions while unreadable, collision-safe guest keys on reset, validate registry invariants |
| 206 | other lane | backend/infra/CI/scripts/contract area: not assessed here |
| 207 | open | design note, no current bug |
| 208 | open | owner check (checklist below) |
| 209 | open | test harness work (per-generation DBs), next account step |
| 210 | fixed | `ff20cb53`: `OpenProfileHandles.trackClose`/`closed()`; the provider's dispose and the switch both track their close; cleanup waits for all; a failed close keeps failing deletion (fail closed) |
| 211 | other lane | backend/infra/CI/scripts/contract area: not assessed here |
| 212 | open | phase 2 (A23b): Buddy controller refactor |
| 213 | open | owner check (checklist below) |
| 217 | closed | done: `secondary_muscles` in `data/exercises.yaml`, `FbMuscleMap` (A37c/A52) |
| 218 | open | A49 (phase 2) |
| 219 | open | owner check (checklist below) |
| 222 | open | kept: not mechanical. Each generator's `_Corpus` differs (case tagging, asymmetry lists, writer cases), and the outputs are the shared corpora the .NET conformance reads; a helper needs a byte-identical regeneration check of all five corpora in its own generator chore |
| 225 | other lane | backend/infra/CI/scripts/contract area: not assessed here |
| 226 | open | A23b (phase 2) |
| 228 | open | owner check (checklist below) |
| 230 | open | changes the targets math (sweep 2: a targets step) |
| 234 | open | owner check (checklist below) |
| 236 | fixed (part) | `c5018241`: `EarlierVersionsButton` (sync barrel) in the weigh-in and measurement edit sheets, with typed-value summaries (a scrubbed tombstone shows its time only). Kept: personal foods (the form holds a draft; a restore under it would fight the form), saved meals (the version is the name only; items are separate rows), workout sets (no per-set editor) |
| 237 | open | owner check (checklist below) |
| 238 | open | owner check (checklist below) |
| 240 | open | follow-up only if `sync_deferred` grows |
| 244 | open | A27 (phase 2) |
| 245 | open | owner use (WorkManager = new dependency) |
| 246 | open | accepted for R1, documented |
| 247 | open | phase 2 (B12/A39b): plan history |
| 248 | open | add only if a device-only issue shows |
| 249 | open | owner check (checklist below) |
| 251 | open | decision made (A40), owner use |
| 252 | open | A41b (phase 2) |
| 253 | open | new permission + hardening check; A41b/owner |
| 254 | open | owner check (checklist below) |
| 255 | open | kept: affects only Ramadan days (next season Feb 2027, see #267). Edge 1 needs date-keyed planned numbers in `WeeklyBudget` (today one weekday map per week) and a per-day maintain flag from the Ramadan calendar; edge 2 needs the version's expenditure, which isn't stored (a generated base is already floor-raised at generation). A targets-math change, not for tomorrow's build |
| 256 | open | per-year keys only if it matters |
| 257 | open | before 2030 |
| 260 | open | owner check (checklist below) |
| 261 | open | A23b (phase 2) |
| 262 | closed | owner 2026-11-06: Sentry sessions stay off (errors-only reading, `docs/runbooks/crash-reports.md`). No code |
| 263 | open | UX call (clearing snackbars on route change would also drop Undo); next UX polish |
| 264 | open | first device numbers (owner #260); OF-01 itself fixed in `df5a0dec` |
| 265 | open | the whole workouts feature reads `allWorkoutSessionsProvider`; a by-date read model is a workouts step, fine at R1 volume |
| 266 | open | needs a schema migration: not before tomorrow's build |
| 267 | open | Ramadan 2027 |
| 268 | open | kept: the setup is built on the fixed `StarterPlan`/`StarterTemplate` enums with ARB names; user-named days need a new setup model, a day-naming page and its write path. The owner logs workouts daily, so this is a designed workouts step, not a sweep fix |
| 269 | open | owner use |
| 270 | open | owner use (A55) |
| 271 | fixed | `04b0c17d`: `app_tabs_test.dart` on the real tab shell: a gated "No plan" save, a switch to Me and Your foods, then the release: Your foods stays, the plan is cleared |
| 272 | fixed | `e6b4d683`: `StartRouteHolder` (core/navigation, outlives profile switches); the account step holds the starter plans before sign-in when "I want a plan"; the next router (new profile generation) opens there once; finishing or leaving the flow clears it. Router tests |
| 273 | open | needs url_launcher (not approved) and a privacy page |
| 274 | closed | owner 2026-11-06: no email kept on the phone. No code |
| 275 | fixed | `12753dee`: `ProgressSeries.build(maintainOn:)` fed from `ramadanCalendarProvider` in `progressDaysProvider`; test `TG-060 G10 … (#275)` in `progress_series_test.dart` |
| 276 | closed (non-Buddy) | already done: the entry amount sheet title, move and merge sheets and the snackbars use the setting (`readFoodNameInline`, tested in `today_names_test.dart` A57 T-N2). The `UndoLabel` args are never rendered (no reader of `label.args`), so storing `names.en` there shows nothing. Buddy proposal lines stay with phase 2 (TD-105) |
| 277 | open | later |
| 278 | open | phase 2 / Buddy frozen |
| 279 | open | R2 |
| 280 | open | kept: (a) effective-dated confirmations change the shape of the synced `targets.dayFloorAcks` setting (new value format, read of old values, export registry); (b) the preview gap is in Buddy's `proposal_input_loader.dart` (frozen, TD-105). Next targets step |
| 281 | fixed | `2b56327e`: measures `tester.getRect` (global, transformed) in `weight_history_screen_test.dart` |
| 282 | fixed | `2b56327e`: `quick_add_bar_test.dart` pins `FbInert.switcherLayout` on the chip row's switcher (animations on) |
| 283 | open | focus moves after reveal: a11y work across A22/A26 flows; next UX polish |
| 284 | fixed | `19a5e4cd`: serving rows sit in a `RevealedColumn` keyed by their input object; removed rows keep their controllers until the form goes (no use after dispose while they shrink); a Reload shows the new rows at once (generation key) |
| 285 | open | no seam in `MobileScannerController` |
| 286 | fixed | `7323ecdb`: T-R4 tests for the measurement sheet and setup load failures, each with Try again |
| 287 | closed | done: nightly run 42187022523 (2026-11-06) passed `app_test.dart` UX-010 tabs incl. Progress on the emulator |
| 288 | open | dev-only gallery |
| 289 | open | owner placement call (rec: add a "Adaptive mode" row under Me › Targets & goal linking Progress › Expenditure) |
| 290 | fixed | `3c828e65`: `account_removed_note_test.dart` AC-002 guest-prompt row: Sign in pushes `SignInRoute`, Not now hides it |
| 291 | fixed | `2b56327e`: `workout_log_controller_test.dart` fills 40 rows with real numbers and checks all 40 autosave |
| 293 | open | nit; name stays editable in Account & data |
| 294 | fixed | `3a715e71`: `FbNumberSlot` measures the sample in the drawn style (inherited `DefaultTextStyle`, letter spacing, bold text); test with letter spacing 1.5. Full golden pass (`heavy.sh make goldens`, all 15 golden files); changed PNGs reviewed (list in the commit) |
| 295 | open | sync recovery path, risky |
| 296 | open | two-device sync test matrix; next diary-sync touch |
| 297 | fixed | `2b56327e`: `export_test.dart` asserts `estimate_only` true/false in the JSON export |
| 298 | closed | TD-114 was amended on the platform branch (owner OK). No code |
| 299 | open | owner after use |

## New rows found

| # | decision | note |
|---|---|---|
| new (nightly 2026-11-06) | fixed | `df5a0dec`: `patrol_test/offline_test.dart` OF-01 failed both attempts at line 199 (`dragUntilVisible`: Bad state: No element, run 42187022523). Cause: the journey read `quickAddContextProvider.slotId` right after boot, before `foodSlotsProvider` emitted, so it was null; the seeded history went to "Other" and no meal header matched `section.key == null`. The test now keeps the context subscribed and waits for a non-null slot. App code unaffected. Needs a manual `android-it` run or the next nightly as proof |
| new | fixed | `1b3b227a`: `targets.trainingDayWeight` and the seven unused `targetsShift*` ARB keys removed. Safe: the key never had a screen (no stored values), nothing reads it, export lists `AppSettings.all` only to name stored keys; test pins its absence |
| new (#136 gap) | open | Codex minor on `1b44f035`: the scrub applies only to `DeleteWeighIn`. Undo of a create goes through `RowWriteSession.inverseRows()`, whose plain `TombstoneRow` keeps kg, typed value and note and syncs them; restoring an older full tombstone through Earlier versions (`RestoreVersionHandler`: `UpsertRow` then plain `TombstoneRow`) bypasses it too. Not fixed here: one shared point (a per-table tombstone scrub in `SyncedTable`, used by the row writer for every `TombstoneRow`) changes the shared write boundary for every entity; left for its own step with writer tests (create→undo, restore of a tombstone version, delete→undo still restores) |

## Owner checklist (A55, one pass)

Optional (D-087: acceptance by use); tick what you get to.

1. Install: new prod build over the old one, data and settings survive, reaches the laptop API (#125); key backup verified with `verify-key-backup.sh` before real data (#127, #48).
2. Today: log a day by hand offline (add, edit amount, change time, move, change food, own nutrient value, delete + Undo, copy meal, save meal), sheets over the keyboard, text scale max (#96, #89).
3. Identity A64: icon on the squircle, themed icon, dev vs prod plate, splash light/dark, notification icon, Buddy avatar in dark (#155).
4. Settings restart persistence + About + licences (#115); Meal times editor at max text size (#130); large meal removal + Undo timing (#131).
5. Targets: setup under 2 minutes, explanation copy, below-floor copy, Me › Targets/Profile edits (#137, #195, #81).
6. Weight: enter past weigh-ins, check the graph with overlays (#213); graph pan jank (#164, adb).
7. Export at max font, share to Gmail/Drive/Sheets, cancel the share sheet (#124).
8. Quick-add chips over a few days (#104); notifications icon/wording and noise over a week (#249).
9. Barcode: halal keyword misses, OFF user agent, coverage line after a week (#228).
10. Accounts (laptop server): email upgrade (#204), Google sign-in (#78), fresh-install anonymous token (#95), sign-in screens and banners at max font (#208), two-phone OF-03 / restore / kill during sync (#237), delete account (#238), identity recovery copy off the laptop (#79), reboot check (#76).
11. Pack update end to end (#185); Buddy cards with keyboard, offline, max font (#147) and the paid smoke when you want Buddy (#154).
12. Device benchmarks over adb: `make perf-startup`, `make perf-device`, `progress_benchmark_test`, proposal recompute/tap (#260, #219, #114, #123, #192).
13. Ramadan: Fajr/Maghrib for Ramallah vs your Awqaf calendar now; the rest in Feb 2027 (#254). Estimator constants after 4+ weeks (#234). Sentry DSN only after the envelope proof (#126).
