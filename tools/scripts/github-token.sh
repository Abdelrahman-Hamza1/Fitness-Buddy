# shellcheck shell=bash
# shellcheck disable=SC2034 # gh_token/gh_token_source are read by the caller
# Sourced by the scripts that read the GitHub API (ci-status.sh, ci-nightly.sh;
# merge-step.sh through ci-status.sh). TD-108: a private read-only token lifts
# the anonymous limit of 60 requests/hour (shared by every lane on this
# machine) to 5,000. Not executable on its own.
#
# load_github_token sets two variables:
#   gh_token          the token, or empty (anonymous)
#   gh_token_source   where it came from, for a log line (never the value)
# Order: GITHUB_TOKEN, then GH_TOKEN, then the private file
#   ${XDG_CONFIG_HOME:-$HOME/.config}/fitness-buddy/github-token
# (outside git; how to create it: docs/runbooks/github-token.md). The file is
# used only when it is a regular file owned by you with mode 600; otherwise it
# is ignored with a warning on stderr. The token itself is never printed.

github_token_file() {
  printf '%s/fitness-buddy/github-token' "${XDG_CONFIG_HOME:-$HOME/.config}"
}

load_github_token() {
  gh_token="" gh_token_source=""
  if [[ -n ${GITHUB_TOKEN:-} ]]; then
    gh_token=$GITHUB_TOKEN gh_token_source=GITHUB_TOKEN
    return 0
  fi
  if [[ -n ${GH_TOKEN:-} ]]; then
    gh_token=$GH_TOKEN gh_token_source=GH_TOKEN
    return 0
  fi
  local file mode owner value
  file=$(github_token_file)
  [[ -e $file || -L $file ]] || return 0
  if [[ -L $file || ! -f $file ]]; then
    printf 'github-token: warning: ignoring %s: not a regular file\n' "$file" >&2
    return 0
  fi
  mode=$(stat -c %a -- "$file" 2>/dev/null || echo '?')
  owner=$(stat -c %u -- "$file" 2>/dev/null || echo '?')
  if [[ $mode != 600 || $owner != "$(id -u)" ]]; then
    printf 'github-token: warning: ignoring %s: mode %s, owner uid %s (must be 600 and yours; fix: chmod 600 %s)\n' \
      "$file" "$mode" "$owner" "$file" >&2
    return 0
  fi
  # First line, surrounding whitespace removed. GitHub tokens are [A-Za-z0-9_]
  # (github_pat_…, ghp_…); anything else is a paste error, reported without
  # echoing it.
  IFS= read -r value <"$file" || true
  value=${value//[[:space:]]/}
  if [[ ! $value =~ ^[A-Za-z0-9_]{20,255}$ ]]; then
    printf 'github-token: warning: ignoring %s: the first line does not look like a GitHub token\n' "$file" >&2
    return 0
  fi
  gh_token=$value gh_token_source=$file
}
