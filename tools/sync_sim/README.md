# Sync feasibility harness (B01)

Codex owns this package (TD-063). It is kept for B05/A34. It uses the generated
API models and `fb_domain` HLC, with a transport port shared by an independent
in-memory fake and the real container API. It contains synthetic data only.

- `make test-dart`: includes 1,000 reproducible seeded runs and fault tests.
- `make sync-spike`: builds the API image, migrates ephemeral pinned Postgres,
  exercises real HTTP connection loss/retries/crashes, runs 50 seeded scenarios,
  and times 5,000 rows pushed then pulled on a fresh simulated device.

`SimStore.checkpoint/restore` models durable rows, immutable outbox versions,
clock and cursor across engine restarts. `apply` stages the whole page before
committing rows/cursor/clock together. A01/A34 must use actual SQLite
transactions. This is a reusable protocol engine, not the production phone
outbox or scheduler. Production sync/auth/schema validation/retention and
reset detection remain B04/B05/A34.

Protocol: `technical-planning/05-data-and-sync.md` §5.4. Keep that section and
the B01 card log current whenever the wire format changes. Future-clock
rejections remain pending; the tool does not silently repair or discard them.
The dedicated `SyncSpike` environment + opt-in flag + random test key + fixed
synthetic principal gate keeps the routes closed in normal runs. Never enable
this on a real-data database. The script binds only loopback, uses no volume,
and deletes its containers/network on exit.

B07 also uses this existing backend-owned integration harness for the tiny offline
`catalog_client_test.dart` gate: it verifies the generated API client preserves arbitrary binary
pack bytes. `make catalog-client-smoke` runs it without a server, credentials or paid calls.
