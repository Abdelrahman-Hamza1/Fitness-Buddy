# Research Notes

_Round 1 · 2026-10-10 · Round 2 (backend & hosting) · 2026-10-11. Fast-moving facts behind the decisions. Many sources are secondary (blogs, aggregators), and those are marked. **Re-verify prices and versions at Phase 0 setup**, and pin exact versions then._

## Flutter platform

| Fact | Confidence | Source |
|---|---|---|
| 2026 release train: 3.41 (Feb), 3.44 (May), 3.47 (Aug), 3.50 (Nov). Current stable is most likely **3.47 / Dart 3.13** | Medium (official schedule + secondary) | [Flutter SDK archive](https://docs.flutter.dev/install/archive?tab=macos), [eCorpIT](https://ecorpit.com/flutter-app-development-company/) |
| Material & Cupertino were **decoupled** into the `material_ui` / `cupertino_ui` pub packages (1.0, Aug 2026). The in-framework libraries are frozen and will be deprecated, then removed, at a future date. Migration via `dart fix` | High (official blog) | [Flutter blog: decoupling](https://flutter.dev/blog/decoupling-material-cupertino), [Code freeze](https://flutter.dev/blog/flutters-material-and-cupertino-code-freeze) |
| **Riverpod 3.0** stable since 2025-09-10, now 3.4.x. Offline persistence and mutations are experimental | High (changelog) | [flutter_riverpod changelog](https://pub.dev/packages/flutter_riverpod/versions/3.4.1/changelog), [riverpod 3.4.0](https://pub.dev/packages/riverpod/versions/3.4.0/changelog) |
| **go_router**: Flutter team focus is bug fixes and stability. No active feature development planned. Still the docs' default | High (pub.dev docs) | [go_router docs](https://pub.dev/documentation/go_router/latest/), [8th Light](https://8thlight.com/insights/flutter-navigation-is-gorouter-still-the-best-choice) |
| **adhan_dart** 2.0.1: offline prayer-time calculation, no dependencies | High | [pub.dev adhan_dart](https://pub.dev/packages/adhan_dart) |
| **ML Kit Text Recognition v2** lists Latin, Chinese, Devanagari, Japanese, Korean scripts. **No Arabic found**, so Arabic labels need cloud vision | Medium-high | [ML Kit v2 languages](https://developers.google.com/ml-kit/vision/text-recognition/v2/languages?hl=de), [ML Kit iOS](https://developers.google.com/ml-kit/vision/text-recognition/v2/ios?hl=fi) |

## Backend & sync

| Fact | Confidence | Source |
|---|---|---|
| Supabase **anonymous sign-ins**: real authenticated users with an `is_anonymous` claim. Converting them requires linking an identity (manual linking enabled), and the **user ID stays the same** | High (official docs) | [Supabase anonymous sign-ins](https://supabase.com/docs/guides/auth/auth-anonymous) |
| Supabase pricing: free projects **pause after 1 week of inactivity**. Pro ≈ $25/mo | Medium (secondary) | [jetadmin review](https://www.jetadmin.io/blog/supabase-review/), [makerkit](https://makerkit.dev/blog/md/saas/supabase-pricing) |
| Supabase Edge Functions: 256 MB memory, wall clock 150 s (free) / 400 s (paid), CPU time 2 s per request (one troubleshooting page says 200 ms; conflicting) | Medium (official docs, conflicting) | [Edge Function limits](https://supabase.com/docs/guides/functions/limits), [CPU limits](https://supabase.com/docs/guides/troubleshooting/edge-function-cpu-limits) |
| **PowerSync**: Flutter SDK on sqlite_async. Drift integration via `drift_sqlite_async` (**beta**). Local-only tables + copy-on-sign-in pattern for guest data (`supabase-todolist-optional-sync` example) | High (official docs) | [PowerSync ORM support](https://docs.powersync.com/client-sdks/orms/flutter-orm-support), [Local-only usage](https://docs.powersync.com/client-sdks/advanced/local-only-usage) |
| PowerSync cloud: Free (2 GB synced, 500 MB hosted, 50 connections, deprovisioned after 7 days idle), Pro from $49/mo. Open Edition self-hostable (service under FSL) | High (official pricing/licensing) | [PowerSync pricing](https://powersync.com/pricing), [Licensing](https://powersync.com/legal/licensing-terms) |
| `syncable` (community drift ↔ Supabase LWW package) exists. Maturity unclear, so it serves as a reference, not a dependency | Low | [pub.dev syncable](https://pub.dev/packages/syncable) |
| Dart server frameworks: shelf (official base), dart_frog, Serverpod 3.x | Medium (secondary) | [pistack comparison](https://www.pistack.xyz/posts/2026-09-04-dart-server-side-frameworks-serverpod-dart-frog-shelf/) |

## Food data

| Fact | Confidence | Source |
|---|---|---|
| USDA FoodData Central: **CC0** public domain. API 1,000 req/hr per key | High (official) | [FDC API guide](https://fdc.nal.usda.gov/api-guide) |
| Open Food Facts: **ODbL** (attribution + share-alike for adapted databases used publicly). Images CC BY-SA. API ≈ 15 product reads/min/IP, 10 searches/min/IP (per user if called from a mobile app). Custom User-Agent required. Server-side caching is encouraged by maintainers | High (official docs + forum) | [OFF API docs](https://openfoodfacts.github.io/documentation/docs/Product-Opener/api/), [Licence tutorial](https://openfoodfacts.github.io/documentation/docs/Product-Opener/api/tutorials/license-be-on-the-legal-side/), [ODbL wiki](https://wiki.openfoodfacts.org/ODBL_License), [Forum: API conditions](https://forum.openfoodfacts.org/t/conditions-to-use-the-open-food-facts-api/443) |

## AI providers (prices per 1M tokens, input / output)

| Model family | Price | Data terms | Confidence | Source |
|---|---|---|---|---|
| **Claude Haiku 5.5** (`claude-haiku-5-5`) | **$0.10 / $0.50** (≤100K-token prompts). Adaptive thinking on by default, effort default `medium` | Commercial API not used for training. Standard retention window conflicting in secondary sources (7 vs 30 days). ZDR for qualifying orgs. **Verify on Anthropic's privacy center** | Price: high (Anthropic's bundled reference, 2026-10-06). Retention: low | Anthropic API reference (claude-api skill), [secondary: retention overview](https://anarlog.so/blog/anthropic-data-retention-policy) |
| Claude Sonnet 5.5 (for harder tasks, if needed) | $2 / $10 | same | High | same |
| **Gemini Flash-Lite class** | 2.5 Flash-Lite ≈ $0.10 / $0.40. 3.1 Flash-Lite ≈ $0.25 / $1.50 (aggregator data, conflicting for newer models) | Paid services: prompts/responses **not used to improve products**. Abuse-monitoring logs kept for a limited time. ZDR available per project on request | Price: medium-low. Terms: high | [Gemini ZDR page](https://ai.google.dev/gemini-api/docs/zdr?hl=en), [Logs policy](https://ai.google.dev/gemini-api/docs/logs-policy), [morphllm pricing](https://www.morphllm.com/gemini-api-pricing) |
| **OpenAI GPT-5.x nano / mini** | GPT-5 nano $0.05 / $0.40, mini $0.25 / $2.00. GPT-5.4-nano ≈ $0.20 / $1.25, -mini ≈ $0.75 / $4.50 (aggregators, conflicting) | API data **not used for training** unless opted in. Abuse logs **up to 30 days** by default. Stricter controls need approval | Price: low-medium. Terms: high | [OpenAI: your data](https://developers.openai.com/api/docs/guides/your-data), [morphllm OpenAI pricing](https://morphllm.com/openai-api-pricing) |

**Not suitable:** Claude Fable 5.x for this app (expensive, and requires 30-day retention, so no ZDR).

## Still to verify in Phase 0

- [ ] Exact current Flutter stable and whether `flutter create` templates use `material_ui` by default.
- [ ] Each AI provider's current retention terms (official pages) and the ZDR application process.
- [ ] Current official prices for the Gemini and OpenAI candidates.
- [ ] LLM latency from the owner's network (part of S1).
- [ ] OFF coverage of West Bank products (S2).
- [ ] Umm al-Qura Hijri package choice. Prayer calculation method commonly used in Palestine.
- [ ] Supabase Pro backup retention and point-in-time-recovery options.

## Round 2 — Backend, hosting, Supabase (2026-10-11)

| Fact | Confidence | Source |
|---|---|---|
| **.NET 10 is LTS, supported until 14 Nov 2028**. .NET 8 and 9 end 10 Nov 2026 | High (official) | [.NET support policy](https://dotnet.microsoft.com/en-us/platform/support/policy/dotnet-core) |
| Official **Anthropic C# SDK** = NuGet `Anthropic` (v10+; earlier versions were a community package now `tryAGI.Anthropic`). **Beta** | High (official docs) | [Anthropic C# SDK](https://platform.claude.com/docs/en/cli-sdks-libraries/sdks/csharp), [NuGet](https://www.nuget.org/packages/anthropic) |
| Official **Google Gen AI .NET SDK** = NuGet `Google.GenAI` (1.x, net8.0 + netstandard2.0) | Medium-high | [NuGet Google.GenAI](https://www.nuget.org/packages/Google.GenAI/1.13.0) |
| OpenAI publishes an official .NET library (`OpenAI` NuGet) | Medium (not re-checked this round) | — |
| **Kamal 2**: deploys containers to any VMs over SSH. kamal-proxy gives zero-downtime switches after a health check + automatic Let's Encrypt. Works for any containerised app | Medium-high (official repo + secondary) | [basecamp/kamal](https://github.com/basecamp/kamal), [Saeloun](https://blog.saeloun.com/2026/07/23/rails-8-kamal-2-deployment-zero-downtime/) |
| **Hetzner has no managed Postgres of its own**. Third parties (e.g. Ubicloud) offer managed Postgres on Hetzner hardware with PITR/HA | Medium (secondary) | [Sliplane](https://sliplane.io/de-de/blog/5-cheap-ways-to-host-postgres), [Ubicloud](https://www.ubicloud.com/use-cases/postgres-and-k8s-on-hetzner) |
| **Hetzner Object Storage**: S3-compatible, Falkenstein/Nuremberg/Helsinki. ≈ €6.49/mo base incl. 1 TB storage + 1 TB egress (2026, third-party). Some reported incidents → keep a second backup copy elsewhere | Medium | [Sliplane EU storage](https://sliplane.io/blog/cheap-object-storage-providers-europe), [heise](https://heise.de/-10189226) |
| DigitalOcean managed Postgres: single node from $15/mo, HA from 2 × $30/mo. PITR availability for PG not confirmed | Medium | [DO pricing](https://docs.digitalocean.com/products/databases/postgresql/details/pricing/) |
| **Supabase Pro** $25/mo incl. a Micro instance (1 GB RAM), 8 GB DB, 100k MAU. Daily backups, 7 days. PITR is an add-on (reported ≈ $100/mo per 7 days). Team $599/mo | Medium (secondary, 2026) | [jetadmin](https://www.jetadmin.io/blog/supabase-pricing-2026-guide-to-plans-limits-and-real-world-costs/), [toolradar](https://toolradar.com/blog/supabase-pricing-2026) |
| **Supabase RLS misconfiguration** is a widespread real-world leak source: 16,000+ exposed databases (UpGuard, Sept 2026), CVE-2025-48757 (170+ apps) | Medium-high | [BleepingComputer](https://bleepingcomputer.com/news/security/misconfigured-supabase-apps-expose-data-in-over-16-000-databases), [UpGuard](https://www.upguard.com/blog/everything-everywhere-systemic-data-exposure-in-supabase-apps.md) |
| Self-hosted Supabase ≈ 10 containers, ~4 GB RAM, lacks some cloud features (managed backups/PITR, logs) | Medium (community + vendors) | [GitHub issue](https://github.com/supabase/supabase-js/issues/1581), [selfhost.dev](https://selfhost.dev/blog/supabase-self-hosting/) |

### Still to verify (round 2)
- [ ] Current Hetzner VM line-up and prices (S05/S29).
- [ ] .NET 10 built-in Minimal API validation capabilities vs FluentValidation (S03).
- [ ] Dart OpenAPI generator support for OpenAPI 3.1 `oneOf` + discriminator (S02).
- [ ] WAL-G vs pgBackRest support for Postgres 18 (S29).
- [ ] The email provider's EU data handling and free tier (S24).

