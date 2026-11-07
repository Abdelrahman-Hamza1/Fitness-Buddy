import 'package:drift/drift.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/db/app_database.dart';
import 'package:fb_mobile/core/db/db_providers.dart';
import 'package:fb_mobile/features/diary/diary.dart' show DiaryReads;
import 'package:fb_mobile/features/foods/foods.dart'
    show PersonalFoodMappingError, personalFoodOf;
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'buddy_phone_reads.g.dart';

/// A set of a session exercise.
typedef PhoneSet = ({
  int? reps,
  double? kg,
  int? durationSeconds,
  double? distanceMeters,
});

/// A session exercise: its exercise ID, a name and its sets.
typedef PhoneExercise = ({String exerciseId, String name, List<PhoneSet> sets});

/// A workout session.
typedef PhoneSession = ({
  String id,
  LocalDate date,
  String? name,
  List<PhoneExercise> exercises,
});

/// The local reads behind Buddy's phone tools (A66 D11): read-only, already
/// bounded by the caller's scope (dates); the tools cut rows further. User
/// content: never logged.
final class BuddyPhoneReads {
  /// Reads [_db].
  const new(this._db);

  final AppDatabase _db;

  /// Every readable live personal food.
  Future<List<PersonalFood>> personalFoods() async {
    final rows = await (_db.select(
      _db.personalFoods,
    )..where((t) => t.deletedAt.isNull())).get();
    return [for (final row in rows) ?_food(row)];
  }

  static PersonalFood? _food(PersonalFoodRow row) {
    try {
      return personalFoodOf(row);
    } on PersonalFoodMappingError {
      return null;
    }
  }

  /// The diary entries from [from] to [to] (inclusive) and the slots.
  Future<(List<DiaryEntry>, List<MealSlot>)> diary(
    LocalDate from,
    LocalDate to,
  ) => _db.readSnapshot(() async {
    final reads = DiaryReads(_db);
    return (await reads.entriesBetween(from, to), await reads.slots());
  });

  /// The day weights from [from] to [to]: each day's preferred (else
  /// latest) weigh-in, oldest first.
  Future<List<(LocalDate, double)>> weights(
    LocalDate from,
    LocalDate to,
  ) async {
    final rows =
        await (_db.select(_db.weighIns)
              ..where(
                (t) =>
                    t.deletedAt.isNull() &
                    t.localDate.isBetweenValues(from.toString(), to.toString()),
              )
              ..orderBy([
                (t) => OrderingTerm(expression: t.localDate),
                (t) => OrderingTerm(expression: t.measuredAtUtc),
              ]))
            .get();
    final byDay = <String, WeighInRow>{};
    for (final row in rows) {
      final kept = byDay[row.localDate];
      if (kept == null || !kept.preferredForDay) byDay[row.localDate] = row;
    }
    return [
      for (final MapEntry(:key, :value) in byDay.entries)
        if (LocalDate.tryParse(key) case final d?) (d, value.kg),
    ];
  }

  /// The workout sessions from [from] to [to], newest first, at most
  /// [limit], with their exercises and sets.
  Future<List<PhoneSession>> sessions(
    LocalDate from,
    LocalDate to, {
    required int limit,
    String? exerciseId,
  }) => _db.readSnapshot(() async {
    final sessions =
        await (_db.select(_db.workoutSessions)
              ..where(
                (t) =>
                    t.deletedAt.isNull() &
                    t.localDate.isBetweenValues(from.toString(), to.toString()),
              )
              ..orderBy([
                (t) => OrderingTerm.desc(t.localDate),
                (t) => OrderingTerm.desc(t.id),
              ]))
            .get();
    final names = {
      for (final c in await (_db.select(
        _db.customExercises,
      )..where((t) => t.deletedAt.isNull())).get())
        c.id: c.name,
    };
    final out = <PhoneSession>[];
    for (final s in sessions) {
      if (out.length == limit) break;
      final date = LocalDate.tryParse(s.localDate);
      if (date == null) continue;
      final exercises =
          await (_db.select(_db.sessionExercises)
                ..where((t) => t.deletedAt.isNull() & t.sessionId.equals(s.id))
                ..orderBy([(t) => OrderingTerm(expression: t.position)]))
              .get();
      final rows = <PhoneExercise>[];
      for (final e in exercises) {
        if (exerciseId != null && e.exerciseId != exerciseId) continue;
        final sets =
            await (_db.select(_db.workoutSets)
                  ..where(
                    (t) =>
                        t.deletedAt.isNull() & t.sessionExerciseId.equals(e.id),
                  )
                  ..orderBy([(t) => OrderingTerm(expression: t.position)]))
                .get();
        rows.add((
          exerciseId: e.exerciseId,
          // Library exercises go by their ID; custom ones by their name.
          name: names[e.exerciseId] ?? e.exerciseId,
          sets: [
            for (final set in sets)
              (
                reps: set.reps,
                kg: set.kg,
                durationSeconds: set.durationSeconds,
                distanceMeters: set.distanceMeters,
              ),
          ],
        ));
      }
      if (exerciseId != null && rows.isEmpty) continue;
      out.add((id: s.id, date: date, name: s.name, exercises: rows));
    }
    return out;
  });
}

/// The phone-tool reads of the open profile.
@Riverpod(keepAlive: true)
BuddyPhoneReads buddyPhoneReads(Ref ref) =>
    BuddyPhoneReads(ref.watch(appDatabaseProvider));
