#!/usr/bin/env bash
# Self-test of merge-step.sh against a throwaway bare remote and a stubbed
# ci-status.sh (no network, no GitHub). It pins the invariants of the gate:
# main moves only to a commit whose ci is green; a red ci leaves main and both
# branches alone; MERGE_REUSE=1 reuses the previous attempt only when the tree
# and the parent are unchanged; the folder (HEAD, working tree) is never
# switched while it works (TD-086). Run: tools/scripts/merge-step-selftest.sh
set -euo pipefail

here=$(cd "$(dirname "$0")" && pwd)
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
fail() { echo "merge-step-selftest: FAIL: $*" >&2; exit 1; }

git init -q --bare -b main "$tmp/remote.git"
git clone -q "$tmp/remote.git" "$tmp/work" 2>/dev/null
cd "$tmp/work"
git config user.name test && git config user.email test@example.com
mkdir -p tools/scripts
cp "$here/merge-step.sh" tools/scripts/merge-step.sh
# The stub reads STUB_CI (pass|fail) and records the sha it was asked about.
cat > tools/scripts/ci-status.sh <<'STUB'
#!/usr/bin/env bash
echo "$1 ${2:-}" >> "$STUB_LOG"
[[ ${STUB_CI:-pass} == pass ]]
STUB
chmod +x tools/scripts/*.sh
echo base > base.txt
git add -A && git commit -q -m base && git push -q origin main

export STUB_LOG="$tmp/ci.log"
run() { tools/scripts/merge-step.sh A01 "Test step" step/A01-test >"$tmp/out.log" 2>&1; }
remote_sha() { git ls-remote -q "$tmp/remote.git" "$1" | cut -f1; }

# 1. Red ci: main untouched, merge and step branches kept.
git checkout -q -b step/A01-test
echo one > one.txt && git add -A && git commit -q -m "feat: one"
main_before=$(remote_sha refs/heads/main)
export STUB_CI=fail
run && fail "a red ci must fail the merge"
[[ $(remote_sha refs/heads/main) == "$main_before" ]] || fail "main moved on a red ci"
[[ -n $(remote_sha refs/heads/merge/A01) ]] || fail "merge branch removed after a red ci"
git rev-parse -q --verify refs/heads/step/A01-test >/dev/null || fail "step branch removed after a red ci"
[[ -z $(remote_sha refs/heads/step/A01-test) ]] || fail "the step branch was pushed (a second CI run)"
first=$(remote_sha refs/heads/merge/A01)
grep -q "^$first 25$" "$tmp/ci.log" || fail "ci-status not asked for the squash commit with the default timeout"

# 2. Without MERGE_REUSE a rerun builds a new commit.
sleep 1.1
git checkout -q step/A01-test
run && fail "still red"
second=$(remote_sha refs/heads/merge/A01)
[[ $first != "$second" ]] || fail "a plain rerun must build a fresh commit"

# 3. MERGE_REUSE=1 with the same tree and parent reuses the previous attempt.
sleep 1.1
git checkout -q step/A01-test
export STUB_CI=pass MERGE_REUSE=1 MERGE_CI_TIMEOUT_MIN=40
run || { cat "$tmp/out.log" >&2; fail "the reused merge failed"; }
grep -q "reusing the previous attempt $second" "$tmp/out.log" || fail "the previous attempt was not reused"
[[ $(remote_sha refs/heads/main) == "$second" ]] || fail "main is not the reused commit"
grep -q "^$second 40$" "$tmp/ci.log" || fail "MERGE_CI_TIMEOUT_MIN not passed on"
[[ -z $(remote_sha refs/heads/merge/A01) && -z $(remote_sha refs/heads/step/A01-test) ]] \
  || fail "branches not deleted after a green merge"

# 4. MERGE_REUSE=1 does not reuse when the tree changed.
git checkout -q -b step/A02-test main
echo two > two.txt && git add -A && git commit -q -m "feat: two"
export STUB_CI=fail
tools/scripts/merge-step.sh A02 "Second" step/A02-test >"$tmp/out.log" 2>&1 && fail "red"
prev=$(remote_sha refs/heads/merge/A02)
git checkout -q step/A02-test
echo three > three.txt && git add -A && git commit -q -m "feat: three"
sleep 1.1
export STUB_CI=pass
tools/scripts/merge-step.sh A02 "Second" step/A02-test >"$tmp/out.log" 2>&1 || fail "changed-tree merge failed"
grep -q "reusing" "$tmp/out.log" && fail "reused a commit with a different tree"
[[ $(remote_sha refs/heads/main) != "$prev" ]] || fail "main is the stale attempt"
git cat-file -e "$(remote_sha refs/heads/main):three.txt" || fail "the new content is not on main"

# 5. The folder can move on while CI runs: merging a branch that isn't checked
#    out leaves HEAD, the working tree and uncommitted edits alone, and still
#    updates the local main ref and deletes the merged branch.
git checkout -q -b step/A03-test main
echo four > four.txt && git add -A && git commit -q -m "feat: four"
git checkout -q -b step/A04-next main
echo wip > wip.txt
export STUB_CI=pass
unset MERGE_REUSE
tools/scripts/merge-step.sh A03 "Third" step/A03-test >"$tmp/out.log" 2>&1 \
  || { cat "$tmp/out.log" >&2; fail "merge of a branch that isn't checked out failed"; }
[[ $(git symbolic-ref --short HEAD) == step/A04-next ]] || fail "HEAD moved"
[[ -f wip.txt && ! -f four.txt ]] || fail "the working tree changed"
[[ $(git rev-parse main) == "$(remote_sha refs/heads/main)" ]] || fail "local main not updated"
git rev-parse -q --verify refs/heads/step/A03-test >/dev/null && fail "merged branch not deleted locally"
git cat-file -e "$(remote_sha refs/heads/main):four.txt" || fail "four.txt not on main"
rm wip.txt

# 6. A conflict pushes nothing and leaves the folder alone.
git checkout -q -b step/A05-conflict main
echo mine > base.txt && git add -A && git commit -q -m "feat: mine"
git checkout -q -b side main
echo theirs > base.txt && git add -A && git commit -q -m "theirs" && git push -q origin side:main
git checkout -q step/A05-conflict
main_before=$(remote_sha refs/heads/main)
tools/scripts/merge-step.sh A05 "Conflict" step/A05-conflict >"$tmp/out.log" 2>&1 && fail "a conflict must fail"
grep -q "conflicts squashing" "$tmp/out.log" || fail "no conflict message"
[[ -z $(remote_sha refs/heads/merge/A05) ]] || fail "a merge branch was pushed despite the conflict"
[[ $(remote_sha refs/heads/main) == "$main_before" ]] || fail "main moved on a conflict"
[[ $(git symbolic-ref --short HEAD) == step/A05-conflict && -z $(git status --porcelain) ]] \
  || fail "the folder changed on a conflict"

# 7. Uncommitted edits on the branch being merged stop the merge.
echo dirty >> base.txt
tools/scripts/merge-step.sh A05 "Conflict" step/A05-conflict >"$tmp/out.log" 2>&1 && fail "dirty branch merged"
grep -q "uncommitted changes" "$tmp/out.log" || fail "no dirty-tree message"
git checkout -q -- base.txt

# 8. chore mode, and a pushed step branch is deleted from the remote after the merge.
git checkout -q -b chore/tools main
echo five > five.txt && git add -A && git commit -q -m "build: five" && git push -q origin chore/tools
tools/scripts/merge-step.sh chore "Tools" chore/tools >"$tmp/out.log" 2>&1 || { cat "$tmp/out.log" >&2; fail "chore merge failed"; }
[[ $(git log -1 --format=%s "$(remote_sha refs/heads/main)") == "chore: Tools" ]] || fail "wrong chore title"
[[ -z $(remote_sha refs/heads/chore/tools) && -z $(remote_sha refs/heads/merge/chore-tools) ]] || fail "chore branches not deleted"

echo "merge-step-selftest: OK"
