#!/usr/bin/env bash
# Measures the app's cold start on a connected Android device (S06 plan D20).
#
# Usage: tools/scripts/cold-start.sh <application-id> [runs]   (make cold-start)
#   ADB      adb binary (default: adb on PATH; the Makefile passes the SDK's)
#   ANDROID_SERIAL  picks the device when several are connected (adb reads it)
#   COLD_START_SETTLE  seconds to wait after each force-stop (default 2)
#
# One discarded warm-up run, then <runs> (default 10) times
# `am start -S -W`: -S force-stops the app first, so every run is a cold
# process start; -W waits for the first drawn frame. Flutter's Android
# embedding keeps the launch window until Flutter's first frame, so TotalTime
# is about the time to the first Flutter frame (cross-check once with
# `flutter run --profile --trace-startup`, plan D20). Prints every TotalTime,
# the median and p90, the device, its Android build and the app version.
# Measure a release build (the CI staging APK), never debug: JIT is slow.
set -euo pipefail

die() { printf 'cold-start: error: %s\n' "$*" >&2; exit 1; }

app_id="${1:-}"
runs="${2:-10}"
ADB="${ADB:-adb}"
[[ "$app_id" =~ ^[A-Za-z][A-Za-z0-9_]*(\.[A-Za-z][A-Za-z0-9_]*)+$ ]] \
  || die "usage: $0 <application-id> [runs]  (e.g. io.github.abdelrahmanhamza1.fitnessbuddy.staging)"
[[ "$runs" =~ ^[1-9][0-9]?$ ]] || die "runs must be 1-99 (got '$runs')"
command -v "$ADB" >/dev/null 2>&1 || [[ -x "$ADB" ]] || die "adb not found ($ADB): run make toolchain-android"

adb_shell() { "$ADB" shell "$@" | tr -d '\r'; }

"$ADB" get-state >/dev/null 2>&1 \
  || die "no single device: connect the phone (USB or Wireless debugging) and allow it; with several, set ANDROID_SERIAL"
version="$(adb_shell dumpsys package "$app_id" | sed -n 's/^ *versionName=//p' | head -n 1)"
[[ -n "$version" ]] || die "$app_id is not installed on the device"
version_code="$(adb_shell dumpsys package "$app_id" | sed -n 's/^ *versionCode=\([0-9]*\).*/\1/p' | head -n 1)"
# The launcher activity, e.g. io.github...staging/io.github...fitnessbuddy.MainActivity
component="$(adb_shell cmd package resolve-activity --brief "$app_id" | tail -n 1)"
[[ "$component" == */* ]] || die "could not find the launcher activity of $app_id"

# One run: prints TotalTime in ms, or fails.
start_once() {
  local out total
  out="$(adb_shell am start -S -W -n "$component")"
  grep -q '^Status: ok' <<<"$out" || { printf '%s\n' "$out" >&2; die "am start failed"; }
  total="$(sed -n 's/^TotalTime: //p' <<<"$out")"
  [[ "$total" =~ ^[0-9]+$ ]] || { printf '%s\n' "$out" >&2; die "no TotalTime in the am start output"; }
  printf '%s\n' "$total"
}

settle() { adb_shell am force-stop "$app_id" >/dev/null; sleep "${COLD_START_SETTLE:-2}"; }

echo "cold-start: $app_id $version ($version_code)"
echo "  device:  $(adb_shell getprop ro.product.manufacturer) $(adb_shell getprop ro.product.model)" \
  "($(adb_shell getprop ro.product.device)), Android $(adb_shell getprop ro.build.version.release)" \
  "(API $(adb_shell getprop ro.build.version.sdk)), build $(adb_shell getprop ro.build.display.id)"
# Plain assignments, so a failed run stops the script (set -e).
settle
warm_up="$(start_once)"
echo "  warm-up: $warm_up ms (discarded)"
times=()
for ((i = 1; i <= runs; i++)); do
  settle
  t="$(start_once)"
  times+=("$t")
  printf '  run %2d:  %s ms\n' "$i" "$t"
done
settle

# Median (mean of the two middle values when even) and p90 (nearest rank).
python3 -I -c '
import math, statistics, sys
t = sorted(int(x) for x in sys.argv[1:])
p90 = t[max(0, math.ceil(0.9 * len(t)) - 1)]
print(f"  median:  {statistics.median(t):g} ms   p90: {p90} ms   min: {t[0]} ms   max: {t[-1]} ms   (n={len(t)})")
' "${times[@]}"
