#!/usr/bin/env bash
# Squash a step branch onto main through a CI-verified merge/<ID> branch
# (TD-036, TD-039, PROCESS.md §A5). It never touches main unless the `ci`
# check on the squash commit is green, and it deletes branches only after
# main moved. Usage:
#   tools/scripts/merge-step.sh <ID> "<step name>" <step-branch>
#   tools/scripts/merge-step.sh docs "<what>" <branch>   (planning/process
#   changes outside a step: commit "docs: <what>", branch merge/docs-<branch>)
#   tools/scripts/merge-step.sh chore "<what>" <branch>  (tooling/CI changes
#   outside a step: commit "chore: <what>", branch merge/chore-<branch>)
# The commit body lists the step branch's commit subjects and ends with the
# trailer in MERGE_TRAILER (one line, optional).
# It never checks out a branch while it works (TD-086): the squash commit is
# built with `git merge-tree` + `git commit-tree` from committed history only,
# so the working folder stays free for the next step while CI runs. At the end
# it updates the local main ref; it checks out main only when the folder was on
# the merged branch with a clean tree. It doesn't push the step branch: that
# would start a second, redundant CI run next to the merge run (the remote step
# branch, if any, is deleted after the merge anyway).
# Environment (both optional, defaults keep the strict behaviour):
#   MERGE_CI_TIMEOUT_MIN  how long to wait for `ci` on the squash commit
#                         (default 25, ci-status.sh's own default).
#   MERGE_REUSE=1         after a timeout (ci still running or finished green
#                         on the previous attempt), reuse that attempt's squash
#                         commit instead of building a new one and running CI
#                         again. Only when origin/<merge branch> has the same
#                         tree and the same parent (the current origin/main);
#                         otherwise a fresh commit is built as usual. Not for
#                         retrying a red CI: a reused red commit stays red.
set -euo pipefail

die() { echo "merge-step: $*" >&2; exit 1; }

[[ $# -eq 3 ]] || die "usage: merge-step.sh <ID> \"<step name>\" <step-branch>"
id=$1 name=$2 branch=$3
if [[ $id == docs || $id == chore ]]; then
  title="$id: $name" merge="merge/$id-${branch##*/}"
elif [[ $id =~ ^[A-Z][0-9]{2}[a-z]?( \(contract\))?$ ]]; then
  title="$id: $name" merge="merge/${id%% *}"
else
  die "bad step ID: $id (A01…, B01…, S06a, 'B05 (contract)', docs or chore)"
fi
root=$(git rev-parse --show-toplevel)
cd "$root"

git rev-parse --verify -q "refs/heads/$branch" >/dev/null || die "no local branch $branch"
current=$(git symbolic-ref -q --short HEAD || true)
clean=false
[[ -z $(git status --porcelain) ]] && clean=true
# Uncommitted edits on the branch being merged would silently miss the merge.
[[ $current != "$branch" || $clean == true ]] \
  || die "$branch is checked out with uncommitted changes: commit or stash them first"

git fetch -q origin main

subjects=$(git log --reverse --format='- %s' "origin/main..$branch")
[[ -n $subjects ]] || die "$branch has no commits beyond origin/main"

# The same three-way merge `git merge --squash` does, without a worktree.
if ! merged=$(git merge-tree --write-tree --no-messages origin/main "$branch"); then
  die "conflicts squashing $branch onto main: rebase $branch on origin/main first"
fi
tree=${merged%%$'\n'*}
msg="$title"$'\n\n'"$subjects"
[[ -n ${MERGE_TRAILER:-} ]] && msg+=$'\n\n'"$MERGE_TRAILER"
sha=$(printf '%s\n' "$msg" | git commit-tree "$tree" -p origin/main)
if [[ ${MERGE_REUSE:-} == 1 ]] && git fetch -q origin "$merge" 2>/dev/null; then
  prev=$(git rev-parse -q --verify FETCH_HEAD || true)
  if [[ -n $prev &&
        $(git rev-parse "$prev^{tree}") == "$tree" &&
        $(git rev-parse "$prev^") == "$(git rev-parse origin/main)" ]]; then
    echo "merge-step: reusing the previous attempt $prev (same tree, same parent)"
    sha=$prev
  fi
fi
git push -q -f origin "$sha:refs/heads/$merge"

echo "merge-step: waiting for ci on $sha"
if ! "$root/tools/scripts/ci-status.sh" "$sha" "${MERGE_CI_TIMEOUT_MIN:-25}"; then
  die "ci is not green on $sha; main untouched, $merge and $branch kept"
fi

git push origin "$sha:main" \
  || die "could not move main (another lane merged while ci ran?); main untouched: rerun merge-step to rebuild on the new main (TD-087)"
git push -q origin --delete "$merge"
if git ls-remote -q --exit-code --heads origin "$branch" >/dev/null; then
  git push -q origin --delete "$branch"
fi
git fetch -q origin main

# Local refs. Re-read HEAD and the tree: the folder may have moved on while CI ran.
current=$(git symbolic-ref -q --short HEAD || true)
clean=false
[[ -z $(git status --porcelain) ]] && clean=true
if [[ $current == "$branch" && $clean == true ]]; then
  git checkout -q -B main origin/main
  git branch -q -D "$branch"
elif [[ $current == "$branch" ]]; then
  git branch -q -f main origin/main
  echo "merge-step: $branch is still checked out with local changes; it was kept locally"
elif [[ $current == main ]]; then
  if [[ $clean == true ]]; then
    git merge -q --ff-only origin/main || echo "merge-step: local main has diverged from origin/main; fix it by hand"
  else
    echo "merge-step: main has local changes; run 'git pull --ff-only' when it is clean"
  fi
  git branch -q -D "$branch"
else
  git branch -q -f main origin/main
  git branch -q -D "$branch"
fi
echo "merge-step: $id is on main at $sha"
