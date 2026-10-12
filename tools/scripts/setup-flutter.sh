#!/usr/bin/env bash
# Installs the Flutter SDK pinned in .fvmrc into ~/development/flutter-<version>
# (or the directory given as the first argument). No sudo, no FVM, no git clone:
# the official stable archive, checked against the sha256 in Flutter's release index.
#
# Usage: tools/scripts/setup-flutter.sh [install-dir]
#
# Idempotent: exits quickly when the pinned SDK is already installed. An SDK in
# the install dir with any other version is an error (never used, never replaced).
set -euo pipefail

readonly RELEASES_URL="https://storage.googleapis.com/flutter_infra_release/releases/releases_linux.json"
# Archive (~1.6 GB) + extracted SDK (~3.5 GB) + headroom, in KiB.
readonly MIN_FREE_KB=$((6 * 1024 * 1024))

log() { printf 'setup-flutter: %s\n' "$*"; }
die() { printf 'setup-flutter: error: %s\n' "$*" >&2; exit 1; }

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
pin_file="$repo_root/.fvmrc"

# --- Prerequisites -----------------------------------------------------------
check_prerequisites() {
  local -A pkg_for=(
    [curl]=curl [tar]=tar [xz]=xz-utils [python3]=python3
    [git]=git [unzip]=unzip [sha256sum]=coreutils
  )
  local missing_cmds=() missing_pkgs=() cmd
  for cmd in curl tar xz python3 git unzip sha256sum; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
      missing_cmds+=("$cmd")
      missing_pkgs+=("${pkg_for[$cmd]}")
    fi
  done
  if ((${#missing_cmds[@]} > 0)); then
    printf 'setup-flutter: error: missing required tools: %s\n' "${missing_cmds[*]}" >&2
    printf 'Install them with:\n  sudo apt-get update && sudo apt-get install -y %s\n' "${missing_pkgs[*]}" >&2
    exit 1
  fi
  if [[ "$(uname -s)" != "Linux" || "$(uname -m)" != "x86_64" ]]; then
    die "only Linux x86_64 is supported (found $(uname -s) $(uname -m))"
  fi
}

# --- Pinned version ----------------------------------------------------------
read_pinned_version() {
  [[ -f "$pin_file" ]] || die "pin file not found: $pin_file"
  local version
  version="$(python3 -I -c '
import json, sys
print(json.load(open(sys.argv[1], encoding="utf-8"))["flutter"])
' "$pin_file")" || die "could not read the \"flutter\" key from $pin_file"
  [[ "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] \
    || die "pinned Flutter version '$version' in $pin_file is not X.Y.Z"
  printf '%s\n' "$version"
}

# Applies the per-user settings we want for every developer. Safe to repeat.
post_install() {
  local dest="$1"
  log "disabling Flutter and Dart analytics"
  "$dest/bin/flutter" --disable-analytics >/dev/null
  "$dest/bin/dart" --disable-analytics >/dev/null
  # Marker inside bin/cache (ignored by Flutter's own git checkout) so an
  # interrupted run finishes these steps next time instead of skipping them.
  : >"$dest/bin/cache/.fitness-buddy-setup-complete"
  local flutter_version
  flutter_version="$("$dest/bin/flutter" --version)"
  log "installed: ${flutter_version%%$'\n'*}"
  log "Dart:      $("$dest/bin/dart" --version 2>&1)"
}

# Prints the framework version of the SDK in $1: from bin/cache/flutter.version.json,
# or, if that file is missing, from `flutter --version --machine` (which writes it).
readonly FRAMEWORK_VERSION_PY='
import json, sys
text = sys.stdin.read() if sys.argv[1] == "-" else open(sys.argv[1], encoding="utf-8").read()
start = text.find("{")
if start < 0:
    sys.exit("no JSON")
data, _ = json.JSONDecoder().raw_decode(text[start:])
print(data.get("frameworkVersion") or data.get("flutterVersion") or "")
'
installed_version() {
  local dest="$1" json="$1/bin/cache/flutter.version.json"
  if [[ -f "$json" ]]; then
    python3 -I -c "$FRAMEWORK_VERSION_PY" "$json" 2>/dev/null
  else
    "$dest/bin/flutter" --version --machine 2>/dev/null | python3 -I -c "$FRAMEWORK_VERSION_PY" - 2>/dev/null
  fi
}

# Fails unless the SDK in $1 is Flutter $2: a directory with the right name is
# not proof of the right version (e.g. an SDK upgraded in place).
check_installed_version() {
  local dest="$1" want="$2" have
  have="$(installed_version "$dest")" || have=""
  [[ "$have" == "$want" ]] \
    || die "the Flutter SDK at $dest is version '${have:-unknown}', but .fvmrc pins $want. Remove it (rm -rf '$dest') and re-run, or pass another install dir."
}

main() {
  check_prerequisites
  local version dest
  version="$(read_pinned_version)"
  dest="${1:-$HOME/development/flutter-$version}"
  local marker="$dest/bin/cache/.fitness-buddy-setup-complete"

  if [[ -x "$dest/bin/flutter" ]]; then
    check_installed_version "$dest" "$version"
  fi
  if [[ -x "$dest/bin/flutter" && -f "$marker" ]]; then
    log "Flutter $version already installed at $dest (nothing to do)"
    exit 0
  fi
  if [[ -x "$dest/bin/flutter" ]]; then
    log "Flutter found at $dest but setup did not finish last time; completing it"
    post_install "$dest"
    exit 0
  fi
  if [[ -e "$dest" ]]; then
    die "$dest exists but has no bin/flutter (incomplete install?). Remove it and re-run: rm -rf '$dest'"
  fi

  local parent
  parent="$(dirname "$dest")"
  mkdir -p "$parent"
  local free_kb
  free_kb="$(df -Pk "$parent" | awk 'NR==2 {print $4}')"
  if ((free_kb < MIN_FREE_KB)); then
    die "not enough free disk in $parent: $((free_kb / 1024 / 1024)) GiB free, need ~6 GiB"
  fi

  # Work dir on the same filesystem as the destination, so the final mv is an
  # atomic rename and a half-extracted SDK never appears at $dest.
  local work
  work="$(mktemp -d "$parent/.flutter-$version.tmp.XXXXXX")"
  # shellcheck disable=SC2064  # expand $work now, on purpose
  trap "rm -rf -- '$work'" EXIT
  mkdir "$work/download" "$work/extract"

  log "fetching the release index"
  curl -fsSL --proto '=https' --tlsv1.2 --retry 3 --retry-delay 2 \
    -o "$work/download/releases_linux.json" "$RELEASES_URL" \
    || die "could not download $RELEASES_URL"

  local info archive sha256 dart_version base_url
  info="$(python3 -I -c '
import json, sys
data = json.load(open(sys.argv[1], encoding="utf-8"))
want = sys.argv[2]
hits = [r for r in data["releases"]
        if r.get("version") == want and r.get("channel") == "stable"
        and r.get("dart_sdk_arch", "x64") == "x64"]
if not hits:
    sys.exit(f"Flutter {want} (stable, x64) is not in the release index")
r = hits[0]
print(data["base_url"], r["archive"], r["sha256"], r.get("dart_sdk_version", "?"))
' "$work/download/releases_linux.json" "$version")" || die "Flutter $version not found in the stable release index"
  read -r base_url archive sha256 dart_version <<<"$info"

  [[ "$base_url" == "https://storage.googleapis.com/flutter_infra_release/releases" ]] \
    || die "unexpected base_url in release index: $base_url"
  [[ "$archive" =~ ^stable/linux/flutter_linux_[0-9.]+-stable\.tar\.xz$ ]] \
    || die "unexpected archive path in release index: $archive"
  [[ "$sha256" =~ ^[0-9a-f]{64}$ ]] || die "unexpected sha256 in release index: $sha256"

  local file="${archive##*/}"
  log "downloading Flutter $version (Dart $dart_version), ~1.6 GB: $base_url/$archive"
  local progress=(-sS)
  [[ -t 2 ]] && progress=(--progress-bar)
  curl -fL "${progress[@]}" --proto '=https' --tlsv1.2 --retry 3 --retry-delay 5 \
    -o "$work/download/$file" "$base_url/$archive" \
    || die "download failed: $base_url/$archive"

  log "verifying sha256"
  (cd "$work/download" && printf '%s  %s\n' "$sha256" "$file" | sha256sum -c --strict -) \
    || die "sha256 mismatch for $file (expected $sha256); download discarded"

  log "extracting (this takes a minute)"
  tar -xJf "$work/download/$file" -C "$work/extract" --no-same-owner
  rm -f -- "$work/download/$file"
  [[ -x "$work/extract/flutter/bin/flutter" ]] || die "archive did not contain flutter/bin/flutter"

  mv -T -- "$work/extract/flutter" "$dest"
  log "installed to $dest"
  post_install "$dest"
}

main "$@"
