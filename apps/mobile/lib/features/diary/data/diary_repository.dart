import 'dart:async';

import 'package:drift/drift.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/db/app_database.dart';
import 'package:fb_mobile/core/db/db_providers.dart';
import 'package:fb_mobile/features/diary/data/diary_day.dart';
import 'package:fb_mobile/features/diary/data/diary_mappers.dart';
import 'package:fb_mobile/features/diary/data/diary_reads.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'diary_repository.g.dart';

/// The diary's read-only repository (A06 §3.3, A01 D12): streams that emit
/// the current value first and again after every change to the tables they
/// read. Writes are change sets through the applier (WP3).
final class DiaryRepository {
  /// A repository over [db].
  new(AppDatabase db, {this.readDay}) : _db = db, _reads = DiaryReads(db);

  /// Optional read port for instrumentation; defaults to [DiaryReads.day].
  final Future<DiaryDay> Function(LocalDate)? readDay;

  final AppDatabase _db;
  final DiaryReads _reads;

  /// The one-shot reads, for the same queries without a stream.
  DiaryReads get reads => _reads;

  /// Latest live snapshot per food. SQLite's single MAX selects the bare
  /// ID from that row (pinned by tests); HLCs are unique per write.
  ///
  /// Initial data is immediate. Later invalidations coalesce for one frame,
  /// so a write burst does not queue a full history scan between every log.
  /// One read runs at a time, with one dirty bit; stale results are discarded.
  Stream<List<FoodHistoryItem>> watchFoodHistory() => _watch(
    {_db.diaryEntries},
    () async => [
      for (final row in await _foodHistoryQuery().get()) _history(row),
    ],
    delay: const Duration(milliseconds: 16),
  );

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

  Selectable<QueryRow> _foodHistoryQuery() => _db.customSelect(
    'WITH latest AS (SELECT id, MAX(updated_hlc) AS last_hlc, COUNT(*) AS uses '
    'FROM diary_entries WHERE deleted_at IS NULL AND food_id IS NOT NULL '
    "AND food_kind IN ('catalog','personal') GROUP BY food_kind, food_id) "
    'SELECT d.food_kind, d.food_id, d.food_version, d.name_en, d.name_ar, '
    'd.input_amount, d.input_unit, d.amount, d.amount_basis, d.per100_kcal, '
    'd.per100_protein_g, d.per100_carbs_g, d.per100_fat_g, d.per100_fiber_g, '
    'd.per100_extras_json, d.source, d.is_estimate, d.estimate_range_json, '
    'd.assumptions_json, d.edited_by_user, latest.last_hlc, latest.uses '
    'FROM latest JOIN diary_entries d ON d.id = latest.id '
    'ORDER BY latest.last_hlc DESC',
    readsFrom: {_db.diaryEntries},
  );

  FoodHistoryItem _history(QueryRow row) {
    return FoodHistoryItem(
      food: EntryFood(
        ref: foodRefOf(
          row.read<String>('food_kind'),
          row.read<String?>('food_id'),
          row.read<String?>('food_version'),
        ),
        names: FoodNames(
          row.read<String>('name_en'),
          ar: row.read<String?>('name_ar'),
        ),
        per100: nutrientsOf(
          kcal: row.read<double>('per100_kcal'),
          proteinG: row.read<double>('per100_protein_g'),
          carbsG: row.read<double>('per100_carbs_g'),
          fatG: row.read<double>('per100_fat_g'),
          fiberG: row.read<double>('per100_fiber_g'),
          extrasJson: row.read<String?>('per100_extras_json'),
        ),
        provenance: provenanceOf(
          row.read<String>('source'),
          row.read<String?>('estimate_range_json'),
          row.read<String?>('assumptions_json'),
          isEstimate: row.read<bool>('is_estimate'),
        ),
      ),
      amount: EntryAmount(
        input: Quantity(
          row.read<double>('input_amount'),
          row.read<String>('input_unit'),
        ),
        amount: row.read<double>('amount'),
        basis: basisOf(row.read<String>('amount_basis')),
      ),
      uses: row.read<int>('uses'),
      lastUsedHlc: Hlc.parse(row.read<String>('last_hlc')),
      editedByUser: row.read<bool>('edited_by_user'),
    );
  }

  /// Authoritative row identity, independent of its current day or slot (PA4).
  Stream<DiaryEntry?> watchEntry(String id) =>
      _watch({_db.diaryEntries}, () async {
        final row =
            await (_db.select(_db.diaryEntries)
                  ..where((t) => t.id.equals(id) & t.deletedAt.isNull()))
                .getSingleOrNull();
        return row == null ? null : diaryEntryOf(row);
      });

  /// The whole day [date]: slots, groups, entries and mark.
  Stream<DiaryDay> watchDay(LocalDate date) =>
      _watch(_reads.dayTables, () => (readDay ?? _reads.day)(date));

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
}

/// The diary repository over the open profile's database. Here, not in
/// `application/`, so `application/` never imports `core/db/` (A01 D12).
@Riverpod(keepAlive: true)
DiaryRepository diaryRepository(Ref ref) =>
    DiaryRepository(ref.watch(appDatabaseProvider));
