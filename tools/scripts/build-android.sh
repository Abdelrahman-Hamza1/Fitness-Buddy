#!/usr/bin/env bash
# Builds the Android app for one flavor and checks what was built (S06 plan D7,
# A6, A8). Called by `make build-android`, which passes everything through the
# environment:
#   FLUTTER, REPO_ROOT, JAVA_HOME, ANDROID_HOME   toolchain (Makefile)
#   FLAVOR        dev | staging | prod            (default staging)
#   MODE          release | debug                 (default release)
#   BUILD_NUMBER  versionCode; empty = pubspec's  (CI: the run number)
#   FB_API_BASE_URL, FB_SENTRY_DSN  private environment overrides (staging/prod)
#   FB_GOOGLE_SERVER_CLIENT_ID  Google web client ID (A50 D4), else WebClientId
#                 from FB_GOOGLE_CLIENTS_FILE (default ~/.local/share/
#                 fitness-buddy/identity/google-clients.json). Compiled in only
#                 for staging/prod release builds signed with the release key;
#                 every other build gets "" (Google sign-in hidden).
#   FB_RELEASE_ENV  file with the release signing variables (default
#                 ~/.fitness-buddy/keys/release.env; empty = don't read one)
#   FB_BUILD_AAB  1 (default) builds the AAB too; 0 builds the APK only. CI
#                 sets 0 on step and merge branches: the AAB compiles every ABI
#                 and is only needed for Play (TD-086); main and nightly build it.
#
# release: an arm64 APK for the phone + an AAB (all ABIs, for Play from A43).
#   - hardening: tools/scripts/apk_hardening_check.py on the built APK (not
#     debuggable, no cleartext, system CAs only). A failing build's outputs are
#     deleted.
#   - catalog (A05 D8): the bundled pack (assets/catalog/catalog_manifest.json,
#     made by `make catalog-pack`) must not include drafts; else the build stops.
#   - signing: with FB_KEYSTORE_PATH + FB_ANDROID_KEYSTORE_PASSWORD,
#     FB_ANDROID_KEY_ALIAS, FB_ANDROID_KEY_PASSWORD in the environment (CI) or
#     in FB_RELEASE_ENV (laptop), the outputs must carry the pinned certificate
#     below. Without them: debug-key outputs renamed *-debugkey.* (why:
#     docs/runbooks/android-signing.md).
# debug: an arm64 debug APK only (no checks: debug builds are debuggable).
#
# Always stops the Gradle daemons at the end: the laptop has 7 GB of RAM.
set -euo pipefail

# SHA-256 of the release certificate (docs/runbooks/android-signing.md). Public:
# anyone can read it from an APK. A build signed with any other key fails, so a
# wrong keystore in the CI secrets can't produce an APK that won't update.
readonly RELEASE_CERT_SHA256="a0e79c3da29ff7fa56cedd6effa8f3996b956d3789e1c11546a0297cf3865226"
# aapt2 and apksigner come from the pinned build-tools (android-sdk-packages.txt).
BUILD_TOOLS_VERSION="$(sed -n 's/^build-tools;\([^|]*\)|.*/\1/p' "$(dirname "${BASH_SOURCE[0]}")/android-sdk-packages.txt")"
readonly BUILD_TOOLS_VERSION
readonly SIGNING_VARS=(FB_KEYSTORE_PATH FB_ANDROID_KEYSTORE_PASSWORD FB_ANDROID_KEY_ALIAS FB_ANDROID_KEY_PASSWORD)

log() { printf 'build-android: %s\n' "$*"; }
warn() { printf 'build-android: WARNING: %s\n' "$*" >&2; }
die() { printf 'build-android: error: %s\n' "$*" >&2; exit 1; }

: "${FLUTTER:?}" "${REPO_ROOT:?}" "${JAVA_HOME:?}" "${ANDROID_HOME:?}"
FLAVOR="${FLAVOR:-staging}"
MODE="${MODE:-release}"
BUILD_NUMBER="${BUILD_NUMBER:-}"
FB_RELEASE_ENV="${FB_RELEASE_ENV-$HOME/.fitness-buddy/keys/release.env}"

app="$REPO_ROOT/apps/mobile"
build_tools="$ANDROID_HOME/build-tools/$BUILD_TOOLS_VERSION"
# apksigner is a shell wrapper that runs `java` from PATH: make it the pinned JDK.
export PATH="$JAVA_HOME/bin:$PATH"

case "$FLAVOR" in dev | staging | prod) ;; *) die "FLAVOR must be dev, staging or prod (got '$FLAVOR')" ;; esac
case "$MODE" in release | debug) ;; *) die "MODE must be release or debug (got '$MODE')" ;; esac
[[ -z "$BUILD_NUMBER" || "$BUILD_NUMBER" =~ ^[1-9][0-9]{0,8}$ ]] \
  || die "BUILD_NUMBER must be a positive integer (got '$BUILD_NUMBER')"
[[ -x "$JAVA_HOME/bin/java" ]] || die "no JDK at JAVA_HOME=$JAVA_HOME (run: make toolchain-android)"
[[ -x "$build_tools/aapt2" && -x "$build_tools/apksigner" ]] \
  || die "build-tools $BUILD_TOOLS_VERSION missing in ANDROID_HOME=$ANDROID_HOME (run: make toolchain-android)"
[[ -f "$app/config/$FLAVOR.json" ]] || die "missing $app/config/$FLAVOR.json"

# --- Release signing variables -----------------------------------------------
# Sets them from FB_RELEASE_ENV unless the environment has them (CI). Only the
# four known names are read; the file is never sourced (it's data, not code).
load_release_env() {
  if [[ -n "${FB_KEYSTORE_PATH:-}" ]]; then
    log "release key: from the environment"
    return
  fi
  if [[ -z "$FB_RELEASE_ENV" || ! -f "$FB_RELEASE_ENV" ]]; then
    return
  fi
  local mode
  mode="$(stat -c '%a' "$FB_RELEASE_ENV")"
  [[ "$mode" == 600 || "$mode" == 400 ]] \
    || die "$FB_RELEASE_ENV is readable by others (mode $mode): chmod 600 it"
  local line name value
  while IFS= read -r line || [[ -n "$line" ]]; do
    [[ "$line" =~ ^[[:space:]]*(#|$) ]] && continue
    [[ "$line" =~ ^([A-Z_]+)=(.*)$ ]] || die "$FB_RELEASE_ENV: unexpected line (not NAME=value)"
    name="${BASH_REMATCH[1]}" value="${BASH_REMATCH[2]}"
    case " ${SIGNING_VARS[*]} " in
      *" $name "*) export "$name=$value" ;;
      *) die "$FB_RELEASE_ENV: unknown variable $name" ;;
    esac
  done <"$FB_RELEASE_ENV"
  log "release key: from $FB_RELEASE_ENV"
}

defines_file=""
cleanup() {
  [[ -z "$defines_file" ]] || rm -f -- "$defines_file"
  stop_gradle
}

stop_gradle() {
  if [[ -x "$app/android/gradlew" ]]; then
    (cd "$app/android" && ./gradlew --stop -q >/dev/null 2>&1) || true
  fi
}

# --- Checks on the built APK ---------------------------------------------------
# check_hardening <apk> <outputs to delete on failure...>
check_hardening() {
  local apk="$1"
  log "checking $(basename "$apk"): release hardening ($FLAVOR)"
  if ! python3 -I "$REPO_ROOT/tools/scripts/apk_hardening_check.py" \
    --flavor "$FLAVOR" --aapt2 "$build_tools/aapt2" "$apk"; then
    # A failing build must not be left behind looking like a good one.
    rm -f -- "$@" "$apk.sha1"
    die "$(basename "$apk") failed the hardening check (see above; outputs deleted). Release builds must be HTTPS only and not debuggable (S06 plan A8)"
  fi
}

# Prints the SHA-256 (lowercase hex) of the APK's or AAB's signing certificate.
apk_cert_sha256() {
  "$build_tools/apksigner" verify --print-certs "$1" \
    | sed -n 's/^Signer #1 certificate SHA-256 digest: //p'
}
# Verifies the AAB's JAR signature (every entry signed, digests match), then
# prints its certificate's SHA-256. jarsigner -strict exits with a bitmask: 4
# (chain not validated: self-signed, but also an expired or not-yet-valid cert)
# is always set for an app signing key and is accepted (the pin checks the
# certificate, and its validity runs to 2056); 1 (digest/signature failure), 8 (key
# usage), 16 (unsigned entries), 32 (alias) fail. An unsigned jar exits 0, hence
# the "jar verified" check.
aab_cert_sha256() {
  local out rc=0
  out="$("$JAVA_HOME/bin/jarsigner" -verify -strict "$1" 2>&1)" || rc=$?
  if [[ $rc -ne 0 && $rc -ne 4 ]] || ! grep -q '^jar verified' <<<"$out"; then
    grep -v 'is signed in JarFile but is not signed in JarInputStream' <<<"$out" | head -n 20 >&2
    die "$(basename "$1"): jarsigner -verify -strict failed (exit $rc)"
  fi
  "$JAVA_HOME/bin/keytool" -printcert -jarfile "$1" 2>/dev/null \
    | sed -n 's/^[[:space:]]*SHA256: //p' | head -n 1 | tr -d ':' | tr 'A-F' 'a-f'
}

describe() {
  local file="$1" cert="$2"
  printf '  %s (%s)\n' "apps/mobile/${file#"$app/"}" "$(du -h "$file" | cut -f1)"
  printf '    sha256 %s\n    signer certificate SHA-256 %s\n' "$(sha256sum "$file" | cut -d' ' -f1)" "$cert"
}

# A05 D8: a release must not ship draft catalog entries (`make catalog
# CATALOG_DRAFTS=1` is a dev-only pack). Checked before the long Gradle build.
check_catalog_pack() {
  local manifest="$app/assets/catalog/catalog_manifest.json"
  [[ -f "$manifest" ]] || die "no bundled catalog pack ($manifest): run 'make catalog-pack'"
  local drafts
  drafts="$(python3 -I -c 'import json,sys; print(json.load(open(sys.argv[1])).get("includes_drafts"))' "$manifest")" \
    || die "cannot read $manifest"
  [[ "$drafts" == False ]] \
    || die "the bundled catalog pack includes drafts (includes_drafts=$drafts in $manifest): rebuild it with 'make catalog-pack' (no CATALOG_DRAFTS) before a release build"
  log "catalog pack: no drafts"
}

# Writes the staging/prod defines (private overrides merged, A11 D13) to a
# mode-600 temp file and points $define at it. Dev keeps its committed config
# (Google always off). Pass --google for a release-key build (A50 D4).
define=""
write_defines() {
  [[ "$FLAVOR" != dev ]] || return 0
  defines_file="$(umask 077 && mktemp "${TMPDIR:-/tmp}/fb-android-defines.XXXXXXXX.json")"
  python3 -I "$REPO_ROOT/tools/scripts/android-defines.py" "$@" \
    "$app/config/$FLAVOR.json" "$defines_file" "$FLAVOR"
  define="--dart-define-from-file=$defines_file"
}

# #216: Gradle's incremental resource merge can keep a res file that was
# deleted or moved since the last build (A44 moved the splash drawable: "drawable/
# launch_background not found"). When a file under android/app/src/*/res is
# gone since the last build here (or on the first build with this check over
# an existing build folder), the app module's intermediates start afresh.
clean_stale_resources() {
  local list="build/.fb-android-res-files" now
  now="$({ find android/app/src -path '*/res/*' -type f 2>/dev/null || true; } | LC_ALL=C sort)"
  if [[ -d build/app/intermediates ]] && {
    [[ ! -f "$list" ]] \
      || [[ -n "$(LC_ALL=C comm -23 "$list" <(printf '%s\n' "$now") | sed '/^$/d')" ]]
  }; then
    log "Android resources removed since the last build: cleaning build/app/intermediates"
    rm -rf -- build/app/intermediates
  fi
  mkdir -p build
  printf '%s\n' "$now" >"$list"
}

main() {
  define="--dart-define-from-file=config/$FLAVOR.json"
  local number=()
  [[ -n "$BUILD_NUMBER" ]] && number=(--build-number="$BUILD_NUMBER")
  local apk_dir="$app/build/app/outputs/flutter-apk"
  local apk="$apk_dir/app-$FLAVOR-$MODE.apk"
  local aab="$app/build/app/outputs/bundle/${FLAVOR}Release/app-$FLAVOR-release.aab"

  trap cleanup EXIT
  trap 'exit 130' INT
  trap 'exit 143' TERM
  cd "$app"
  clean_stale_resources

  if [[ "$MODE" == debug ]]; then
    write_defines
    log "flutter build apk --debug --flavor $FLAVOR (arm64)"
    SECONDS=0
    "$FLUTTER" build apk --debug --flavor "$FLAVOR" --target-platform android-arm64 "$define" "${number[@]}"
    log "debug APK built in ${SECONDS}s"
    describe "$apk" "$(apk_cert_sha256 "$apk")"
    return
  fi

  check_catalog_pack
  load_release_env
  local signed=false
  if [[ -n "${FB_KEYSTORE_PATH:-}" ]]; then
    signed=true
  else
    # Gradle refuses a release build without the key unless told it's on purpose.
    export FB_ALLOW_DEBUG_SIGNING=1
  fi
  # A50 D4: only the release key matches the registered Android OAuth client.
  if [[ "$signed" == true ]]; then
    write_defines --google
  else
    write_defines
  fi
  # Outputs of an earlier build with the other key must not be mistaken for this one.
  rm -f -- "$apk" "$apk.sha1" "$aab" "${apk%.apk}-debugkey.apk" "${aab%.aab}-debugkey.aab"

  log "flutter build apk --release --flavor $FLAVOR (arm64)${number:+ ${number[*]}}"
  SECONDS=0
  "$FLUTTER" build apk --release --flavor "$FLAVOR" --target-platform android-arm64 "$define" "${number[@]}"
  local apk_time=$SECONDS
  local with_aab=true
  [[ "${FB_BUILD_AAB:-1}" == 0 ]] && with_aab=false
  local aab_time=0
  if [[ "$with_aab" == true ]]; then
    log "flutter build appbundle --release --flavor $FLAVOR${number:+ ${number[*]}}"
    SECONDS=0
    "$FLUTTER" build appbundle --release --flavor "$FLAVOR" "$define" "${number[@]}"
    aab_time=$SECONDS
    [[ -f "$apk" && -f "$aab" ]] || die "expected outputs not found: $apk, $aab"
  else
    log "FB_BUILD_AAB=0: APK only, no AAB"
    [[ -f "$apk" ]] || die "expected output not found: $apk"
  fi

  check_hardening "$apk" "$aab"

  local apk_cert aab_cert=""
  apk_cert="$(apk_cert_sha256 "$apk")"
  if [[ "$with_aab" == true ]]; then
    aab_cert="$(aab_cert_sha256 "$aab")"
    [[ "$apk_cert" == "$aab_cert" ]] || die "the APK and AAB are signed with different certificates"
  fi
  if [[ "$signed" == true ]]; then
    [[ "$apk_cert" == "$RELEASE_CERT_SHA256" ]] \
      || die "signed with certificate $apk_cert, not the Fitness Buddy release key $RELEASE_CERT_SHA256 (wrong keystore? see docs/runbooks/android-signing.md)"
    log "signed with the release key"
  else
    [[ "$apk_cert" != "$RELEASE_CERT_SHA256" ]] || die "unexpected: release certificate without a release key"
    # Flutter's sidecar checksum (used by `flutter install`) would name the wrong file.
    rm -f -- "$apk.sha1"
    mv -- "$apk" "${apk%.apk}-debugkey.apk"
    [[ "$with_aab" == true ]] && mv -- "$aab" "${aab%.aab}-debugkey.aab"
    apk="${apk%.apk}-debugkey.apk" aab="${aab%.aab}-debugkey.aab"
    warn "no release key (FB_KEYSTORE_PATH unset): signed with this machine's DEBUG key, outputs renamed *-debugkey.*; never hand them out (docs/runbooks/android-signing.md)."
  fi
  if [[ "$with_aab" == true ]]; then
    log "built in ${apk_time}s (APK) + ${aab_time}s (AAB):"
    describe "$apk" "$apk_cert"
    describe "$aab" "$aab_cert"
  else
    log "built in ${apk_time}s (APK):"
    describe "$apk" "$apk_cert"
  fi
}

main "$@"
