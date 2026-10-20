# Catalog (B07)

Global reference data, imported from an A05 release; no user content or model-generated nutrition.
The module owns `catalog.*`. Application credentials have SELECT only. OFF data is reserved in
`off_cache`, never imported or merged into release foods (B10).

`CatalogModule.ImportAsync` is the operator boundary used by the migrate role under recovery
maintenance. `Catalog:ImportDirectory` points to the build root containing `catalog.db` and `release/`.
The importer validates the embedded closed JSON Schemas, byte/count/hash budgets and references,
then publishes data, immutable pack bytes and latest pointer in one transaction. Version rollback,
version/content/pack reuse and stable identity/first-version changes fail. Retired foods remain
addressable by key but leave search. Current releases are per100g; per100ml input is rejected
rather than silently relabelled (add an explicit HTTP basis before supporting that release variant).

`Contracts.IFoodResolver` is the only Buddy seam. EN/AR candidates union by key and best score;
state/kind are strict filters. Candidate scores combine the same source and matching priority as search, never confidence in nutrients.
No user history or OFF input exists here. The implementation does not use the network.

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
