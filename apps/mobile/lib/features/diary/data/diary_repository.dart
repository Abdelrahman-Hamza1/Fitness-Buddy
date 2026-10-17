import 'package:drift/drift.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/db/app_database.dart';
import 'package:fb_mobile/core/db/db_providers.dart';
import 'package:fb_mobile/features/diary/data/diary_day.dart';
import 'package:fb_mobile/features/diary/data/diary_reads.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'diary_repository.g.dart';

/// The diary's read-only repository (A06 §3.3, A01 D12): streams that emit
/// the current value first and again after every change to the tables they
/// read. Writes are change sets through the applier (WP3).
final class DiaryRepository {
  /// A repository over [db].
  new(AppDatabase db) : this._(db, DiaryReads(db));

  new _(this._db, this._reads);

  final AppDatabase _db;
  final DiaryReads _reads;

  /// The one-shot reads, for the same queries without a stream.
  DiaryReads get reads => _reads;

  /// The whole day [date]: slots, groups, entries and mark.
  Stream<DiaryDay> watchDay(LocalDate date) =>
      _watch(_reads.dayTables, () => _reads.day(date));

  /// The live entries of slot [slotId] on [date].
  Stream<List<DiaryEntry>> watchSlot(LocalDate date, String slotId) =>
      _watch({_db.diaryEntries}, () => _reads.entriesIn(date, slotId));

  /// The live entries from [from] to [to] (inclusive), by date and time.
  Stream<List<DiaryEntry>> watchEntries(LocalDate from, LocalDate to) =>
      _watch({_db.diaryEntries}, () => _reads.entriesBetween(from, to));

  /// The stored-precision totals per day from [from] to [to] (charts).
  Stream<List<DailyTotals>> watchDailyTotals(LocalDate from, LocalDate to) =>
      _watch({_db.diaryEntries}, () => _reads.dailyTotals(from, to));

  /// The live slots of [mode], by `sort_order`.
  Stream<List<MealSlot>> watchSlots([SlotMode mode = SlotMode.normal]) =>
      _watch({_db.mealSlots}, () async {
        final all = await _reads.slots();
        return [
          for (final slot in all)
            if (slot.mode == mode) slot,
        ];
      });

  /// The day marks from [from] to [to] (inclusive).
  Stream<List<DayMark>> watchDayMarks(LocalDate from, LocalDate to) =>
      _watch({_db.dayMarks}, () => _reads.marksBetween(from, to));

  /// Runs [read] now and again after each write to [tables]. drift's custom
  /// query streams re-run on table updates and don't compare results, so
  /// every change re-emits.
  Stream<T> _watch<T>(
    Set<TableInfo<Table, Object?>> tables,
    Future<T> Function() read,
  ) => _db
      .customSelect('SELECT 1', readsFrom: tables)
      .watch()
      .asyncMap((_) => read());
}

/// The diary repository over the open profile's database. Here, not in
/// `application/`, so `application/` never imports `core/db/` (A01 D12).
@Riverpod(keepAlive: true)
DiaryRepository diaryRepository(Ref ref) =>
    DiaryRepository(ref.watch(appDatabaseProvider));
