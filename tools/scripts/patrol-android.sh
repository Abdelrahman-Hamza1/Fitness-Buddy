#!/usr/bin/env bash
# Runs or builds the app's Patrol integration tests (apps/mobile/patrol_test/,
# S06 plan D18) for the dev flavor. Called by `make test-it` and `make build-it`,
# which pass everything through the environment:
#   DART, FLUTTER, REPO_ROOT, JAVA_HOME, ANDROID_HOME   toolchain (Makefile)
#   PATROL_CLI_VERSION   the pinned patrol_cli (Makefile; pairs with the
#                        `patrol` pin in apps/mobile/pubspec.yaml)
#   PATROL_ARGS          extra patrol arguments (optional, e.g. --verbose)
#
# Usage: patrol-android.sh test | build
#   test   builds the APKs, installs them on the one connected device or
#          emulator (with several: ANDROID_SERIAL) and runs every test in
#          patrol_test/ (`patrol test`)
#   build  only builds the app APK and the instrumentation APK
#          (`patrol build android`): no device needed
#
# The dev flavor with config/dev.json: the API is http://127.0.0.1:5198, which
# nothing serves on an emulator (no `adb reverse`), so the tests prove the app
# works with no API.
#
# Always, even on failure: deletes patrol_test/test_bundle.dart (patrol_cli
# generates it on every run; unformatted, it would fail `make check-dart`) and
# stops the Gradle daemons (the laptop has 7 GB of RAM).
set -euo pipefail

log() { printf 'patrol-android: %s\n' "$*"; }
die() { printf 'patrol-android: error: %s\n' "$*" >&2; exit 1; }

: "${DART:?}" "${FLUTTER:?}" "${REPO_ROOT:?}" "${JAVA_HOME:?}" "${ANDROID_HOME:?}" "${PATROL_CLI_VERSION:?}"
mode="${1:-}"
case "$mode" in test | build) ;; *) die "usage: patrol-android.sh test|build" ;; esac
read -r -a extra_args <<<"${PATROL_ARGS:-}"

app="$REPO_ROOT/apps/mobile"
[[ -x "$JAVA_HOME/bin/java" ]] || die "no JDK at JAVA_HOME=$JAVA_HOME (run: make toolchain-android)"
[[ -f "$app/config/dev.json" ]] || die "missing $app/config/dev.json"

# patrol_cli runs `flutter`, `java` and `adb` from PATH: make them the pinned
# ones. FLUTTER may be a bare `flutter` (CI), already on PATH.
if [[ "$FLUTTER" == */* ]]; then
  PATH="$(dirname "$FLUTTER"):$PATH"
fi
export PATH="$JAVA_HOME/bin:$ANDROID_HOME/platform-tools:$PATH"
# patrol_cli defaults: usage analytics to Google Analytics on (off only on CI),
# and shell completion installed into ~/.bashrc on the first run. Both off.
export PATROL_ANALYTICS_ENABLED=false
export PATROL_NO_COMPLETION=1

# --- The pinned patrol_cli ------------------------------------------------------
# A global activation (no project-local option exists). Re-activated when
# missing or at another version, so the pin in the Makefile always wins.
installed="$("$DART" pub global list 2>/dev/null | awk '$1 == "patrol_cli" { print $2 }')"
if [[ "$installed" != "$PATROL_CLI_VERSION" ]]; then
  log "activating patrol_cli $PATROL_CLI_VERSION (found: ${installed:-none})"
  "$DART" pub global activate patrol_cli "$PATROL_CLI_VERSION" >/dev/null
fi
patrol=("$DART" pub global run patrol_cli:main)

cleanup() {
  rm -f "$app/patrol_test/test_bundle.dart"
  if [[ -x "$app/android/gradlew" ]]; then
    (cd "$app/android" && ./gradlew --stop -q >/dev/null 2>&1) || true
  fi
}
trap cleanup EXIT

cd "$app"
flavor_args=(--flavor dev --dart-define-from-file=config/dev.json)
case "$mode" in
  build)
    "${patrol[@]}" build android "${flavor_args[@]}" "${extra_args[@]}"
    log "built (dev debug): build/app/outputs/apk/dev/debug/app-dev-debug.apk +" \
      "build/app/outputs/apk/androidTest/dev/debug/app-dev-debug-androidTest.apk"
    ;;
  test)
    adb_state="$(adb get-state 2>/dev/null || true)"
    [[ "$adb_state" == device ]] \
      || die "no single device: start an emulator or connect a phone (with several, set ANDROID_SERIAL)"
    device_args=()
    [[ -n "${ANDROID_SERIAL:-}" ]] && device_args=(--device "$ANDROID_SERIAL")
    "${patrol[@]}" test "${flavor_args[@]}" "${device_args[@]}" "${extra_args[@]}"
    ;;
esac
