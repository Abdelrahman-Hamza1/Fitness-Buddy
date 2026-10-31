/// Test support for the sync engine: the in-memory store, the fake server,
/// the store contract checks and the convergence scenarios. Synthetic data
/// only; never imported by the app's `lib/`.
library;

export 'src/testing/fake_server.dart';
export 'src/testing/memory_store.dart';
export 'src/testing/scenarios.dart';
export 'src/testing/store_contract.dart';
