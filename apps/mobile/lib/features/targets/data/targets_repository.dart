import 'dart:async';

import 'package:drift/drift.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/db/app_database.dart';
import 'package:fb_mobile/core/db/db_providers.dart';
import 'package:fb_mobile/features/targets/data/target_mappers.dart';
import 'package:flutter/foundation.dart' show immutable;
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'targets_repository.g.dart';

/// A stored value with the row version a revise op must expect.
@immutable
final class Versioned<T> {
  /// [value] at row [version].
  const new(this.value, this.version);

  /// The decoded record.
  final T value;

  /// The row version (optimistic concurrency).
  final int version;

  @override
  bool operator ==(Object other) =>
      other is Versioned<T> && other.value == value && other.version == version;

  @override
  int get hashCode => Object.hash(value, version);

  // The value is sensitive body data: never in the text.
  @override
  String toString() => 'Versioned(v$version)';
}

/// One consistent read of the targets tables: live rows only, each decoded
/// tolerantly. Rows this version can't read are skipped and counted in
/// [skippedRows] (never thrown, never logged with values).
@immutable
final class TargetsData {
  /// The decoded rows.
  new({
    this.profile,
    Iterable<Versioned<GoalPhaseRecord>> phases = const [],
    Iterable<Versioned<TargetSettingsRecord>> settings = const [],
    this.skippedRows = 0,
  }) : phases = List.unmodifiable(phases),
       settings = List.unmodifiable(settings);

  /// The live profile, or null (absent, tombstoned or unreadable).
  final Versioned<ProfileRecord>? profile;

  /// Live goal phases, by ID. Unmodifiable.
  final List<Versioned<GoalPhaseRecord>> phases;

  /// Live target settings versions, by ID. Unmodifiable.
  final List<Versioned<TargetSettingsRecord>> settings;

  /// Live rows that couldn't be decoded.
  final int skippedRows;

  @override
  bool operator ==(Object other) =>
      other is TargetsData &&
      other.profile == profile &&
      other.skippedRows == skippedRows &&
      _sameList(other.phases, phases) &&
      _sameList(other.settings, settings);

  @override
  int get hashCode => Object.hash(
    profile,
    skippedRows,
    Object.hashAll(phases),
    Object.hashAll(settings),
  );

  @override
  String toString() =>
      'TargetsData(profile: ${profile != null}, ${phases.length} phases, '
      '${settings.length} versions, $skippedRows skipped)';
}

/// Read-only targets queries (A13 §3.2). Writes go through the
/// `ChangeSetApplier` with `TargetsOp`s.
final class TargetsRepository {
  /// Reads the profile's [_db].
  const new(this._db);

  final AppDatabase _db;

  /// The live rows, in one snapshot.
  Future<TargetsData> read() => _db.readSnapshot(() async {
    var skipped = 0;
    List<Versioned<R>> decode<D, R>(
      List<D> rows,
      R? Function(D) decode,
      int Function(D) version,
    ) {
      final decoded = <Versioned<R>>[];
      for (final row in rows) {
        final value = decode(row);
        if (value == null) {
          skipped++;
        } else {
          decoded.add(Versioned(value, version(row)));
        }
      }
      return decoded;
    }

    final profileRow =
        await (_db.select(_db.profiles)
              ..where((t) => t.id.equals(profileRowId) & t.deletedAt.isNull()))
            .getSingleOrNull();
    final profiles = decode([?profileRow], profileOf, (row) => row.version);
    final phases = decode(
      await (_db.select(_db.goalPhases)
            ..where((t) => t.deletedAt.isNull())
            ..orderBy([(t) => OrderingTerm(expression: t.id)]))
          .get(),
      goalPhaseOf,
      (row) => row.version,
    );
    final settings = decode(
      await (_db.select(_db.targetSettingsRows)
            ..where((t) => t.deletedAt.isNull())
            ..orderBy([(t) => OrderingTerm(expression: t.id)]))
          .get(),
      targetSettingsOf,
      (row) => row.version,
    );
    return TargetsData(
      profile: profiles.firstOrNull,
      phases: phases,
      settings: settings,
      skippedRows: skipped,
    );
  });

  /// [read] now and after every change to the targets tables.
  Stream<TargetsData> watchTargets() =>
      _watch({_db.profiles, _db.goalPhases, _db.targetSettingsRows}, read);

  /// The live profile.
  Stream<Versioned<ProfileRecord>?> watchProfile() =>
      watchTargets().map((data) => data.profile).distinct();

  /// The live goal phases.
  Stream<List<Versioned<GoalPhaseRecord>>> watchGoalPhases() =>
      watchTargets().map((data) => data.phases).distinct(_sameList);

  /// The live target settings versions.
  Stream<List<Versioned<TargetSettingsRecord>>> watchTargetSettings() =>
      watchTargets().map((data) => data.settings).distinct(_sameList);

  // One in-flight read and one dirty bit bound burst work (A08 D12(6)).
  Stream<T> _watch<T>(
    Set<TableInfo<Table, Object?>> tables,
    Future<T> Function() load,
  ) => Stream.multi((listener) {
    var cancelled = false;
    var running = false;
    var dirty = false;
    Timer? timer;
    late void Function() schedule;
    Future<void> run() async {
      if (cancelled) return;
      dirty = false;
      running = true;
      try {
        final value = await load();
        if (!cancelled && !dirty) listener.add(value);
      } on Object catch (error, stack) {
        if (!cancelled && !dirty) listener.addError(error, stack);
      } finally {
        running = false;
        if (dirty && !cancelled) schedule();
      }
    }

    schedule = () {
      dirty = true;
      if (running) return;
      timer?.cancel();
      timer = Timer(Duration.zero, run);
    };
    final updates = _db
        .tableUpdates(TableUpdateQuery.onAllTables(tables))
        .listen((_) => schedule());
    schedule();
    listener.onCancel = () {
      cancelled = true;
      timer?.cancel();
      return updates.cancel();
    };
  });
}

bool _sameList<T>(List<T> a, List<T> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

/// Read-only repository composition stays in data (application-db rule).
/// Kept alive like the diary's: stateless over the profile's database, and
/// the session-owned `TargetsActions` reads through it.
@Riverpod(keepAlive: true)
TargetsRepository targetsRepository(Ref ref) =>
    TargetsRepository(ref.watch(appDatabaseProvider));
