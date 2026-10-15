#!/usr/bin/env bash
# Regenerates the committed generated code of the Flutter app in apps/mobile
# (S06 plan D14):
#   1. gen-l10n: lib/l10n/app_en.arb -> lib/l10n/gen/ (config in l10n.yaml),
#   2. build_runner: riverpod_generator -> lib/**/*.g.dart (config in build.yaml),
#   3. dart format both, so `make check-dart` accepts them as they are.
# Old outputs are deleted first, so a removed ARB file or provider leaves no
# stale file behind. The result is committed; `make gen-check` fails CI if it
# is stale.
# Called by `make gen-app`, which passes DART and FLUTTER.
# Usage: DART=... FLUTTER=... gen-app.sh
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
: "${DART:?gen-app: error: DART is not set (the Makefile passes it)}"
: "${FLUTTER:?gen-app: error: FLUTTER is not set (the Makefile passes it)}"

cd "$repo_root/apps/mobile"

# --- 1. Localizations -----------------------------------------------------------
rm -rf lib/l10n/gen
echo "gen-app: flutter gen-l10n"
"$FLUTTER" gen-l10n
[[ -f lib/l10n/gen/app_localizations.dart ]] ||
  { echo "gen-app: error: gen-l10n wrote nothing to lib/l10n/gen" >&2; exit 1; }

# --- 2. Riverpod providers --------------------------------------------------------
find lib -name '*.g.dart' -type f -delete
echo "gen-app: build_runner"
"$DART" run build_runner build

# --- 3. Format ------------------------------------------------------------------
mapfile -t outputs < <(find lib/l10n/gen -name '*.dart'; find lib -name '*.g.dart')
"$DART" format "${outputs[@]}" | tail -n 1
echo "gen-app: wrote apps/mobile/lib/l10n/gen and apps/mobile/lib/**/*.g.dart (${#outputs[@]} files)"
