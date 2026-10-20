# Identity operations (B04)

Identity is disabled by default. The private laptop uses the owner-approved TD-077 boundary,
a separately provisioned wrapping key and email-code pepper, and only the web/server Google client
ID as an accepted token audience. Android OAuth registration uses the existing release certificate;
never generate a new app signing key. App integration belongs to A20/A33.

## Private laptop activation

After the B04 implementation is reviewed and merged to main:

1. Keep the original private Google IDs file at
   `~/.local/share/fitness-buddy/identity/google-clients.json` (0600, parent0700), containing
   `AndroidClientId` and `WebClientId`. IDs are public configuration; no client secret is used.
2. Run `python3 tools/scripts/phone-server.py configure-identity`. This creates private
   `identity/v1.key`, `identity/pepper`, `identity/config.json`, `identity/email/` and a compose overlay
   under the existing phone-server state. Re-running preserves keys; missing keys after configuration
   require recovery. It does not start a server or deploy branch images.
3. Take a backup, stop the phone stack, prepare the latest main image, start it and take another
   backup/restore check with the B03 commands. The explicit migrate command provisions a signing
   key only if none exists (`--Identity:KeyOperation=ensure`). Normal API/worker startup never creates keys.
4. The overlay runs as the operator's unprivileged UID so private0600 bind-mounted secrets remain
   readable without broadening file permissions. Root, capability grants and writable image filesystems
   are not needed. Config/wrapping keys mount read-only; the local-code subdirectory is writable. B06 also mounts
   separate protected recovery state read-write for API/migrate and read-only for worker.
5. Local email delivery requires both `Identity:PrivateLaptop=true` and
   `Identity:Email:LocalFile:Enabled=true`; Production environment alone never enables it.
   Codes are private0600 JSON files under `identity/email/`, capped at100 files and published by
   atomic rename. Their recorded10-minute expiry is checked on issuance, before host startup opens
   traffic, and on each running one-minute reaper sweep. Unsafe/unwritable cleanup refuses startup;
   a later reaper failure stops the host. A stopped process cannot physically erase files until it
   restarts. Files are never logged or backed up.
   For a manual code check, read the matching challenge file on the laptop; never paste codes/tokens in git.

The existing unencrypted-storage exception applies only to this private laptop. B13/B14 must reject
this local email option and use their own secrets, encrypted recovery storage and the real sender.
Keep the laptop awake/online and Tailscale connected when using online features from the phone.

## Backup and recovery

Each successful phone backup also atomically saves private0600 `backups/identity-recovery.json`:
config, pepper and **all** wrapping-key versions. It excludes delivered-code files. Retain this file
with the DB dump and protect it like the database credentials; keep an owner-controlled copy off
this laptop. The laptop exception does not authorize production recovery storage.

Restore the original pepper/wrapping keys and permissions before starting a restored database.
Do not replace missing files with random bytes: the pepper determines email identity lookup and
wrapping keys decrypt stored signing material. The recovery file is base64 encoding, not encryption.
The restore-check command restores only into a scratch database; it never overwrites live data.

## Explicit rotation

Use the migrate role with its original external migrator connection, identity config and the
existing protected recovery directory/mount. It verifies recovery state and holds the global
maintenance lock before key operations. Routine rotation never replaces the recovery generation:


- `migrate --Identity:KeyOperation=rotate --Identity:WrappingVersion=v1` makes a new active ES256 key;
  the preceding public key stays available for16 minutes (15-minute access lifetime plus30-second skew).
- Create a private32-byte `v2.key` in the existing wrapping directory, back it up, then run
  `migrate --Identity:KeyOperation=rewrap --Identity:WrappingVersion=v2`.
  Rewrap decrypts/authenticates each row, creates fresh96-bit nonces/full128-bit tags, verifies the
  new ciphertext and commits all rows atomically under an advisory lock. Interrupted work rolls back;
  retrying is safe. Keep old wrapping files until every dependent key/dump is retired or recovered.
- `ensure` is idempotent; it never rotates a key merely because a process restarts.

Do not pass passwords or keys on the command line. Supply the existing secret configuration/mounts.
No key-management endpoint exists, and the API has no key-write or migration grants.

Account erasure and backup admission also depend on the protected generation. Follow
[account deletion](account-deletion.md) and [laptop recovery](laptop-test-server.md); restoring the
key bundle alone cannot authorize an old database snapshot.
