#!/usr/bin/env bash
# Prints the toolchain versions and machine resources, and checks the pinned
# SDKs. Called by `make doctor`, which passes the tool paths through the
# environment (FLUTTER, DART, DOTNET, FLUTTER_VERSION, DOTNET_ROOT, ...).
# Exit code: 0 if the pinned toolchain is in place, 1 otherwise.
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
: "${FLUTTER:?}" "${DART:?}" "${DOTNET:?}" "${FLUTTER_VERSION:?}"
DOTNET_ROOT="${DOTNET_ROOT:-}"
DOTNET_ROOT_ORIGIN="${DOTNET_ROOT_ORIGIN:-unknown}"
FLUTTER_ROOT_ORIGIN="${FLUTTER_ROOT_ORIGIN:-unknown}"

problems=()
warnings=()

row() { printf '  %-12s %s\n' "$1" "$2"; }
first_line() { local s; s="$("$@" 2>&1)" || true; s="${s%%$'\n'*}"; printf '%s\n' "${s:0:72}"; }
have() { command -v "$1" >/dev/null 2>&1; }

echo "Base tools"
for tool in git make python3 curl xz tar unzip; do
  if have "$tool"; then
    flag="--version"
    [[ "$tool" == unzip ]] && flag="-v"
    row "$tool" "$(first_line "$tool" "$flag")"
  else
    row "$tool" "MISSING"
    problems+=("$tool is not installed (sudo apt-get install -y ${tool/xz/xz-utils})")
  fi
done

echo
echo "Flutter / Dart (pinned in .fvmrc: $FLUTTER_VERSION)"
if have "$FLUTTER"; then
  machine="$("$FLUTTER" --version --machine 2>/dev/null)" || machine=""
  read -r fv dv < <(python3 -I -c '
import json, sys
try:
    d = json.loads(sys.argv[1])
    print(d.get("frameworkVersion", "?"), d.get("dartSdkVersion", "?"))
except Exception:
    print("? ?")
' "$machine")
  if [[ "$fv" == "$FLUTTER_VERSION" ]]; then status="OK"; else
    status="MISMATCH"
    problems+=("Flutter is $fv, pinned $FLUTTER_VERSION (run: make toolchain-flutter)")
  fi
  row "Flutter" "$fv (bundled Dart $dv)  [$status]  $(command -v "$FLUTTER")"
  row "FLUTTER_ROOT" "$(dirname "$(dirname "$(command -v "$FLUTTER")")")  (from $FLUTTER_ROOT_ORIGIN)"
else
  row "Flutter" "NOT INSTALLED at $FLUTTER"
  problems+=("Flutter $FLUTTER_VERSION is not installed (run: make toolchain-flutter)")
fi
if have "$DART"; then
  dart_line="$(first_line "$DART" --version)"
  dart_version="${dart_line#Dart SDK version: }"
  row "Dart" "${dart_version%% *}  $(command -v "$DART")"
else
  row "Dart" "NOT INSTALLED at $DART"
  problems+=("Dart is not available at $DART (it ships with Flutter: make toolchain-flutter)")
fi

echo
pin="$(python3 -I -c '
import json, sys
sdk = json.load(open(sys.argv[1], encoding="utf-8"))["sdk"]
print(sdk["version"], sdk.get("rollForward", "latestPatch"))
' "$repo_root/backend/global.json")"
read -r dotnet_pin roll_forward <<<"$pin"
echo ".NET SDK (pinned in backend/global.json: $dotnet_pin, rollForward $roll_forward)"
if have "$DOTNET"; then
  # SDK resolution follows the working directory: ask from backend/.
  if sdk="$(cd "$repo_root/backend" && "$DOTNET" --version 2>/dev/null)"; then
    pin_band="${dotnet_pin%??}"
    if [[ "$sdk" == "$dotnet_pin" ]]; then status="OK"
    elif [[ "$sdk" == "$pin_band"?? ]]; then status="OK (newer patch, allowed by latestPatch)"
    else
      status="MISMATCH"
      problems+=(".NET SDK is $sdk, pinned $dotnet_pin (run: make toolchain-dotnet)")
    fi
    row ".NET SDK" "$sdk  [$status]  $(command -v "$DOTNET")"
  else
    row ".NET SDK" "NO SDK matching $dotnet_pin for $DOTNET"
    problems+=(".NET SDK $dotnet_pin is not installed for $DOTNET (run: make toolchain-dotnet)")
  fi
  row "DOTNET_ROOT" "${DOTNET_ROOT:-<unset>}  (from $DOTNET_ROOT_ORIGIN)"
else
  row ".NET SDK" "NOT INSTALLED at $DOTNET"
  problems+=(".NET SDK $dotnet_pin is not installed (run: make toolchain-dotnet)")
fi

# The laptop has an old global dotnet-ef (net8) in ~/.dotnet/tools. If the
# user-local ~/.dotnet comes first on PATH, `dotnet ef` would run it on a host
# without the .NET 8 runtime. The Makefile never relies on PATH; this is a hint.
path_dotnet="$(command -v dotnet 2>/dev/null || true)"
if [[ -n "$DOTNET_ROOT" && -n "$path_dotnet" \
  && "$(readlink -f "$path_dotnet")" == "$(readlink -f "$DOTNET_ROOT/dotnet" 2>/dev/null || echo none)" \
  && -e "$DOTNET_ROOT/tools/dotnet-ef" ]]; then
  warnings+=("'dotnet' on PATH is $path_dotnet and a global dotnet-ef exists in $DOTNET_ROOT/tools; it was built for an older .NET and may fail. The repo will use a local tool manifest (S04).")
fi

echo
echo "Machine"
row "Disk free" "$(df -h --output=avail "$HOME" | tail -n 1 | tr -d ' ') in $HOME"
row "RAM avail" "$(free -h | awk '/^Mem:/ {print $7}') of $(free -h | awk '/^Mem:/ {print $2}')"

echo
for w in "${warnings[@]}"; do printf 'warning: %s\n' "$w"; done
if ((${#problems[@]} > 0)); then
  for p in "${problems[@]}"; do printf 'problem: %s\n' "$p"; done
  echo "doctor: NOT READY"
  exit 1
fi
echo "doctor: toolchain OK"
