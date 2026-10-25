# A11 verification (2026-10-25)

Tier **Risky** (exports, backups, crash reporting and release signing). Built by Codex (WP1–WP3, WP5 and fix round 1), Claude flutter-engineer (WP4), and tech-researcher (WP0). This continuation checked committed WIP `50ad012` against every review finding. Round 1 corrected one restore-test fixture. Round 2 fixes new major C5: premature deletion of plugin handoff copies. This records host evidence, not completion of the device or live-service checks.

## Exit criterion → evidence → status

| Exit criterion | Evidence | Status |
|---|---|---|
| Every entity exported; registry catches omissions; opens cleanly in a spreadsheet | `test/core/export/export_test.dart`: T1–T7/T10 compare synced tables and columns, live DB counts, typed JSON and RFC 4180 CSV (Arabic, quoting, BOM, CRLF, formula guards). Format v1: `docs/export-format.md`. | **Host PASS; PENDING owner:** open the A55 export in a spreadsheet, including largest Android font and share-target checks. Combined criterion remains unchecked. |
| Off-laptop release key + password; copied key matches TD-055 | `verify-key-backup-selftest.sh` accepts a synthetic matching private key; rejects certificate-only, wrong alias/certificate/store password/key password. Verifier requires pinned alias, `PrivateKeyEntry` and private-key signing with env-only passwords. | **Tool PASS; PENDING owner:** verify the actual off-laptop copy and record only the result/certificate fingerprint, never secrets. |
| CI prod APK installs and updates with data intact; laptop `/v1/config` reachable | T18 in `test_android_ci.py` pins flavor selection, upload eligibility and annotations. T19 reopens populated DB and runs newer-pack bootstrap. Runbook: `docs/runbooks/install-a-build.md`. | **Host PASS; PENDING Claude/owner:** prod build and packaged checks, CI artifact, A55 install/update over existing app, diary retention and `/v1/config`. Earlier laptop build failed before an APK; this continuation ran no Gradle. |
| A55 test crash reaches Sentry without user content, device name or IP | T11–T15/T26 in `test/core/errors`, config tests from WP2, plus envelope-sink self-test (5 cases). Native capture options/NDK metadata and serialized canary scrubbing are pinned. | **Host PASS; PENDING Claude/owner:** emulator envelope-sink proof (handled/unhandled, native crash and relaunch counts), then real EU DSN event and A55 test-crash inspection. No real DSN/event or native-delivery proof claimed. |
| Dogfood 1 daily food logging on prod | Implementation and install/export/crash-report runbooks are available. | **PENDING owner:** daily prod use confirmation. M1 is not claimed. |

All five combined card exit criteria remain unchecked. CI on the **merge commit** is the full-suite gate; no full `make test-dart`, Docker, Gradle, emulator, A55 or paid/live-service run was performed here.

## Review findings → evidence → disposition

Independent code review: **2 major + 2 minor**. Separate security review: **1 major**. UX review: **1 major + 7 minor**. All are fixed or explicitly recorded below; this continuation is a builder verification, not a fresh independent approval.

| Finding | Evidence on disk | Disposition |
|---|---|---|
| Code major: leading whitespace bypasses CSV formula guard | T6 `AC-030 CSV formula guard prefixes = + - @ tab CR text cells only`: space/tab/CR/LF combinations, NBSP, Unicode whitespace, BOM, zero-width/control prefixes; numeric negatives and already-prefixed `'=1` unchanged. | Fixed in WIP; focused PASS. |
| Code major: public certificate accepted as signing-key backup | T17 bash self-test rejects certificate-only, wrong alias and unrecoverable private key; positive case signs a CSR. | Fixed in WIP; self-test PASS. |
| Code minor: overlapping export falsely cancelled | `AC-030 overlapping preparation reports busy, never dismissed`; `AC-030 close and reopen during preparation skips sharing; retry succeeds` uses real rows and reaches the fake sharer with 9 files. | Fixed in WIP; focused PASS. |
| Code minor: prod signing annotation reports staging failure | T18 `test_AT_006_signing_annotations_use_flavor_and_upload_eligibility` exercises signed prod main/merge, staging and unsigned prod. | Fixed in WIP; Python PASS. |
| Security major: raw backup carries historical install identity | XML, format doc, runbook and card disclose historical install IDs and sync bookkeeping under owner-approved Q2; active preferences/credentials excluded. `AT-006 restored DB uses fresh active ID, advances HLC and preserves historical outbox` copies a real DB, uses fresh preferences and a clock behind restored HLC, checks new authorship/HLC and unchanged historical rows/outbox tuples. | Approved-policy alternative implemented. Continuation first reproduced `Bad state: No element`: fixture inserted `new-setting` but queried a natural ID. Corrected fixture now passes. No sync transport run claimed; A34 owns it. |
| UX major: large-text export actions below fold | Optional `FbSheet.actions`/`showFbSheet.actionsBuilder`; `UX-070 export sheet actions stay inside 320x640 viewport at 2.0` plus idle/working/shared/dismissed rectangle checks. Export goldens use height 900. | Fixed in WIP; widget and golden comparisons PASS. |
| UX minor 2: duplicate failure retry | Failure has one banner retry; widget test checks the action. | Fixed; optional storage-specific copy recorded as follow-up. |
| UX minor 3: share opens after back-out | Pop/disposal abandons preparation; close/reopen regression checks no share, file deletion and successful later retry. | Fixed; focused PASS. |
| UX minor 4: privacy wording | ARB says Fitness Buddy uploads nothing, files are unencrypted/readable by the selected app, deleted items/Buddy chats omitted, phone identifiers omitted from exports. | Fixed; backup/export distinction documented. |
| C5 re-check NEW MAJOR (supersedes UX minor 5): premature plugin-copy deletion | Failing-first `AC-030 receiver reads shared copies after share returns`; age-boundary/next-export, bounded/link-safe, no-throw/timeout and post-frame startup isolation regressions. | Fixed: only preparation originals are removed on handoff/failure/abandonment. Unencrypted handoff copies remain; a best-effort sweep removes regular files older than 24 hours, at next export and post-frame startup (256 entries/two seconds). Age is not a deletion deadline; closed app, errors or budget exhaustion can retain copies longer. Format doc and runbook disclose this. |
| UX minor 6: unavailable share result overclaims success | ARB uses “Handed to the share sheet” with counts; OS handoff is distinguished from delivery. | Fixed; real Android cancellation/share targets PENDING owner. |
| UX minor 7: inaccessible/narrow About gesture | `PR-11 About version exposes a full-width semantic long press` checks semantic action and hit area. | Fixed; focused PASS. |
| UX minor 8: report says sent rather than queued | ARB says “Test report queued” and discloses app/device information with no diary/personal content; About tests exercise confirm/cancel/off states. | Fixed; real event PENDING. |

WIP goldens changed only `about.png`, `export_sheet.png`, `export_sheet_failed.png` (CI variants, light/dark × 1.0/2.0). This continuation re-recorded none. Changed-copy grep in `apps/mobile/patrol_test/` found no matching old export/report text requiring an update.

## Plan review PA1–PA11

| Amendment | Evidence / status |
|---|---|
| PA1 read-only transaction/layers | `core/db/export_snapshot.dart`, T8 and app-check; PASS. |
| PA2 derived setting keys | `AppSettings.all` supplied by controller, T3; PASS. |
| PA3 errors-only Sentry policy | `09` §5 amendment and TD candidate (b) recorded; no sessions, performance deferred to A42. |
| PA4 handled + unhandled test reports | T12/T15 and `FlutterErrorDetails` canary; host PASS, device delivery PENDING. |
| PA5 database-only encrypted-capability backups | Exact file paths and exclusions pinned by hardening fixtures (26 total); raw historical identifiers disclosed. Device restore PENDING. |
| PA6 tags allow-list/debug off | T11/T12 serialized scrubber/SDK option tests; PASS. |
| PA7 route-template breadcrumbs | WP0 corrected the plan's per-branch observer proposal: one root observer sees shell branches, avoids duplicates. T13 includes real-ID/template and shell-branch checks; PASS. |
| PA8 deleted/inactive parent names | Export snapshot lookups and T3; PASS. |
| PA9 no password argv | T17 env-only keytool wrapper assertions; PASS. |
| PA10 proof before real DSN; explicit CI wiring | Named Python/bash tests wired into `ci.yml`; host PASS. Emulator proof and adding real DSN remain PENDING in that order. |
| PA11 key-only validation diagnostics | T16 and T26; recorded WP2/WP3 evidence plus build self-test PASS. |

## Fix round 2 gates (C5)

- Failing first: delayed receiver read after `share()` returned threw `PathNotFoundException` with the old cleanup; the corrected test passes.
- `make check-dart`: **PASS** after correcting new lint findings. No generated input/annotation/ARB/schema changed, so `make gen-app` was unnecessary (the new cleanup provider is declared directly).
- Pinned `flutter test --no-pub --concurrency=1 test/core/export test/features/settings test/app/session_bootstrap_test.dart --reporter expanded`: **101 PASS**, including unchanged settings goldens, T6 apostrophe idempotence, delayed receipt, age boundary, sweep bounds/link safety/errors/timeout and startup isolation.
- `make trace`: **PASS**, R1 **124/319**, existing `ZZ-060` fixture warning. `git diff --check`: **PASS**.
- ARB privacy copy makes no immediate-deletion promise; Patrol grep found no affected expectation. Neither changed. No git writes, Gradle, full test-dart, backlog/board edit or device/live-service run.

## Fix round 1 gates

- Focused pinned-Flutter run: `flutter test --concurrency=1 test/core/db/backup_restore_test.dart test/core/export test/core/errors test/features/settings --reporter expanded`: **101 passed**, including settings goldens. Initial concurrent run exposed the fixture bug and the existing LC-033 timing test exceeded 5 ms under load; serial rerun passed without changing its threshold/code.
- `make check-dart`: **PASS on retry** (format, analyzer, app-check, frozen migrations and 4 OFF self-tests). First attempt: analysis server crashed without diagnostics; no source change for the retry.
- Bash syntax; `build-android-selftest.sh`; `verify-key-backup-selftest.sh`: **PASS**. Python `test_android_ci.py` **2 passed**, `test_sentry_envelope_sink.py` **5 passed**, `test_session_release_check.py` **3 passed**.
- `make apk-hardening-selftest`: **26 cases PASS**. This is fixture evidence, not an inspection of a newly built prod APK.
- `make trace`: **PASS**, R1 **124/319** covered; existing synthetic `ZZ-060` scanner-fixture warning.
- `git diff --check`: **PASS**. No ARB/provider/schema change in this continuation, so `make gen-app` was not needed (WIP generation recorded in the Progress log).

## Follow-ups and limits

Owner/Claude pending checks and proposed backlog wording are in the card's Progress log; `backlog.md` and the board were not edited. Include Gmail/Drive/Sheets multi-file opening after cache cleanup, largest font, prod About long-press/report, update retention, actual key backup and device backup/restore. Unencrypted handoff copies deliberately survive chooser return and are eligible for sweeping after 24 hours on next export/post-frame startup. Cleanup is bounded and best effort; copies may remain longer while closed or on failure/budget exhaustion. Preparation originals interrupted by process death remain until the next export. share_plus itself clears its cache at the next share; finish receiving before exporting again. Storage-specific retry wording is optional future work. Historical outbox tuples are preserved, but end-to-end restored-outbox transport belongs to A34.
