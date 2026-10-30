#!/usr/bin/env bash
# Self-test of merge-step.sh against a throwaway bare remote and a stubbed
# ci-status.sh (no network, no GitHub). It pins the invariants of the gate:
# main moves only to a commit whose ci is green; a red ci leaves main and both
# branches alone; MERGE_REUSE=1 reuses the previous attempt only when the tree
# and the parent are unchanged; the folder (HEAD, working tree) is never
# switched while it works (TD-086). TD-108: the group form chains one squash
# commit per entry in the given order, pushes once, lands nothing on a red ci
# and aborts on a conflict naming the entry; PROGRESS.md is regenerated (with
# origin/main's generator only, never the branch's) when it is the only
# conflict or stale, while any other conflict still aborts. Run: tools/scripts/merge-step-selftest.sh
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
# A stand-in for progress.py with the same interface (repo root in, page out):
# the done IDs on a summary line (so two branches that finish different steps
# conflict there), then the board. merge-step.sh must run origin/main's copy.
cat > tools/scripts/progress.py <<'GEN'
import os, sys
root = sys.argv[1]
def read(p):
    with open(os.path.join(root, p), encoding="utf-8") as f:
        return f.read()
board = read("technical-planning/steps/README.md")
backlog = read("technical-planning/steps/backlog.md")
done = [l.split()[0] for l in board.splitlines() if l.endswith(" done")]
sys.stdout.write("# Progress\ndone: " + " ".join(done) + "\n\n" + board + backlog)
GEN
mkdir -p technical-planning/steps
printf 'A10 todo\n--\nA11 todo\n--\nA12 todo\n--\nA13 todo\n--\nA14 todo\n' > technical-planning/steps/README.md
echo "backlog" > technical-planning/steps/backlog.md
regen() { python3 -I tools/scripts/progress.py . > PROGRESS.md; }
regen
chmod +x tools/scripts/*.sh
echo base > base.txt
git add -A && git commit -q -m base && git push -q origin main
# Every ref the remote receives, in order ("<ref> <new sha>").
cat > "$tmp/remote.git/hooks/post-receive" <<HOOK
#!/usr/bin/env bash
while read -r old new ref; do echo "\$ref \$new" >> "$tmp/push.log"; done
HOOK
chmod +x "$tmp/remote.git/hooks/post-receive"

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

grep -q "PROGRESS.md" "$tmp/out.log" && fail "PROGRESS.md touched in a merge where it was fresh"

# Is PROGRESS.md at commit $1 what the generator writes from that commit's board?
fresh_at() {
  local d
  d=$(mktemp -d "$tmp/fresh.XXXXXX")
  mkdir -p "$d/technical-planning/steps"
  for f in technical-planning/steps/README.md technical-planning/steps/backlog.md; do
    git show "$1:$f" > "$d/$f"
  done
  [[ $(python3 -I tools/scripts/progress.py "$d") == "$(git show "$1:PROGRESS.md")" ]]
}
mark() { sed -i "s/^$1 todo\$/$1 done/" technical-planning/steps/README.md; }
new_branch() { git fetch -q origin && git checkout -q -b "$1" "${2:-origin/main}"; }

unset MERGE_CI_TIMEOUT_MIN

# 9. PROGRESS.md is the only conflict: regenerated from the merged board.
new_branch step/A10-done
mark A11 && regen && git add -A && git commit -q -m "docs: A11 done"
new_branch side10
mark A10 && regen && git add -A && git commit -q -m "A10 done" && git push -q origin side10:main
git checkout -q step/A10-done
tools/scripts/merge-step.sh A11 "Eleven" step/A10-done >"$tmp/out.log" 2>&1 \
  || { cat "$tmp/out.log" >&2; fail "a PROGRESS.md-only conflict blocked the merge"; }
grep -q "PROGRESS.md conflicted: regenerated" "$tmp/out.log" || fail "no regeneration note"
top=$(remote_sha refs/heads/main)
git show "$top:PROGRESS.md" | grep -qx "done: A10 A11" || fail "PROGRESS.md not regenerated from the merged board"
fresh_at "$top" || fail "PROGRESS.md on main is stale after the conflict"

# 10. A stale PROGRESS.md without a conflict is regenerated too.
new_branch step/A15-stale
mark A14 && git add -A && git commit -q -m "docs: A14 done, no make progress"
tools/scripts/merge-step.sh A14 "Fourteen" step/A15-stale >"$tmp/out.log" 2>&1 \
  || { cat "$tmp/out.log" >&2; fail "stale merge failed"; }
grep -q "PROGRESS.md was stale: regenerated" "$tmp/out.log" || fail "no stale note"
fresh_at "$(remote_sha refs/heads/main)" || fail "stale PROGRESS.md reached main"

# 11. PROGRESS.md plus another conflicting file: abort, nothing pushed.
new_branch step/A16-both
mark A12 && regen && echo mine16 > base.txt && git add -A && git commit -q -m "feat: both"
new_branch side16
mark A13 && regen && echo theirs16 > base.txt && git add -A && git commit -q -m "theirs" && git push -q origin side16:main
git checkout -q step/A16-both
main_before=$(remote_sha refs/heads/main)
pushes=$(wc -l < "$tmp/push.log")
tools/scripts/merge-step.sh A16 "Both" step/A16-both >"$tmp/out.log" 2>&1 && fail "a conflict besides PROGRESS.md must fail"
grep -q "conflicts squashing step/A16-both onto main (PROGRESS.md, base.txt)" "$tmp/out.log" \
  || { cat "$tmp/out.log" >&2; fail "the conflict message does not name both files"; }
[[ $(wc -l < "$tmp/push.log") == "$pushes" && $(remote_sha refs/heads/main) == "$main_before" ]] \
  || fail "something was pushed despite the conflict"

# 12. Group: entries chained in order, ONE push, nothing lands on a red ci;
#     a branch stacked on an earlier entry counts only its own commits; each
#     commit's PROGRESS.md is fresh (entry 3 conflicts with entry 1 there).
new_branch step/A20-one
echo one > g.txt && mark A12 && regen && git add -A && git commit -q -m "feat: g one"
git checkout -q -b step/A21-two step/A20-one
echo two >> g.txt && git add -A && git commit -q -m "feat: g two"
new_branch docs/notes
echo notes > notes.md && mark A13 && regen && git add -A && git commit -q -m "docs: notes"
git checkout -q step/A21-two
group() {
  tools/scripts/merge-step.sh group A20 "Twenty" step/A20-one A21 "Twenty-one" step/A21-two \
    docs "Notes" docs/notes >"$tmp/out.log" 2>&1
}
main_before=$(remote_sha refs/heads/main)
pushes=$(wc -l < "$tmp/push.log")
calls=$(wc -l < "$tmp/ci.log")
export STUB_CI=fail
group && fail "a red ci must fail the group"
[[ $(remote_sha refs/heads/main) == "$main_before" ]] || fail "main moved on a red group ci"
[[ $(($(wc -l < "$tmp/push.log") - pushes)) == 1 ]] || fail "the group was not pushed exactly once"
gtop=$(remote_sha refs/heads/merge/group-A20-A21-docs-notes)
[[ -n $gtop ]] || fail "no merge/group-A20-A21-docs-notes branch"
tail -n 1 "$tmp/push.log" | grep -q "^refs/heads/merge/group-A20-A21-docs-notes $gtop$" || fail "the one push was not the top commit"
[[ $(($(wc -l < "$tmp/ci.log") - calls)) == 1 ]] || fail "ci not waited for exactly once"
grep -q "^$gtop 25$" "$tmp/ci.log" || fail "ci not waited for on the top commit"
grep -q "every entry's branch kept" "$tmp/out.log" || { cat "$tmp/out.log" >&2; fail "no red group message"; }
grep -q "3. docs: Notes  \[docs/notes\]" "$tmp/out.log" || fail "the red message does not list the group"
for b in step/A20-one step/A21-two docs/notes; do
  git rev-parse -q --verify "refs/heads/$b" >/dev/null || fail "$b removed after a red group ci"
done
[[ $(git log --format=%s "$main_before..$gtop") == $'docs: Notes\nA21: Twenty-one\nA20: Twenty' ]] \
  || fail "wrong chain order: $(git log --format=%s "$main_before..$gtop")"
[[ $(git rev-parse "$gtop~3") == "$main_before" ]] || fail "the chain does not start on origin/main"
[[ $(git log -1 --format=%b "$gtop~1") == "- feat: g two" ]] || fail "the stacked entry lists commits of the earlier entry"
[[ $(git show "$gtop~2:g.txt") == one && $(git show "$gtop~1:g.txt") == $'one\ntwo' ]] || fail "the stacked entry was not squashed on its base"
git cat-file -e "$gtop~1:notes.md" 2>/dev/null && fail "entry 3's file is in entry 2's commit"
git cat-file -e "$gtop:notes.md" || fail "entry 3's file is missing"
for k in 0 1 2; do fresh_at "$gtop~$k" || fail "PROGRESS.md stale at chain commit ~$k"; done
git show "$gtop:PROGRESS.md" | grep -q "^done: .*A12 A13" || fail "PROGRESS.md at the top misses an entry"

# 13. MERGE_REUSE=1 reuses the whole chain; a green ci lands every entry and
#     cleans up like a single merge.
sleep 1.1
export STUB_CI=pass MERGE_REUSE=1
group || { cat "$tmp/out.log" >&2; fail "the green group failed"; }
unset MERGE_REUSE
grep -q "reusing the previous attempt $gtop" "$tmp/out.log" || fail "the group's previous attempt was not reused"
[[ $(remote_sha refs/heads/main) == "$gtop" ]] || fail "main is not the group's top commit"
[[ -z $(remote_sha refs/heads/merge/group-A20-A21-docs-notes) ]] || fail "the group branch was not deleted"
for b in step/A20-one step/A21-two docs/notes; do
  git rev-parse -q --verify "refs/heads/$b" >/dev/null && fail "$b not deleted locally after the group merge"
done
[[ $(git symbolic-ref --short HEAD) == main && $(git rev-parse main) == "$gtop" ]] \
  || fail "the folder was on an entry with a clean tree: it should be on the new main"

# 14. A conflict in any entry aborts before pushing and names the entry.
new_branch step/A30-ok
echo ok30 > ok30.txt && git add -A && git commit -q -m "feat: ok"
new_branch step/A31-bad
echo mine31 > base.txt && git add -A && git commit -q -m "feat: bad"
new_branch side31
echo theirs31 > base.txt && git add -A && git commit -q -m "theirs" && git push -q origin side31:main
git checkout -q step/A31-bad
main_before=$(remote_sha refs/heads/main)
pushes=$(wc -l < "$tmp/push.log")
tools/scripts/merge-step.sh group A30 "Ok" step/A30-ok A31 "Bad" step/A31-bad >"$tmp/out.log" 2>&1 \
  && fail "a conflicting group entry must fail"
grep -q "conflicts squashing entry 2 (A31, step/A31-bad) onto main (base.txt)" "$tmp/out.log" \
  || { cat "$tmp/out.log" >&2; fail "the conflict does not name the entry"; }
grep -q "nothing was pushed" "$tmp/out.log" || fail "no nothing-pushed note"
[[ $(wc -l < "$tmp/push.log") == "$pushes" && $(remote_sha refs/heads/main) == "$main_before" ]] \
  || fail "something was pushed despite the group conflict"
[[ $(git symbolic-ref --short HEAD) == step/A31-bad && -z $(git status --porcelain) ]] \
  || fail "the folder changed on a group conflict"

# 15. Usage: a group needs two entries.
tools/scripts/merge-step.sh group A30 "Ok" step/A30-ok >"$tmp/out.log" 2>&1 && fail "a one-entry group was accepted"
grep -q "at least two entries" "$tmp/out.log" || fail "no usage message for a one-entry group"

# 16. Branch code never runs: PROGRESS.md is generated only with origin/main's
#     progress.py. A branch that changes the generator and conflicts on
#     PROGRESS.md aborts without running it.
evil() {
  cat > tools/scripts/progress.py <<EVIL
open("$tmp/pwned", "w").write("branch code ran")
print("evil")
EVIL
}
new_branch step/A40-evil
sed -i '1i A15 done\n--' technical-planning/steps/README.md && regen && evil
git add -A && git commit -q -m "feat: a new generator"
new_branch side40
printf -- '--\nA16 done\n' >> technical-planning/steps/README.md && regen
git add -A && git commit -q -m "A16 done" && git push -q origin side40:main
git checkout -q step/A40-evil
main_before=$(remote_sha refs/heads/main)
rc=0
tools/scripts/merge-step.sh A40 "Evil" step/A40-evil >"$tmp/out.log" 2>&1 || rc=$?
[[ ! -e $tmp/pwned ]] || fail "merge-step ran the branch's progress.py"
[[ $rc != 0 ]] || fail "a conflict with a changed generator must fail"
grep -q "changes tools/scripts/progress.py" "$tmp/out.log" || { cat "$tmp/out.log" >&2; fail "no changed-generator message"; }
[[ $(remote_sha refs/heads/main) == "$main_before" && -z $(remote_sha refs/heads/merge/A40) ]] || fail "pushed despite the abort"

# 17. Same without a conflict: the merge lands with the branch's own PROGRESS.md
#     (not regenerated with main's generator), and the branch code never runs.
new_branch step/A41-gen
sed -i '1i A17 done\n--' technical-planning/steps/README.md && evil
git add -A && git commit -q -m "feat: another generator"
before=$(git show origin/main:PROGRESS.md)
tools/scripts/merge-step.sh A41 "Generator" step/A41-gen >"$tmp/out.log" 2>&1 \
  || { cat "$tmp/out.log" >&2; fail "a clean merge with a changed generator failed"; }
[[ ! -e $tmp/pwned ]] || fail "merge-step ran the branch's progress.py"
grep -q "regenerated" "$tmp/out.log" && fail "PROGRESS.md regenerated with main's generator despite a changed one"
[[ $(git show "$(remote_sha refs/heads/main):PROGRESS.md") == "$before" ]] || fail "PROGRESS.md changed"

echo "merge-step-selftest: OK"
