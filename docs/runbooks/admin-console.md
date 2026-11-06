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

5. **Start.** `make serve-phone-prepare`, then `make serve-phone`. The controller makes sure the `fb_admin` login exists
   (`ensure-admin-role`), runs migrations (they seed remote config version 1 from the current settings), starts api,
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
- **Database unreachable:** API and worker keep the last good config; after a restart they use the settings' defaults
  (never "no minimum").

## Local development

`make up` now runs a one-shot `roles` step before migrations that creates any missing development login (B23: `fb_admin`),
so an existing local volume upgrades without a reset. `make up-admin` also starts the console on `http://localhost:5196/admin`; it needs
`FB_ADMIN_GOOGLE_CLIENT_ID` (a Web client with that origin) and `FB_ADMIN_CONSOLE_DIR` pointing at a folder with an
`allow-list.json` in the same format as above. Tests use a fake Google verifier; never put a real account in fixtures.
