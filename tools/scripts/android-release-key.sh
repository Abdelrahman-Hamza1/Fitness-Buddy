#!/usr/bin/env bash
# Creates Fitness Buddy's Android release signing key, once (S06 plan D4, A6;
# runbook docs/runbooks/android-signing.md). Run by hand, never by CI.
#
# Usage: tools/scripts/android-release-key.sh [key-dir]   (default ~/.fitness-buddy/keys)
#
# Writes, outside the repo, readable only by you:
#   <key-dir>/fitnessbuddy-release.jks  PKCS12 keystore, RSA 4096, 30 years, alias fitnessbuddy
#   <key-dir>/release.env               FB_KEYSTORE_PATH + the three values for Gradle
# One random password protects both the keystore and the key: PKCS12 keystores
# don't support a separate key password (keytool ignores it), so
# FB_ANDROID_KEY_PASSWORD = FB_ANDROID_KEYSTORE_PASSWORD.
#
# Refuses to overwrite: a lost or replaced key means every installed build must
# be uninstalled (losing its local data) before a new one installs. Prints the
# certificate's SHA-256 only, never a password.
set -euo pipefail

readonly ALIAS="fitnessbuddy"
readonly VALIDITY_DAYS=10950 # 30 years; Play needs validity past 2033-10-22
readonly DNAME="CN=Fitness Buddy, O=io.github.abdelrahmanhamza1"

log() { printf 'android-release-key: %s\n' "$*"; }
die() { printf 'android-release-key: error: %s\n' "$*" >&2; exit 1; }

key_dir="${1:-$HOME/.fitness-buddy/keys}"
keystore="$key_dir/fitnessbuddy-release.jks"
env_file="$key_dir/release.env"
keytool="${JAVA_HOME:?JAVA_HOME is not set (run via make, or export it)}/bin/keytool"
[[ -x "$keytool" ]] || die "keytool not found at $keytool (run: make toolchain-android)"
command -v python3 >/dev/null || die "python3 is needed to make the password"

[[ ! -e "$keystore" && ! -e "$env_file" ]] \
  || die "$keystore or $env_file already exists; never replace a release key (see the runbook)"

umask 077
mkdir -p "$key_dir"
chmod 700 "$key_dir"

# 256 bits, URL-safe alphabet: no quoting issues in release.env or GitHub secrets.
password="$(python3 -I -c 'import secrets; print(secrets.token_urlsafe(32))')"
export FB_ANDROID_KEYSTORE_PASSWORD="$password"
unset password

# Passwords reach keytool through the environment (:env), never argv.
"$keytool" -genkeypair -keystore "$keystore" -storetype PKCS12 \
  -alias "$ALIAS" -keyalg RSA -keysize 4096 -validity "$VALIDITY_DAYS" \
  -dname "$DNAME" \
  -storepass:env FB_ANDROID_KEYSTORE_PASSWORD -keypass:env FB_ANDROID_KEYSTORE_PASSWORD \
  >/dev/null 2>&1 || { rm -f -- "$keystore"; die "keytool -genkeypair failed"; }

write_env() {
  echo "# Fitness Buddy release signing (S06 D4). SECRET: back up in the password"
  echo "# manager with the keystore; never commit, never paste anywhere else."
  echo "# Read by tools/scripts/build-android.sh (make build-android)."
  echo "FB_KEYSTORE_PATH=$keystore"
  echo "FB_ANDROID_KEYSTORE_PASSWORD=$FB_ANDROID_KEYSTORE_PASSWORD"
  echo "FB_ANDROID_KEY_ALIAS=$ALIAS"
  echo "FB_ANDROID_KEY_PASSWORD=$FB_ANDROID_KEYSTORE_PASSWORD"
}
# A keystore whose password never reached release.env is unusable: written to a
# temp file and renamed, and on any failure both are removed.
env_tmp="$(mktemp "$key_dir/.release.env.XXXXXX")"
if ! { write_env >"$env_tmp" && chmod 600 "$keystore" "$env_tmp" && mv -T -- "$env_tmp" "$env_file"; }; then
  rm -f -- "$env_tmp" "$keystore"
  die "could not write $env_file; removed the new keystore"
fi

fingerprint="$("$keytool" -list -v -keystore "$keystore" -alias "$ALIAS" \
  -storepass:env FB_ANDROID_KEYSTORE_PASSWORD 2>/dev/null \
  | sed -n 's/^[[:space:]]*SHA256: //p')"
log "created $keystore and $env_file (mode 600, dir 700)"
log "certificate SHA-256: $fingerprint"
log "next: back both files up in the password manager, then follow docs/runbooks/android-signing.md"
