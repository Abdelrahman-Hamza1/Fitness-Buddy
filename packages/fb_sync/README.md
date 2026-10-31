# fb_sync

The production sync engine (A34, TD-006, `technical-planning/05-data-and-sync.md` §5).
Pure Dart: the engine talks to a `SyncStore` port (the app implements it with drift in
`apps/mobile/lib/core/db/sync/`) and a `SyncTransport` port (`ApiSyncTransport` over the
generated client). The same engine runs on the phone, in the 1,000-seed convergence test
(`test/convergence_test.dart`, in-memory store + fake server) and against the real API in
CI (`tools/sync_sim`, `make sync-spike`).

`package:fb_sync/testing.dart` holds the in-memory store, the fake server, the store
contract checks the drift store also runs, and the convergence scenarios. Synthetic data only.

The design and its decisions are in `technical-planning/steps/A34-sync-engine-app.md`
(Low-level plan, D1–D20).
