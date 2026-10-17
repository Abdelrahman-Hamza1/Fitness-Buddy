#!/usr/bin/env bash
# Regenerates the committed generated code of the Flutter app in apps/mobile
# (S06 plan D14):
#   1. gen-l10n: lib/l10n/app_en.arb -> lib/l10n/gen/ (config in l10n.yaml),
#   2. build_runner: riverpod_generator + drift_dev -> lib/**/*.g.dart, and
#      drift_dev -> test/**/*.g.dart for test-only databases (config in
#      build.yaml),
#   3. drift migration code from the schema dumps in drift_schemas/<db>/ (A01
#      D15): lib/core/db/app_database.steps.dart and the migration tests'
#      schema classes in test/drift/<db>/generated/. New dumps come from
#      `make db-migrations`, never from here.
#   4. dart format all of it, so `make check-dart` accepts them as they are.
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
find lib test -name '*.g.dart' -type f -delete
echo "gen-app: build_runner"
"$DART" run build_runner build

# --- 3. drift migration code (one database: user) ---------------------------------
echo "gen-app: drift_dev schema steps + generate"
"$DART" run drift_dev schema steps drift_schemas/user lib/core/db/app_database.steps.dart
rm -rf test/drift/user/generated
"$DART" run drift_dev schema generate --data-classes --companions \
  drift_schemas/user test/drift/user/generated

# --- 4. Format ------------------------------------------------------------------
mapfile -t outputs < <(find lib/l10n/gen -name '*.dart'; find lib -name '*.g.dart' -o -name '*.steps.dart';
  find test -name '*.g.dart';
  find test/drift -path '*/generated/*.dart')
"$DART" format "${outputs[@]}" | tail -n 1
echo "gen-app: wrote apps/mobile/lib/l10n/gen, lib/**/*.g.dart, lib/**/*.steps.dart, test/**/*.g.dart, test/drift/*/generated (${#outputs[@]} files)"
