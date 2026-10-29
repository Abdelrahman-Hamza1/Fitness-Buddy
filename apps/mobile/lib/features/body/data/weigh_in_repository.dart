import 'dart:async';

import 'package:drift/drift.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/db/app_database.dart';
import 'package:fb_mobile/core/db/db_providers.dart';
import 'package:fb_mobile/features/body/data/weigh_in_mappers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'weigh_in_repository.g.dart';

/// Read-only weigh-in queries (A14 §3.2). Writes go through the applier
/// (`WeighInOpHandler`). Reactive through drift's table watches.
final class WeighInRepository {
  /// Over one profile's database.
  const new(this._db);

  final AppDatabase _db;

  /// The live weigh-ins ordered by local date, measured time and ID. Rows the
  /// domain can't read (corrupt or from an incompatible client) are left
  /// out rather than failing the whole list.
  ///
  /// Re-read on every write to `weigh_ins` (drift's table updates), one read
  /// at a time; a write during a read drops that read's result for a fresh
  /// one. Like the diary's streams it sets no timer, so a screen that goes
  /// away leaves nothing pending.
  Stream<List<WeighIn>> watchLive() => Stream.multi((listener) {
    var cancelled = false;
    var running = false;
    var dirty = false;
    Future<void> read() async {
      running = true;
      try {
        do {
          dirty = false;
          final rows = await _liveQuery().get();
          if (!cancelled && !dirty) {
            listener.add([for (final row in rows) ?_read(row)]);
          }
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
        .tableUpdates(TableUpdateQuery.onAllTables({_db.weighIns}))
        .listen((_) => schedule());
    schedule();
    listener.onCancel = () {
      cancelled = true;
      return updates.cancel();
    };
  });

  SimpleSelectStatement<$WeighInsTable, WeighInRow> _liveQuery() =>
      _db.select(_db.weighIns)
        ..where((t) => t.deletedAt.isNull())
        ..orderBy([
          (t) => OrderingTerm(expression: t.localDate),
          (t) => OrderingTerm(expression: t.measuredAtUtc),
          (t) => OrderingTerm(expression: t.id),
        ]);

  WeighIn? _read(WeighInRow row) {
    try {
      return weighInOf(row);
    } on WeighInMappingError {
      return null;
    }
  }
}

/// The repository over the profile database (read-only composition stays in
/// data, the application-db rule).
@riverpod
WeighInRepository weighInRepository(Ref ref) =>
    WeighInRepository(ref.watch(appDatabaseProvider));
