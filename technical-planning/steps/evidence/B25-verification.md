# B25 security verification (Buddy agent core, server)

- **Review:** Codex security + privacy + data-integrity task, 2026-11-07, on `origin/main..ef65afa8`. Verdict: changes required, 0 blockers, 5 majors.
- **Majors:** nested continuation-result validation before ledger changes; disclosure counters rolled back on replay; no attempt fencing for concurrent retries; input-token budget checked after spending; turn deadline not covering action execution.
- **Fixes:** 259550c8, 767a5f03, 52b8e822 (recursive validation, ledger-held disclosure counters with a result digest, attempt fencing of sends/completion/continuations, deadline across model and tool work); fix-check left S4 open → 1761220e (conservative input reservation per send, reconciled to reported usage).
- **Fix-check:** Codex, 2026-11-07: all resolved except S4, fixed in 1761220e (no third round, cap 2).
- **Follow-up found in B26 review:** turn routes held the request recovery lease for the whole stream; fixed in B26 (3d586b73).
- **Residual:** D24: with two API processes an old attempt may emit one event before the ledger fence (R1 runs one process).
