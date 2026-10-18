# Laptop test server (B03)

The laptop is the phone's private server until B14. This is separate from `make up`: project
`fitness-buddy-phone`, volume `fitness-buddy-phone_phone-data`, API bound only to
`127.0.0.1:5199`. Postgres publishes no port. Production configuration runs api, worker and
migrate from one immutable image built from `origin/main`. Development resets must never target
this project or volume. No automatic network exposure or container restart after a reboot.

## Initial owner setup

1. Install Tailscale on the A55 from its official Android store page, sign in, and connect.
   Laptop: `bash tools/scripts/setup-tailscale.sh` installs pinned **1.104.1** from Tailscale's
   signed Ubuntu 24.04 repository (sudo is required). Then:

   ```bash
   sudo tailscale up --accept-routes=false --accept-dns=false
   sudo tailscale set --operator="$USER"
   ```

   Sign in with the same account as the phone. Operator access lets your existing laptop user
   manage Serve without repeated sudo; it does not turn on Tailscale SSH, exit nodes or Funnel.
   No key or sudo password belongs in chat or git. Use the laptop only as a test server.

2. **Check storage protection before real data.** Check `lsblk -o NAME,TYPE,FSTYPE,MOUNTPOINTS`
   and `findmnt --target /var/lib/docker`. The controller checks for a `crypt` block ancestor on
   Docker's data root, its private state and its backups. It refuses activation without encryption or an explicit recorded owner exception. On2026-10-18
   the owner approved **unencrypted storage for this private laptop test server**, after the risk
   of a lost/accessed disk exposing data and backups was explained. This approval does not apply
   to production. Record it using `python3 tools/scripts/phone-server.py accept-unencrypted-storage`
   only after owner approval. The private receipt binds the project, machine, selected-device
   policy, actual state/Docker/backup paths and backing mounts. Changes invalidate it. Inspection
   errors still fail closed. Never repartition/reinstall or silently accept a storage trade-off.

3. From the clean up-to-date `main` checkout:

   ```bash
   make serve-phone-prepare
   make serve-phone-policy
   ```

   Prepare fetches main, exports `backend/` into a disposable build context and records the
   exact revision and immutable image ID. Step-branch/uncommitted backend code cannot enter
   the phone image. Four unrelated random database passwords are created once, outside git;
   never delete or regenerate them while the volume exists. State lives in
   `~/.local/share/fitness-buddy/phone-server/` (directory 0700, secrets 0600). It includes
   runtime compose/controller snapshots, so later branch changes do not change the running
   stack or the backup timer. The bootstrap script contains no secrets and is 0644 so the
   container's Postgres user can read it; its parent is private.

4. Open [Tailscale Access controls](https://login.tailscale.com/admin/acls) yourself. For this
   dedicated two-device tailnet, apply the **whole private** `tailnet-policy.json` printed by
   the policy command, replacing the default allow-all rules. It grants only A55 IPv4/IPv6
   addresses → laptop IPv4/IPv6 TCP443. The generated tests assert allowed 443 and denied
   SSH/direct API/another source. Save only when policy validation passes. If you add another
   device, preserve default-deny and add a negative assertion for its real address. Policy
   tests are not proof of a physical third-device test. This complete policy is suitable only
   for the dedicated tailnet; do not overwrite unrelated devices' access without review.

5. In [Tailscale DNS](https://login.tailscale.com/admin/dns), enable HTTPS certificates.
   Certificate Transparency publishes the machine DNS name. Keep the concrete hostname out of
   this public repo, screenshots and evidence. Network isolation and policy, rather than name
   secrecy, protect the service. **Never enable Funnel.** After applying the exact policy:

   ```bash
   python3 tools/scripts/phone-server.py confirm-policy
   make serve-phone
   make serve-phone-status
   ```

   `confirm-policy` records **your attestation**, not an automated inspection of the remote
   policy. Regenerating/changing the policy or selected devices invalidates it. Never run it
   just to bypass the gate. Startup also checks device identity/addresses, certificate
   capability and encrypted storage or the exact owner-approved laptop exception. Existing unrelated Serve configuration is refused.
   The Docker bridge gateway is discovered after Postgres starts and trusted as one `/32`
   proxy hop; broad Docker CIDRs are not trusted.

## Phone check and access boundaries

Turn A55 Wi-Fi **off**, leave mobile data and Tailscale **on**, and open the private HTTPS URL
printed by `make serve-phone-status`. `/health/ready` should return `Healthy` with a valid
system-trusted certificate. A normal browser cannot supply `/v1/config`'s required headers;
use the app/integration client or an HTTP client with these fixed synthetic headers:

```text
X-App-Version: 0.1.0
X-Platform: android
X-Device-Id: 0192a5d4-7c3e-7b1a-9f2e-3c4d5e6f7a8b
```

`/v1/config` returns `minimumAppVersion`, `featureFlags`, `thresholds`. A browser without
headers correctly returns a 400 problem. Check `/v1/config` on the phone with headers before
claiming the card's full config criterion. A11 wires the app's daily-build URL.

- With Tailscale off on the A55, the HTTPS URL must be unreachable. Reconnect afterward.
- A third tailnet device must also fail to reach TCP443; test both address families if present.
- Through Serve, a synthetic client request with spoofed `X-Forwarded-For` and `-Proto: http`
  must still receive HSTS (Serve should overwrite client values). Record only booleans and
  a trace ID, never an address or identity. Existing Host tests also reject forwarding from
  untrusted direct peers. The actual Serve-to-container hop remains a live check.
- `make serve-phone-status` tests HTTPS from the laptop itself, which the A55-only ACL may deny; use loopback readiness plus the real A55 test as the health evidence. `tailscale serve status --json` must show only the intended HTTPS reverse proxy and no
  enabled `AllowFunnel`. No LAN or public listener should expose 5199 or Postgres.

You may **disconnect USB and close the chat app at any time**; neither is used for hosting.
The phone needs Tailscale only while using online backend features. Offline diary, targets and
other local features keep working without it. Until B14, online features also need the laptop
awake, online and running this stack. No Buddy paid calls are part of B03.

## Backups and restore drill

After first startup:

```bash
make serve-phone-backup
make serve-phone-restore-check
make serve-phone-timer
systemctl --user list-timers fitness-buddy-phone-backup.timer
```

Nightly at 02:00 local time, a user timer writes a PostgreSQL custom-format dump under the
private `backups/` folder. Missed ticks catch up while logged in (`Persistent=true`); the timer
cannot run while the laptop is off, logged out without a user manager, or the database is
stopped. `make serve-phone-status` reports backup age and marks over 26 hours overdue. Inspect
`systemctl --user status fitness-buddy-phone-backup.service` for a content-free error. Child
stdout/stderr, SQL errors and credentials are never echoed by the controller.

The dedicated non-superuser `fb_backup` has `pg_read_all_data` and BYPASSRLS, needed to include
all users' FORCE RLS rows. It has no write, create-database or create-role permission. Application
containers receive only fb_app; migrate receives only fb_migrator. Backup and scratch restore
commands execute through the private Postgres container. No backup credential is given to API.

Dumps are atomically installed only after successful completion. Only matching owned dump
files older than seven days are pruned, after success; a failed dump preserves old backups.
Restore-check creates a randomly named `fb_restore_…` database, restores without owner/ACL
using admin, checks module tables, and drops only that scratch database, including on failure.
The live database is never a restore target. CI additionally proves two synthetic RLS users'
rows/counts and values survive restore. Live row counts are not compared with a concurrent
changing database. Do not print user row contents for verification.

These are **local daily dumps**, not B14's off-device/PITR backups. Losing the laptop loses
both server copy and local dumps; the phone still holds its local-first data. B14 will require
an explicit protected transfer, validated restore, appropriate secrets and cutover to Hetzner.

## Stop, restart and upgrade

```bash
make serve-phone-stop        # removes only this controller's Serve mapping; stops containers
make serve-phone             # rechecks gates; migrates before api/worker; existing volume stays
```

After a reboot/login, run `make serve-phone`; the stack deliberately starts manually. Tailscale's
system daemon and background Serve configuration persist, but a stopped API is unavailable.
Do not enable the mapping until the stack is ready. Stop before planned shutdown. The nightly
backup timer returns at login. Do not use `docker compose down -v`, Docker volume pruning, dev
credentials or a dev image tag against this stack.

Before an upgrade, back up and restore-check, stop, then `make serve-phone-prepare` from main,
then start and check. Preparing refuses a running stack. Migrations are forward/expand only;
rolling back an image never rolls back database schema or overwrites data. Do not delete a
volume to fix a credential/migration problem. The private snapshot can be run even while the
repo is on another branch:

```bash
python3 ~/.local/share/fitness-buddy/phone-server/phone-server.py status
```

## Synthetic verification

`make phone-server-smoke` uses randomly named disposable Docker projects and synthetic data;
it never starts Serve, changes Tailscale policy or reuses the real phone volume. It exercises
Production config and the exact gateway, isolated dev destruction/restart, worker, backups,
read-only backup privileges and scratch restores. `make phone-server-check` is offline.
The CI image job reuses the already-built smoke image. Real mobile data, third-device denial
and spoofed headers through actual Serve remain explicit owner/network checks.

Sources: [official Ubuntu packages](https://pkgs.tailscale.com/stable/#ubuntu-noble),
[Serve](https://tailscale.com/docs/reference/tailscale-cli/serve),
[operator permissions](https://tailscale.com/docs/reference/troubleshooting/linux/linux-operator-permission),
[policy reference](https://tailscale.com/docs/reference/syntax/policy-file).
