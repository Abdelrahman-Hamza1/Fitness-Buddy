import 'package:fb_api_client/fb_api_client.dart';
import 'package:fb_sync/fb_sync.dart';
import 'package:fb_sync/testing.dart';

/// The fixed test epoch.
final DateTime base = DateTime.fromMillisecondsSinceEpoch(
  1760351234567,
  isUtc: true,
);

/// [StoreHarness] over [MemorySyncStore] (entity `setting`, payload
/// `{'value': n}`); documents up to schema 2 are readable.
final class MemoryHarness implements StoreHarness {
  new() : clock = SimClock(base) {
    _store = MemorySyncStore(
      clock: clock,
      deviceId: syntheticId(1),
      readable: (_, version) => version <= 2,
    );
  }

  final SimClock clock;
  late MemorySyncStore _store;

  @override
  SyncStore get store => _store;

  @override
  Future<SyncVersion> write(
    String id, {
    int value = 0,
    bool deleted = false,
  }) async {
    clock.now = clock.now.add(const Duration(milliseconds: 1));
    return SyncVersion.ofChange(
      _store.confirm(
        entity: 'setting',
        id: id,
        payload: {'value': value},
        deleted: deleted,
      ),
    );
  }

  @override
  Future<({String hlc, bool deleted, int? value})?> row(String id) async {
    final row = _store.rows['setting/$id'];
    if (row == null) return null;
    return (
      hlc: row.hlc,
      deleted: row.deletedAt != null,
      value: row.payload['value'] as int?,
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
    deletedAt: deleted ? base : null,
    payload: compacted ? const {} : {'value': value},
    serverSeq: '$seq',
    compacted: compacted,
  );

  @override
  Future<int> outboxCount() async => _store.outboxLength;

  @override
  Future<int> parkedCount() async =>
      _store.parked.length +
      _store.displaced.values.where((d) => d.$2 != null).length;

  @override
  Future<int> deferredCount() async => _store.deferred.length;

  @override
  int? valueOf(SyncChange change) => change.payload['value'] as int?;

  @override
  void crashNextCommit() {
    _store.crash = (_) {
      _store.crash = null;
      throw const InjectedCrash();
    };
  }

  @override
  Future<void> restart() async => _store = _store.restarted();

  @override
  String remoteHlc(int wallMs) =>
      '${wallMs.toString().padLeft(13, '0')}-00000-${syntheticId(2)}';

  @override
  int get nowMs => clock.now.millisecondsSinceEpoch;
}
