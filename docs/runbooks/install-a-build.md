# Install or update the daily app (A11)

The daily app is **prod**, package `io.github.abdelrahmanhamza1.fitnessbuddy`.
Staging is a separate app (`.staging`): its data does not move into prod.
Before logging real data, verify the off-laptop release-key backup using
[android-signing.md](android-signing.md#2-back-it-up-in-the-password-manager-owner-3-min).

On the A55, open GitHub in Chrome, sign in, open this repository → Actions →
a successful **CI run on main** → `app-prod-release.apk`. Download the APK
(the artifact is unzipped), open it, allow Chrome to install unknown apps when
prompted, and choose **Install/Update over the existing app**. Never uninstall
or clear storage to update. Builds last 30 days; a weekly main run refreshes them.
Step branches build staging; merge branches build prod for verification without
publishing it. Fork builds have no secrets and use a debug key; never install a
`*-debugkey.apk` as the daily build.

Before an update, export your data and keep the files outside the app. Note the
About build number and a few diary/food/meal counts. Install a newer main APK;
confirm the build number increased and the same diary, foods, meals and settings
remain. This A55 check is the real update proof; host tests also reopen every
table and run startup with a newer catalog pack. If Android reports a signature
conflict, stop: check the artifact and certificate using the signing runbook.
Do not uninstall to bypass it. A version downgrade needs a newer CI run.

With the laptop server on and Tailscale connected, launch prod and ask Claude
to confirm a `GET /v1/config` 200 in the laptop API log (no content/URL in evidence).
The app remains usable offline when the server is off.

## Android backup and exports

Exports are unencrypted. Preparation originals in private `export/` are removed
after handoff (also on failure/abandonment); handed-off `cache/share_plus/` copies
remain available for delayed receivers. A best-effort sweep removes files older
than 24 hours before the next export and after the first frame on app start
(at most 256 entries/two seconds; errors discarded without content). Copies may
stay longer while the app is closed or cleanup fails/reaches its budget.
share_plus clears its own cache at the next share, so let the receiver finish
before exporting again. Share targets can keep their own copies indefinitely.

Android 12+ includes **only** `files/profiles/local/user.db`, `user.db-wal`
and `user.db-shm` in encrypted device transfer and cloud backup when end-to-end
encryption capability is available. Set a device PIN/password/pattern and enable
backup. The raw database includes historical install IDs in row authorship/HLCs
and sync bookkeeping (including pending outbox rows). The owner approved retaining
these in encrypted backups (A11 Q2). Active install-id preferences, session
credentials, catalog packs and future photos stay outside this include-only allow-list; redundant excludes are rejected by lint
and the packaged policy check. Android 8–11 and cross-platform transfer exclude all data.
New account/profile paths require a separately reviewed rule at A33.

Cloud backup has a **25 MB per-app quota**: exceeding it stops cloud backups
without an app warning. The database plus WAL count toward the quota. Keep
regular exports off the phone; backup is not a guaranteed current copy. A42 (or
the first database approaching 15 MB) must check size and notify the owner.
Android restores during device setup/installation, not as an in-app import.
A new install creates a fresh active ID from excluded preferences; new writes
use that ID and advance past the restored HLC. Existing row authorship and pending
outbox HLCs remain unchanged for later sync (A34).
Export import is not implemented. See [Android Auto Backup](https://developer.android.com/identity/data/autobackup).
