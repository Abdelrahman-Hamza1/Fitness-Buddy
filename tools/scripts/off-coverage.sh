#!/usr/bin/env bash
# A03 D11: measure Open Food Facts coverage for Palestine / Jordan / Israel.
# Downloads the official TSV export (~0.9 GB gz) into a fresh temp dir OUTSIDE the
# repo, records Last-Modified + download date + sha256, streams it through
# off_coverage.py (aggregates only), deletes the file. OFF data is ODbL: it is
# never committed. Usage: off-coverage.sh   (prints Markdown on stdout)
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
url="${OFF_EXPORT_URL:-https://static.openfoodfacts.org/data/en.openfoodfacts.org.products.csv.gz}"
need_kb=$((2 * 1024 * 1024))

tmp="$(mktemp -d "${TMPDIR:-/tmp}/off-coverage.XXXXXX")"
trap 'rm -rf "$tmp"' EXIT

free_kb="$(df -Pk "$tmp" | awk 'NR==2 {print $4}')"
if [ "$free_kb" -lt "$need_kb" ]; then
  echo "off-coverage: need >= 2 GB free in $tmp, have $((free_kb / 1024)) MB" >&2
  exit 1
fi

gz="$tmp/export.csv.gz"
curl -fsSL --retry 3 --retry-delay 5 -D "$tmp/headers" -o "$gz" "$url" >&2
last_modified="$(tr -d '\r' < "$tmp/headers" | awk -F': ' 'tolower($1)=="last-modified" {v=$2} END {print v}')"
sha="$(sha256sum "$gz" | awk '{print $1}')"
size="$(stat -c %s "$gz")"

echo "- Export URL: $url"
echo "- Last-Modified: ${last_modified:-unknown}"
echo "- Downloaded: $(date -u +%Y-%m-%dT%H:%MZ)"
echo "- Size (gz): $size bytes"
echo "- sha256: $sha"
echo
gzip -dc "$gz" | python3 -I "$repo_root/tools/scripts/off_coverage.py" "$repo_root/data/sources/off_local_sample.yaml"
