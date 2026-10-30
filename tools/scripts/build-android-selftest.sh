#!/usr/bin/env bash
# A11 T16, A50 T11: fake Flutter inspects the private file; no toolchain or
# secrets needed. FB_GOOGLE_CLIENTS_FILE always points at a fixture, so the
# laptop's real B04 file is never read.
set -euo pipefail
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
work="$(mktemp -d)"
trap 'rm -rf -- "$work"' EXIT
mkdir -p "$work/repo/apps/mobile/config" "$work/repo/tools" "$work/jdk/bin" "$work/sdk/build-tools" "$work/tmp"
ln -s "$root/tools/scripts" "$work/repo/tools/scripts"
cp "$root/apps/mobile/config/"*.json "$work/repo/apps/mobile/config/"
version="$(sed -n 's/^build-tools;\([^|]*\)|.*/\1/p' "$root/tools/scripts/android-sdk-packages.txt")"
mkdir "$work/sdk/build-tools/$version"
printf '#!/bin/sh\nexit 0\n' >"$work/jdk/bin/java"
cp "$work/jdk/bin/java" "$work/sdk/build-tools/$version/aapt2"
printf '#!/bin/sh\necho "Signer #1 certificate SHA-256 digest: fake"\n' >"$work/sdk/build-tools/$version/apksigner"
cat >"$work/flutter" <<'PY'
#!/usr/bin/env python3
import json, os, pathlib, sys
arg = next(a for a in sys.argv if a.startswith('--dart-define-from-file='))
p = pathlib.Path(arg.split('=', 1)[1])
pathlib.Path(os.environ['PROBE']).write_text(str(p.resolve()))
v = json.loads(p.read_text())
flavor = sys.argv[sys.argv.index('--flavor')+1]
assert v['FB_FLAVOR'] == flavor
if flavor != 'dev':
    assert p.stat().st_mode & 0o777 == 0o600
    for key in ('FB_API_BASE_URL', 'FB_SENTRY_DSN'):
        if os.environ.get(key):
            assert v[key] == os.environ[key]
if os.environ.get('GOOGLE_PROBE'):
    pathlib.Path(os.environ['GOOGLE_PROBE']).write_text(v['FB_GOOGLE_SERVER_CLIENT_ID'])
if os.environ.get('FAIL_FLUTTER'):
    sys.exit(42)
out = pathlib.Path('build/app/outputs/flutter-apk')
out.mkdir(parents=True, exist_ok=True)
(out / f'app-{flavor}-debug.apk').touch()
PY
chmod +x "$work/flutter" "$work/jdk/bin/java" "$work/sdk/build-tools/$version/"*
export FLUTTER="$work/flutter" REPO_ROOT="$work/repo" JAVA_HOME="$work/jdk" ANDROID_HOME="$work/sdk" MODE=debug FB_RELEASE_ENV= TMPDIR="$work/tmp" PROBE="$work/probe"
export FB_API_BASE_URL=https://fake-api.invalid FB_SENTRY_DSN=https://FAKE123@o0.ingest.de.sentry.io/0
export FB_GOOGLE_CLIENTS_FILE="$work/no-google-clients.json"
unset FB_GOOGLE_SERVER_CLIENT_ID FB_KEYSTORE_PATH
run() { bash "$root/tools/scripts/build-android.sh" >"$work/output" 2>&1; }
for FLAVOR in staging prod; do
  export FLAVOR
  run
  [[ ! -e "$(cat "$PROBE")" ]]
  if FAIL_FLUTTER=1 run; then exit 1; fi
  [[ ! -e "$(cat "$PROBE")" ]]
done
for key in FB_API_BASE_URL FB_SENTRY_DSN; do
  original="${!key}"
  for bad in 'SYNTHETIC_SECRET_CANARY' 'http://fake.invalid' 'https://fake.invalid/path?secret=CANARY'; do
    export "$key=$bad"
    if run; then echo 'build-android-selftest: invalid override accepted' >&2; exit 1; fi
    grep -q "$key" "$work/output"
    if grep -qF "$bad" "$work/output"; then echo 'build-android-selftest: value leaked' >&2; exit 1; fi
    [[ -z "$(find "$work/tmp" -type f -print -quit)" ]]
  done
  export "$key=$original"
done
# Actions forks: empty secrets fall back to committed config. Dev ignores overrides.
FB_API_BASE_URL= FB_SENTRY_DSN= run
FLAVOR=dev FB_API_BASE_URL=SYNTHETIC_SECRET_CANARY FB_SENTRY_DSN=SYNTHETIC_SECRET_CANARY run

# A50 T11: the Google web client ID only reaches staging/prod release builds
# signed with the release key. The fake Flutter fails on purpose after it
# recorded the merged value (the release checks need a real APK).
mkdir -p "$work/repo/apps/mobile/assets/catalog"
echo '{"includes_drafts": false}' >"$work/repo/apps/mobile/assets/catalog/catalog_manifest.json"
env_id='111111111111-selftestenvcanary.apps.googleusercontent.com'
file_id='222222222222-selftestfilecanary.apps.googleusercontent.com'
clients="$work/google-clients.json"
printf '{"AndroidClientId": "333333333333-android.apps.googleusercontent.com", "WebClientId": "%s"}' "$file_id" >"$clients"
export GOOGLE_PROBE="$work/google-probe"
# google <expected> <env...>: runs a build that reaches Flutter, checks the ID.
google() {
  local expected="$1"
  shift
  rm -f -- "$GOOGLE_PROBE"
  if env FAIL_FLUTTER=1 "$@" bash "$root/tools/scripts/build-android.sh" >"$work/output" 2>&1; then exit 1; fi
  [[ -f "$GOOGLE_PROBE" ]] || { cat "$work/output" >&2; echo 'build-android-selftest: Flutter not reached' >&2; exit 1; }
  [[ "$(cat "$GOOGLE_PROBE")" == "$expected" ]] || { echo "build-android-selftest: wrong Google ID (expected ${expected:+an ID}${expected:-none})" >&2; exit 1; }
  if grep -qF -e "$env_id" -e "$file_id" "$work/output"; then echo 'build-android-selftest: Google ID leaked' >&2; exit 1; fi
  [[ -z "$(find "$work/tmp" -type f -print -quit)" ]]
}
release_key=(MODE=release FB_KEYSTORE_PATH="$work/fake.jks")
for FLAVOR in staging prod; do
  export FLAVOR
  google "$env_id" "${release_key[@]}" FB_GOOGLE_SERVER_CLIENT_ID="$env_id" FB_GOOGLE_CLIENTS_FILE="$clients"
  google "$file_id" "${release_key[@]}" FB_GOOGLE_SERVER_CLIENT_ID= FB_GOOGLE_CLIENTS_FILE="$clients"
  google '' "${release_key[@]}"
  # Debug mode and a debug-key release build never get it (PA2).
  google '' MODE=debug FB_GOOGLE_SERVER_CLIENT_ID="$env_id" FB_GOOGLE_CLIENTS_FILE="$clients"
  google '' MODE=release FB_GOOGLE_SERVER_CLIENT_ID="$env_id" FB_GOOGLE_CLIENTS_FILE="$clients"
done
FLAVOR=dev google '' "${release_key[@]}" FB_GOOGLE_SERVER_CLIENT_ID="$env_id" FB_GOOGLE_CLIENTS_FILE="$clients"
# A malformed ID (environment or file) fails the build and is never printed.
bad='SYNTHETIC_GOOGLE_CANARY'
printf '{"WebClientId": "%s"}' "$bad" >"$work/bad-clients.json"
for source in "FB_GOOGLE_SERVER_CLIENT_ID=$bad" "FB_GOOGLE_CLIENTS_FILE=$work/bad-clients.json"; do
  rm -f -- "$GOOGLE_PROBE"
  if env FLAVOR=prod "${release_key[@]}" "$source" bash "$root/tools/scripts/build-android.sh" >"$work/output" 2>&1; then exit 1; fi
  [[ ! -e "$GOOGLE_PROBE" ]]
  grep -q FB_GOOGLE_SERVER_CLIENT_ID "$work/output"
  if grep -qF "$bad" "$work/output"; then echo 'build-android-selftest: value leaked' >&2; exit 1; fi
  [[ -z "$(find "$work/tmp" -type f -print -quit)" ]]
done
echo 'build-android-selftest: PASS (merge, validation, privacy, cleanup, forks, dev, Google ID only with the release key)'
