# B02 offline replay

Model: `gpt-6-luna` · prompt: `interpret-v0` · standard pricing estimate dated 2026-10-16.

Hand-authored synthetic fixtures through the real .NET SDK/adapter. No API key or external API calls. Replay plumbing only, not model quality; latency/tokens/cost are not live measurements.

| Case | Outcome | Parse checks | Elapsed ms | Input / cached / output tokens | Estimated USD |
|---|---|---|---:|---|---:|
| en-eggs | success | pass | fixture | fixture | fixture |
| ar-eggs | success | pass | fixture | fixture | fixture |
| az-eggs | success | pass | fixture | fixture | fixture |

Completed 3/3 cases; 3 passed. Result: pass.

No AQ threshold, language-equivalence claim or R1 sign-off follows from this set. AQ-02/03/06/07 and real ProposalEngine evaluation remain B08/B15/A21. AQ-12 needs the full app path and a representative sample. Other provider adapters and a fallback are intentionally absent (TD-067).
