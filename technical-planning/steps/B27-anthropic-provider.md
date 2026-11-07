# B27 — Anthropic Claude Sonnet 5.5 as a switchable Buddy provider (OpenAI kept)

| Track | Depends on | Size | Owner | Status |
|---|---|---|---|---|
| Backend | B25, B26 | S–M | Claude (Opus build), Codex review | ✅ done (Codex review + fix-check; live-checked) |

**Goal.** The owner's Anthropic API credits run Buddy (owner, 2026-11-07): **Claude Sonnet 5.5** (`claude-sonnet-5-5`) behind the same `IChatClient` loop, with OpenAI `gpt-6-luna` still selectable by one server setting (TD-129). Server-internal: contract unchanged, no app change.

## Scope
1. `Buddy:Provider` = `openai` (default, behaviour unchanged) | `anthropic`; `Buddy:AnthropicApiKeyFile` (same private-file checks as the OpenAI key); validated on start.
2. Official `Anthropic` C# SDK (`AsIChatClient` adapter), no SDK retries, a pinned named HttpClient `buddy-anthropic`, SDK telemetry off.
3. The two model adapters (`ChatClientAgentModel`, `ChatClientLabelReader`) become provider-neutral: a small per-provider strategy shapes the request, decides completion and prices usage; the ledger records the active model.
4. Laptop server: `phone-server.py configure-buddy --provider anthropic [--anthropic-key-file …]`.
5. Docs: TD-129, `02` stack row, `06` §9, this card, the board row.

## Exit criteria
1. `make check-dotnet` green; focused provider tests (wire-level, fake transport) and the confirmation-guard tests green; `phone-server-check` green.
2. With the key file present: a few live turns (≤ 10 paid calls) through the real loop, results below (content-free).
3. Codex review passed.

## Low-level plan

One engineer, lane `fitness_buddy_2`, one local commit per WP.

- **WP1 Provider strategy + options** (`Application/BuddyOptions.cs`, `Infrastructure/BuddyProvider*.cs`, `BuddyClientRegistration.cs`, `BuddyModule.cs`, `PostgresAgentLedger.cs`): `BuddyProvider` (name, model, agent/label `ChatOptions`, message shaping, completion, cost, transport-failure check); `OpenAIProvider` reproduces today's request exactly; `AnthropicProvider` per the D-rows. Registration reads only the active provider's key file.
- **WP2 Adapters neutral** (`ChatClientAgentModel`, `ChatClientLabelReader`): spans, options, completion and cost via the provider; no OpenAI types left in them.
- **WP3 Tests** (`Persistence.Tests/BuddyProviderTests.cs`, no network): options validation, the Anthropic wire body (no sampling params, `tool_choice` auto/none only, `thinking` `between_tools`, effort, cache breakpoints on the static system block and the last message, tools kept on tool-less rewrites), stop-reason mapping (refusal, max_tokens), usage → cost, the Claude label read (schema in the cached system prompt, fenced JSON parsed); the OpenAI body still carries `store:false`.
- **WP4 Laptop server** (`tools/scripts/phone-server.py`, `test_phone_server.py`): `--provider`, `--anthropic-key-file`; overlay per provider; only the active key is copied and checked.
- **WP5 Docs + live experiments** (only if `~/.config/fitness-buddy/anthropic-api-key` exists).

**Decisions (simplest sound option):**
- **D1 SDK:** NuGet `Anthropic` **13.3.0** (2026-10-23; the newest release outside the 7-day cooldown, TD-040). Licence **Apache-2.0** (the SDK moved from MIT; permissive, compatible). Adapter: `IAnthropicClient.Beta.AsIChatClient(model)` from the SDK's `Microsoft.Extensions.AI` integration; Beta surface because `fallbacks` exists only there (D6), same `/v1/messages` endpoint.
- **D2 Thinking:** `{type:"between_tools"}` (up-front thinking off; Sonnet 5.5 rejects `disabled`). Our transcript re-sends only text, tool calls and tool results, never thinking blocks; the preserved-thinking rules allow dropping all of them ("the check has nothing to test"), so history rebuilt from the sealed continuation is safe on every account. Adaptive thinking would need the signed blocks carried byte-identical through the continuation: more state, more latency and cost for a short tool loop.
- **D3 Effort:** `output_config.effort` = `Buddy:AnthropicEffort` (`low|medium|high`, default **medium**; `between_tools` rejects `xhigh`/`max`). Label read: `low`.
- **D4 Request rules:** no `temperature`/`top_p`/`top_k`, no prefill (the transcript never ends on an assistant turn), `tool_choice` only `auto` or `none` (the loop sends nothing else; the strategy maps any other mode to `auto`). A step with no tools but tool blocks in its history (guard rewrites) still declares the full tool list with `tool_choice: none` (the API needs the definitions; it also keeps the tools/system cache prefix).
- **D5 Caching:** breakpoint 1 at the end of the system prompt (tools render first, so it covers tools + `agent-v1` + the exercise library, which is catalog data shared by every user; per-user context starts in the messages); breakpoint 2 on the last block of the last message (the next step of the turn reads the whole prefix). 5-minute TTL. Label: one breakpoint on its system prompt (label-v1 + the schema, ≈ 2.3k tokens).
- **D6 Server-side fallback:** supported by the adapter (`fallbacks: "default"` + beta `server-side-fallback-2026-07-01`), but TD-067/TD-124 (Accepted) say "no provider retries or fallback". Built behind `Buddy:AnthropicServerFallback`, **default false**; turning it on is an owner call (a refused request is retried on Anthropic's recommended model inside the same call).
- **D7 Refusals:** `stop_reason: refusal` (→ `ChatFinishReason.ContentFilter`) maps to `Refused`, the existing failure path; nothing about the content is logged.
- **D8 Price** (platform.claude.com pricing, 2026-11-07): input $2/M, 5-min cache write $2.50/M, cache read **$0.10/M** (0.05×, not $0.20), output $10/M. Cache writes are counted as input in the ledger (no new column).
- **D9 Usage rows:** `usage.daily` is keyed by model, so switching provider starts a fresh daily row (the daily ceilings count per model). Accepted for R1 (one user, switches are rare).
- **D10 Timeouts:** SDK timeout = `StepTimeoutSeconds` + 5 s so our step timeout fires first (status `Timeout`); the named HttpClient has no timeout and no redirects, like `buddy-openai`.
- **D11 Claude label read (found live):** `output_config.format` rejects the label schema twice: an `enum` under a type union (`basis`), and more than 16 union-typed fields (it has 19). So for Claude the schema is an instruction appended to `label-v1` in the cached system prompt, and the reply is JSON text parsed by the existing parser (a ```json fence is stripped); `LabelRules` checks it as before; a malformed reply → Unavailable (no repair call). OpenAI keeps the strict schema format. The prompt file and version are unchanged.
- **D12 Turn input budget (found live, owner call):** one Claude send is ≈ 20k input tokens (27 tool schemas + prompt + exercise library; OpenAI ≈ 6k), so TD-124's 64k turn input budget allows only ≈ 3 sends; a 3-send suggestion used 66k. The default stays 64k; `configure-buddy --max-input-tokens N` (1000–400000) sets `Buddy:Agent:MaxInputTokens` once the owner approves (recommended 200000 for Claude: TD-124's ≈ 10-send intent; worst case ≈ $0.15 per turn, mostly cache reads at $0.10/M).

## Outcome
Built and live-checked (Claude reached through the real loop; owner's laptop server not redeployed).
- `Buddy:Provider` `openai` (default, wire unchanged: `store:false`, low effort, gpt-6-luna) | `anthropic` (`claude-sonnet-5-5`), `Buddy:AnthropicApiKeyFile`, `Buddy:AnthropicEffort` (medium), `Buddy:AnthropicServerFallback` (false). `BuddyProvider` strategy (`Infrastructure/BuddyProvider.cs`): `OpenAIProvider`, `AnthropicProvider`; `AnthropicClientFactory` (Anthropic 13.3.0, `client.Beta.AsIChatClient`, `MaxRetries 0`, telemetry off, explicit base URL); the ledger/Usage rows use the active model.
- Tests: `BuddyProviderTests` (10, fake transport); `ConfirmationGuardTests` and Architecture.Tests (67) green; `IdentityPrivacyTests` canaries green; `phone-server-check` (46) green; `make check-dotnet` green.
- Open: owner OK for D12 (turn input budget for Claude) and D6 (server fallback); effort `low` untried; trim the tool declarations (≈ 15.5k tokens) as tuning.

## Live experiments
2026-11-07, `claude-sonnet-5-5`, effort medium, `between_tools`, through the real loop (HTTP + SSE, Postgres ledger, catalog release imported) in a throwaway local harness (not committed); prices $2/M in, $2.50/M cache write, $0.10/M cache read, $10/M out. 11 calls: 9 billed, 2 rejected with 400 before any tokens (label schema, D11). Spend ≈ $0.15. Content-free:

| Turn | Rounds · sends | Wall | Per send (s) | Input (cache read / write) | Output | Cost | Outcome |
|---|---|---|---|---|---|---|---|
| "2 eggs and toast" (no catalog, 64k budget, cold) | 1 · 3 | 10.4 s | 4.0, 2.8, 2.7 | 16.3k (0 / 16.3k), 16.8k (16.3k / 0.5k), 17.1k (16.8k / 0.4k) | 415, 298, 300 | $0.056 | `limit` (input budget); no card: harness DB had no catalog |
| "2 eggs and toast" | 1 · 1 | 5.2 s | 4.0 | 20.2k (15.5k / 4.7k) | 415 | $0.017 | foodLog card, templated line |
| "chicken shawarma for lunch and a laban" | 1 · 1 | 4.3 s | 4.0 | 20.2k (15.5k / 4.7k) | 511 | $0.018 | foodLog card |
| "what should I eat tonight?" (160k budget) | 1 · 3 | 14.2 s | 6.4, 4.8, 2.3 | 20.2k (15.5k / 4.7k), 22.5k (20.2k / 2.3k), 23.3k (22.5k / 0.8k) | 1011, 746, 168 | $0.045 | `check_fit`, `suggest_foods` → suggestion card + text; 66k input (> 64k default) |
| Label photo (synthetic panel, 520×640 JPEG) | – · 1 | 3.3 s | 2.9 | 2.7k (0 / 2.3k) | 369 | $0.010 | found, per 100 g, 400 kcal high, protein 9 g high |

Findings: the cache works across steps and turns (a later send reads the earlier prefix); thinking `between_tools`, effort, `tool_choice` auto and the no-sampling body are accepted. The 4.7k written per turn above was the exercise library in an uncached second system block; it now sits inside breakpoint 1 (D5; checked by `BuddyProviderTests`, not re-run live), so a warm simple log should cost ≈ $0.008 and a cold one (cache expired after 5 min) ≈ $0.055. A simple log is one send at ≈ 4 s, inside the 5 s target.

## Progress log

- 2026-11-07: plan written (self-approved by the orchestrator); key file `~/.config/fitness-buddy/anthropic-api-key` not present yet.
- 2026-11-07: WP1–WP2 committed (provider strategy, Anthropic client, neutral adapters, ledger model), WP3 `BuddyProviderTests`, WP4 `configure-buddy --provider anthropic`. `make check-dotnet`, Architecture.Tests (incl. ConfirmationGuardTests), IdentityPrivacyTests, `phone-server-check` green.
- 2026-11-07: key file appeared; live experiments (table above). Fixes from them: one cached system block (the exercise library is shared), the Claude label path (D11), `--max-input-tokens` (D12). Docs: TD-129, `02`, `06` §9, the module README, the board row.
- 2026-11-07: owner decisions ("Rec to both"): D12 turn input budget 200000 for Claude on the laptop server (set with `configure-buddy --provider anthropic --max-input-tokens 200000`; code default stays 64000, amends TD-124's ceiling for this provider by owner OK); D6 server-side fallback stays off.
- 2026-11-07: Codex review fixes (no blocker; 2 majors, 1 minor): (1) `IAgentModel.Declared` gives the declarations a send really carries (a Claude rewrite with tool history keeps the full list, `tool_choice: none` via `AllowToolCalls`); `ReserveAsync` budgets and `SendAsync` sends that same list; near the ceiling a Claude rewrite is now refused (test). (2) Label JSON is parsed with required constructor parameters and `LabelRules.Complete` (nested objects, array elements); a partial transcription → Unavailable (tests: missing, null and partial nested objects, null element). (3) `Buddy:AnthropicServerFallback=true` fails options validation until per-attempt model/usage/pricing is recorded. `make check-dotnet`, BuddyProviderTests (17), Architecture.Tests (67), IdentityPrivacy/limit/image/barcode tests (24) green. No paid calls.
