# GitHub read token for the CI scripts (TD-108)

`tools/scripts/ci-status.sh` (and through it `merge-step.sh`) and
`tools/scripts/ci-nightly.sh` poll the GitHub API for check runs and workflow
runs. Without a token GitHub allows 60 requests per hour per IP, shared by
every lane on the laptop; on 2026-10-30 that ran out and stalled merges for
about 25 minutes. With a token the limit is 5,000 per hour.

The scripts only **read public data** of this public repo, so the token needs
**no permissions at all**. It only identifies you for the higher rate limit.

## Create it (owner, 3 min, on the laptop or phone)

1. GitHub → profile picture → **Settings** → **Developer settings** →
   **Personal access tokens** → **Fine-grained tokens** → **Generate new token**.
   (Shortcut: <https://github.com/settings/personal-access-tokens/new?name=fitness-buddy-ci-read&description=Laptop+scripts+read+CI+status+of+Fitness-Buddy&expires_in=90>
   fills in the name, description and a 90-day expiry.)
2. **Token name:** `fitness-buddy-ci-read`. **Expiration:** 90 days.
3. **Resource owner:** your account (`Abdelrahman-Hamza1`).
4. **Repository access:** **Public repositories** (read-only). If your screen
   doesn't offer that option, pick **Only select repositories** → `Fitness-Buddy`.
5. **Permissions:** add **none**. Leave every permission at "No access".
6. **Generate token** and copy it (it starts with `github_pat_`; GitHub shows it once).

Never paste the token into a chat, a commit, an issue or a script argument.

## Install it on the laptop (one command)

The token goes into a file outside git, readable only by you:

```bash
install -d -m 700 ~/.config/fitness-buddy
( umask 077; read -rsp 'Paste the token, then Enter: ' t; echo; printf '%s\n' "$t" > ~/.config/fitness-buddy/github-token )
chmod 600 ~/.config/fitness-buddy/github-token
```

`read -s` keeps it off the screen and out of the shell history. If
`XDG_CONFIG_HOME` is set, the file lives at `$XDG_CONFIG_HOME/fitness-buddy/github-token`.

Check: `tools/scripts/ci-nightly.sh` works, and `ci-status.sh` logs
`using the token from …/github-token` (never the value). The scripts ignore the
file with a warning if it is not a regular file with mode 600 owned by you.
`GITHUB_TOKEN` or `GH_TOKEN`, when set, win over the file.

## Rotate it (every 90 days, or at once if it may have leaked)

GitHub emails you about a week before it expires. An expired or revoked token
gets HTTP 401: the scripts print a warning and carry on anonymously (60/hour),
so nothing breaks, it just gets slower. To rotate: open the token in
**Fine-grained tokens** → **Regenerate token** (same settings, new expiry), then
run the install command again. If it may have leaked: **Delete** it there first,
then create a new one. Because it has no permissions, a leaked token can only
read public data and use up your API rate limit.

## Why this token type (checked 2026-10-30)

- A fine-grained token can't be given the **Checks** permission at all
  (a listed fine-grained limitation), but the check-runs and workflow-runs
  endpoints work **without any permission for public resources**, and every
  fine-grained token includes read-only access to public repositories.
- **Public repositories** access gives no access to anything private. "Only
  select repositories → Fitness-Buddy" would work too, but adds the repo's
  Metadata read and nothing useful.
- A classic token would need no scope either, but can't be limited the same way
  and is the older, broader mechanism. A GitHub App is more setup for no gain.
- If the repo ever becomes **private**, this token stops being enough: the
  check-runs endpoint then needs Checks access, which fine-grained tokens can't
  get. Revisit this then.

Sources: GitHub Docs, "Managing your personal access tokens"
(<https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/managing-your-personal-access-tokens>),
"Rate limits for the REST API"
(<https://docs.github.com/en/rest/using-the-rest-api/rate-limits-for-the-rest-api>),
"Permissions required for fine-grained personal access tokens"
(<https://docs.github.com/en/rest/authentication/permissions-required-for-fine-grained-personal-access-tokens>),
"REST API endpoints for check runs"
(<https://docs.github.com/en/rest/checks/runs>).
