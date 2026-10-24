import 'dart:async';

import 'package:drift/drift.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/db/app_database.dart';
import 'package:fb_mobile/core/db/db_providers.dart';
import 'package:fb_mobile/features/foods/data/personal_food_mappers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'personal_food_repository.g.dart';

/// Read-only, latest-wins personal-food queries (A09 §3.2).
final class PersonalFoodRepository {
  /// One profile's database.
  const new(this._db);
  final AppDatabase _db;

  /// Live definitions by name, stable on ID ties.
  Stream<List<PersonalFood>> watchAll() =>
      _watch({_db.personalFoods}, () async {
        final rows =
            await (_db.select(_db.personalFoods)
                  ..where((t) => t.deletedAt.isNull())
                  ..orderBy([
                    (t) => OrderingTerm(expression: t.nameEn),
                    (t) => OrderingTerm(expression: t.id),
                  ]))
                .get();
        final foods = <PersonalFood>[];
        for (final row in rows) {
          final food = _read(row);
          if (food != null) foods.add(food);
        }
        return foods;
      });

  PersonalFood? _read(PersonalFoodRow row) {
    try {
      return personalFoodOf(row);
    } on PersonalFoodMappingError {
      return null;
    }
  }

  /// Live row or null after deletion.
  Future<PersonalFood?> byId(String id) async {
    final row = await (_db.select(
      _db.personalFoods,
    )..where((t) => t.id.equals(id) & t.deletedAt.isNull())).getSingleOrNull();
    return row == null ? null : _read(row);
  }

  /// Definition changes, with immediate initial data.
  Stream<PersonalFood?> watchFood(String id) =>
      _watch({_db.personalFoods}, () => byId(id));
  // One in-flight read and one dirty bit bound burst work (A08 D12(6)).
  Stream<T> _watch<T>(
    Set<TableInfo<Table, Object?>> tables,
    Future<T> Function() load, {
    Duration delay = Duration.zero,
  }) => Stream.multi((listener) {
    var cancelled = false;
    var running = false;
    var dirty = false;
    Timer? timer;
    late void Function(Duration) schedule;
    Future<void> read() async {
      if (cancelled) return;
      dirty = false;
      running = true;
      try {
        final value = await load();
        if (!cancelled && !dirty) {
          listener.add(value);
        }
      } on Object catch (error, stack) {
        if (!cancelled && !dirty) listener.addError(error, stack);
      } finally {
        running = false;
        if (dirty && !cancelled) schedule(delay);
      }
    }

    schedule = (delay) {
      dirty = true;
      if (running) return;
      timer?.cancel();
      timer = Timer(delay, read);
    };
    final updates = _db
        .tableUpdates(TableUpdateQuery.onAllTables(tables))
        .listen((_) => schedule(delay));
    schedule(Duration.zero);
    listener.onCancel = () {
      cancelled = true;
      timer?.cancel();
      return updates.cancel();
    };
  });
}

/// Read-only repository composition stays in data (application-db rule).
@riverpod
PersonalFoodRepository personalFoodRepository(Ref ref) =>
    PersonalFoodRepository(ref.watch(appDatabaseProvider));
