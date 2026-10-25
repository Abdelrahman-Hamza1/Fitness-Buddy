#!/usr/bin/env bash
# A11 D16/PA9: verify the downloaded backup, without a password in argv or logs.
set -euo pipefail
[[ $# == 1 && -f "$1" ]] || { echo 'verify-key-backup: supply a keystore copy' >&2; exit 1; }
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
pin="$(sed -n 's/^readonly RELEASE_CERT_SHA256="\([a-f0-9]*\)"$/\1/p' "$root/tools/scripts/build-android.sh")"
[[ "$pin" =~ ^[a-f0-9]{64}$ ]] || exit 1
# The release alias is pinned in CI (android-signing.md), not secret input.
alias="$(sed -n 's/^          FB_ANDROID_KEY_ALIAS: \([a-zA-Z0-9_-]*\)$/\1/p' "$root/.github/workflows/ci.yml")"
[[ "$alias" == fitnessbuddy ]] || { echo 'verify-key-backup: release alias config invalid' >&2; exit 1; }
keytool="${JAVA_HOME:+$JAVA_HOME/bin/}keytool"
IFS= read -r -s -p 'Backup keystore password: ' FB_BACKUP_PASSWORD
printf '\n' >&2
export FB_BACKUP_PASSWORD
# Suppress keytool diagnostics: a wrong password or corrupt file is just failure.
listing="$({ "$keytool" -J-Duser.language=en -J-Duser.country=US -list -v \
  -alias "$alias" -keystore "$1" -storepass:env FB_BACKUP_PASSWORD 2>/dev/null || true; } )"
cert="$(printf '%s\n' "$listing" | sed -n 's/^[[:space:]]*SHA256: //p' | tr -d ':' | tr 'A-F' 'a-f')"
[[ "$listing" == *'Entry type: PrivateKeyEntry'* && "$cert" == "$pin" ]] || {
  echo 'verify-key-backup: release alias/private key/certificate verification failed' >&2; exit 1;
}
# A CSR is signed by the recovered private key. No private material is exported.
"$keytool" -certreq -alias "$alias" -keystore "$1" \
  -storepass:env FB_BACKUP_PASSWORD -keypass:env FB_BACKUP_PASSWORD \
  -file /dev/null >/dev/null 2>&1 || {
  echo 'verify-key-backup: private-key signing failed' >&2; exit 1;
}
unset FB_BACKUP_PASSWORD
printf 'Certificate SHA-256: %s\n' "$cert"
