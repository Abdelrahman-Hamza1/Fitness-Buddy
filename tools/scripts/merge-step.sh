#!/usr/bin/env bash
# Squash step branches onto main through a CI-verified merge/… branch (TD-036,
# TD-039, TD-108, PROCESS.md §A5). It never touches main unless the `ci` check
# on the pushed commit is green, and it deletes branches only after main moved.
# Usage:
#   tools/scripts/merge-step.sh <ID> "<step name>" <step-branch>
#   tools/scripts/merge-step.sh docs "<what>" <branch>   (planning/process
#   changes outside a step: commit "docs: <what>", branch merge/docs-<branch>)
#   tools/scripts/merge-step.sh chore "<what>" <branch>  (tooling/CI changes
#   outside a step: commit "chore: <what>", branch merge/chore-<branch>)
#   tools/scripts/merge-step.sh group <ID1> "<name1>" <branch1> <ID2> "<name2>" <branch2> […]
#     (TD-108: two or more entries, steps, docs or chore, landing with ONE CI
#     run. One squash commit per entry, chained in the given order: entry 1 on
#     origin/main, entry 2 on entry 1, … Only the top commit is pushed, as
#     merge/group-<ids>; on a green `ci` main moves to it, so main still gets
#     one commit per entry. A branch stacked on an earlier entry's branch is
#     squashed against that branch, so only its own commits count.)
# Each commit is "<ID>: <name>" (or "docs: …"/"chore: …"); the body lists the
# branch's own commit subjects and ends with the trailer in MERGE_TRAILER (one
# line, optional).
# It never checks out a branch while it works (TD-086): the commits are built
# with `git merge-tree` + `git commit-tree` from committed history only, so the
# working folder stays free for the next step while CI runs. At the end it
# updates the local main ref; it checks out main only when the folder was on a
# merged branch with a clean tree. It doesn't push the step branches (CI runs
# only on merge/**, TD-108); remote copies, if any, are deleted after the merge.
# PROGRESS.md never blocks a merge (TD-108): when it is the only conflicting
# file it is regenerated from the merged board and backlog with origin/main's
# tools/scripts/progress.py (never the branch's code; what `make progress`
# writes), and a stale PROGRESS.md in a clean merge is regenerated too, so CI's
# staleness check passes. Any other conflict aborts before anything is pushed.
# Exception: a branch that changes progress.py regenerates PROGRESS.md itself
# (see fresh_progress).
# Environment (both optional, defaults keep the strict behaviour):
#   MERGE_CI_TIMEOUT_MIN  how long to wait for `ci` on the pushed commit
#                         (default 25, ci-status.sh's own default).
#   MERGE_REUSE=1         after a timeout (ci still running or finished green
#                         on the previous attempt), reuse that attempt's commits
#                         instead of building new ones and running CI again.
#                         Only when origin/<merge branch> has the same trees
#                         (one per entry) on the same base (the current
#                         origin/main); otherwise fresh commits are built as
#                         usual. Not for retrying a red CI: a reused red commit
#                         stays red.
# ci-status.sh reads the GitHub token from GITHUB_TOKEN/GH_TOKEN or the private
# file ~/.config/fitness-buddy/github-token (TD-108).
set -euo pipefail
shopt -s inherit_errexit

die() { echo "merge-step: $*" >&2; exit 1; }
note() { echo "merge-step: $*" >&2; }

usage='usage: merge-step.sh <ID> "<step name>" <step-branch>
   or: merge-step.sh group <ID1> "<name1>" <branch1> <ID2> "<name2>" <branch2> [...]'

group=false
if [[ ${1:-} == group ]]; then
  group=true
  shift
  (($# >= 6 && $# % 3 == 0)) || die "group needs at least two entries of <ID> \"<name>\" <branch>"$'\n'"$usage"
else
  [[ $# -eq 3 ]] || die "$usage"
fi

ids=() titles=() branches=() tags=()
while (($#)); do
  id=$1 name=$2 branch=$3
  shift 3
  if [[ $id == docs || $id == chore ]]; then
    tag="$id-${branch##*/}"
  elif [[ $id =~ ^[A-Z][0-9]{2}[a-z]?( \(contract\))?$ ]]; then
    tag="${id%% *}"
  else
    die "bad step ID: $id (A01…, B01…, S06a, 'B05 (contract)', docs or chore)"
  fi
  [[ -n $name ]] || die "empty name for $id"
  for b in "${branches[@]}"; do
    [[ $b != "$branch" ]] || die "$branch appears twice in the group"
  done
  ids+=("$id") titles+=("$id: $name") branches+=("$branch") tags+=("$tag")
done
n=${#ids[@]}
if [[ $group == true ]]; then
  merge="merge/group-$(IFS=-; echo "${tags[*]}")"
else
  merge="merge/${tags[0]}"
fi
git check-ref-format "refs/heads/$merge" || die "not a valid branch name: $merge"

# "entry 2 (A18, step/A18-x)" in a group, the branch alone otherwise.
label() {
  if [[ $group == true ]]; then
    echo "entry $(($1 + 1)) (${ids[$1]}, ${branches[$1]})"
  else
    echo "${branches[$1]}"
  fi
}
entries() {
  local i
  for ((i = 0; i < n; i++)); do echo "  $((i + 1)). ${titles[i]}  [${branches[i]}]"; done
}

root=$(git rev-parse --show-toplevel)
cd "$root"

current=$(git symbolic-ref -q --short HEAD || true)
clean=false
[[ -z $(git status --porcelain) ]] && clean=true
for branch in "${branches[@]}"; do
  git rev-parse --verify -q "refs/heads/$branch" >/dev/null || die "no local branch $branch"
  # Uncommitted edits on a branch being merged would silently miss the merge.
  [[ $current != "$branch" || $clean == true ]] \
    || die "$branch is checked out with uncommitted changes: commit or stash them first"
done

git fetch -q origin main
base=$(git rev-parse origin/main)
scratch=$(mktemp -d)
trap 'rm -rf "$scratch"' EXIT

# Prints tree $1 with PROGRESS.md regenerated from that tree's board and
# backlog, exactly what `make progress` writes after the merge. The generator
# is ALWAYS origin/main's tools/scripts/progress.py (CI-verified), never the
# branch's: the merge runs before CI, on a machine with credentials, so branch
# code must not run here. The branch only supplies the two Markdown inputs,
# read as data. The generator also runs with the GitHub token and SSH agent
# variables removed. $2 = required (PROGRESS.md conflicted: every failure is
# fatal) or optional (clean merge: without a PROGRESS.md, its inputs or a
# working generator the tree stays as it is, and CI's staleness check reports
# it as before).
# A branch that changes progress.py itself can't be regenerated with main's
# generator (CI checks the page against the branch's generator): a clean merge
# keeps the branch's own PROGRESS.md, a conflicted one aborts. Such a branch
# rebases and runs `make progress` itself.
fresh_progress() {
  local tree=$1 mode=$2 dir f blob old new gen_base gen_tree
  if [[ $mode == optional ]] && ! git cat-file -e "$tree:PROGRESS.md" 2>/dev/null; then
    echo "$tree"
    return 0
  fi
  gen_base=$(git rev-parse -q --verify "$base:tools/scripts/progress.py" || true)
  gen_tree=$(git rev-parse -q --verify "$tree:tools/scripts/progress.py" || true)
  if [[ -z $gen_base || $gen_base != "$gen_tree" ]]; then
    if [[ $mode == optional ]]; then
      echo "$tree"
      return 0
    fi
    if [[ -z $gen_base ]]; then
      note "PROGRESS.md conflicts and origin/main has no tools/scripts/progress.py to regenerate it"
    else
      note "PROGRESS.md conflicts and this merge changes tools/scripts/progress.py: merge-step only runs main's generator. Rebase the branch on origin/main and run 'make progress' in it"
    fi
    return 1
  fi
  dir=$(mktemp -d "$scratch/progress.XXXXXX")
  mkdir -p "$dir/gen" "$dir/in/technical-planning/steps"
  git cat-file blob "$gen_base" >"$dir/gen/progress.py"
  for f in technical-planning/steps/README.md technical-planning/steps/backlog.md; do
    if ! git cat-file blob "$tree:$f" >"$dir/in/$f" 2>/dev/null; then
      [[ $mode == optional ]] && { echo "$tree"; return 0; }
      note "PROGRESS.md conflicts and the merged tree has no $f to regenerate it"
      return 1
    fi
  done
  if ! env -u GITHUB_TOKEN -u GH_TOKEN -u SSH_AUTH_SOCK -u SSH_AGENT_PID -u GIT_ASKPASS -u SSH_ASKPASS \
    PYTHONDONTWRITEBYTECODE=1 python3 -I -B "$dir/gen/progress.py" "$dir/in" \
    >"$dir/PROGRESS.md" 2>"$dir/stderr"; then
    note "progress.py failed on the merged tree: $(head -c 500 "$dir/stderr")"
    [[ $mode == optional ]] && { echo "$tree"; return 0; }
    return 1
  fi
  blob=$(git hash-object -w "$dir/PROGRESS.md")
  old=$(git rev-parse -q --verify "$tree:PROGRESS.md" || true)
  if [[ $old == "$blob" ]]; then
    echo "$tree"
    return 0
  fi
  new=$(
    export GIT_INDEX_FILE="$dir/index"
    git read-tree "$tree"
    git update-index --add --cacheinfo "100644,$blob,PROGRESS.md"
    git write-tree
  )
  if [[ $mode == required ]]; then
    note "PROGRESS.md conflicted: regenerated it from the merged board and backlog"
  else
    note "PROGRESS.md was stale: regenerated it from the merged board and backlog"
  fi
  echo "$new"
}

# Prints the merge base for squashing entry $1 onto the chain: the newest of its
# branch's merge bases with origin/main and with the earlier entries' branches.
# A branch stacked on an earlier entry is thus squashed against that entry's
# branch (only its own changes), not against the old main. Prints nothing for
# the first entry, or when there is no single newest base (git then picks it).
squash_base() {
  local i=$1 b mb cands=() tips
  ((i > 0)) || return 0
  for b in "$base" "${branches[@]:0:i}"; do
    if mb=$(git merge-base "$b" "${branches[i]}" 2>/dev/null); then
      cands+=("$mb")
    fi
  done
  ((${#cands[@]})) || return 0
  tips=$(git merge-base --independent "${cands[@]}" | sort -u)
  [[ $tips == *$'\n'* ]] || echo "$tips"
}

# Prints the squash tree of entry $1 on top of commit $2. Conflicts abort,
# except when PROGRESS.md is the only conflicting file (regenerated).
squash_tree() {
  local i=$1 parent=$2 mb out rc=0 tree conflicts args=()
  mb=$(squash_base "$i")
  if [[ -n $mb ]]; then args=(--merge-base="$mb"); fi
  out=$(git merge-tree --write-tree --no-messages --name-only "${args[@]}" "$parent" "${branches[i]}") || rc=$?
  ((rc <= 1)) || { note "git merge-tree failed on $(label "$i") (exit $rc)"; return 1; }
  tree=${out%%$'\n'*}
  if ((rc == 0)); then
    fresh_progress "$tree" optional
    return
  fi
  conflicts=$(sed 1d <<<"$out" | sed '/^$/d' | LC_ALL=C sort -u)
  if [[ $conflicts != PROGRESS.md ]]; then
    note "conflicts squashing $(label "$i") onto main (${conflicts//$'\n'/, }): rebase ${branches[i]} on origin/main first"
    if [[ $group == true ]]; then note "nothing was pushed; the group was:"$'\n'"$(entries)"; fi
    return 1
  fi
  fresh_progress "$tree" required
}

# Build the chain: one squash commit per entry, each on the previous one.
parent=$base
for ((i = 0; i < n; i++)); do
  subjects=$(git log --reverse --format='- %s' "${branches[i]}" --not "$base" "${branches[@]:0:i}")
  if [[ -z $subjects ]]; then
    die "$(label "$i") has no commits beyond origin/main$([[ $group == true ]] && echo ' and the earlier entries')"
  fi
  tree=$(squash_tree "$i" "$parent")
  msg="${titles[i]}"$'\n\n'"$subjects"
  [[ -n ${MERGE_TRAILER:-} ]] && msg+=$'\n\n'"$MERGE_TRAILER"
  parent=$(printf '%s\n' "$msg" | git commit-tree "$tree" -p "$parent")
done
sha=$parent

# True when $1 is a chain of n commits on $base with the same trees as $sha's.
same_chain() {
  local prev=$1 k
  for ((k = 0; k < n; k++)); do
    [[ $(git rev-parse -q --verify "$prev~$k^{tree}" || true) == "$(git rev-parse "$sha~$k^{tree}")" ]] || return 1
  done
  [[ $(git rev-parse -q --verify "$prev~$n" || true) == "$base" ]]
}
if [[ ${MERGE_REUSE:-} == 1 ]] && git fetch -q origin "$merge" 2>/dev/null; then
  prev=$(git rev-parse -q --verify FETCH_HEAD || true)
  if [[ -n $prev ]] && same_chain "$prev"; then
    echo "merge-step: reusing the previous attempt $prev (same tree, same parent)"
    sha=$prev
  fi
fi
git push -q -f origin "$sha:refs/heads/$merge"

if [[ $group == true ]]; then
  echo "merge-step: pushed $merge, $n commits:"
  entries
fi
echo "merge-step: waiting for ci on $sha"
if ! "$root/tools/scripts/ci-status.sh" "$sha" "${MERGE_CI_TIMEOUT_MIN:-25}"; then
  if [[ $group == true ]]; then
    die "ci is not green on $sha; main untouched, $merge and every entry's branch kept. The group was:"$'\n'"$(entries)"
  fi
  die "ci is not green on $sha; main untouched, $merge and ${branches[0]} kept"
fi

git push origin "$sha:main" \
  || die "could not move main (another lane merged while ci ran?); main untouched: rerun merge-step to rebuild on the new main (TD-087)"
git push -q origin --delete "$merge"
for branch in "${branches[@]}"; do
  if git ls-remote -q --exit-code --heads origin "$branch" >/dev/null; then
    git push -q origin --delete "$branch"
  fi
done
git fetch -q origin main

# Local refs. Re-read HEAD and the tree: the folder may have moved on while CI ran.
current=$(git symbolic-ref -q --short HEAD || true)
clean=false
[[ -z $(git status --porcelain) ]] && clean=true
on_entry=false
for branch in "${branches[@]}"; do
  if [[ $current == "$branch" ]]; then on_entry=true; fi
done
if [[ $on_entry == true && $clean == true ]]; then
  git checkout -q -B main origin/main
  current=main
elif [[ $on_entry == true ]]; then
  git branch -q -f main origin/main
  echo "merge-step: $current is still checked out with local changes; it was kept locally"
elif [[ $current == main ]]; then
  if [[ $clean == true ]]; then
    git merge -q --ff-only origin/main || echo "merge-step: local main has diverged from origin/main; fix it by hand"
  else
    echo "merge-step: main has local changes; run 'git pull --ff-only' when it is clean"
  fi
else
  git branch -q -f main origin/main
fi
for branch in "${branches[@]}"; do
  if [[ $branch != "$current" ]]; then git branch -q -D "$branch"; fi
done
if [[ $group == true ]]; then
  echo "merge-step: the group is on main at $sha:"
  git log --reverse --format='  %h %s' "$base..$sha"
else
  echo "merge-step: ${ids[0]} is on main at $sha"
fi
