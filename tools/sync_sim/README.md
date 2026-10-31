# Real-API sync harness (B01, A34)

Claude owns this package (TD-085; Codex wrote the B01 version). Since A34 it runs the
**production engine** from `packages/fb_sync` (in-memory stores, the same `SyncEngine`
the phone runs over drift) against the real API container. Synthetic data only.

- `make test-dart`: the 1,000 seeded fake-server runs, OF-03 and the fault tests live in
  `packages/fb_sync/test/` now; this package keeps the TD-049 vector test and the B07
  catalog client gate.
- `make sync-spike`: builds the API image, migrates ephemeral pinned Postgres, then
  `bin/sync_sim.dart` runs: a half-sent request body (no commit, idempotent retry), the
  fault set (dropped push before/after commit, crash before the local acknowledgement,
  a local edit while a push is in flight, a crash mid-page, a duplicate push), OF-03 in
  both sync orders, `SYNC_SIM_RUNS` randomized multi-device runs (50 per CI build,
  1,000 on nightly and manual runs, A34 D20) and a 10,000-row push then fresh pull.

Each randomized run starts its devices at the server's current cursor (rows of different
runs are disjoint), so a run doesn't re-pull every earlier run; the 10,000-row benchmark
and the fault set still restore a fresh device from cursor `0`. The oracle reads the
global history incrementally (`GET /v1/sync/history`, its own cursor).

Protocol: `technical-planning/05-data-and-sync.md` §5. Future-clock rejections stay
pending; the harness never repairs or discards them. The script binds only loopback, uses
no volume, and deletes its containers and network on exit.

B07 also uses this package for the tiny offline `catalog_client_test.dart` gate: it
verifies the generated API client preserves arbitrary binary pack bytes.
`make catalog-client-smoke` runs it without a server, credentials or paid calls.
