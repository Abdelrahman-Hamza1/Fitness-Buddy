import 'package:fb_api_client/fb_api_client.dart';
import 'package:fb_mobile/core/db/sync/drift_sync_store.dart';
import 'package:fb_sync/fb_sync.dart';

/// The parked-version step of a sync run, between the deferred retry and
/// the push (`SyncEngine.afterDeferredRetry`, TD-114, A62 D23): when the
/// parked retry is due (an app update or a day passed), first resolve the
/// versions parked as a possible schema downgrade against the server
/// ([recoverRefusedDowngrades]), then retry the parked versions.
Future<void> retryParkedSafely({
  required DriftSyncStore store,
  required SyncTransport transport,
  required int nowMs,
  required String appVersion,
}) async {
  if (!await store.parkedRetryDue(nowMs: nowMs, appVersion: appVersion)) {
    return;
  }
  await recoverRefusedDowngrades(store: store, transport: transport);
  await store.retryParkedIfDue(nowMs: nowMs, appVersion: appVersion);
}

/// Re-reads the server's current document of every row with a version
/// parked as a possible schema downgrade and resolves them
/// ([DriftSyncStore.resolveRefusedDowngrades]). The pull API has no
/// by-id read, so this scans the dataset's documents from cursor `0`
/// without moving the stored cursor, and stops once every row was seen.
/// It is rare (an old build's refused edit, or a phone ahead of the
/// server) and works whatever the cursor and the deferred set hold: an
/// older build skipped the newer document by HLC and moved on.
///
/// Does nothing without a bound dataset or during a reset (the run's own
/// pull deals with those). Throws `SyncFailure` like any pull; nothing is
/// resolved then.
Future<void> recoverRefusedDowngrades({
  required DriftSyncStore store,
  required SyncTransport transport,
  int pageLimit = 100,
}) async {
  final rows = await store.refusedDowngrades();
  if (rows.isEmpty) return;
  final checkpoint = await store.checkpoint();
  final dataset = checkpoint.datasetId;
  if (dataset == null || checkpoint.resetActive) return;
  final found = <SyncRowKey, SyncDocument>{};
  var cursor = '0';
  while (found.length < rows.length) {
    final page = await transport.pull(
      cursor: cursor,
      limit: pageLimit,
      datasetId: dataset,
    );
    // A changed dataset: the run's pull resets; resolve nothing now.
    if (page.reason != null || page.datasetId != dataset) return;
    for (final d in page.changes) {
      final key = (entity: d.entity, id: d.id);
      if (rows.contains(key)) found[key] = d;
    }
    if (page.changes.isEmpty || page.nextCursor == cursor) break;
    cursor = page.nextCursor;
  }
  await store.resolveRefusedDowngrades(found);
}
