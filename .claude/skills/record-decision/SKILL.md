---
name: record-decision
description: Record a Fitness Buddy decision correctly: technical decisions as TD entries in technical-planning/12-decisions-and-questions.md, product/spec decisions as D-entries in spec/decisions.md plus the spec edits they imply, and owner questions as TQ entries. Use whenever a plan, review, research result or owner answer settles something worth remembering, or changes an earlier decision.
---

# Record a decision

## 1. Classify
| It changes… | Record as | Who may decide |
|---|---|---|
| What the product does, for whom, a requirement or its release tag, an acceptance criterion | **Spec decision** `D-xxx` in `spec/decisions.md` + edits to the spec files | **Owner only.** Ask first, with a recommendation |
| How we build it: architecture, a technology, a convention, a process | **Technical decision** `TD-xxx` in `technical-planning/12-decisions-and-questions.md` §1 | Orchestrator for Proposed ones without cost/vendor/lock-in impact. **Owner** for changes to Accepted TDs or anything with cost/vendor/lock-in impact |
| A question that needs the owner | **TQ-xx** in `12` §2.1 (with "Rec:") | Owner answers |

## 2. Spec decision (D-xxx)
- Append to `spec/decisions.md` (append-only; never edit past entries except adding a `Status: Superseded by / Amended by D-xxx` line to the old one):
```
## D-0xx — <short title>
- Date / Source: YYYY-MM-DD · <where the owner said it, quoted briefly>
- Status: Accepted. <Supersedes / Amends …>
- Decision: <what>
- Why: <reasoning, alternatives rejected>
```
- Edit every affected requirement (keep IDs stable; move release tags rather than deleting; add new IDs for split requirements), reference the D-entry, and update the counts in `spec/README.md`.
- Check that the step cards and planning docs referencing the changed IDs are updated too (`grep -rn "<ID>" technical-planning`).

## 3. Technical decision (TD-xxx)
- Add a row to the TD table in `12` §1 with the next free number: `| TD-0xx | **<decision>** | <Status> | <main reason> | <alternatives> | <doc § details> |`.
- Status: `Proposed` (default) · `Pending spike <ID>` · `Accepted (owner, YYYY-MM-DD)` · `Rejected` · `Superseded by TD-0yy`.
- Changing an **Accepted** TD = a **new** TD that supersedes it. Mark the old one `Superseded by TD-0yy` (the only edit allowed on it).
- Update the detailed doc section the row points to, so docs and log agree.

## 4. Owner question (TQ-xx)
- Add it to `12` §2.1 with the next free number: the question in plain language, `_Rec: …_`, and an empty `**A:**`. When answered, move it to the §2.2 table with its effect.

## 5. Tell the owner
One line in the next owner message: "Recorded TD-0xx: <decision>" (or "Need your call on TQ-xx: … (rec: …)").
