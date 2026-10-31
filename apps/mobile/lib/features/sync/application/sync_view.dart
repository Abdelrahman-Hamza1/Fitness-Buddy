import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/account/profile_generation.dart';
import 'package:fb_mobile/core/changes/apply_result.dart';
import 'package:fb_mobile/core/changes/change_providers.dart';
import 'package:fb_mobile/core/sync/earlier_versions.dart';
import 'package:fb_mobile/core/sync/restore_version.dart';
import 'package:fb_mobile/core/sync/sync_guard.dart';
import 'package:fb_mobile/core/sync/sync_providers.dart';
import 'package:fb_mobile/core/sync/sync_status.dart';
import 'package:fb_mobile/core/time/clock_provider.dart';
import 'package:fb_mobile/core/undo/undo_stack.dart';
import 'package:fb_sync/fb_sync.dart' show SyncFailure, SyncFailureKind;
import 'package:riverpod_annotation/riverpod_annotation.dart';

export 'package:fb_mobile/core/sync/earlier_versions.dart' show EarlierVersion;
export 'package:fb_mobile/core/sync/sync_status.dart' show SyncProblem;

part 'sync_view.g.dart';

/// What the sync UI shows (A34 D13, AC-013, UX-053).
final class SyncView {
  /// See the fields.
  const new({
    required this.enabled,
    required this.running,
    required this.restoring,
    required this.restoredRows,
    required this.problem,
    required this.pending,
    required this.parked,
    required this.lastSuccessMs,
    required this.oldestPendingMs,
    required this.nowMs,
  });

  /// Sync applies (a registered, writable profile).
  final bool enabled;

  /// A run is in flight.
  final bool running;

  /// A first sync is restoring data (AC-011).
  final bool restoring;

  /// Rows restored so far.
  final int restoredRows;

  /// The last run's problem.
  final SyncProblem problem;

  /// Rows waiting to sync.
  final int pending;

  /// Changes that couldn't sync (A34 D5).
  final int parked;

  /// The last successful run (UTC ms), if any.
  final int? lastSuccessMs;

  /// The oldest waiting change (UTC ms), if any.
  final int? oldestPendingMs;

  /// Now (UTC ms), when the view was built.
  final int nowMs;

  /// How long a change may wait before Today mentions it.
  static const Duration quietWait = Duration(minutes: 2);

  /// Everything local is on the server.
  bool get synced => pending == 0 && parked == 0;

  /// Whether Today shows the small sync line: only when something hasn't
  /// synced for a while, a problem, parked changes or a first restore. The
  /// session-expired banner (A33) covers [SyncProblem.needsSignIn].
  bool get showOnToday {
    if (!enabled) return false;
    if (restoring) return true;
    if (parked > 0) return true;
    if (pending == 0) return false;
    if (problem != SyncProblem.none && problem != SyncProblem.needsSignIn) {
      return true;
    }
    final oldest = oldestPendingMs;
    return oldest != null && nowMs - oldest > quietWait.inMilliseconds;
  }
}

/// The current [SyncView].
@riverpod
SyncView syncView(Ref ref) {
  final activity = ref.watch(syncControllerProvider);
  // A guest or signed-out profile has nothing to sync: no counts query.
  final counts = activity.enabled ? ref.watch(syncCountsProvider).value : null;
  return SyncView(
    enabled: activity.enabled,
    running: activity.running,
    restoring: activity.restoring,
    restoredRows: activity.restoredRows,
    problem: activity.problem,
    pending: counts?.pendingRows ?? 0,
    parked: counts?.parked ?? 0,
    lastSuccessMs: counts?.lastSuccessMs,
    oldestPendingMs: counts?.oldestPendingMs,
    nowMs: ref.watch(clockProvider).nowUtc().millisecondsSinceEpoch,
  );
}

/// Why earlier versions couldn't be read.
enum EarlierVersionsFailure implements Exception {
  /// No connection.
  offline,

  /// Not signed in (or the session ended).
  signedOut,

  /// Anything else.
  failed,
}

/// The earlier versions of one row (online, G7).
@riverpod
Future<List<EarlierVersion>> earlierVersions(
  Ref ref,
  String entity,
  String id,
) async {
  final generation = ref.read(profileGenerationProvider);
  final transport = GuardedSyncTransport(
    ref.read(syncTransportProvider),
    () => ref.mounted && ref.read(profileGenerationProvider) == generation,
  );
  try {
    return await readEarlierVersions(
      transport,
      ref.read(syncStoreProvider),
      entity,
      id,
    );
  } on SyncFailure catch (failure) {
    throw switch (failure.kind) {
      SyncFailureKind.offline ||
      SyncFailureKind.server => EarlierVersionsFailure.offline,
      SyncFailureKind.unauthorized ||
      SyncFailureKind.forbidden => EarlierVersionsFailure.signedOut,
      _ => EarlierVersionsFailure.failed,
    };
  }
}

/// A restore's result: its undo entry, or why it was refused.
sealed class RestoreOutcome {
  const new();
}

/// Restored; [undoEntryId] undoes it.
final class RestoreDone extends RestoreOutcome {
  /// A restore with undo.
  const new(this.undoEntryId);

  /// The undo entry.
  final String undoEntryId;
}

/// The row changed since, or the version can't be restored.
final class RestoreRefused extends RestoreOutcome {
  /// A refusal.
  const new();
}

/// Sync commands for the UI.
@riverpod
class SyncActions extends _$SyncActions {
  @override
  void build() {}

  /// "Sync now" / pull-to-refresh.
  Future<void> syncNow() =>
      ref.read(syncControllerProvider.notifier).syncNow().then((_) {});

  /// "Try again" for changes that couldn't sync.
  Future<void> retryParked() =>
      ref.read(syncControllerProvider.notifier).retryParked();

  /// Restores [version] of row [id] of [entity] (a direct action, G7):
  /// one change set with undo.
  Future<RestoreOutcome> restore(
    String entity,
    String id,
    EarlierVersion version,
  ) async {
    final result = await ref
        .read(changeSetApplierProvider)
        .apply(
          ChangeSet([
            RestoreVersionOp(
              entity: entity,
              id: id,
              payload: version.payload,
              deleted: version.deleted,
              expectedVersion: version.localVersion,
            ),
          ], origin: Origin.direct),
        );
    if (result case final Applied applied) {
      final entry = ref
          .read(undoStackProvider)
          .record(applied, UndoLabel('syncRestore'));
      return RestoreDone(entry.id);
    }
    return const RestoreRefused();
  }
}
