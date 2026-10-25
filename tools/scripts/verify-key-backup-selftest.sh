#!/usr/bin/env bash
# A11 T17: two disposable stores; a private script copy pins the first cert.
set -euo pipefail
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
work="$(mktemp -d)"
trap 'rm -rf -- "$work"' EXIT
keytool="${JAVA_HOME:+$JAVA_HOME/bin/}keytool"
export FB_TEST_PASSWORD=obviously-fake-test-password
for key in first second; do
  "$keytool" -genkeypair -alias fitnessbuddy -storetype JKS -keyalg RSA -keysize 2048 -validity 1 \
    -dname CN=synthetic-test -keystore "$work/$key.jks" \
    -storepass:env FB_TEST_PASSWORD >/dev/null 2>&1
done
cert="$("$keytool" -J-Duser.language=en -J-Duser.country=US -list -v -keystore "$work/first.jks" -storepass:env FB_TEST_PASSWORD 2>/dev/null | sed -n 's/^[[:space:]]*SHA256: //p' | tr -d ':' | tr A-F a-f)"
"$keytool" -exportcert -alias fitnessbuddy -keystore "$work/first.jks" -storepass:env FB_TEST_PASSWORD -file "$work/public.cer" >/dev/null 2>&1
"$keytool" -importcert -noprompt -alias fitnessbuddy -keystore "$work/cert-only.jks" -storepass:env FB_TEST_PASSWORD -file "$work/public.cer" >/dev/null 2>&1
cp "$work/first.jks" "$work/wrong-key-password.jks"
export FB_OTHER_PASSWORD=different-fake-key-password
"$keytool" -keypasswd -alias fitnessbuddy -keystore "$work/wrong-key-password.jks" -storepass:env FB_TEST_PASSWORD -keypass:env FB_TEST_PASSWORD -new:env FB_OTHER_PASSWORD >/dev/null 2>&1
cp "$work/first.jks" "$work/wrong-alias.jks"
"$keytool" -changealias -alias fitnessbuddy -destalias wrong -keystore "$work/wrong-alias.jks" -storepass:env FB_TEST_PASSWORD >/dev/null 2>&1
mkdir -p "$work/repo/tools/scripts" "$work/repo/.github/workflows" "$work/jdk/bin"
cp "$root/.github/workflows/ci.yml" "$work/repo/.github/workflows/ci.yml"
cp "$root/tools/scripts/verify-key-backup.sh" "$work/repo/tools/scripts/"
printf 'readonly RELEASE_CERT_SHA256="%s"\n' "$cert" >"$work/repo/tools/scripts/build-android.sh"
# Assert the actual invocation, then forward to the real keytool.
export REAL_KEYTOOL="$(command -v "$keytool")"
cat >"$work/jdk/bin/keytool" <<'PY'
#!/usr/bin/env python3
import os, sys
assert '-storepass' not in sys.argv
assert '-keypass' not in sys.argv
assert sys.argv[sys.argv.index('-storepass:env')+1] == 'FB_BACKUP_PASSWORD'
assert os.environ['FB_BACKUP_PASSWORD'] not in sys.argv
os.execv(os.environ['REAL_KEYTOOL'], [os.environ['REAL_KEYTOOL'], *sys.argv[1:]])
PY
chmod +x "$work/jdk/bin/keytool"
export JAVA_HOME="$work/jdk"
# The real production pin must reject the disposable test certificate.
if printf '%s\n' "$FB_TEST_PASSWORD" | bash "$root/tools/scripts/verify-key-backup.sh" "$work/first.jks" >"$work/out" 2>&1; then exit 1; fi
verify() { printf '%s\n' "$FB_TEST_PASSWORD" | bash "$work/repo/tools/scripts/verify-key-backup.sh" "$1" >"$work/out" 2>&1; }
verify "$work/first.jks"
if verify "$work/wrong-key-password.jks"; then echo 'AT-006 unrecoverable private key accepted' >&2; exit 1; fi
if verify "$work/cert-only.jks"; then echo 'AT-006 certificate-only backup accepted' >&2; exit 1; fi
if verify "$work/wrong-alias.jks"; then echo 'AT-006 wrong-alias backup accepted' >&2; exit 1; fi
if verify "$work/second.jks"; then exit 1; fi
FB_TEST_PASSWORD=wrong-fake-password
if verify "$work/first.jks"; then exit 1; fi
if grep -qF "$FB_TEST_PASSWORD" "$work/out"; then exit 1; fi
echo 'verify-key-backup-selftest: PASS (AT-006 matching private key, certificate-only, wrong alias/cert/store password/key password, env-only passwords)'
