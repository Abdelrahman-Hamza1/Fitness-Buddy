# Admin console (B23, D-099)

The owner-only web console: remote config & flags and the audit log in B23a; Overview, Accounts, Jobs & sync and Catalog
in B23b. It runs as the `admin` role of the same image with its own database login `fb_admin`, behind **its own tailnet node**
`fb-admin` (a Tailscale sidecar container). There is **no public URL**: the laptop and the A55 both open
`https://fb-admin.<tailnet>.ts.net/admin` over Tailscale. Never enable Funnel. Spec: `spec/22-admin-console.md`; plan:
the B23 card.

**Why its own hostname:** browsers don't separate cookies by port. On a shared hostname (the old `:8443` plan) the console
session cookie would also be sent to the API on `:443`, so a compromised API could replay it. On `fb-admin.<tailnet>` the
host-only `__Host-` cookies never reach the API. For the same reason there is no `http://localhost` console URL on the
laptop stack: its loopback port `127.0.0.1:5197` is for the controller's readiness check only.

## What it never shows

No user content (AD-001): no food names, diary entries, chat text, prompts or replies, weights, notes or measurements.
Only counts, sizes, timings, error types and pseudonymous account IDs. Emails show masked (`o…@example.com`). The
`fb_admin` login can't read any user table; it runs only content-free `admin_*` database functions (owner O1, TD-118).
Console logs carry IDs and codes only.

## One-time setup (owner, ~15 minutes, free)

Do these in order, on the laptop, from a clean `main` that includes B23. `<tailnet>` is your tailnet's MagicDNS suffix
(`make serve-phone-status` prints the full console URL once the policy exists); keep it out of git, screenshots and chat.

1. **Tailnet policy.** Regenerate and re-apply it. It now declares the tag `tag:fb-admin` (owned by tailnet admins) and
   lets the A55 and the laptop reach the console node on HTTPS 443 only; the console node itself can reach nothing, and no
   device can turn on Funnel:

   ```sh
   make serve-phone-policy                 # then paste the printed private file into Tailscale → Access controls
   python3 tools/scripts/phone-server.py confirm-policy
   ```

2. **Console node auth key.** Tailscale admin console → Settings → Keys → **Generate auth key**: Reusable **off**,
   Ephemeral **off**, Tags **on** → `tag:fb-admin`, expiry 1 day (it's used once, at the node's first start; pre-approved
   if device approval is on). Then store it; it's typed at a hidden prompt, never on the command line:

   ```sh
   make serve-phone-console-key
   ```

   It lives at `~/.local/share/fitness-buddy/phone-server/console-tailscale-key/authkey` (0600); the node's state lives
   next to it in `console-tailscale/` (0700). If a machine named `fb-admin` already exists in Tailscale, remove it first,
   or the node gets another name and the controller stops.

3. **Google Web client.** In the Google Cloud project that holds the app's sign-in clients: APIs & Services →
   Credentials → Create credentials → OAuth client ID → **Web application**. Authorized JavaScript origins: exactly
   `https://fb-admin.<tailnet>.ts.net` (no port, no localhost). No redirect URIs, no client secret. Then:

   ```sh
   make serve-phone-console CONSOLE_CLIENT_ID=<id>.apps.googleusercontent.com
   ```

4. **Allow-list.** Add yourself; the email is typed at a hidden prompt:

   ```sh
   make serve-phone-admin-allow            # handle owner, role operator (ADMIN_HANDLE / ADMIN_ROLE to change)
   ```

5. **Start.** `make serve-phone-prepare`, then `make serve-phone`. The controller makes sure the `fb_admin` and `fb_worker`
   logins exist with their own passwords (`ensure-admin-role`, `ensure-worker-role`; an old state gets the new secret), runs migrations (they seed remote config version 1 from the current settings), starts api,
   worker, the console and its node, and refuses to go on unless the node is exactly `fb-admin.<tailnet>`, tagged
   `tag:fb-admin`, has its HTTPS certificate and serves exactly one route (HTTPS 443 → the console) with no Funnel. Then
   it serves the API on the laptop's own name as before (exactly one route). `make serve-phone-status` shows both.

6. **Pin your Google subject.** Open `https://fb-admin.<tailnet>.ts.net/admin` and sign in once: the entry is still
   **pending**, so the console creates no session and shows your Google subject (a long number). Pin it, then sign in
   again:

   ```sh
   make serve-phone-admin-allow ADMIN_SUBJECT=<the number>
   ```

The allow-list file is `~/.local/share/fitness-buddy/phone-server/console/allow-list.json` (0600). Changes apply within
10 seconds. Only pinned entries can sign in; a session ends at once when its entry is removed, re-keyed to another Google
account or its handle is reused. Roles: `viewer` (read) and `operator` (also change).

## Using it

- **Sign-in:** Google's button. The session lasts 12 hours (no sliding); sign out from the top bar.
- **Remote config & flags:** edit a draft, review the diff and its reach, publish with a reason. Every version stays in
  the history; "Review rollback" publishes a new version with an older version's values. Changes reach the API and the
  worker within about 5 seconds.
- **Minimum app version (the "Update the app" kill switch):** it can never be raised above the newest app version an
  install active in the last 7 days reported, and not at all when no install reported one. A raise needs the version
  typed and a sign-in less than 15 minutes old (the console asks you to sign in again). Re-auth proves a fresh, explicit
  Google sign-in step by the same account in this browser; it doesn't make Google ask for your password again.
- **Audit log:** every sign-in, refused sign-in, change and export, newest first; filter and export CSV. It can't be
  edited or deleted.
- **Overview (home):** health of the API (its readiness, probed on the compose network), database, workers (heartbeats
  every 30 s), backups (the controller's status file after each backup), catalog and Buddy; installs in 1/7/30 days,
  accounts by type, server errors in 24 h, AI spend this month ("no cap set" until phase 2), app versions in use and open
  alerts, each linking to the window behind it. Error and lookup counts are approximate (written once a minute).
- **Accounts:** newest first, filter by type or "sync issues" (rejects in the last 7 days, most first); both filters apply
  before the page is cut, and the issue list pages on ("More accounts with issues"). Find an account only by its
  **exact** email (case and spaces ignored); partial or wildcard searches never match. The lookup is audited without the
  address and limited to 10 a minute. Email sign-in accounts never store the address (only its keyed hash), so their email
  column says "not stored (email sign-in)" and the lookup finds them only when the console has Identity's lookup key: on the
  laptop the controller mounts just the pepper into the console (read-only, `Identity__PepperFile`); without it the result
  says those accounts weren't searched and the audit row reads `no-match-partial`. The detail page shows documents per
  entity type and the devices without their ids.
  Account controls (revoke, disable, delete) come with B24.
- **Jobs & sync:** queues per type with pending, due, in progress (as of the last heartbeat, jobs and events counted
  separately), failed and oldest due item. A type or error the console doesn't know reads `other`. Operators can retry a
  failed item, cancel a pending or failed job, and pause/resume a job type (`ops.cleanup` can't be paused; events never
  pause). Each request has exactly one audit row with the state found under the lock: `ok` (before → after), `no-op` (it
  already was so, e.g. a resubmitted form) or `refused` (wrong state, missing, or a worker is running it right now:
  "busy", try again later). Sync shows pushes, pulls and rejects by reason in 7 days.
- **Catalog:** releases (version, foods and change, pack size, current), the Open Food Facts cache, lookup outcomes and
  sanity flags for 14 days. Publishing or rolling back a release stays a laptop command
  ([catalog runbook](catalog.md)); installs per pack version and a maintenance message are in the backlog.

### Account controls (B24, AD-011)

On an account's page (`/admin/accounts/<id>`, the Controls section), operators only. Each control needs a **reason code** (owner
request, test account, security, abuse, support, other), never free text, so no email or user content ever sits next to
an account ID in the audit log. **Revoke all devices, disable and delete** also need the account ID typed and a sign-in
less than 15 minutes old (the console sends you to sign in again).

| Control | Effect on the app |
|---|---|
| Revoke one device | That device's next request gets 401; its refresh fails. A registered person sees "sign in again"; a guest's app starts a new guest account |
| Revoke all devices | The same on every device |
| Disable | Every session ends; sync, Buddy and every request get 401; signing in again fails (generic sign-in error, no "disabled" message yet). Queued maintenance work keeps running |
| Enable | Signing in works again (old sessions stay ended). Refused while a deletion is pending |
| Buddy daily limit | 0–1000 calls a day for this account; 0 turns Buddy off for it (the app shows its "limit reached" state); empty = the default |
| Delete | The account is disabled at once; the API deletes all its server data within seconds, the same deletion as in the app (AC-031). The page then says "no such account" |

What these can't do: **guests** can't be kept out (after a revoke or disable the app creates a new guest account with the
phone's data; delete removes the old one), and **no server control wipes a phone**: the phone keeps its local data, and
signing in again after a deletion creates a new account.

A pending deletion that fails (for example, the recovery state is broken) keeps the account disabled and retries with
backoff; the page shows the attempts and the last error code. Fix the cause (the account deletion runbook), and the next
try completes it.

**Audit rows of a deleted account** keep its pseudonymous account ID (it matches no row anywhere after the deletion) and
only codes and numbers: no email, device ID or content. They're kept like every audit row (append-only, no retention
job). Opening the account then shows "no such account (deleted or never existed)".

## Recovery

- **A bad minimum version locked apps out:** force the minimum from configuration, which wins over the database and works
  with it down, then fix the config in the console and clear the override:

  ```sh
  make serve-phone-override VERSION=0.1.0  # then: make serve-phone
  # … publish a correct version in the console …
  make serve-phone-override VERSION=       # then: make serve-phone
  ```

  The console shows a banner while the override is active. Locally (dev stack) the same switch is
  `FB_MIN_APP_VERSION=… make up`.
- **Console node won't start** (`serve-phone` stops with a console-node message): an expired or used key → create a new
  one (step 2) and run `make serve-phone-console-key`; "not named fb-admin" → remove the stale `fb-admin` machine in
  Tailscale and delete `console-tailscale/` in the state folder, then add a new key. The API keeps running either way.
- **Can't sign in:** check the allow-list file (an invalid file means nobody can sign in, and readiness reports
  `allow-list-invalid`), the pinned subject, and the client ID's JavaScript origins. Fix the file; no restart needed.
- **A job type is paused and work piles up:** Jobs & sync → Resume. Pauses survive restarts (they are rows in
  `ops.queue_pauses`).
- **"No worker heartbeat" alert:** the worker container is down or can't reach the database; `make serve-phone-status`,
  then `make serve-phone`.
- **Database unreachable:** API and worker keep the last good config; after a restart they use the settings' defaults
  (never "no minimum").

## Local development

`make up` now runs a one-shot `roles` step before migrations that creates any missing development login (B23: `fb_admin`; B23b: `fb_worker`, which the worker now uses),
so an existing local volume upgrades without a reset. `make up-admin` also starts the console on `http://localhost:5196/admin`; it needs
`FB_ADMIN_GOOGLE_CLIENT_ID` (a Web client with that origin) and `FB_ADMIN_CONSOLE_DIR` pointing at a folder with an
`allow-list.json` in the same format as above. Tests use a fake Google verifier; never put a real account in fixtures.
