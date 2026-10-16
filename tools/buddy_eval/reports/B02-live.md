# B02 live smoke

Model: `gpt-6-luna` · prompt: `interpret-v0` · standard pricing estimate dated 2026-10-16.

Owner-approved synthetic smoke only. No retries or fallback. At most three requests. Individual laptop-network samples, not percentiles or end-to-end proposal latency.

| Case | Outcome | Parse checks | Elapsed ms | Input / cached / output tokens | Estimated USD |
|---|---|---|---:|---|---:|
| en-eggs | success | fail | 4959 | 863 / 0 / 168 | 0.0001703 |
| ar-eggs | success | pass | 3378 | 870 / 0 / 194 | 0.000184 |
| az-eggs | success | pass | 3617 | 869 / 0 / 205 | 0.0001894 |

Completed 3/3 cases; 2 passed. Result: fail (English cooked-state check).

No AQ threshold, language-equivalence claim or R1 sign-off follows from this set. AQ-02/03/06/07 and real ProposalEngine evaluation remain B08/B15/A21. AQ-12 needs the full app path and a representative sample. Other provider adapters and a fallback are intentionally absent (TD-067).

Recorded 2026-10-16; three live calls, total estimated **$0.0005437**. English failed only the expected cooked-state check (backlog #58, B08). The subsequent review closed the food-unit enum and tested that hardening offline; no additional live call was made. The exact pre-review schema blob is recorded in the JSON report.
