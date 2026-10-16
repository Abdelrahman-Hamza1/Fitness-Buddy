# Runbook: Android release signing

**What:** the one stable key that signs every installable Fitness Buddy build (S06 plan D4, A6; owner decision 2026-10-15).
**Why it matters:** Android only installs an update over an existing app if both are signed with the same certificate. A build signed with another key (a debug key, a new key) can't update the installed app. The only way forward is to uninstall it, and that **deletes the app's local-first data on the phone**. So the key is generated once, backed up, and never replaced.

| Item | Value |
|---|---|
| Keystore | `~/.fitness-buddy/keys/fitnessbuddy-release.jks` (PKCS12, RSA 4096, valid until 2056-10-07) |
| Alias | `fitnessbuddy` |
| Passwords | `~/.fitness-buddy/keys/release.env` (one random password for both the keystore and the key: PKCS12 has no separate key password) |
| Certificate SHA-256 (public) | `A0:E7:9C:3D:A2:9F:F7:FA:56:CE:DD:6E:FF:A8:F3:99:6B:95:6D:37:89:E1:C1:15:46:A0:29:7C:F3:86:52:26` |
| Pinned in | `tools/scripts/build-android.sh` (`RELEASE_CERT_SHA256`): a build signed with any other key fails |
| Used by | `make build-android` (laptop, reads `release.env`), the CI job `android` (3 GitHub Actions secrets; the alias is set in `.github/workflows/ci.yml`) |

**Builds without the key** (forks, Dependabot, a laptop without `release.env`): `make build-android` signs them with the machine's debug key and names them `*-debugkey.apk` / `*-debugkey.aab`. They install on a phone without the app, but can't update a real install, so never hand one out. Gradle refuses a release build without the key unless `FB_ALLOW_DEBUG_SIGNING=1`, which only `tools/scripts/build-android.sh` sets: a plain `flutter build apk --release` fails instead of producing a debug-signed `app-staging-release.apk`.

Both files are `chmod 600` in a `chmod 700` directory, outside the repo. `.gitignore` also blocks `*.jks`, `*.keystore`, `key.properties`, `release.env` and `*.jks.base64` anywhere in the repo.

## 1. Generate the key (done once, 2026-10-15)

```bash
JAVA_HOME=~/development/jdk-21.0.12.1+1 tools/scripts/android-release-key.sh
```

It refuses to run if either file exists. It prints only the certificate SHA-256. If you ever need a new key (see section 6), put the new fingerprint in `RELEASE_CERT_SHA256` and in the table above.

## 2. Back it up in the password manager (owner, ~3 min)

Losing the key is the same as losing the phone's data on the next install. Keep a copy off the laptop:

1. In the password manager, create an item "Fitness Buddy Android release key".
2. Attach the file `~/.fitness-buddy/keys/fitnessbuddy-release.jks` to the item.
3. Paste the whole content of `~/.fitness-buddy/keys/release.env` into the item's notes. Open it with a text editor (`gedit ~/.fitness-buddy/keys/release.env`) and don't paste it anywhere else.
4. Save the item. Check that the attachment opens.

To restore on a new laptop: put both files back in `~/.fitness-buddy/keys/`, fix the `FB_KEYSTORE_PATH=` line if your home directory differs, then run `chmod 700 ~/.fitness-buddy/keys` and `chmod 600 ~/.fitness-buddy/keys/*`.

## 3. Put the 3 secrets in GitHub (owner, ~5 min, on the laptop)

GitHub repo → **Settings** → **Secrets and variables** → **Actions** → **Repository secrets** → **New repository secret**. Create these three. Names must match exactly.

| Secret name | Value |
|---|---|
| `FB_ANDROID_KEYSTORE_BASE64` | The keystore as one line of base64. Run `base64 -w0 ~/.fitness-buddy/keys/fitnessbuddy-release.jks > ~/.fitness-buddy/keys/fitnessbuddy-release.jks.base64`, open that file in a text editor, select all, copy, paste. Then delete it: `shred -u ~/.fitness-buddy/keys/fitnessbuddy-release.jks.base64` |
| `FB_ANDROID_KEYSTORE_PASSWORD` | The text after `FB_ANDROID_KEYSTORE_PASSWORD=` in `release.env` |
| `FB_ANDROID_KEY_PASSWORD` | The text after `FB_ANDROID_KEY_PASSWORD=` in `release.env` (the same password) |

Paste without a trailing space or newline. GitHub never shows a secret again; to change one, overwrite it.

The alias (`fitnessbuddy`) is not a secret: the workflow sets it directly. As a secret, GitHub would mask the word "fitnessbuddy" (and so the application id) in every CI log. If an older `FB_ANDROID_KEY_ALIAS` secret exists, you may delete it; it is harmless if left, as nothing reads it.

**Who can use them:** only workflow runs from branches of this repository. Pull requests from forks and Dependabot don't get Actions secrets, so their builds are debug-signed (`*-debugkey.apk`) and are never uploaded as the owner's build. The workflow keeps `permissions: contents: read` and never prints a secret. The CI job writes the keystore to `$RUNNER_TEMP` and deletes it in an `if: always()` step (S06 plan A6).

Rules that keep it that way:
- **Never copy an `FB_*` value into Dependabot secrets** (Settings → Secrets → Dependabot). Dependabot PRs run code from dependency updates; they must stay debug-signed.
- **Nothing built into the APK is secret.** The repo is public and anyone can unpack an APK: `apps/mobile/config/*.json` (passed with `--dart-define-from-file`) and everything else compiled in may hold public values (an API URL, a Sentry DSN), never API keys, tokens or passwords.
- **Before any collaborator gets write access** (R2 or later): repository secrets reach every workflow run on any branch a writer pushes. Move the three secrets into a GitHub **Environment** (for example `android-release`) whose deployment branch policy allows only protected branches (`main`), optionally with the owner as required reviewer, and set `environment: android-release` on the `android` job. Step branches then build debug-signed; that is the trade-off.

## 4. Check a build

Laptop:

```bash
make build-android              # staging; reads ~/.fitness-buddy/keys/release.env
# → "signed with the release key", then the APK and AAB with "cert SHA-256 a0e79c3d…"
~/development/android-sdk/build-tools/36.0.0/apksigner verify --print-certs \
  apps/mobile/build/app/outputs/flutter-apk/app-staging-release.apk
make build-android FB_RELEASE_ENV=   # ignore the key: *-debugkey.apk / *-debugkey.aab
```

CI: the `android` job summary shows the APK's SHA-256. The signed APK is uploaded only when it was signed with this key.

## 5. Google Play (S29)

Not decided yet. This key is pinned in `build-android.sh` and is the certificate every installed build carries, so it stays the app's signing key. At S29, decide between:

- **Keep sideloading** the builds signed with this key (no Play), or
- **Play with Play App Signing**, enrolling **this key as the app signing key** ("Use existing app signing key from Java keystore", uploaded with Google's PEPK tool), so Play's builds update the sideloaded installs in place. Play then also wants an **upload key**: either a new one (the CI secrets would sign uploads with it, and the pin would have to cover two certificates) or this key itself.

Record the choice in S29's card and update this runbook and the pin.

## 6. If something goes wrong

- **Lost key (no backup):** no build can update the installed app again. Generate a new key (section 1), update `RELEASE_CERT_SHA256`, and replace the secrets. Every phone must export its data, uninstall, then install the new build.
- **Leaked key or password:** anyone with it can sign an "update" that installs over the real app. Tell the owner (it is a security incident). Then do the same as for a lost key, and delete the old secrets. If Play App Signing is in use by then (section 5), Google holds the app signing key: a leaked upload key is reset in Play Console, but the sideloaded installs, signed with this key, still need the new-key procedure above.
- **CI build fails with "signed with certificate …, not the Fitness Buddy release key":** the secrets hold another keystore. Redo section 3 from the backup.
- **CI build is `*-debugkey.apk` on a branch of this repo:** a secret is missing or misnamed. Check the three names in section 3.
- **`flutter build apk --release` fails with "Release build without the release key":** build with `make build-android` (it reads `release.env`), or export the signing variables. Don't set `FB_ALLOW_DEBUG_SIGNING=1` for a build you mean to install.
