import 'package:drift/drift.dart' show Variable;
import 'package:fb_api_client/fb_api_client.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/db/app_database.dart';
import 'package:fb_mobile/core/db/sync/drift_sync_store.dart';
import 'package:fb_mobile/core/db/sync/sync_codec.dart';
import 'package:fb_mobile/core/db/write_guard.dart';
import 'package:fb_mobile/features/buddy/data/buddy_sync_codecs.dart';
import 'package:fb_sync/fb_sync.dart';
import 'package:fb_sync/testing.dart';

import '../support/db_support.dart';

/// The fixed test epoch.
final DateTime syncBase = DateTime.fromMillisecondsSinceEpoch(
  1760351234567,
  isUtc: true,
);

/// Every codec the app wires (`app/app_scope.dart`).
Map<String, SyncEntityCodec> appCodecs(AppDatabase db) => {
  ...columnSyncCodecs(db.syncedTables),
  'chatMessage': ChatMessageSyncCodec(db),
  'proposal': ProposalSyncCodec(db),
};

/// Runs a body directly (tests without an applier).
Future<T> direct<T>(Future<T> Function() body) => body();

/// A [DriftSyncStore] over [db] for device [deviceId].
DriftSyncStore driftStore(
  AppDatabase db, {
  required Clock clock,
  String deviceId = testDevice,
  ExclusiveWrite exclusive = direct,
}) => DriftSyncStore(
  db,
  codecs: appCodecs(db),
  clock: clock,
  deviceId: () async => deviceId,
  exclusive: exclusive,
);

/// A local write as the applier makes it (A01 D9/D10): the next HLC after
/// `hlc.last`, the row with that HLC (the trigger appends the outbox row),
/// then `hlc.last`. Rows of `settings_kv` with `value_json` = [value].
Future<String> localSetting(
  AppDatabase db,
  Clock clock,
  String id, {
  required int value,
  bool deleted = false,
  String deviceId = testDevice,
}) => runAuthorizedWrite(
  () => db.transaction(() async {
    final last = await db
        .customSelect("SELECT value FROM sync_state WHERE key = 'hlc.last'")
        .getSingleOrNull();
    final hlc = HybridLogicalClock(
      clock: clock,
      deviceId: deviceId,
      last: last == null ? null : Hlc.parse(last.read<String>('value')),
    ).now().toString();
    final now = clock.nowUtc().millisecondsSinceEpoch;
    await db.customStatement(
      'INSERT INTO settings_kv (id, created_at, updated_hlc, version, '
      'deleted_at, device_id, origin, edited_by_user, value_json) '
      "VALUES (?, ?, ?, 1, ?, ?, 'direct', 0, ?) ON CONFLICT (id) DO UPDATE "
      'SET updated_hlc = excluded.updated_hlc, version = version + 1, '
      'deleted_at = excluded.deleted_at, device_id = excluded.device_id, '
      'value_json = excluded.value_json',
      [id, now, hlc, if (deleted) now else null, deviceId, '$value'],
    );
    await db.customStatement(
      "INSERT INTO sync_state (key, value) VALUES ('hlc.last', ?) "
      'ON CONFLICT (key) DO UPDATE SET value = excluded.value',
      [hlc],
    );
    return hlc;
  }),
);

/// [StoreHarness] over a drift database: entity `setting`, the value in
/// `value_json`. A "crash" is a temporary trigger that aborts the
/// transaction's last statements (the cursor write, the parked cleanup).
final class DriftHarness implements StoreHarness {
  new() : clock = SimClock(syncBase), db = memoryDatabase() {
    _store = driftStore(db, clock: clock);
  }

  final SimClock clock;
  final AppDatabase db;
  late DriftSyncStore _store;

  @override
  SyncStore get store => _store;

  @override
  Future<SyncVersion> write(
    String id, {
    int value = 0,
    bool deleted = false,
  }) async {
    clock.now = clock.now.add(const Duration(milliseconds: 1));
    final hlc = await localSetting(
      db,
      clock,
      id,
      value: value,
      deleted: deleted,
    );
    return SyncVersion('setting', id, hlc);
  }

  @override
  Future<({String hlc, bool deleted, int? value})?> row(String id) async {
    final r = await db
        .customSelect(
          'SELECT updated_hlc, deleted_at, value_json FROM settings_kv '
          'WHERE id = ?',
          variables: [Variable.withString(id)],
        )
        .getSingleOrNull();
    if (r == null) return null;
    return (
      hlc: r.read<String>('updated_hlc'),
      deleted: r.readNullable<int>('deleted_at') != null,
      value: int.tryParse(r.read<String>('value_json')),
    );
  }

  @override
  SyncDocument document(
    String id, {
    required String hlc,
    required int seq,
    int value = 0,
    bool deleted = false,
    bool compacted = false,
    int schemaVersion = 1,
  }) => SyncDocument(
    entity: 'setting',
    id: id,
    schemaVersion: schemaVersion,
    hlc: hlc,
    deviceId: hlc.substring(20),
    deletedAt: deleted ? syncBase : null,
    payload: compacted
        ? const {}
        : {
            'createdAtMs': 0,
            'origin': 'direct',
            'editedByUser': false,
            'valueJson': '$value',
          },
    serverSeq: '$seq',
    compacted: compacted,
  );

  Future<int> _count(String table) async =>
      (await db.customSelect('SELECT count(*) AS n FROM $table').getSingle())
          .read<int>('n');

  @override
  Future<int> outboxCount() => _count('sync_outbox');

  @override
  Future<int> parkedCount() async =>
      await _count('sync_parked') +
      await _count('sync_displaced WHERE parked_reason IS NOT NULL');

  @override
  int? valueOf(SyncChange change) =>
      int.tryParse(change.payload['valueJson']! as String);

  @override
  Future<int> deferredCount() => _count('sync_deferred');

  @override
  // Issued together, before any later statement of the test.
  void crashNextCommit() => _crash = runAuthorizedWrite(
    () => Future.wait([
      for (final sql in _crashTriggers) db.customStatement(sql),
    ]),
  );

  Future<void>? _crash;

  /// Waits for an armed crash's triggers (call before the crashing step).
  Future<void> get armed => _crash ?? Future.value();

  @override
  Future<void> restart() async {
    await runAuthorizedWrite(() async {
      for (final t in ['crash_cursor_i', 'crash_cursor_u', 'crash_parked']) {
        await db.customStatement('DROP TRIGGER IF EXISTS $t');
      }
    });
    _store = driftStore(db, clock: clock);
  }

  @override
  String remoteHlc(int wallMs) =>
      '${wallMs.toString().padLeft(13, '0')}-00000-${syntheticId(2)}';

  @override
  int get nowMs => clock.now.millisecondsSinceEpoch;
}

/// A raw test write outside the applier.
Future<void> writeRaw(AppDatabase db, String sql) =>
    runAuthorizedWrite(() => db.customStatement(sql));

/// The temporary triggers of `DriftHarness.crashNextCommit`.
const List<String> _crashTriggers = [_crashInsert, _crashUpdate, _crashSettle];

const _crashInsert =
    'CREATE TEMP TRIGGER crash_cursor_i BEFORE INSERT ON sync_state WHEN '
    "NEW.key = 'sync.cursor' BEGIN SELECT RAISE(ABORT, 'crash'); END";

const _crashUpdate =
    'CREATE TEMP TRIGGER crash_cursor_u BEFORE UPDATE ON sync_state WHEN '
    "NEW.key = 'sync.cursor' BEGIN SELECT RAISE(ABORT, 'crash'); END";

const _crashSettle =
    'CREATE TEMP TRIGGER crash_parked BEFORE DELETE ON sync_outbox '
    "BEGIN SELECT RAISE(ABORT, 'crash'); END";
