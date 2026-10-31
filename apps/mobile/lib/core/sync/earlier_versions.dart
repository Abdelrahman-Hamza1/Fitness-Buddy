import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/db/sync/drift_sync_store.dart';
import 'package:fb_mobile/core/sync/legacy_target_factors.dart';
import 'package:fb_sync/fb_sync.dart';

/// One earlier version of a row from the server's history (G7, A34 D14).
/// [payload] is upgraded to the current schema version and holds user
/// content: show it, never log it.
final class EarlierVersion {
  /// See the fields.
  const new({
    required this.hlc,
    required this.wallMs,
    required this.deleted,
    required this.payload,
    this.localVersion,
  });

  /// The version's HLC.
  final String hlc;

  /// When it was written (its HLC wall time, UTC ms).
  final int wallMs;

  /// It was a tombstone.
  final bool deleted;

  /// The payload at the current schema version.
  final Map<String, Object?> payload;

  /// The local row's `version` when this list was read: a restore expects
  /// it, so an edit or a pull meanwhile refuses the restore (A34 fix 5).
  final int? localVersion;

  @override
  String toString() => 'EarlierVersion($wallMs)';
}

/// The earlier versions of row [id] of [entity], newest first (online only;
/// throws `SyncFailure` when offline). Compacted fences and versions this
/// app can't read are left out; at most [maxPages] pages of 100.
Future<List<EarlierVersion>> readEarlierVersions(
  SyncTransport transport,
  DriftSyncStore store,
  String entity,
  String id, {
  int maxPages = 5,
}) async {
  final dataset = (await store.checkpoint()).datasetId;
  final localVersion = await store.localVersion(entity, id);
  final factorsSince = entity == 'targetSettings'
      ? await store.dayFactorsSinceMs()
      : null;
  final versions = <EarlierVersion>[];
  var cursor = '0';
  for (var page = 0; page < maxPages; page++) {
    final result = await transport.itemHistory(
      entity,
      id,
      cursor: cursor,
      limit: 100,
      datasetId: dataset,
    );
    if (result.changes.isEmpty) break;
    for (final d in result.changes) {
      if (d.compacted || d.entity != entity || d.id != id) continue;
      final hlc = Hlc.tryParse(d.hlc);
      final payload = SyncDocumentUpgraders.upgrade(
        entity,
        d.schemaVersion,
        d.payload,
      );
      if (hlc == null || payload == null) continue;
      versions.add(
        EarlierVersion(
          hlc: d.hlc,
          wallMs: hlc.wallMs,
          deleted: d.deletedAt != null,
          payload: entity == 'targetSettings'
              ? legacyTargetSettings(
                  payload,
                  wallMs: hlc.wallMs,
                  sinceMs: factorsSince,
                )
              : payload,
          localVersion: localVersion,
        ),
      );
    }
    cursor = result.nextCursor;
  }
  versions.sort((a, b) => b.hlc.compareTo(a.hlc));
  return versions;
}
