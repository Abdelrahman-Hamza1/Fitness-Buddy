import 'package:fb_api_client/fb_api_client.dart';
import 'package:fb_sync/src/model.dart';

/// The engine's durable side (A34 §1): the outbox, the rows and the pull
/// position. The app implements it with drift (`DriftSyncStore`); tests and
/// tools/sync_sim use `MemorySyncStore` from `package:fb_sync/testing.dart`.
///
/// **Every method is atomic:** it commits completely or not at all (one
/// SQLite transaction in the app), so a crash between any two calls leaves
/// a state the next run continues from. `test/store_contract_test.dart`
/// and the app's drift store test run the same checks
/// (`storeContractChecks`).
abstract interface class SyncStore {
  /// The pull position.
  Future<SyncCheckpoint> checkpoint();

  /// Up to [limit] pending rows, oldest first, one per row (the outbox
  /// coalesced per `(entity, id)`), each encoded **as the row is now**: its
  /// own HLC, device, tombstone and payload (A34 D3). Rows the app's
  /// encoder refuses are parked here and listed in
  /// [PendingRead.parkedNow]. Parked versions are not pending.
  Future<PendingRead> pending({required int limit});

  /// Settles a push in one commit: for each of [acknowledged], deletes the
  /// row's outbox entries and parked entries with `hlc <= version.hlc`; for
  /// each of [parked], moves the row's outbox entries with
  /// `hlc <= version.hlc` to the parked set with its reason. A newer local
  /// edit made meanwhile (a higher HLC) stays pending.
  Future<void> settle({
    List<SyncVersion> acknowledged = const [],
    List<ParkedVersion> parked = const [],
  });

  /// Applies one pull [page] requested at [requestedCursor], all or
  /// nothing, together with the cursor, the dataset id and the local clock
  /// (A34 D6, D9):
  /// - throws `SyncFailure(protocol)` unless the page's `serverSeq`s are
  ///   strictly ascending and above [requestedCursor] and `nextCursor` is
  ///   the last one (or [requestedCursor] when empty);
  /// - throws `SyncFailure(clockBehind)` if a document's HLC is too far
  ///   ahead of the device clock;
  /// - writes a document only if its HLC is greater than the local row's;
  ///   a compacted document tombstones an older local row and is skipped
  ///   when the row is absent; a document the app can't read is deferred;
  /// - while a reset is active, deletes the outbox entries of each pulled
  ///   row with `hlc <= document.hlc`, and an empty page ends the reset.
  Future<PageApplied> applyPage(
    SyncPage page, {
    required String requestedCursor,
  });

  /// Binds the dataset discovered by an unbound pull at cursor `0`
  /// ([datasetId]) when none is bound yet and no page was applied, so the
  /// first run can push before it pulls (A34 D2). Does nothing otherwise.
  Future<void> bindDataset(String datasetId);

  /// Starts a dataset reset (TD-066, A34 D8) in one commit: cursor `0`, no
  /// dataset, reset active, and every local row enqueued again.
  Future<void> beginReset();

  /// Applies the deferred documents this app can read now (after an app
  /// update), by the same LWW rule. Returns what it changed.
  Future<PageApplied> retryDeferred();

  /// Moves every parked version back to the outbox ("Try again", A34 D5).
  Future<int> retryParked();

  /// Records a successful run at [at] (UTC).
  Future<void> recordSuccess(DateTime at);
}
