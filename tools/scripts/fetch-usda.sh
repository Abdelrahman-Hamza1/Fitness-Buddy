#!/usr/bin/env bash
# Downloads the pinned USDA FoodData Central CSV zips (SR Legacy + Foundation
# Foods, CC0) and unpacks them into <out-dir>/sr_legacy and <out-dir>/foundation.
# <out-dir> must not exist yet or be empty, and must be outside the repo: the
# bulk data is never committed (A03 D2).
#
# The sha256 of each zip is pinned in data/usda/sources.yaml. On the first run
# (no sources.yaml) the file is recorded from what was downloaded; afterwards a
# mismatch fails.
#
# Usage: tools/scripts/fetch-usda.sh <out-dir>
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
sources="$repo_root/data/usda/sources.yaml"
base="https://fdc.nal.usda.gov/fdc-datasets"

die() { echo "fetch-usda: error: $*" >&2; exit 1; }

[[ $# -eq 1 ]] || die "usage: fetch-usda.sh <out-dir>"
out="$1"
case "$(realpath -m "$out")/" in
  "$repo_root"/*) die "out-dir must be outside the repository (bulk data is never committed)" ;;
esac
if [[ -d "$out" ]] && [[ -n "$(ls -A "$out")" ]]; then die "out-dir is not empty: $out"; fi
mkdir -p "$out"

# name|release|zip file
datasets=(
  "sr_legacy|2018-04|FoodData_Central_sr_legacy_food_csv_2018-04.zip"
  "foundation|2026-04-30|FoodData_Central_foundation_food_csv_2026-04-30.zip"
)

# pinned_sha <name>: the sha256 recorded in sources.yaml, or empty.
pinned_sha() {
  [[ -f "$sources" ]] || return 0
  awk -v n="$1" '$1 == "-" && $2 == "name:" { cur = $3 } cur == n && $1 == "sha256:" { print $2; exit }' "$sources"
}

record="# Pinned USDA FoodData Central CSV releases (CC0). Written by
# tools/scripts/fetch-usda.sh on the first download; later runs verify against it.
datasets:"
for entry in "${datasets[@]}"; do
  IFS='|' read -r name release file <<<"$entry"
  zip="$out/$file"
  echo "== $name $release"
  curl --fail --silent --show-error --location --retry 3 -o "$zip" "$base/$file"
  actual="$(sha256sum "$zip" | awk '{print $1}')"
  pinned="$(pinned_sha "$name")"
  if [[ -f "$sources" && -z "$pinned" ]]; then
    die "$name not pinned in sources.yaml"
  fi
  if [[ -n "$pinned" && "$pinned" != "$actual" ]]; then
    die "$name: sha256 mismatch (pinned $pinned, got $actual)"
  fi
  record+="
  - name: $name
    release: \"$release\"
    url: $base/$file
    downloaded: $(date -u +%Y-%m-%d)
    sha256: $actual"
  mkdir -p "$out/$name"
  # Some releases nest the CSVs in a folder: flatten with -j.
  unzip -q -j -o "$zip" '*.csv' -d "$out/$name"
  rm -f "$zip"
done

if [[ ! -f "$sources" ]]; then
  mkdir -p "$(dirname "$sources")"
  printf '%s\n' "$record" >"$sources"
  echo "fetch-usda: recorded $sources (first run)"
fi
echo "fetch-usda: ok -> $out"
