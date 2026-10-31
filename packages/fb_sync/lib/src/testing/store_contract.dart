import 'package:fb_api_client/fb_api_client.dart';
import 'package:fb_sync/src/model.dart';
import 'package:fb_sync/src/store.dart';

/// What the shared [storeContractChecks] need from a [SyncStore]
/// implementation: the store, its local write path, its rows and a way to
/// simulate a crash and a restart. The in-memory store and the app's drift
/// store both implement it, so both meet the same contract.
abstract interface class StoreHarness {
  /// The store under test (a new instance after [restart]).
  SyncStore get store;

  /// A confirmed local write of row [id] holding [value] (a tombstone if
  /// [deleted]) through the implementation's real write path.
  Future<SyncVersion> write(String id, {int value = 0, bool deleted = false});

  /// Row [id] as stored: its HLC, tombstone and value, or `null`.
  Future<({String hlc, bool deleted, int? value})?> row(String id);

  /// A pulled document for row [id] at [hlc] and server sequence [seq].
  SyncDocument document(
    String id, {
    required String hlc,
    required int seq,
    int value = 0,
    bool deleted = false,
    bool compacted = false,
    int schemaVersion = 1,
  });

  /// Outbox entries left (versions, not rows).
  Future<int> outboxCount();

  /// Parked rows.
  Future<int> parkedCount();

  /// Deferred documents.
  Future<int> deferredCount();

  /// The value a pushed change carries (its payload, as [write] stored it).
  int? valueOf(SyncChange change);

  /// Makes the next commit fail like a crash mid-transaction.
  void crashNextCommit();

  /// Reopens the store over the same durable state.
  Future<void> restart();

  /// An HLC from another device at wall ms [wallMs] (counter 0).
  String remoteHlc(int wallMs);

  /// The test clock's current wall time in ms.
  int get nowMs;
}

/// A failed contract check.
final class ContractViolation implements Exception {
  /// [message] names the check.
  const new(this.message);

  /// What failed.
  final String message;

  @override
  String toString() => 'ContractViolation: $message';
}

void _require(bool ok, String message) {
  if (!ok) throw ContractViolation(message);
}

Future<void> _throws(Future<void> Function() body, String message) async {
  try {
    await body();
  } on Object {
    return;
  }
  throw ContractViolation(message);
}

const _dataset = '00000000-0000-7000-8000-000000000777';

SyncPage _page(
  List<SyncDocument> documents, {
  required String next,
  String dataset = _dataset,
}) => SyncPage(
  changes: documents,
  nextCursor: next,
  datasetId: dataset,
  serverTime: DateTime.utc(2026),
  reason: null,
);

String _id(int n) =>
    '00000000-0000-7000-8000-${n.toRadixString(16).padLeft(12, '0')}';

/// The store contract (A34 §1, `SyncStore`'s documentation), by name. Each
/// check gets a fresh harness.
final Map<String, Future<void> Function(StoreHarness h)> storeContractChecks = {
  'pending coalesces per row and sends the row as it is now': (h) async {
    await h.write(_id(1), value: 1);
    final second = await h.write(_id(1), value: 2);
    await h.write(_id(2), value: 3);
    final read = await h.store.pending(limit: 10);
    _require(read.changes.length == 2, 'one change per row');
    final first = read.changes.first;
    _require(
      first.id == _id(1) && first.hlc == second.hlc,
      'the newest version, oldest row first',
    );
    final limited = await h.store.pending(limit: 1);
    _require(limited.changes.length == 1, 'the limit holds');
  },
  'settle acknowledges <= hlc and keeps a newer local edit': (h) async {
    await h.write(_id(1), value: 1);
    final sent = SyncVersion.ofChange(
      (await h.store.pending(limit: 10)).changes.single,
    );
    final newer = await h.write(_id(1), value: 2);
    await h.store.settle(acknowledged: [sent]);
    final read = await h.store.pending(limit: 10);
    _require(
      read.changes.length == 1 && read.changes.single.hlc == newer.hlc,
      'the newer edit stays pending',
    );
    await h.store.settle(acknowledged: [newer]);
    _require(await h.outboxCount() == 0, 'acknowledged versions leave');
  },
  'parking moves a version out; a newer edit pushes and clears it': (h) async {
    final v1 = await h.write(_id(1), value: 1);
    await h.store.settle(parked: [ParkedVersion(v1, 'invalidPayload')]);
    _require(await h.parkedCount() == 1, 'parked');
    _require(
      (await h.store.pending(limit: 10)).changes.isEmpty,
      'a parked version is not pending',
    );
    _require((await h.row(_id(1)))?.value == 1, 'the row is kept');
    final v2 = await h.write(_id(1), value: 2);
    final read = await h.store.pending(limit: 10);
    _require(read.changes.single.hlc == v2.hlc, 'the newer edit pushes');
    await h.store.settle(acknowledged: [v2]);
    _require(await h.parkedCount() == 0, 'its ack clears the parked one');
    final v3 = await h.write(_id(2), value: 3);
    await h.store.settle(parked: [ParkedVersion(v3, 'unsupported')]);
    _require(await h.store.retryParked() == 1, 'try again counts');
    _require(
      (await h.store.pending(limit: 10)).changes.single.id == _id(2),
      'try again makes it pending',
    );
  },
  'applyPage writes newer documents only, with the cursor': (h) async {
    final local = await h.write(_id(1), value: 1);
    final localWall = int.parse(local.hlc.substring(0, 13));
    await h.store.applyPage(
      _page([
        h.document(_id(1), hlc: h.remoteHlc(localWall - 1000), seq: 1),
        h.document(_id(2), hlc: h.remoteHlc(localWall - 1000), seq: 2),
      ], next: '2'),
      requestedCursor: '0',
    );
    _require((await h.row(_id(1)))?.value == 1, 'an older remote loses');
    _require((await h.row(_id(2)))?.value == 0, 'a new row is written');
    final cp = await h.store.checkpoint();
    _require(
      cp.cursor == '2' && cp.datasetId == _dataset,
      'cursor and dataset move with the page',
    );
    await h.store.applyPage(
      _page([
        h.document(
          _id(1),
          hlc: h.remoteHlc(localWall + 1000),
          seq: 3,
          value: 9,
        ),
      ], next: '3'),
      requestedCursor: '2',
    );
    final row = await h.row(_id(1));
    _require(row?.value == 9, 'a newer remote wins');
    final next = await h.write(_id(1), value: 10);
    _require(
      next.hlc.compareTo(row!.hlc) > 0,
      'a later local write is after the pulled version (clock fed)',
    );
  },
  'a bad page and a crash commit nothing': (h) async {
    final hlc = h.remoteHlc(h.nowMs - 1000);
    await _throws(
      () => h.store.applyPage(
        _page([
          h.document(_id(1), hlc: hlc, seq: 2),
          h.document(_id(2), hlc: hlc, seq: 1),
        ], next: '2'),
        requestedCursor: '0',
      ),
      'unordered pages are refused',
    );
    await _throws(
      () => h.store.applyPage(
        _page([h.document(_id(1), hlc: hlc, seq: 2)], next: '5'),
        requestedCursor: '0',
      ),
      'a cursor past the delivered rows is refused',
    );
    h.crashNextCommit();
    await _throws(
      () => h.store.applyPage(
        _page([h.document(_id(1), hlc: hlc, seq: 1)], next: '1'),
        requestedCursor: '0',
      ),
      'the crash propagates',
    );
    await h.restart();
    _require(await h.row(_id(1)) == null, 'no row from a failed page');
    _require(
      (await h.store.checkpoint()).cursor == '0',
      'no cursor from a failed page',
    );
  },
  'a crash during settle keeps the outbox': (h) async {
    final v = await h.write(_id(1), value: 1);
    h.crashNextCommit();
    await _throws(
      () => h.store.settle(acknowledged: [v]),
      'the crash propagates',
    );
    await h.restart();
    _require(await h.outboxCount() == 1, 'still pending after the crash');
  },
  'a compacted fence tombstones an older row and skips an absent one':
      (h) async {
        final local = await h.write(_id(1), value: 1);
        final wall = int.parse(local.hlc.substring(0, 13));
        await h.store.applyPage(
          _page([
            h.document(
              _id(1),
              hlc: h.remoteHlc(wall + 1000),
              seq: 1,
              deleted: true,
              compacted: true,
            ),
            h.document(
              _id(2),
              hlc: h.remoteHlc(wall + 1000),
              seq: 2,
              deleted: true,
              compacted: true,
            ),
          ], next: '2'),
          requestedCursor: '0',
        );
        final row = await h.row(_id(1));
        _require(row != null && row.deleted, 'the fence tombstones the row');
        _require(await h.row(_id(2)) == null, 'no row from a bare fence');
      },
  'a pulled newer version keeps a pending local edit for push': (h) async {
    final mine = await h.write(_id(1), value: 1);
    final wall = int.parse(mine.hlc.substring(0, 13));
    final theirs = h.remoteHlc(wall + 1000);
    await h.store.applyPage(
      _page([h.document(_id(1), hlc: theirs, seq: 1, value: 9)], next: '1'),
      requestedCursor: '0',
    );
    _require((await h.row(_id(1)))?.value == 9, 'the newer version wins');
    final read = await h.store.pending(limit: 10);
    _require(
      read.changes.length == 1 &&
          read.changes.single.hlc == mine.hlc &&
          h.valueOf(read.changes.single) == 1,
      'the replaced local edit is pushed with its own payload',
    );
    await h.restart();
    _require(
      (await h.store.pending(limit: 10)).changes.single.hlc == mine.hlc,
      'kept across a restart',
    );
    await h.store.settle(
      acknowledged: [SyncVersion('setting', _id(1), theirs)],
    );
    _require(
      (await h.store.pending(limit: 10)).changes.single.hlc == mine.hlc,
      'only its own acknowledgement removes it',
    );
    await h.store.settle(acknowledged: [mine]);
    _require(
      (await h.store.pending(limit: 10)).changes.isEmpty,
      'acknowledged, gone',
    );
  },
  'a pulled version keeps a parked local edit for Try again': (h) async {
    final mine = await h.write(_id(1), value: 1);
    await h.store.settle(parked: [ParkedVersion(mine, 'invalidPayload')]);
    final wall = int.parse(mine.hlc.substring(0, 13));
    await h.store.applyPage(
      _page([
        h.document(_id(1), hlc: h.remoteHlc(wall + 1000), seq: 1, value: 9),
      ], next: '1'),
      requestedCursor: '0',
    );
    _require(
      (await h.store.pending(limit: 10)).changes.isEmpty,
      'still parked',
    );
    _require(await h.parkedCount() == 1, 'counted as parked');
    await h.store.retryParked();
    final read = await h.store.pending(limit: 10);
    _require(
      read.changes.length == 1 &&
          read.changes.single.hlc == mine.hlc &&
          h.valueOf(read.changes.single) == 1,
      'try again pushes the parked payload, not the pulled one',
    );
  },
  'a fence over a pending local edit keeps it for push': (h) async {
    final mine = await h.write(_id(1), value: 1);
    final wall = int.parse(mine.hlc.substring(0, 13));
    await h.store.applyPage(
      _page([
        h.document(
          _id(1),
          hlc: h.remoteHlc(wall + 1000),
          seq: 1,
          deleted: true,
          compacted: true,
        ),
      ], next: '1'),
      requestedCursor: '0',
    );
    final read = await h.store.pending(limit: 10);
    _require(
      read.changes.length == 1 &&
          read.changes.single.hlc == mine.hlc &&
          h.valueOf(read.changes.single) == 1,
      'the replaced edit is pushed',
    );
  },
  'bindDataset binds only an unbound store at cursor 0': (h) async {
    await h.store.bindDataset(_dataset);
    _require(
      (await h.store.checkpoint()).datasetId == _dataset,
      'bound at cursor 0',
    );
    await h.store.bindDataset('00000000-0000-7000-8000-000000000778');
    _require(
      (await h.store.checkpoint()).datasetId == _dataset,
      'never rebinds',
    );
  },
  'a reset re-enqueues every row and prunes what the new dataset has':
      (h) async {
        final a = await h.write(_id(1), value: 1);
        await h.write(_id(2), value: 2);
        await h.store.settle(
          acknowledged: [
            for (final c in (await h.store.pending(limit: 10)).changes)
              SyncVersion.ofChange(c),
          ],
        );
        _require(await h.outboxCount() == 0, 'synced before the reset');
        await h.store.beginReset();
        final cp = await h.store.checkpoint();
        _require(
          cp.resetActive && cp.cursor == '0' && cp.datasetId == null,
          'reset state',
        );
        // Every local row: the two, plus any rows the implementation
        // seeds (the app's default meal slots).
        _require(await h.outboxCount() >= 2, 'every row enqueued');
        await h.restart();
        _require(
          (await h.store.checkpoint()).resetActive,
          'the reset survives a restart',
        );
        await h.store.applyPage(
          _page([h.document(_id(1), hlc: a.hlc, seq: 1, value: 1)], next: '1'),
          requestedCursor: '0',
        );
        final ids = {
          for (final c in (await h.store.pending(limit: 1000)).changes) c.id,
        };
        _require(
          ids.contains(_id(2)) && !ids.contains(_id(1)),
          'only what the new dataset lacks stays pending',
        );
        await h.store.applyPage(_page([], next: '1'), requestedCursor: '1');
        _require(
          !(await h.store.checkpoint()).resetActive,
          'an empty page ends the reset',
        );
      },
  'a pulled version far in the future stops the page': (h) async {
    await _throws(
      () => h.store.applyPage(
        _page([
          h.document(
            _id(1),
            hlc: h.remoteHlc(h.nowMs + const Duration(days: 2).inMilliseconds),
            seq: 1,
          ),
        ], next: '1'),
        requestedCursor: '0',
      ),
      'clockBehind',
    );
    _require(await h.row(_id(1)) == null, 'nothing written');
    _require((await h.store.checkpoint()).cursor == '0', 'cursor kept');
  },
  'an unreadable newer schema is deferred and the cursor moves': (h) async {
    final applied = await h.store.applyPage(
      _page([
        h.document(
          _id(1),
          hlc: h.remoteHlc(h.nowMs - 1000),
          seq: 1,
          schemaVersion: 99,
        ),
      ], next: '1'),
      requestedCursor: '0',
    );
    _require(applied.deferred.length == 1, 'reported as deferred');
    _require(await h.deferredCount() == 1, 'stored aside');
    _require(await h.row(_id(1)) == null, 'not applied');
    _require((await h.store.checkpoint()).cursor == '1', 'cursor moved');
  },
};
