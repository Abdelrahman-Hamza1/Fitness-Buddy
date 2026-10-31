import 'package:fb_api_client/fb_api_client.dart';
import 'package:fb_sync/src/batching.dart';
import 'package:fb_sync/src/model.dart';
import 'package:fb_sync/src/store.dart';
import 'package:fb_sync/src/transport.dart';

/// Where a run is, for the sync indicator (A34 D13).
enum SyncPhase {
  /// Applying pulled pages.
  pulling,

  /// Sending pending changes.
  pushing,
}

/// A run's progress: [pulledRows] written from the server so far and
/// whether this is the first sync of this database ([firstSync]: it started
/// at cursor `0`, AC-011).
final class SyncProgress {
  /// See the fields.
  const new({
    required this.phase,
    required this.pulledRows,
    required this.firstSync,
  });

  /// The current phase.
  final SyncPhase phase;

  /// Rows written from pulled pages in this run.
  final int pulledRows;

  /// The run started from cursor `0` (a new device or a reset).
  final bool firstSync;
}

/// What a successful run did. Counts and fixed codes only.
final class SyncRunReport {
  /// See the fields.
  const new({
    required this.pushed,
    required this.pulled,
    required this.entities,
    required this.parked,
    required this.deferred,
    required this.firstSync,
  });

  /// Changes the server acknowledged.
  final int pushed;

  /// Rows written from the server.
  final int pulled;

  /// The entity wire names of the rows written from the server.
  final Set<String> entities;

  /// Versions parked in this run (A34 D5).
  final List<ParkedVersion> parked;

  /// Documents deferred in this run (A34 D7).
  final List<DeferredDocument> deferred;

  /// The run started from cursor `0`.
  final bool firstSync;
}

/// The dataset changed under a run (TD-066): restart with a reset.
final class _DatasetChanged implements Exception {
  const new();
}

/// The production sync engine (A34, TD-006, `05` §5): one [run] pulls when
/// no dataset is bound or a reset is pending, pushes every pending change
/// (push first, A34 D2), then pulls until an empty page.
///
/// Crash safety comes from the store: every store call commits atomically,
/// a push is idempotent per immutable version, and the cursor moves only
/// with the rows it covers. A run interrupted anywhere (network, process
/// death) is continued by the next run without losing or duplicating a
/// version. Runs must not overlap on one store (the app's scheduler runs
/// one at a time).
final class SyncEngine {
  /// An engine over [store] and [transport]. [pullLimit] is the pull page
  /// size (A34 D6). [onProgress], [onApplied], [onParked] and [onDeferred]
  /// hear about the run as it goes (the app updates its status, notifies
  /// features and reports fixed kinds).
  new({
    required this.store,
    required this.transport,
    this.pullLimit = 100,
    this.onProgress,
    this.onApplied,
    this.onParked,
    this.onDeferred,
  });

  /// The durable side.
  final SyncStore store;

  /// The network side.
  final SyncTransport transport;

  /// Rows per pull page.
  final int pullLimit;

  /// Progress, for the indicator.
  final void Function(SyncProgress progress)? onProgress;

  /// After each committed page (or deferred retry) that wrote rows.
  final void Function(Set<String> entities)? onApplied;

  /// After versions were parked.
  final void Function(List<ParkedVersion> parked)? onParked;

  /// After documents were deferred.
  final void Function(List<DeferredDocument> deferred)? onDeferred;

  /// Dataset resets one run may start before giving up until the next.
  static const int _maxResetsPerRun = 1;

  /// One sync run. Throws [SyncFailure] (offline, auth, clock, …) after
  /// committing whatever it finished; the next run continues from there.
  Future<SyncRunReport> run() async {
    final run = _Run(firstSync: (await store.checkpoint()).cursor == '0');
    final retried = await store.retryDeferred();
    run.applied(retried, this);
    var resets = 0;
    while (true) {
      try {
        final checkpoint = await store.checkpoint();
        if (checkpoint.resetActive) {
          // TD-066: merge the new dataset's winners and fences first.
          await _pullAll(run);
        } else if (checkpoint.datasetId == null) {
          await _discover();
        }
        await _pushAll(run);
        await _pullAll(run);
        break;
      } on _DatasetChanged {
        if (++resets > _maxResetsPerRun) {
          throw const SyncFailure(SyncFailureKind.datasetUnstable);
        }
        await store.beginReset();
        run.firstSync = true;
      }
    }
    return SyncRunReport(
      pushed: run.pushed,
      pulled: run.pulled,
      entities: run.entities,
      parked: run.parked,
      deferred: run.deferred,
      firstSync: run.firstSync,
    );
  }

  /// Learns the dataset with a one-row unbound pull at cursor `0` and
  /// binds it without applying the row, so even the first run pushes
  /// before it pulls (A34 D2: a pending local loser reaches history).
  Future<void> _discover() async {
    final page = await transport.pull(cursor: '0', limit: 1, datasetId: null);
    if (page.reason != null) throw const SyncFailure(SyncFailureKind.protocol);
    await store.bindDataset(page.datasetId);
  }

  Future<void> _pullAll(_Run run) async {
    while (true) {
      final checkpoint = await store.checkpoint();
      final bound = checkpoint.datasetId;
      final cursor = checkpoint.cursor;
      final page = await transport.pull(
        cursor: cursor,
        limit: pullLimit,
        datasetId: bound,
      );
      if (page.reason case 'datasetMismatch' || 'cursorInvalid') {
        throw const _DatasetChanged();
      }
      if (page.reason != null) {
        throw const SyncFailure(SyncFailureKind.protocol);
      }
      if (bound != null && page.datasetId != bound) {
        throw const _DatasetChanged();
      }
      final applied = await store.applyPage(page, requestedCursor: cursor);
      run.applied(applied, this);
      onProgress?.call(
        SyncProgress(
          phase: SyncPhase.pulling,
          pulledRows: run.pulled,
          firstSync: run.firstSync,
        ),
      );
      if (page.changes.isEmpty) return;
    }
  }

  Future<void> _pushAll(_Run run) async {
    // Versions sent in this run: a listing that holds only these is done
    // (their settlement already ran; anything left is a newer edit).
    final attempted = <SyncVersion>{};
    while (true) {
      final checkpoint = await store.checkpoint();
      final dataset = checkpoint.datasetId;
      if (dataset == null) return;
      final read = await store.pending(limit: PushLimits.maxChanges);
      run.parkedNow(read.parkedNow, this);
      final fresh = [
        for (final change in read.changes)
          if (attempted.add(SyncVersion.ofChange(change))) change,
      ];
      if (fresh.isEmpty) {
        // Parking refused rows made progress: rows behind them may still
        // be pending (A34 fix 4). Each read parks or pushes at least one
        // row, so this ends.
        if (read.parkedNow.isNotEmpty) continue;
        return;
      }
      onProgress?.call(
        SyncProgress(
          phase: SyncPhase.pushing,
          pulledRows: run.pulled,
          firstSync: run.firstSync,
        ),
      );
      for (final batch in pushBatches(fresh)) {
        await _push(batch, dataset, run);
      }
    }
  }

  Future<void> _push(List<SyncChange> batch, String dataset, _Run run) async {
    final SyncPushResponse response;
    try {
      response = await transport.push(batch, datasetId: dataset);
    } on SyncFailure catch (failure) {
      if (failure.kind != SyncFailureKind.payloadTooLarge) rethrow;
      // B18 handoff: split on 413; a single row that still gets 413 is
      // parked so it never blocks the queue (#111).
      if (batch.length == 1) {
        final parked = [
          ParkedVersion(SyncVersion.ofChange(batch.single), 'tooLarge'),
        ];
        await store.settle(parked: parked);
        run.parkedNow(parked, this);
        return;
      }
      final half = batch.length ~/ 2;
      await _push(batch.sublist(0, half), dataset, run);
      await _push(batch.sublist(half), dataset, run);
      return;
    }
    if (response.datasetId != dataset) throw const _DatasetChanged();
    final results = response.results;
    if (results.length != batch.length) {
      throw const SyncFailure(SyncFailureKind.protocol);
    }
    final acknowledged = <SyncVersion>[];
    final parked = <ParkedVersion>[];
    var clockDrift = false;
    var datasetChanged = false;
    for (var i = 0; i < batch.length; i++) {
      final sent = SyncVersion.ofChange(batch[i]);
      final result = results[i];
      if (result.entity != sent.entity ||
          result.id != sent.id ||
          result.hlc != sent.hlc) {
        throw const SyncFailure(SyncFailureKind.protocol);
      }
      switch ((result.status, result.reason)) {
        case ('accepted' || 'stale', _):
        // The server already holds this immutable version (A34 D4).
        case ('invalid', 'versionConflict'):
          acknowledged.add(sent);
        case ('invalid', 'clockDrift'):
          clockDrift = true;
        case ('invalid', 'datasetMismatch'):
          datasetChanged = true;
        case ('invalid', final reason):
          parked.add(ParkedVersion(sent, _reasonCode(reason)));
        default:
          throw const SyncFailure(SyncFailureKind.protocol);
      }
    }
    await store.settle(acknowledged: acknowledged, parked: parked);
    run
      ..pushed += acknowledged.length
      ..parkedNow(parked, this);
    if (datasetChanged) throw const _DatasetChanged();
    if (clockDrift) throw const SyncFailure(SyncFailureKind.clockAhead);
  }

  /// The server's reason as a fixed code: its closed vocabulary, or
  /// `unknown` (never free text).
  static String _reasonCode(String? reason) => switch (reason) {
    'unsupported' || 'invalidPayload' => reason!,
    _ => 'unknown',
  };
}

final class _Run {
  new({required this.firstSync});

  bool firstSync;
  int pushed = 0;
  int pulled = 0;
  final Set<String> entities = {};
  final List<ParkedVersion> parked = [];
  final List<DeferredDocument> deferred = [];

  void applied(PageApplied page, SyncEngine engine) {
    pulled += page.applied;
    entities.addAll(page.entities);
    if (page.entities.isNotEmpty) engine.onApplied?.call(page.entities);
    if (page.deferred.isNotEmpty) {
      deferred.addAll(page.deferred);
      engine.onDeferred?.call(page.deferred);
    }
  }

  void parkedNow(List<ParkedVersion> versions, SyncEngine engine) {
    if (versions.isEmpty) return;
    parked.addAll(versions);
    engine.onParked?.call(versions);
  }
}
