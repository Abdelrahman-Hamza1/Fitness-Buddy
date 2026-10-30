import 'dart:async';

import 'package:drift/drift.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/db/app_database.dart';
import 'package:fb_mobile/core/db/db_providers.dart';
import 'package:fb_mobile/features/body/data/measurement_mappers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'measurement_repository.g.dart';

/// The live measurements and custom types as read (A15b D25), with how
/// many rows were skipped because the domain can't read them (counts only,
/// never values).
final class MeasurementData {
  /// [types] and [measurements]; [skipped] unreadable rows.
  new({
    required Iterable<MeasurementType> types,
    required Iterable<Measurement> measurements,
    this.skipped = 0,
  }) : types = List.unmodifiable(types),
       measurements = List.unmodifiable(measurements);

  /// The live custom types, by name (ignoring case), then ID. Two live types
  /// with the same name (possible after sync) are both here. Unmodifiable.
  final List<MeasurementType> types;

  /// The live measurements of built-in kinds and of live types, ordered by
  /// local date, measured time and ID. Unmodifiable.
  final List<Measurement> measurements;

  /// Rows left out because they can't be read (corrupt, or synced rows
  /// that break the wire rules).
  final int skipped;

  @override
  String toString() =>
      'MeasurementData(${types.length} types, ${measurements.length} '
      'measurements, $skipped skipped)';
}

/// Read-only measurement queries (A15b D25). Writes go through the applier
/// (`MeasurementOpHandler`). Reactive through drift's table watches.
final class MeasurementRepository {
  /// Over one profile's database.
  const new(this._db);

  final AppDatabase _db;

  /// The live types and measurements, re-read on every write to either
  /// table, one read at a time (the weigh-in repository's pattern: no
  /// timer, a write during a read drops that read for a fresh one).
  ///
  /// Measurements whose custom type is missing or deleted (a sync race) are
  /// hidden until the type arrives; unreadable rows are skipped and
  /// counted.
  Stream<MeasurementData> watch() => Stream.multi((listener) {
    var cancelled = false;
    var running = false;
    var dirty = false;
    Future<void> read() async {
      running = true;
      try {
        do {
          dirty = false;
          final data = await this.read();
          if (!cancelled && !dirty) listener.add(data);
        } while (dirty && !cancelled);
      } on Object catch (error, stack) {
        if (!cancelled) listener.addError(error, stack);
      } finally {
        running = false;
      }
    }

    void schedule() {
      dirty = true;
      if (!running) unawaited(read());
    }

    final updates = _db
        .tableUpdates(
          TableUpdateQuery.onAllTables({
            _db.measurements,
            _db.measurementTypes,
          }),
        )
        .listen((_) => schedule());
    schedule();
    listener.onCancel = () {
      cancelled = true;
      return updates.cancel();
    };
  });

  /// The live types and measurements once (see [watch]).
  Future<MeasurementData> read() => _db.readSnapshot(() async {
    var skipped = 0;
    final types = <MeasurementType>[];
    for (final row in await (_db.select(
      _db.measurementTypes,
    )..where((t) => t.deletedAt.isNull())).get()) {
      try {
        types.add(measurementTypeOf(row));
      } on MeasurementMappingError {
        skipped++;
      }
    }
    types.sort((a, b) {
      final byName = CustomTypeName.compareKey(a.name)
          .compareTo(CustomTypeName.compareKey(b.name));
      return byName != 0 ? byName : a.id.compareTo(b.id);
    });
    final liveTypes = {for (final t in types) t.id};
    final measurements = <Measurement>[];
    final rows =
        await (_db.select(_db.measurements)
              ..where((t) => t.deletedAt.isNull())
              ..orderBy([
                (t) => OrderingTerm(expression: t.localDate),
                (t) => OrderingTerm(expression: t.measuredAtUtc),
                (t) => OrderingTerm(expression: t.id),
              ]))
            .get();
    for (final row in rows) {
      final Measurement measurement;
      try {
        measurement = measurementOf(row);
      } on MeasurementMappingError {
        skipped++;
        continue;
      }
      final typeId = measurement.type.customTypeId;
      if (typeId != null && !liveTypes.contains(typeId)) continue;
      measurements.add(measurement);
    }
    return MeasurementData(
      types: types,
      measurements: measurements,
      skipped: skipped,
    );
  });
}

/// The repository over the profile database (read-only composition stays
/// in data, the application-db rule).
@Riverpod(keepAlive: true)
MeasurementRepository measurementRepository(Ref ref) =>
    MeasurementRepository(ref.watch(appDatabaseProvider));
