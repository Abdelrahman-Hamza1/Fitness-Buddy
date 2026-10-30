# Catalog (B07, B10a)

Global reference data, imported from an A05 release; no user content or model-generated nutrition.
The module owns `catalog.*`. Application credentials have SELECT only on release tables; since B10a
they also write `off_cache`, the licence-isolated Open Food Facts cache, which is never imported or
merged into release foods (`07` §3).

`CatalogModule.ImportAsync` is the operator boundary used by the migrate role under recovery
maintenance. `Catalog:ImportDirectory` points to the build root containing `catalog.db` and `release/`.
The importer validates the embedded closed JSON Schemas, byte/count/hash budgets and references,
then publishes data, immutable pack bytes and latest pointer in one transaction. Version rollback,
version/content/pack reuse and stable identity/first-version changes fail. Retired foods remain
addressable by key but leave search. Current releases are per100g; per100ml input is rejected
rather than silently relabelled (add an explicit HTTP basis before supporting that release variant).

`Contracts.IFoodResolver` is the only Buddy seam. EN/AR candidates union by key and best score;
state/kind are strict filters. Candidate scores combine the same source and matching priority as search, never confidence in nutrients.
No user history or OFF input exists here. Release search and import do not use the network.

Search keys use explicit TD-030 tables, every shared YAML golden case and fixed point is tested.
One alias table uses GIN trigram and simple-token indexes. SQL parameters carry queries, filters
and cursor values. Exact/prefix/token/substring/fuzzy rank within source priority, then score and
C-collated stable key. Fuzzy matching is English/Arabizi only; Arabic uses listed aliases/tokens.
Canonical ID grouping and normalized name+state+source dedup precede keyset paging. Query and
release bind the cursor; importing a newer release requires restarting pagination. Reads use a
repeatable snapshot. Public source_ref null stays null; its private relational identity sentinel is
empty string (not a permitted nonnull source_ref), so identity checks remain unambiguous.

`GET /v1/foods/search`, `/v1/foods/{id}`, `/v1/catalog/packs/latest` and the versioned binary download
all require any live Identity principal, including guests, and the common recovery/client/rate gates.
Download URLs are API-relative, carry no secrets and require the same headers. Check SHA256 and
size before installation (A24). Binary packs stay in Postgres until B13/B14 storage provisioning.

Tests: `make test-dotnet` builds the non-mutating A05 catalog then runs shared normalization,
synthetic dish/import/paging/auth fixtures and real full-catalog import/relevance/p95 checks.
`make check-catalog-schemas` proves the embedded release validator matches `contracts/catalog`.
Operations: [catalog runbook](../../../../docs/runbooks/catalog.md).

## Barcode lookup (B10a)

`GET /v1/foods/barcode/{code}` (any live principal): GTIN-8/12/13/14 with a valid check digit, keyed in
OFF's 13-digit form. `BarcodeLookup` reads `catalog.off_cache` (products 30 days, unknown codes 1 day),
else one Open Food Facts v2 read through `OpenFoodFactsClient`: `User-Agent` from
`Catalog:OpenFoodFacts:UserAgent`, no identity or cookies, no redirects, 5 s timeout, 1 MB cap, the
framework's HttpClient logs removed (they would print the barcode). `OffGate` (singleton) enforces a
process-wide budget (`ReadsPerMinute`, default 10), a per-account budget for upstream fetches
(`UserFetchesPerHour`, default 30; cache hits are free), a cool-down after OFF answers 429/503 and
one in-flight read per code. While OFF can't be asked, an expired product is served for 7 more days,
then 503 with `Retry-After`. `OffCacheExpiryJob` (`catalog.off-cache-expiry`, daily 03:17 UTC, a
DI-registered `JobSchedule`) deletes rows past that window. Logs carry outcome codes only; outbound
client spans keep only the origin. `Catalog:OpenFoodFacts:Enabled=false` answers 503 without calling OFF.
Tests: `Persistence.Tests/BarcodeLookupTests` (fake OFF handler, Testcontainers).
