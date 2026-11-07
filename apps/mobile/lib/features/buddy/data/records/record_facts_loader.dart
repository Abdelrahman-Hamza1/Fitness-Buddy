import 'package:drift/drift.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/db/app_database.dart';
import 'package:fb_mobile/core/db/db_providers.dart';
import 'package:fb_mobile/features/buddy/data/buddy_phone_reads.dart';
import 'package:fb_mobile/features/buddy/data/memory_repository.dart';
import 'package:fb_mobile/features/buddy/data/proposal_input_loader.dart';
import 'package:fb_mobile/features/buddy/data/records/record_intents.dart';
import 'package:fb_mobile/features/diary/diary.dart'
    show DiaryReads, diaryEntryOf;
import 'package:fb_mobile/features/foods/foods.dart'
    show PersonalFoodMappingError, personalFoodOf;
import 'package:fb_text/fb_text.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'record_facts_loader.g.dart';

/// Reads what a record card's plan needs (A67 D1), the rows in one read
/// snapshot, and builds its foods (ingredients, components, a swap) with
/// the food engine. Never writes. User content: never logged.
final class RecordFactsLoader {
  /// Over [_db], building foods with [_loader].
  const new(this._db, this._loader);

  final AppDatabase _db;
  final ProposalInputLoader _loader;

  /// The most entries a swap is built for (a day's worth).
  static const _swaps = 30;

  /// The facts of [intent] at [now]; [cardEntryIds] are the logged entries
  /// of the card a "save this" names (`null`: not logged).
  Future<RecordFacts?> load(
    RecordIntent intent,
    EntryTime now, {
    required ProposalIdSource ids,
    Set<String>? cardEntryIds,
  }) async {
    try {
      final r = intent.request;
      final facts = await _db.readSnapshot(() async {
        final reads = DiaryReads(_db);
        final slots = await reads.slots();
        final today = now.localDate;
        LocalDate? day(String? hint) =>
            hint == null ? today : DayHint.resolve(hint, today);
        final wanted = <String>{
          ...switch (r) {
            EditRecord(:final targets) => targets,
            DeleteRecord(:final targets) => targets,
            AmbiguousRecord(:final candidates) => candidates,
            SavedMealCreateRecord(:final targets) => targets,
            _ => const <String>[],
          },
          ...?cardEntryIds,
        };
        final lookupDay = switch (r) {
          EditRecord(:final targets, :final reference) when targets.isEmpty =>
            day(reference.when.dateHint),
          DeleteRecord(:final targets, :final reference) when targets.isEmpty =>
            day(reference.when.dateHint),
          CopyRecord(:final source) => day(source.dateHint),
          SavedMealCreateRecord(:final targets, :final source)
              when targets.isEmpty && source != null =>
            day(source.dateHint),
          _ => null,
        };
        final entries = await _entries(wanted);
        BatchFacts? batch;
        if (r
            case BatchPortionRecord(:final batchId) ||
                BatchCloseRecord(:final batchId)) {
          batch = await batchFacts(batchId);
        }
        double? trend;
        if (r is WeighInRecord) {
          final weights = await BuddyPhoneReads(_db)
              .weights(today.plusDays(-60), today);
          if (weights.isNotEmpty) {
            trend = smoothDaily(weights, TrendWeightConfig.standard).last;
          }
        }
        return RecordFacts(
          now: now,
          slots: slots,
          normalize: normalizeKey,
          entries: {for (final e in entries) e.id: e},
          dayEntries: lookupDay == null
              ? const []
              : await reads.entriesOn(lookupDay),
          groups: lookupDay == null
              ? const []
              : await reads.groupsOn(lookupDay),
          savedMeal: r is SavedMealLogRecord
              ? await reads.savedMeal(r.savedMealId)
              : null,
          batch: batch,
          memory: r is MemoryRecord
              ? await MemoryRepository(_db).all()
              : const [],
          trendKg: trend,
          cardEntries: cardEntryIds == null
              ? null
              : [
                  for (final e in entries)
                    if (cardEntryIds.contains(e.id)) e,
                ],
        );
      });
      if (intent.foodItems.isEmpty) return facts;
      // The foods, built by the engine as a meal would be (AI-070).
      final replacements = <String, RecordFoodLine>{};
      var lines = const <RecordFoodLine>[];
      if (r
          case EditRecord(replace: true) ||
              AmbiguousRecord(then: EditRecord(replace: true))) {
        // The named targets, and a lookup's candidates (`targets: []`,
        // A67 review 5), at most [_swaps].
        final pool = {
          for (final e in [...facts.entries.values, ...facts.dayEntries])
            e.id: e,
        }.values.take(_swaps);
        for (final e in pool) {
          final line = await _swap(intent, e, now, ids);
          if (line != null) replacements[e.id] = line;
        }
      } else {
        lines = await _lines(
          intent.foodItems,
          now,
          ids,
          language: intent.language,
        );
      }
      return RecordFacts(
        now: facts.now,
        slots: facts.slots,
        normalize: facts.normalize,
        entries: facts.entries,
        dayEntries: facts.dayEntries,
        groups: facts.groups,
        savedMeal: facts.savedMeal,
        batch: facts.batch,
        memory: facts.memory,
        trendKg: facts.trendKg,
        cardEntries: facts.cardEntries,
        replacements: replacements,
        foodLines: lines,
      );
      // Unreadable rows are a card that can't be planned (content never
      // leaves here).
      // ignore: avoid_catches_without_on_clauses
    } catch (_) {
      return null;
    }
  }

  /// Batch [id] with the grams already logged of it, or `null`.
  Future<BatchFacts?> batchFacts(String id) async {
    final row = await (_db.select(
      _db.personalFoods,
    )..where((t) => t.id.equals(id) & t.deletedAt.isNull())).getSingleOrNull();
    if (row == null) return null;
    final PersonalFood food;
    try {
      food = personalFoodOf(row);
    } on PersonalFoodMappingError {
      return null;
    }
    if (food.createdFrom != BatchFacts.openCode &&
        food.createdFrom != BatchFacts.closedCode) {
      return null;
    }
    final rows =
        await (_db.select(_db.diaryEntries)..where(
              (t) =>
                  t.deletedAt.isNull() &
                  t.foodKind.equals('personal') &
                  t.foodId.equals(id),
            ))
            .get();
    return BatchFacts(
      food: food,
      eatenGrams: rows.fold(0, (sum, r) => sum + r.amount),
      consumption: [for (final r in rows) VersionedId(r.id, r.version)],
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        row.createdAt,
        isUtc: true,
      ),
    );
  }

  Future<List<DiaryEntry>> _entries(Set<String> ids) async {
    if (ids.isEmpty) return const [];
    final rows = await (_db.select(
      _db.diaryEntries,
    )..where((t) => t.id.isIn(ids) & t.deletedAt.isNull())).get();
    return [for (final row in rows) diaryEntryOf(row)];
  }

  /// [items] as engine lines (a one-card meal of them).
  Future<List<RecordFoodLine>> _lines(
    List<Map<String, Object?>> items,
    EntryTime now,
    ProposalIdSource ids, {
    String? language,
    String? dateHint,
    String? slotHint,
  }) async {
    final answer = {
      'promptVersion': 'interpret-v1',
      'model': 'agent',
      'intents': [
        {
          'kind': 'foodLog',
          'language': language ?? 'english',
          'script': 'latin',
          'timeHint': null,
          'slotHint': slotHint,
          'dateHint': dateHint,
          'dishGroup': null,
          'items': items,
        },
      ],
    };
    final request = await _loader.load(
      interpretation: answer,
      messageId: ids.next(),
      idSource: ids,
      referenceTime: now,
    );
    final value = request.value;
    if (value == null) return const [];
    final session = ProposalEngine.build(value).value;
    if (session == null) return const [];
    return [
      for (final card in session.cards)
        for (final l in card.lines)
          RecordFoodLine(
            food: l.entry.food,
            amount: l.entry.amount,
            snapshot: l.snapshot,
            estimate: l.entry.food.provenance.isEstimate,
            density: l.selectedFood?.density,
          ),
    ];
  }

  /// The swap food for entry [e] (its amount kept unless one is stated).
  Future<RecordFoodLine?> _swap(
    RecordIntent intent,
    DiaryEntry e,
    EntryTime now,
    ProposalIdSource ids,
  ) async {
    final item = {...intent.foodItems.first};
    final amount = item['amount'];
    final stated =
        amount is Map<String, Object?> &&
        amount['explicit'] == true &&
        amount['value'] != null;
    if (!stated) {
      item['amount'] = {
        'value': e.amount.input.amount,
        'unit': e.amount.input.unitCode,
        'explicit': true,
      };
    }
    final lines = await _lines(
      [item],
      now,
      ids,
      language: intent.language,
      dateHint: 'date:${e.localDate}',
      slotHint: e.slotId,
    );
    return lines.firstOrNull;
  }

  @override
  String toString() => 'RecordFactsLoader';
}

/// The app's record facts loader.
@Riverpod(keepAlive: true)
RecordFactsLoader recordFactsLoader(Ref ref) => RecordFactsLoader(
  ref.watch(appDatabaseProvider),
  ref.watch(proposalInputLoaderProvider),
);
