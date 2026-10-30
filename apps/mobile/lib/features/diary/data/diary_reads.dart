import 'package:drift/drift.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/db/app_database.dart';
import 'package:fb_mobile/features/diary/data/diary_day.dart';
import 'package:fb_mobile/features/diary/data/diary_mappers.dart';

/// The diary's one-shot reads (A06 §3.3): the queries the repository's
/// streams re-run, and the op handler's reads inside a change set. Every
/// query includes `deleted_at IS NULL`, so the partial indexes in
/// `core/db/diary.drift` apply (A06 D2).
final class DiaryReads {
  /// Reads through [db] (or the transaction's executor).
  const new(this.db);

  /// The database, a transaction or any other query executor.
  final AppDatabase db;

  /// The SQL of [entriesOn]; exposed for the query-plan test.
  static const String dayEntriesSql =
      'SELECT * FROM diary_entries WHERE local_date = ? '
      'AND deleted_at IS NULL ORDER BY occurred_at_utc, id';

  /// The SQL of [entriesIn].
  static const String slotEntriesSql =
      'SELECT * FROM diary_entries WHERE local_date = ? AND slot_id = ? '
      'AND deleted_at IS NULL ORDER BY occurred_at_utc, id';

  /// The SQL of [entriesBetween].
  static const String rangeEntriesSql =
      'SELECT * FROM diary_entries WHERE local_date BETWEEN ? AND ? '
      'AND deleted_at IS NULL ORDER BY local_date, occurred_at_utc, id';

  /// The SQL of [dailyTotals].
  static const String dailyTotalsSql =
      'SELECT local_date, SUM(kcal) AS kcal, SUM(protein_g) AS protein_g, '
      'SUM(carbs_g) AS carbs_g, SUM(fat_g) AS fat_g, SUM(fiber_g) AS fiber_g, '
      'COUNT(*) AS n, COUNT(DISTINCT slot_id) AS meals '
      'FROM diary_entries WHERE local_date BETWEEN ? AND ? '
      'AND deleted_at IS NULL GROUP BY local_date ORDER BY local_date';

  /// The SQL of [firstDiaryDate]: the earlier of the first live entry and
  /// the first live day mark (the date indexes serve each MIN).
  static const String firstDiaryDateSql =
      'SELECT MIN(first_date) AS first_date FROM ( '
      'SELECT MIN(local_date) AS first_date FROM diary_entries '
      'WHERE deleted_at IS NULL '
      'UNION ALL SELECT MIN(local_date) AS first_date FROM day_marks '
      'WHERE deleted_at IS NULL)';

  /// The tables the day read depends on.
  Set<TableInfo<Table, Object?>> get dayTables => {
    db.diaryEntries,
    db.dishGroups,
    db.mealSlots,
    db.dayMarks,
  };

  /// The whole day [date]: slots, groups, entries and mark.
  Future<DiaryDay> day(LocalDate date) async {
    final (slots, groups, entries, mark) = await (
      this.slots(),
      groupsOn(date),
      entriesOn(date),
      markOn(date),
    ).wait;
    return DiaryDay(
      date: date,
      slots: slots,
      groups: groups,
      entries: entries,
      mark: mark,
    );
  }

  /// Every live slot, by `sort_order` then ID.
  Future<List<MealSlot>> slots() async {
    final rows =
        await (db.select(db.mealSlots)
              ..where((t) => t.deletedAt.isNull())
              ..orderBy([
                (t) => OrderingTerm(expression: t.sortOrder),
                (t) => OrderingTerm(expression: t.id),
              ]))
            .get();
    return rows.map(mealSlotOf).toList();
  }

  /// The live groups of [date].
  Future<List<DishGroup>> groupsOn(LocalDate date) async {
    final rows =
        await (db.select(db.dishGroups)
              ..where((t) => t.localDate.equals('$date') & t.deletedAt.isNull())
              ..orderBy([(t) => OrderingTerm(expression: t.id)]))
            .get();
    return rows.map(dishGroupOf).toList();
  }

  /// The marks of [date], or `null`.
  Future<DayMark?> markOn(LocalDate date) async {
    final row =
        await (db.select(
              db.dayMarks,
            )..where((t) => t.localDate.equals('$date') & t.deletedAt.isNull()))
            .getSingleOrNull();
    return row == null ? null : dayMarkOf(row);
  }

  /// The marks of the days from [from] to [to] (inclusive), by date.
  Future<List<DayMark>> marksBetween(LocalDate from, LocalDate to) async {
    final rows =
        await (db.select(db.dayMarks)
              ..where(
                (t) =>
                    t.localDate.isBetweenValues('$from', '$to') &
                    t.deletedAt.isNull(),
              )
              ..orderBy([(t) => OrderingTerm(expression: t.localDate)]))
            .get();
    return rows.map(dayMarkOf).toList();
  }

  /// The live entries of [date], by time then ID.
  Future<List<DiaryEntry>> entriesOn(LocalDate date) =>
      _entries(dayEntriesSql, ['$date']);

  /// The live entries of [date] in slot [slotId].
  Future<List<DiaryEntry>> entriesIn(LocalDate date, String slotId) =>
      _entries(slotEntriesSql, ['$date', slotId]);

  /// The live entries from [from] to [to] (inclusive), by date, time, ID.
  Future<List<DiaryEntry>> entriesBetween(LocalDate from, LocalDate to) =>
      _entries(rangeEntriesSql, ['$from', '$to']);

  /// The stored-precision totals of each day from [from] to [to]
  /// (inclusive) that has live entries (A06 D12), by date.
  Future<List<DailyTotals>> dailyTotals(LocalDate from, LocalDate to) async {
    final rows = await db
        .customSelect(
          dailyTotalsSql,
          variables: [Variable<String>('$from'), Variable<String>('$to')],
          readsFrom: {db.diaryEntries},
        )
        .get();
    return [
      for (final row in rows)
        DailyTotals(
          LocalDate.parse(row.read<String>('local_date')),
          Nutrients(
            kcal: row.read<double>('kcal'),
            protein: row.read<double>('protein_g'),
            carbs: row.read<double>('carbs_g'),
            fat: row.read<double>('fat_g'),
            fiber: row.read<double>('fiber_g'),
          ).rounded(),
          row.read<int>('n'),
          mealCount: row.read<int>('meals'),
        ),
    ];
  }

  /// The earliest day with a live entry or a live day mark, or null without
  /// either (A16 D14): a day that only has a mark (or whose entries were
  /// all deleted but stays marked) is still reachable in Progress.
  Future<LocalDate?> firstDiaryDate() async {
    final row = await db
        .customSelect(
          firstDiaryDateSql,
          readsFrom: {db.diaryEntries, db.dayMarks},
        )
        .getSingle();
    final text = row.read<String?>('first_date');
    return text == null ? null : LocalDate.tryParse(text);
  }

  /// Consistent parent/item snapshot, ordered for list and guarded logging.
  Future<List<SavedMeal>> savedMeals({String? id}) async {
    final query =
        db.select(db.savedMeals).join([
            leftOuterJoin(
              db.savedMealItems,
              db.savedMealItems.savedMealId.equalsExp(db.savedMeals.id) &
                  db.savedMealItems.deletedAt.isNull(),
            ),
          ])
          ..where(
            db.savedMeals.deletedAt.isNull() &
                (id == null
                    ? const Constant(true)
                    : db.savedMeals.id.equals(id)),
          )
          ..orderBy([
            OrderingTerm(expression: db.savedMeals.name),
            OrderingTerm(expression: db.savedMeals.id),
            OrderingTerm(expression: db.savedMealItems.sortOrder),
            OrderingTerm(expression: db.savedMealItems.id),
          ]);
    // One SELECT gives a consistent source snapshot without a write boundary.
    final joined = await query.get();
    final parents = <String, SavedMealRow>{};
    final rows = <SavedMealItemRow>[];
    for (final result in joined) {
      final parent = result.readTable(db.savedMeals);
      parents[parent.id] = parent;
      final item = result.readTableOrNull(db.savedMealItems);
      if (item != null) rows.add(item);
    }
    final items = <String, List<SavedMealItem>>{};
    try {
      for (final row in rows) {
        (items[row.savedMealId] ??= []).add(
          SavedMealItem(
            id: row.id,
            version: row.version,
            sortOrder: row.sortOrder,
            food: EntryFood(
              ref: foodRefOf(row.foodKind, row.foodId, row.foodVersion),
              names: FoodNames(row.nameEn, ar: row.nameAr),
              per100: nutrientsOf(
                kcal: row.per100Kcal,
                proteinG: row.per100ProteinG,
                carbsG: row.per100CarbsG,
                fatG: row.per100FatG,
                fiberG: row.per100FiberG,
                extrasJson: row.per100ExtrasJson,
              ),
              provenance: provenanceOf(
                row.source,
                row.estimateRangeJson,
                row.assumptionsJson,
                isEstimate: row.isEstimate,
              ),
              editedByUser: row.editedByUser,
            ),
            amount: EntryAmount(
              input: Quantity(row.inputAmount, row.inputUnit),
              amount: row.amount,
              basis: basisOf(row.amountBasis),
            ),
            snapshot: nutrientsOf(
              kcal: row.kcal,
              proteinG: row.proteinG,
              carbsG: row.carbsG,
              fatG: row.fatG,
              fiberG: row.fiberG,
              extrasJson: row.extrasJson,
            ),
          ),
        );
      }
      return [
        for (final row in parents.values)
          SavedMeal(
            id: row.id,
            version: row.version,
            name: row.name,
            items: items[row.id] ?? [],
          ),
      ];
    } on FormatException {
      throw const SavedMealReadFailure();
      // Constructors may include private values in their errors.
      // ignore: avoid_catching_errors
    } on ArgumentError {
      throw const SavedMealReadFailure();
    }
  }

  /// One live saved snapshot, including an empty live parent.
  Future<SavedMeal?> savedMeal(String id) async {
    final meals = await savedMeals(id: id);
    return meals.isEmpty ? null : meals.single;
  }

  Future<List<DiaryEntry>> _entries(String sql, List<String> args) async {
    final rows = await db
        .customSelect(
          sql,
          variables: [for (final a in args) Variable<String>(a)],
          readsFrom: {db.diaryEntries},
        )
        .map((row) => diaryEntryOf(db.diaryEntries.map(row.data)))
        .get();
    return rows;
  }
}

/// Redacted typed failure for an unreadable saved snapshot.
final class SavedMealReadFailure implements Exception {
  /// No row content is carried into diagnostics.
  const new();
  @override
  String toString() => 'SavedMealReadFailure';
}
