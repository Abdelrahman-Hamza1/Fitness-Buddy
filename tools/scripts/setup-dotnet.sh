#!/usr/bin/env bash
# Installs the .NET SDK pinned in backend/global.json into ~/.dotnet (or the
# directory given as the first argument). No sudo, no dotnet-install.sh: the
# official SDK tarball named in Microsoft's release metadata, checked against
# the sha512 published there BEFORE anything is extracted, then merged into the
# install dir. Never touches the system .NET (/usr/lib/dotnet) or ~/.dotnet/tools.
#
# Usage: tools/scripts/setup-dotnet.sh [install-dir]
#
# Idempotent: exits quickly when the pinned SDK (or a newer patch in the same
# feature band, as global.json's rollForward=latestPatch allows) is installed.
#
# Merge rules (the same as dotnet-install.sh): versioned folders (sdk/<v>,
# shared/<fw>/<v>, host/fxr/<v>, packs/<pack>/<v>, ...) are added when missing,
# and existing ones only gain files they lack (no file is overwritten); the top-level files (the `dotnet` muxer, LICENSE.txt,
# ThirdPartyNotices.txt) are replaced. sdk/<version> is moved in last, so an
# interrupted run never looks like a finished install.
set -euo pipefail

readonly RELEASE_METADATA_URL="https://builds.dotnet.microsoft.com/dotnet/release-metadata"
# The only host the release metadata uses for SDK archives (checked 2026-10).
readonly ARCHIVE_HOST="builds.dotnet.microsoft.com"
readonly RID="linux-x64"
# Archive (~230 MB) + extracted SDK (~850 MB) + headroom, in KiB.
readonly MIN_FREE_KB=$((2 * 1024 * 1024))

export DOTNET_CLI_TELEMETRY_OPTOUT=1
export DOTNET_NOLOGO=1

log() { printf 'setup-dotnet: %s\n' "$*"; }
die() { printf 'setup-dotnet: error: %s\n' "$*" >&2; exit 1; }

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
global_json="$repo_root/backend/global.json"

check_prerequisites() {
  local -A pkg_for=([curl]=curl [tar]=tar [gzip]=gzip [python3]=python3 [sha512sum]=coreutils)
  local missing_cmds=() missing_pkgs=() cmd
  for cmd in curl tar gzip python3 sha512sum; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
      missing_cmds+=("$cmd")
      missing_pkgs+=("${pkg_for[$cmd]}")
    fi
  done
  if ((${#missing_cmds[@]} > 0)); then
    printf 'setup-dotnet: error: missing required tools: %s\n' "${missing_cmds[*]}" >&2
    printf 'Install them with:\n  sudo apt-get update && sudo apt-get install -y %s\n' "${missing_pkgs[*]}" >&2
    exit 1
  fi
  if [[ "$(uname -s)" != "Linux" || "$(uname -m)" != "x86_64" ]]; then
    die "only Linux x86_64 is supported (found $(uname -s) $(uname -m))"
  fi
}

# Prints "<version> <rollForward>" from global.json.
read_pin() {
  [[ -f "$global_json" ]] || die "pin file not found: $global_json"
  local pin
  pin="$(python3 -I -c '
import json, sys
sdk = json.load(open(sys.argv[1], encoding="utf-8"))["sdk"]
print(sdk["version"], sdk.get("rollForward", "latestPatch"))
' "$global_json")" || die "could not read sdk.version from $global_json"
  [[ "$pin" =~ ^[0-9]+\.[0-9]+\.[0-9]{3}\ [A-Za-z]+$ ]] \
    || die "unexpected sdk pin in $global_json: '$pin' (want X.Y.Znn)"
  printf '%s\n' "$pin"
}

# Prints the installed SDK version that satisfies the pin, if any.
# Accepted: the exact version, or (unless rollForward is "disable") a newer
# patch in the same feature band, e.g. 10.0.401 -> 10.0.4xx.
find_satisfying_sdk() {
  local dest="$1" pinned="$2" roll_forward="$3"
  [[ -x "$dest/dotnet" && -d "$dest/sdk" ]] || return 1
  local major minor patch
  IFS=. read -r major minor patch <<<"$pinned"
  local band=$((10#$patch / 100)) best="" best_patch=-1 dir v p
  for dir in "$dest"/sdk/*/; do
    v="$(basename "$dir")"
    [[ "$v" =~ ^${major}\.${minor}\.([0-9]{3})$ ]] || continue
    p=$((10#${BASH_REMATCH[1]}))
    if [[ "$v" == "$pinned" ]] \
      || { [[ "$roll_forward" != "disable" ]] && ((p / 100 == band && p > 10#$patch)); }; then
      if ((p > best_patch)); then best="$v"; best_patch=$p; fi
    fi
  done
  [[ -n "$best" ]] && printf '%s\n' "$best"
}

# Prints "<url> <sha512>" for the SDK tarball of version $2 / RID $3 from the
# release metadata file $1. Fails (non-zero, message on stderr) when the version
# has no tar.gz for the RID, when the entry has no hash, or when two entries
# disagree.
readonly ARCHIVE_INFO_PY='
import json, sys
path, want, rid = sys.argv[1], sys.argv[2], sys.argv[3]
data = json.load(open(path, encoding="utf-8"))
found = set()
for release in data.get("releases", []):
    sdks = list(release.get("sdks") or [])
    if release.get("sdk"):
        sdks.append(release["sdk"])
    for sdk in sdks:
        if sdk.get("version") != want:
            continue
        for f in sdk.get("files") or []:
            if f.get("rid") == rid and str(f.get("url", "")).endswith(".tar.gz"):
                found.add((f.get("url") or "", (f.get("hash") or "").lower()))
if not found:
    sys.exit(f"SDK {want} ({rid}, tar.gz) not found in the release metadata")
if len(found) > 1:
    sys.exit(f"SDK {want} ({rid}) has conflicting entries in the release metadata")
url, digest = found.pop()
if not url or not digest:
    sys.exit(f"SDK {want} ({rid}) has no url or no hash in the release metadata")
print(url, digest)
'

# Prints the host of URL $1 if it is https, nothing otherwise.
readonly URL_HOST_PY='
import sys
from urllib.parse import urlsplit
u = urlsplit(sys.argv[1])
if u.scheme == "https" and u.hostname and u.port is None and not u.username:
    print(u.hostname)
'

# Moves the entries of directory $1 into directory $2. New entries are moved
# (a rename: same filesystem). Existing directories are merged recursively;
# existing files are kept, except at the top level ($3 = 1), where they are
# replaced (non-versioned files: the muxer and the license texts).
merge_tree() {
  local src="$1" dst="$2" top="$3" entry name
  for entry in "$src"/* "$src"/.[!.]* "$src"/..?*; do
    [[ -e "$entry" || -L "$entry" ]] || continue # unmatched glob
    name="${entry##*/}"
    if [[ ! -e "$dst/$name" && ! -L "$dst/$name" ]]; then
      mv -T -- "$entry" "$dst/$name"
    elif [[ -d "$entry" && ! -L "$entry" && -d "$dst/$name" && ! -L "$dst/$name" ]]; then
      merge_tree "$entry" "$dst/$name" 0
    elif ((top)) && [[ -f "$entry" && ! -d "$dst/$name" ]]; then
      mv -fT -- "$entry" "$dst/$name"
    fi
  done
}

main() {
  check_prerequisites
  local dest="${1:-$HOME/.dotnet}"
  local pin version roll_forward installed
  pin="$(read_pin)" # separate assignment so a failure stops the script
  read -r version roll_forward <<<"$pin"

  if installed="$(find_satisfying_sdk "$dest" "$version" "$roll_forward")"; then
    log ".NET SDK $installed already installed in $dest (pin $version, rollForward $roll_forward; nothing to do)"
    exit 0
  fi
  if [[ -e "$dest/sdk/$version" ]]; then
    die "$dest/sdk/$version exists but $dest/dotnet is missing (broken install?). Remove $dest/sdk/$version and re-run."
  fi

  [[ "$dest" == /* ]] || dest="$PWD/$dest"
  local parent free_kb
  parent="$(dirname "$dest")"
  mkdir -p -- "$parent"
  free_kb="$(df -Pk "$parent" | awk 'NR==2 {print $4}')"
  if ((free_kb < MIN_FREE_KB)); then
    die "not enough free disk in $parent: $((free_kb / 1024)) MiB free, need ~2 GiB"
  fi

  # Work dir next to the install dir (same filesystem), so the merge is renames
  # only. Nothing in it is trusted until the sha512 check has passed.
  local work
  work="$(mktemp -d "$parent/.dotnet-sdk-$version.tmp.XXXXXX")"
  # shellcheck disable=SC2064  # expand $work now, on purpose
  trap "rm -rf -- '$work'" EXIT
  mkdir "$work/meta" "$work/download" "$work/stage"

  local channel="${version%.*}"
  local metadata_url="$RELEASE_METADATA_URL/$channel/releases.json"
  log "fetching the release metadata: $metadata_url"
  curl -fsSL --proto '=https' --proto-redir '=https' --tlsv1.2 --retry 3 --retry-delay 2 \
    -o "$work/meta/releases.json" "$metadata_url" \
    || die "could not download $metadata_url"

  local info url sha512 host
  info="$(python3 -I -c "$ARCHIVE_INFO_PY" "$work/meta/releases.json" "$version" "$RID")" \
    || die "no verifiable SDK archive for $version ($RID) in the release metadata (see above)"
  read -r url sha512 <<<"$info"

  host="$(python3 -I -c "$URL_HOST_PY" "$url")"
  [[ "$host" == "$ARCHIVE_HOST" ]] \
    || die "unexpected archive URL in the release metadata: $url (want https://$ARCHIVE_HOST/...)"
  local file="dotnet-sdk-$version-$RID.tar.gz"
  [[ "${url##*/}" == "$file" ]] || die "unexpected archive name in the release metadata: $url (want $file)"
  [[ "$sha512" =~ ^[0-9a-f]{128}$ ]] || die "unexpected sha512 in the release metadata for $file: '$sha512'"

  log "downloading .NET SDK $version ($RID), ~230 MB: $url"
  local progress=(-sS)
  [[ -t 2 ]] && progress=(--progress-bar)
  curl -fL "${progress[@]}" --proto '=https' --proto-redir '=https' --tlsv1.2 \
    --retry 3 --retry-delay 5 -o "$work/download/$file" "$url" \
    || die "download failed: $url"

  log "verifying sha512"
  (cd "$work/download" && printf '%s  %s\n' "$sha512" "$file" | sha512sum -c --strict -) \
    || die "sha512 mismatch for $file (expected $sha512); download discarded, nothing installed"

  log "extracting"
  tar -xzf "$work/download/$file" -C "$work/stage" --no-same-owner
  rm -f -- "$work/download/$file"
  [[ -x "$work/stage/dotnet" && -d "$work/stage/sdk/$version" ]] \
    || die "archive did not contain dotnet and sdk/$version"

  log "merging into $dest"
  # sdk/<version> last: until it is there, the fast path above does not fire.
  local sdk_stage="$work/sdk-$version"
  mv -T -- "$work/stage/sdk/$version" "$sdk_stage"
  mkdir -p -- "$dest"
  merge_tree "$work/stage" "$dest" 1
  mkdir -p -- "$dest/sdk"
  mv -T -- "$sdk_stage" "$dest/sdk/$version"

  installed="$(find_satisfying_sdk "$dest" "$version" "$roll_forward")" \
    || die "install finished but no SDK matching $version was found in $dest/sdk"
  log "installed: .NET SDK $installed in $dest"
  # SDK resolution follows the working directory, so ask from backend/.
  log "dotnet --version (in backend/): $(cd "$repo_root/backend" && "$dest/dotnet" --version)"
}

main "$@"
