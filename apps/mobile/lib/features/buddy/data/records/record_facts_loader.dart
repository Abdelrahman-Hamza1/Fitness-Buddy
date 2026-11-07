import 'package:drift/drift.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/catalog/catalog.dart';
import 'package:fb_mobile/core/db/app_database.dart';
import 'package:fb_mobile/core/db/db_providers.dart';
import 'package:fb_mobile/core/settings/settings_store.dart';
import 'package:fb_mobile/features/body/body.dart'
    show MeasurementMappingError, WeighInMappingError, measurementOf, weighInOf;
import 'package:fb_mobile/features/buddy/data/buddy_phone_reads.dart';
import 'package:fb_mobile/features/buddy/data/memory_repository.dart';
import 'package:fb_mobile/features/buddy/data/proposal_input_loader.dart';
import 'package:fb_mobile/features/buddy/data/records/record_intents.dart';
import 'package:fb_mobile/features/diary/diary.dart'
    show DiaryReads, diaryEntryOf;
import 'package:fb_mobile/features/foods/foods.dart'
    show PersonalFoodMappingError, personalFoodOf;
import 'package:fb_mobile/features/settings/settings.dart' show AppSettings;
import 'package:fb_mobile/features/workouts/workouts.dart'
    show
        ExerciseLibrary,
        LibraryExercise,
        WorkoutRepository,
        readExerciseLibrary;
import 'package:fb_text/fb_text.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'record_facts_loader.g.dart';

/// Reads what a record card's plan needs (A67 D1), the rows in one read
/// snapshot, and builds its foods (ingredients, components, a swap) with
/// the food engine. Never writes. User content: never logged.
final class RecordFactsLoader {
  /// Over [_db], building foods with [_loader]; workout cards read the
  /// exercise library from [catalog] (built-ins) and the custom exercises,
  /// body cards the [units] setting (metric when not given).
  const new(this._db, this._loader, {this.catalog, this.units});

  final AppDatabase _db;
  final ProposalInputLoader _loader;

  /// The offline catalog (built-in exercises), when there is one.
  final OfflineCatalog? catalog;

  /// The unit setting.
  final Future<UnitSystem> Function()? units;

  /// The most library matches an unmatched exercise offers (WO-033).
  static const _candidates = 3;

  /// Days around imported dates whose stored weigh-ins the checks read.
  static const _importMargin = 8;

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
      final library = r is WorkoutRecord
          ? await readExerciseLibrary(catalog, WorkoutRepository(_db))
          : null;
      final system = r is MeasurementRecord || r is ImportRowsRecord
          ? await units?.call() ?? UnitSystem.metric
          : UnitSystem.metric;
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
        final body = await _bodyFacts(r, today);
        final workout = library == null || r is! WorkoutRecord
            ? null
            : await _workoutFacts(r, library);
        return RecordFacts(
          now: now,
          slots: slots,
          normalize: normalizeKey,
          exercises: workout?.exercises ?? const {},
          exerciseCandidates: workout?.candidates ?? const {},
          liftedSets: workout?.lifted ?? const {},
          massUnit: system == UnitSystem.imperial
              ? MassUnit.pound
              : MassUnit.kilogram,
          lengthUnit: system == UnitSystem.imperial
              ? MeasurementUnit.inch
              : MeasurementUnit.cm,
          weighIns: body.weighIns,
          measurements: body.measurements,
          customMeasurementTypes: body.customTypes,
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
        exercises: facts.exercises,
        exerciseCandidates: facts.exerciseCandidates,
        liftedSets: facts.liftedSets,
        massUnit: facts.massUnit,
        lengthUnit: facts.lengthUnit,
        weighIns: facts.weighIns,
        measurements: facts.measurements,
        customMeasurementTypes: facts.customMeasurementTypes,
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

  /// A workout's exercises (named and picked from), each unmatched one's
  /// closest library matches, and the earlier weighted sets of the named
  /// ones.
  Future<
    ({
      Map<String, ExerciseFacts> exercises,
      Map<int, List<ExerciseFacts>> candidates,
      Map<String, List<LiftedSet>> lifted,
    })
  >
  _workoutFacts(WorkoutRecord r, ExerciseLibrary library) async {
    ExerciseFacts facts(LibraryExercise e) => ExerciseFacts(
      id: e.id,
      name: e.name,
      type: e.type,
      equipment: e.equipment,
    );
    final exercises = <String, ExerciseFacts>{};
    final candidates = <int, List<ExerciseFacts>>{};
    for (final (i, e) in r.exercises.indexed) {
      final known = library.byId[e.exerciseRef];
      if (known != null) {
        exercises[known.id] = facts(known);
        continue;
      }
      final hits = [
        for (final hit in library.search(e.mention).take(_candidates))
          facts(hit),
      ];
      candidates[i] = hits;
      for (final h in hits) {
        exercises[h.id] = h;
      }
    }
    final lifted = <String, List<LiftedSet>>{};
    if (exercises.isNotEmpty) {
      final sets = _db.workoutSets;
      final links = _db.sessionExercises;
      final sessions = _db.workoutSessions;
      final rows =
          await (_db.select(sets).join([
                innerJoin(links, links.id.equalsExp(sets.sessionExerciseId)),
                innerJoin(sessions, sessions.id.equalsExp(links.sessionId)),
              ])..where(
                links.exerciseId.isIn(exercises.keys) &
                    links.deletedAt.isNull() &
                    sets.deletedAt.isNull() &
                    sessions.deletedAt.isNull() &
                    sets.kg.isNotNull() &
                    sets.reps.isNotNull(),
              ))
              .get();
      for (final row in rows) {
        final set = row.readTable(sets);
        final kg = set.kg!;
        final reps = set.reps!;
        if (!kg.isFinite || kg < 0 || reps < 1) continue;
        (lifted[row.readTable(links).exerciseId] ??= []).add((
          kg: kg,
          reps: reps,
        ));
      }
    }
    return (exercises: exercises, candidates: candidates, lifted: lifted);
  }

  /// The stored body rows a measurement or import card checks against.
  Future<
    ({
      List<WeighIn> weighIns,
      List<Measurement> measurements,
      Set<String> customTypes,
    })
  >
  _bodyFacts(RecordRequest r, LocalDate today) async {
    const none = (
      weighIns: <WeighIn>[],
      measurements: <Measurement>[],
      customTypes: <String>{},
    );
    switch (r) {
      case MeasurementRecord(:final kindCode, :final customTypeId):
        final types = await (_db.select(
          _db.measurementTypes,
        )..where((t) => t.deletedAt.isNull())).get();
        return (
          weighIns: const <WeighIn>[],
          measurements: await _measurementsOf(kindCode, customTypeId),
          customTypes: {for (final t in types) t.id},
        );
      case ImportRowsRecord(:final rows, :final measurementKind):
        if (measurementKind != null) {
          return (
            weighIns: const <WeighIn>[],
            measurements: await _measurementsOf(measurementKind, null),
            customTypes: const <String>{},
          );
        }
        final dates = [
          for (final row in rows) ?LocalDate.tryParse(row.date ?? ''),
        ]..sort();
        if (dates.isEmpty) return none;
        final from = dates.first.plusDays(-_importMargin).toString();
        final to = dates.last.plusDays(_importMargin).toString();
        final stored =
            await (_db.select(_db.weighIns)..where(
                  (t) =>
                      t.deletedAt.isNull() &
                      t.localDate.isBetweenValues(from, to),
                ))
                .get();
        return (
          weighIns: [for (final row in stored) ?_weighIn(row)],
          measurements: const <Measurement>[],
          customTypes: const <String>{},
        );
      default:
        return none;
    }
  }

  static WeighIn? _weighIn(WeighInRow row) {
    try {
      return weighInOf(row);
    } on WeighInMappingError {
      return null;
    }
  }

  Future<List<Measurement>> _measurementsOf(
    String kind,
    String? customTypeId,
  ) async {
    final rows =
        await (_db.select(_db.measurements)..where(
              (t) =>
                  t.deletedAt.isNull() &
                  t.kind.equals(kind) &
                  (customTypeId == null
                      ? t.customTypeId.isNull()
                      : t.customTypeId.equals(customTypeId)),
            ))
            .get();
    return [for (final row in rows) ?_measurement(row)];
  }

  static Measurement? _measurement(MeasurementRow row) {
    try {
      return measurementOf(row);
    } on MeasurementMappingError {
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
  catalog: ref.watch(offlineCatalogProvider),
  units: () => ref.read(settingsStoreProvider).read(AppSettings.unitSystem),
);
