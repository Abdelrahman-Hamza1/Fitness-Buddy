#!/usr/bin/env bash
# Installs the Android build toolchain user-locally (S06 plan D19, research
# "S06 — Android toolchain"): Eclipse Temurin JDK 21 and the Android SDK
# (cmdline-tools, then platform-tools, the platforms, build-tools, NDK and
# CMake the app's Gradle build needs). No sudo, no Android Studio.
#
# Usage: tools/scripts/setup-android.sh <java-home> <android-home>
#   (`make toolchain-android` passes $(JAVA_HOME) and $(ANDROID_HOME):
#    ~/development/jdk-21.0.12.1+1 and ~/development/android-sdk by default)
#        tools/scripts/setup-android.sh --sdk-only <android-home>
#   (`make toolchain-android-sdk`, CI): only the SDK packages below, into an
#    SDK that already exists (the GitHub runner's), with the JDK at $JAVA_HOME.
#    Uses the SDK's own sdkmanager (cmdline-tools/latest); if that one fails
#    (the runner's cmdline-tools 12 against today's repository XML), installs
#    the pinned cmdline-tools 22.0 next to it and retries with that.
#
# Pins: the JDK and cmdline-tools archives are checked against the sha256s
# below. sdkmanager checks every SDK package against the checksum in Google's
# repository XML (fetched over HTTPS). platform-tools (adb) can't be pinned:
# Google only serves the current one.
#
# Licences: running this accepts the Android SDK licences (`sdkmanager
# --licenses`), as the owner decided (S06 plan D19, 2026-10-15).
#
# Idempotent: when everything is in place it exits without network access.
set -euo pipefail

# --- Pins (bump together with research-notes.md and the Makefile defaults) ---
readonly JDK_RELEASE="21.0.12.1+1" # Temurin 21.0.12+1, build 21.0.12.1+1
readonly JDK_JAVA_VERSION="21.0.12.1" # JAVA_VERSION in the JDK's release file
readonly JDK_URL="https://github.com/adoptium/temurin21-binaries/releases/download/jdk-21.0.12.1%2B1/OpenJDK21U-jdk_x64_linux_hotspot_21.0.12.1_1.tar.gz"
readonly JDK_SHA256="ce79869e1307ed8ee1e2baa86a412b1eb5b75d10a01006d788a6f968bcfaee94"

readonly CMDLINE_TOOLS_VERSION="22.0"
readonly CMDLINE_TOOLS_URL="https://dl.google.com/android/repository/commandlinetools-linux-15859902_latest.zip"
readonly CMDLINE_TOOLS_SHA256="4e4c464f145a7512b57d088ac6c278c03c9eea610886b35a5e0804e74eedf583"

# The SDK packages: tools/scripts/android-sdk-packages.txt (shared with doctor.sh
# and build-android.sh). Each entry: "<sdkmanager package>|<dir under the SDK>".
mapfile -t SDK_PACKAGES < <(grep -v -e '^#' -e '^[[:space:]]*$' "$(dirname "${BASH_SOURCE[0]}")/android-sdk-packages.txt")
readonly SDK_PACKAGES
((${#SDK_PACKAGES[@]} > 0)) || { echo "setup-android: error: no packages in android-sdk-packages.txt" >&2; exit 1; }

# JDK + SDK (~3 GB) + the Gradle cache the first build fills (~3.5 GB), in KiB.
readonly MIN_FREE_KB=$((8 * 1024 * 1024))

log() { printf 'setup-android: %s\n' "$*"; }
die() { printf 'setup-android: error: %s\n' "$*" >&2; exit 1; }

check_prerequisites() {
  local missing=() cmd
  for cmd in curl tar unzip sha256sum df; do
    command -v "$cmd" >/dev/null 2>&1 || missing+=("$cmd")
  done
  ((${#missing[@]} == 0)) \
    || die "missing required tools: ${missing[*]} (sudo apt-get install -y curl tar unzip coreutils)"
  [[ "$(uname -s)" == "Linux" && "$(uname -m)" == "x86_64" ]] \
    || die "only Linux x86_64 is supported (found $(uname -s) $(uname -m))"
}

# Fails unless $1 has at least MIN_FREE_KB free. Only checked before a download.
check_disk() {
  local dir="$1" free_kb
  mkdir -p "$dir"
  free_kb="$(df -Pk "$dir" | awk 'NR==2 {print $4}')"
  ((free_kb >= MIN_FREE_KB)) \
    || die "not enough free disk in $dir: $((free_kb / 1024 / 1024)) GiB free, need 8 GiB (JDK, SDK, Gradle cache)"
}

# download <url> <sha256> <output file>
download() {
  local url="$1" sha256="$2" out="$3" progress=(-sS)
  [[ -t 2 ]] && progress=(--progress-bar)
  curl -fL "${progress[@]}" --proto '=https' --tlsv1.2 --retry 3 --retry-delay 5 -o "$out" "$url" \
    || die "download failed: $url"
  log "verifying sha256 of ${out##*/}"
  printf '%s  %s\n' "$sha256" "$out" | sha256sum -c --strict --quiet - \
    || die "sha256 mismatch for ${out##*/} (expected $sha256); download discarded"
}

# remove_hint <dir> <problem> <otherwise>: deleting is only suggested inside
# ~/development, where this script installs; anywhere else the dir may be
# something another tool relies on, so <otherwise> is the advice.
remove_hint() {
  local dir="$1" problem="$2" otherwise="$3"
  case "$(readlink -m -- "$dir")/" in
    "$(readlink -m -- "$HOME/development")"/?*) printf '%s. Remove it and re-run: rm -rf %q' "$problem" "$dir" ;;
    *) printf '%s. %s' "$problem" "$otherwise" ;;
  esac
}
readonly JDK_ELSEWHERE="JAVA_HOME points to a JDK that isn't the pinned one: unset it or point it at ~/development/jdk-$JDK_RELEASE"
readonly SDK_ELSEWHERE="ANDROID_HOME points to an SDK this script didn't install: unset it (default ~/development/android-sdk) or fix that SDK by hand"

# Reads JAVA_VERSION from the JDK's release file.
jdk_version() { sed -n 's/^JAVA_VERSION="\(.*\)"$/\1/p' "$1/release" 2>/dev/null; }

install_jdk() {
  local dest="$1"
  if [[ -x "$dest/bin/java" ]]; then
    local have
    have="$(jdk_version "$dest")"
    [[ "$have" == "$JDK_JAVA_VERSION" ]] || die "$(remove_hint "$dest" "the JDK at $dest is version '${have:-unknown}', pinned $JDK_JAVA_VERSION" "$JDK_ELSEWHERE")"
    log "JDK $JDK_RELEASE already installed at $dest"
    return
  fi
  [[ ! -e "$dest" ]] || die "$(remove_hint "$dest" "$dest exists but has no bin/java (incomplete install?)" "$JDK_ELSEWHERE")"

  local parent work
  parent="$(dirname "$dest")"
  check_disk "$parent"
  # Same filesystem as the destination: the final mv is an atomic rename.
  work="$(mktemp -d "$parent/.jdk.tmp.XXXXXX")"
  # shellcheck disable=SC2064  # expand $work now, on purpose
  trap "rm -rf -- '$work'" EXIT
  mkdir "$work/download" "$work/extract"
  log "downloading Temurin JDK $JDK_RELEASE (~200 MB)"
  download "$JDK_URL" "$JDK_SHA256" "$work/download/jdk.tar.gz"
  tar -xzf "$work/download/jdk.tar.gz" -C "$work/extract" --no-same-owner
  [[ -x "$work/extract/jdk-$JDK_RELEASE/bin/java" ]] || die "the JDK archive did not contain jdk-$JDK_RELEASE/bin/java"
  mv -T -- "$work/extract/jdk-$JDK_RELEASE" "$dest"
  rm -rf -- "$work"
  trap - EXIT
  log "JDK installed: $("$dest/bin/java" -version 2>&1 | head -n 1)"
}

install_cmdline_tools() {
  local sdk="$1" dest="$1/cmdline-tools/$CMDLINE_TOOLS_VERSION"
  if [[ -x "$dest/bin/sdkmanager" ]]; then
    local have
    have="$(sed -n 's/^Pkg.Revision=//p' "$dest/source.properties" 2>/dev/null)"
    [[ "$have" == "$CMDLINE_TOOLS_VERSION" ]] \
      || die "$(remove_hint "$dest" "cmdline-tools at $dest are version '${have:-unknown}', pinned $CMDLINE_TOOLS_VERSION" "$SDK_ELSEWHERE")"
    log "cmdline-tools $CMDLINE_TOOLS_VERSION already installed"
    return
  fi
  [[ ! -e "$dest" ]] || die "$(remove_hint "$dest" "$dest exists but has no bin/sdkmanager" "$SDK_ELSEWHERE")"

  check_disk "$sdk"
  local work
  mkdir -p "$sdk/cmdline-tools"
  work="$(mktemp -d "$sdk/cmdline-tools/.tmp.XXXXXX")"
  # shellcheck disable=SC2064
  trap "rm -rf -- '$work'" EXIT
  mkdir "$work/download" "$work/extract"
  log "downloading Android cmdline-tools $CMDLINE_TOOLS_VERSION (~180 MB)"
  download "$CMDLINE_TOOLS_URL" "$CMDLINE_TOOLS_SHA256" "$work/download/cmdline-tools.zip"
  unzip -q "$work/download/cmdline-tools.zip" -d "$work/extract"
  [[ -x "$work/extract/cmdline-tools/bin/sdkmanager" ]] || die "the archive did not contain cmdline-tools/bin/sdkmanager"
  # A versioned dir, not `latest` (research): the pin is visible on disk.
  mv -T -- "$work/extract/cmdline-tools" "$dest"
  rm -rf -- "$work"
  trap - EXIT
  log "cmdline-tools installed to $dest"
}

# The SDK packages that are not installed yet, one sdkmanager name per line.
missing_packages() {
  local sdk="$1" entry
  for entry in "${SDK_PACKAGES[@]}"; do
    [[ -f "$sdk/${entry#*|}/source.properties" ]] || printf '%s\n' "${entry%%|*}"
  done
}

licences_accepted() { [[ -f "$1/licenses/android-sdk-license" ]]; }

# install_packages <sdkmanager> <sdk> <package...>: returns sdkmanager's status
# (callers decide whether to fall back or fail). Its output is a wall of
# progress bars: kept in a file, shown on failure, warnings shown always.
install_packages() {
  local sdkmanager="$1" sdk="$2" out rc=0
  shift 2
  local note=""
  [[ " $* " == *" ndk;"* ]] && note=" (the NDK is ~2 GB: a few minutes)"
  log "installing with ${sdkmanager#"$sdk/"}: $*$note"
  out="$(mktemp)"
  "$sdkmanager" --sdk_root="$sdk" --install "$@" >"$out" 2>&1 || rc=$?
  if ((rc != 0)); then
    tr '\r' '\n' <"$out" | grep -v -e '^\[' -e '^ *$' | tail -n 30 >&2
  else
    tr '\r' '\n' <"$out" | grep -i -e 'warning' -e 'error' | grep -v -i 'deprecated' | sort -u | sed 's/^/  sdkmanager: /' || true
  fi
  rm -f -- "$out"
  return "$rc"
}

# --sdk-only <android-home>: the SDK packages into an existing SDK (CI).
sdk_only() {
  (($# == 1)) || die "usage: $0 --sdk-only <android-home>"
  local sdk="$1"
  [[ "$sdk" == /* && -d "$sdk" ]] || die "--sdk-only needs an existing SDK dir (got '$sdk')"
  [[ -x "${JAVA_HOME:-}/bin/java" ]] || die "--sdk-only runs sdkmanager on \$JAVA_HOME: no java at '${JAVA_HOME:-}'"
  licences_accepted "$sdk" || die "the SDK at $sdk has no accepted licences (run the full setup instead)"

  local -a missing
  mapfile -t missing < <(missing_packages "$sdk")
  if ((${#missing[@]} == 0)); then
    log "Android SDK packages already installed at $sdk (nothing to do)"
    return
  fi
  local pinned="$sdk/cmdline-tools/$CMDLINE_TOOLS_VERSION/bin/sdkmanager"
  local existing="$sdk/cmdline-tools/latest/bin/sdkmanager"
  local used=""
  if [[ -x "$pinned" ]]; then
    install_packages "$pinned" "$sdk" "${missing[@]}" && used="$pinned"
  elif [[ -x "$existing" ]]; then
    log "the SDK's own cmdline-tools: $(sed -n 's/^Pkg.Revision=//p' "$sdk/cmdline-tools/latest/source.properties" 2>/dev/null || echo unknown)"
    if install_packages "$existing" "$sdk" "${missing[@]}"; then
      used="$existing"
    else
      log "the SDK's own sdkmanager failed: falling back to the pinned cmdline-tools $CMDLINE_TOOLS_VERSION"
    fi
  fi
  if [[ -z "$used" && ! -x "$pinned" ]]; then
    install_cmdline_tools "$sdk"
    mapfile -t missing < <(missing_packages "$sdk")
    install_packages "$pinned" "$sdk" "${missing[@]}" || die "sdkmanager --install failed (output above)"
    used="$pinned"
  fi
  [[ -n "$used" ]] || die "sdkmanager --install failed (output above)"
  local still
  still="$(missing_packages "$sdk")"
  [[ -z "$still" ]] || die "sdkmanager did not install: ${still//$'\n'/, }"
  log "Android SDK packages ready at $sdk (sdkmanager: ${used#"$sdk/"})"
}

main() {
  check_prerequisites
  if [[ "${1:-}" == --sdk-only ]]; then
    shift
    sdk_only "$@"
    return
  fi
  (($# == 2)) || die "usage: $0 <java-home> <android-home>"
  local java_home="$1" sdk="$2"
  [[ "$java_home" == /* && "$sdk" == /* ]] || die "both paths must be absolute (got '$java_home', '$sdk')"

  install_jdk "$java_home"
  install_cmdline_tools "$sdk"

  local -a missing
  mapfile -t missing < <(missing_packages "$sdk")
  if ((${#missing[@]} == 0)) && licences_accepted "$sdk"; then
    log "Android SDK packages already installed at $sdk (nothing to do)"
    return
  fi

  local sdkmanager="$sdk/cmdline-tools/$CMDLINE_TOOLS_VERSION/bin/sdkmanager"
  # sdkmanager is a Java program: it runs on the pinned JDK, never a system one.
  export JAVA_HOME="$java_home"
  if ! licences_accepted "$sdk"; then
    log "accepting the Android SDK licences (S06 plan D19)"
    # `yes` gets SIGPIPE when sdkmanager exits, and the trailing `|| true` also
    # swallows sdkmanager's and grep's status: the licence-file check below is
    # what decides. The "sdkmanager is deprecated" banner (research: it still
    # works) is dropped.
    { yes 2>/dev/null || true; } | "$sdkmanager" --sdk_root="$sdk" --licenses 2>&1 >/dev/null \
      | grep -v -i -e 'deprecated' -e "'android' binary" -e 'android-cli' -e '^ *$' >&2 \
      || true
    licences_accepted "$sdk" || die "sdkmanager --licenses did not write $sdk/licenses"
  fi
  if ((${#missing[@]} > 0)); then
    check_disk "$sdk"
    install_packages "$sdkmanager" "$sdk" "${missing[@]}" || die "sdkmanager --install failed (output above)"
    local still
    still="$(missing_packages "$sdk")"
    [[ -z "$still" ]] || die "sdkmanager did not install: ${still//$'\n'/, }"
  fi
  log "Android SDK ready at $sdk (platform-tools $(sed -n 's/^Pkg.Revision=//p' "$sdk/platform-tools/source.properties"))"
}

main "$@"
