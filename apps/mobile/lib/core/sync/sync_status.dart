import 'package:flutter/foundation.dart' show immutable;

/// Why sync isn't running normally (A34 D13). Fixed kinds for the UI.
enum SyncProblem {
  /// Nothing wrong.
  none,

  /// No connection (or the server is unreachable): retrying.
  offline,

  /// The session ended: sign in again (A33's banner).
  needsSignIn,

  /// The phone clock is ahead of the server's: changes wait.
  clockAhead,

  /// The phone clock is far behind: pulled changes wait.
  clockBehind,

  /// The server needs a newer app (426): changes wait on the phone until
  /// the app is updated; the update gate shows too (#242).
  updateRequired,

  /// Something else failed: retrying.
  error,
}

/// What the sync controller is doing (A34 D13): a run in flight, a first
/// sync restoring rows, and the last run's problem.
@immutable
final class SyncActivity {
  /// See the fields.
  const new({
    this.running = false,
    this.restoring = false,
    this.restoredRows = 0,
    this.problem = SyncProblem.none,
    this.enabled = false,
  });

  /// A run is in flight.
  final bool running;

  /// The run is a first sync (cursor 0: a new phone or a reset).
  final bool restoring;

  /// Rows restored so far in this first sync.
  final int restoredRows;

  /// The last run's problem.
  final SyncProblem problem;

  /// Sync applies to this profile (registered and writable).
  final bool enabled;

  /// A copy with changes.
  SyncActivity copyWith({
    bool? running,
    bool? restoring,
    int? restoredRows,
    SyncProblem? problem,
    bool? enabled,
  }) => SyncActivity(
    running: running ?? this.running,
    restoring: restoring ?? this.restoring,
    restoredRows: restoredRows ?? this.restoredRows,
    problem: problem ?? this.problem,
    enabled: enabled ?? this.enabled,
  );

  @override
  bool operator ==(Object other) =>
      other is SyncActivity &&
      other.running == running &&
      other.restoring == restoring &&
      other.restoredRows == restoredRows &&
      other.problem == problem &&
      other.enabled == enabled;

  @override
  int get hashCode =>
      Object.hash(running, restoring, restoredRows, problem, enabled);

  @override
  String toString() =>
      'SyncActivity(running: $running, ${problem.name}, enabled: $enabled)';
}

/// What the sync indicator shows (A34 D13), read from the local tables.
@immutable
final class LocalSyncCounts {
  /// See the fields.
  const new({
    required this.pendingRows,
    required this.parked,
    required this.oldestPendingMs,
    required this.lastSuccessMs,
  });

  /// Rows with a version the server doesn't have yet.
  final int pendingRows;

  /// Parked versions (A34 D5).
  final int parked;

  /// The wall time of the oldest pending version (its HLC), or `null`.
  final int? oldestPendingMs;

  /// The last successful run, UTC ms, or `null`.
  final int? lastSuccessMs;
}
