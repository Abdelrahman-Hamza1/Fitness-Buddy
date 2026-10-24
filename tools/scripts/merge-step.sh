#!/usr/bin/env bash
# Squash a step branch onto main through a CI-verified merge/<ID> branch
# (TD-036, TD-039, PROCESS.md §A5). It never touches main unless the `ci`
# check on the squash commit is green, and it deletes branches only after
# main moved. Usage:
#   tools/scripts/merge-step.sh <ID> "<step name>" <step-branch>
#   tools/scripts/merge-step.sh docs "<what>" <branch>   (planning/process
#   changes outside a step: commit "docs: <what>", branch merge/docs-<branch>)
# The commit body lists the step branch's commit subjects and ends with the
# trailer in MERGE_TRAILER (one line, optional).
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
if [[ $id == docs ]]; then
  title="docs: $name" merge="merge/docs-${branch##*/}"
elif [[ $id =~ ^[A-Z][0-9]{2}[a-z]?( \(contract\))?$ ]]; then
  title="$id: $name" merge="merge/${id%% *}"
else
  die "bad step ID: $id (A01…, B01…, S06a, 'B05 (contract)' or docs)"
fi
root=$(git rev-parse --show-toplevel)
cd "$root"

[[ -z $(git status --porcelain) ]] || die "the working tree is not clean"
git rev-parse --verify -q "refs/heads/$branch" >/dev/null || die "no local branch $branch"

git fetch -q origin main
git push -q -u --force-with-lease origin "$branch"

subjects=$(git log --reverse --format='- %s' "origin/main..$branch")
[[ -n $subjects ]] || die "$branch has no commits beyond origin/main"

git checkout -q -B "$merge" origin/main
if ! git merge --squash -q "$branch" >/dev/null; then
  git merge --abort 2>/dev/null || git reset -q --hard origin/main
  git checkout -q "$branch"
  die "conflicts squashing $branch onto main: rebase $branch on origin/main first"
fi
msg="$title"$'\n\n'"$subjects"
[[ -n ${MERGE_TRAILER:-} ]] && msg+=$'\n\n'"$MERGE_TRAILER"
git commit -q -m "$msg"
if [[ ${MERGE_REUSE:-} == 1 ]] && git fetch -q origin "$merge" 2>/dev/null; then
  prev=$(git rev-parse -q --verify FETCH_HEAD || true)
  if [[ -n $prev &&
        $(git rev-parse "$prev^{tree}") == "$(git rev-parse 'HEAD^{tree}')" &&
        $(git rev-parse "$prev^") == "$(git rev-parse origin/main)" ]]; then
    echo "merge-step: reusing the previous attempt $prev (same tree, same parent)"
    git reset -q --hard "$prev"
  fi
fi
sha=$(git rev-parse HEAD)
git push -q -f -u origin "$merge"

echo "merge-step: waiting for ci on $sha"
if ! "$root/tools/scripts/ci-status.sh" "$sha" "${MERGE_CI_TIMEOUT_MIN:-25}"; then
  git checkout -q "$branch"
  die "ci is not green on $sha; main untouched, $merge and $branch kept"
fi

git push origin "$sha:main"
git push -q origin --delete "$merge" "$branch"
git checkout -q --detach "$sha"
git branch -q -D "$merge" "$branch"
git checkout -q -B main origin/main 2>/dev/null || git checkout -q main
git pull -q --ff-only origin main
echo "merge-step: $id is on main at $sha"
