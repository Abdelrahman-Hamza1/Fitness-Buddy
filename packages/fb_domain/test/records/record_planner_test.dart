import 'package:fb_domain/fb_domain.dart';
import 'package:test/test.dart';

import '../helpers/diary.dart';
import '../proposals/proposal_fixtures.dart' show FixedIds;

final _now = EntryTime(DateTime.utc(2026, 10, 13, 12), 180);
final LocalDate _today = _now.localDate;

RecordFacts _facts({
  Iterable<DiaryEntry> entries = const [],
  Iterable<DiaryEntry> day = const [],
  List<DishGroup> groups = const [],
  SavedMeal? meal,
  BatchFacts? batch,
  Map<String, RecordFoodLine> replacements = const {},
  List<RecordFoodLine> lines = const [],
  List<MemoryItem> memory = const [],
  double? trendKg,
  List<DiaryEntry>? cardEntries,
}) => RecordFacts(
  now: _now,
  slots: DefaultSlots.all,
  entries: {for (final e in entries) e.id: e},
  dayEntries: day.toList(),
  groups: groups,
  savedMeal: meal,
  batch: batch,
  replacements: replacements,
  foodLines: lines,
  memory: memory,
  trendKg: trendKg,
  cardEntries: cardEntries,
);

RecordPlan _plan(
  RecordRequest r,
  RecordFacts f, {
  String? choice,
  BatchPath? path,
}) => RecordPlanner.plan(r, f, FixedIds(), choice: choice, path: path);

const _lunch = RecordDayHint(slotHint: 'lunch');

RecordReference _ref(String mention, {RecordDayHint when = _lunch}) =>
    RecordReference(mention: mention, when: when);

DiaryEntry _pieces({String id = entryC}) => DiaryEntry(
  id: id,
  version: 2,
  time: _now,
  localDate: _today,
  slotId: DefaultSlots.breakfastId,
  food: EntryFood(
    ref: FoodRef.personal('0199e3c2-5b1a-7000-8000-0000000000e1'),
    names: FoodNames('Egg'),
    per100: Nutrients(kcal: 140, protein: 12, carbs: 1, fat: 10, fiber: 0),
    provenance: Provenance(source: FoodSource.yours),
  ),
  amount: EntryAmount(
    input: Quantity(2, 'piece'),
    amount: 100,
    basis: NutrientBasis.per100g,
  ),
  snapshot: snapshotOf(140),
);

RecordFoodLine _line(String name, double grams, double kcal) => RecordFoodLine(
  food: EntryFood(
    ref: FoodRef.estimate(),
    names: FoodNames(name),
    per100: Nutrients(
      kcal: kcal / grams * 100,
      protein: 1,
      carbs: 1,
      fat: 1,
      fiber: 0,
    ),
    provenance: Provenance(source: FoodSource.database),
  ),
  amount: grams.toEntryAmount(),
  snapshot: Nutrients(kcal: kcal, protein: 1, carbs: 1, fat: 1, fiber: 0),
);

extension on double {
  EntryAmount toEntryAmount() => grams(this);
}

void main() {
  group('diary edits (AI-050, AI-090)', () {
    test("AI-090 the entry's own unit scales by ratio; a mass converts; "
        'another unit is refused', () {
      final egg = _pieces();
      final three = _plan(
        EditRecord(
          targets: [egg.id],
          reference: _ref('egg'),
          amount: const RecordAmountInput(3, 'piece'),
        ),
        _facts(entries: [egg]),
      );
      final op = three.ops.single as UpdateDiaryEntry;
      expect(op.expectedVersion, 2);
      expect(op.patch.amount!.amount, 150);
      expect(three.view!.lines.single.after!.kcal, closeTo(210, 0.01));
      expect(three.view!.kcalDelta, closeTo(70, 0.01));

      final grams = _plan(
        EditRecord(
          targets: [egg.id],
          reference: _ref('egg'),
          amount: const RecordAmountInput(0.2, 'kg'),
        ),
        _facts(entries: [egg]),
      );
      expect((grams.ops.single as UpdateDiaryEntry).patch.amount!.amount, 200);

      final cup = _plan(
        EditRecord(
          targets: [egg.id],
          reference: _ref('egg'),
          amount: const RecordAmountInput(1, 'cup'),
        ),
        _facts(entries: [egg]),
      );
      expect(cup.issue, RecordIssue.unsupportedUnit);
    });

    test('AI-090 amount and move are one update; a missing target is not '
        'found; nothing changing is refused', () {
      final rice = entry();
      final plan = _plan(
        EditRecord(
          targets: [rice.id],
          reference: _ref('rice'),
          amount: const RecordAmountInput(200, 'g'),
          move: const RecordDayHint(
            dateHint: 'yesterday',
            slotHint: 'dinner',
            timeHint: '8pm',
          ),
        ),
        RecordFacts(
          now: EntryTime(DateTime.utc(2026, 10, 14, 12), 180),
          slots: DefaultSlots.all,
          entries: {rice.id: rice},
        ),
      );
      final op = plan.ops.single as UpdateDiaryEntry;
      expect(op.patch.slotId, DefaultSlots.dinnerId);
      // Yesterday of the 14th is the entry's own day: not a date change.
      expect(op.patch.localDate, isNull);
      expect(op.patch.amount!.amount, 200);
      expect(plan.view!.notes, contains(RecordNote.timeIgnored));
      expect(plan.view!.lines.single.toSlotId, DefaultSlots.dinnerId);

      expect(
        _plan(
          EditRecord(targets: [entryB], reference: _ref('x')),
          _facts(entries: [rice]),
        ).issue,
        RecordIssue.notFound,
      );
      expect(
        _plan(
          EditRecord(
            targets: [rice.id],
            reference: _ref('rice'),
            amount: const RecordAmountInput(150, 'g'),
          ),
          _facts(entries: [rice]),
        ).issue,
        RecordIssue.noChange,
      );
    });

    test('AI-091 a lookup (no targets) by day, slot and the mention: one '
        'edits it, two ask which, the pick plans it', () {
      final a = entry();
      final b = entry(id: entryB);
      final other = entry(
        id: entryC,
        food: riceFood(id: 'usda:1'),
      );
      final pool = [a, other.copyWithName('Salad'), b];
      final ask = _plan(
        DeleteRecord(targets: const [], reference: _ref('the rice')),
        _facts(day: pool),
      );
      expect(ask.needsChoice, isTrue);
      expect(ask.canConfirm, isFalse);
      expect(ask.view!.choices.map((c) => c.id), [entryA, entryB]);
      final picked = _plan(
        DeleteRecord(targets: const [], reference: _ref('the rice')),
        _facts(day: pool),
        choice: entryB,
      );
      final del = picked.ops.single as DeleteEntries;
      expect(del.entries.single, VersionedId(entryB, 1));
      expect(picked.view!.lines.single.removed, isTrue);

      final one = _plan(
        DeleteRecord(targets: const [], reference: _ref('salad')),
        _facts(day: pool),
      );
      expect((one.ops.single as DeleteEntries).entries.single.id, entryC);

      // Nothing named: the whole slot, all of it with scope all.
      final all = _plan(
        const DeleteRecord(
          targets: [],
          reference: RecordReference(mention: 'lunch', when: _lunch, all: true),
        ),
        _facts(day: pool),
      );
      expect((all.ops.single as DeleteEntries).entries, hasLength(3));
      expect(
        _plan(
          DeleteRecord(
            targets: const [],
            reference: _ref('x', when: const RecordDayHint()),
          ),
          _facts(day: pool),
        ).issue,
        RecordIssue.notFound,
      );
    });

    test('AI-091 an ambiguous reference asks, then edits or deletes the '
        'picked entry', () {
      final a = entry();
      final b = entry(id: entryB);
      final edit = AmbiguousRecord(
        candidates: [a.id, b.id],
        reference: _ref('rice'),
        then: EditRecord(
          targets: const [],
          reference: _ref('rice'),
          amount: const RecordAmountInput(100, 'g'),
        ),
      );
      expect(_plan(edit, _facts(entries: [a, b])).view!.choices, hasLength(2));
      final picked = _plan(edit, _facts(entries: [a, b]), choice: entryB);
      expect((picked.ops.single as UpdateDiaryEntry).id, entryB);
      expect(picked.view!.kind, RecordKind.ambiguousReference);
      final del = _plan(
        AmbiguousRecord(
          candidates: [a.id, b.id],
          reference: _ref('rice'),
          then: DeleteRecord(targets: const [], reference: _ref('rice')),
        ),
        _facts(entries: [a, b]),
        choice: entryA,
      );
      expect(del.ops.single, isA<DeleteEntries>());
      expect(_plan(edit, _facts()).issue, RecordIssue.notFound);
    });

    test('AI-050 a swap takes the app-built food and amount', () {
      final rice = entry();
      final swap = RecordFoodLine(
        food: EntryFood(
          ref: FoodRef.catalog('usda:2', version: '1'),
          names: FoodNames('Bulgur'),
          per100: rice100,
          provenance: Provenance(source: FoodSource.database, isEstimate: true),
        ),
        amount: grams(150),
        snapshot: snapshotOf(195),
        estimate: true,
      );
      final plan = _plan(
        EditRecord(targets: [rice.id], reference: _ref('rice'), replace: true),
        _facts(entries: [rice], replacements: {rice.id: swap}),
      );
      final op = plan.ops.single as UpdateDiaryEntry;
      expect(op.patch.food!.names.en, 'Bulgur');
      expect(plan.view!.lines.single.newNames!.en, 'Bulgur');
      expect(plan.view!.notes, contains(RecordNote.estimate));
      expect(
        _plan(
          EditRecord(
            targets: [rice.id],
            reference: _ref('rice'),
            replace: true,
          ),
          _facts(entries: [rice]),
        ).issue,
        RecordIssue.notFound,
      );
    });
  });

  group('copies and saved meals (AI-090, DY-031)', () {
    test("AI-090 a copy pins the slot's entries and groups; same place is "
        'refused; no source slot is refused', () {
      final a = entry(dishGroupId: groupG);
      final group = DishGroup(
        id: groupG,
        version: 3,
        name: 'Plate',
        localDate: _today,
        slotId: DefaultSlots.lunchId,
      );
      final plan = _plan(
        const CopyRecord(
          source: RecordDayHint(slotHint: 'lunch'),
          target: RecordDayHint(dateHint: 'yesterday', timeHint: 'noon'),
        ),
        _facts(day: [a], groups: [group]),
      );
      final copy = plan.ops.single as CopyMeal;
      expect(copy.toDate, _today.plusDays(-1));
      expect(copy.toSlotId, isNull);
      expect(copy.expected.groups.single, VersionedId(groupG, 3));
      expect(copy.copyIds.keys, containsAll([entryA, groupG]));
      expect(plan.view!.notes, contains(RecordNote.timeIgnored));
      expect(
        _plan(
          const CopyRecord(source: _lunch, target: RecordDayHint()),
          _facts(day: [a]),
        ).issue,
        RecordIssue.noChange,
      );
      expect(
        _plan(
          const CopyRecord(source: RecordDayHint(), target: _lunch),
          _facts(day: [a]),
        ).issue,
        RecordIssue.noSource,
      );
      expect(
        _plan(
          const CopyRecord(
            source: RecordDayHint(slotHint: 'dinner'),
            target: _lunch,
          ),
          _facts(day: [a]),
        ).issue,
        RecordIssue.notFound,
      );
    });

    test(
      'DY-031 a saved meal logs its exact snapshots; a share is refused',
      () {
        final meal = SavedMeal(
          id: savedMeal,
          version: 1,
          name: 'Usual breakfast',
          items: [
            SavedMealItem(
              id: copyA,
              version: 1,
              sortOrder: 0,
              food: riceFood(),
              amount: grams(100),
              snapshot: snapshotOf(130),
            ),
          ],
        );
        final plan = _plan(
          const SavedMealLogRecord(
            savedMealId: savedMeal,
            when: RecordDayHint(slotHint: 'breakfast'),
          ),
          _facts(meal: meal),
        );
        final log = plan.ops.single as LogSavedMeal;
        expect(log.slotId, DefaultSlots.breakfastId);
        expect(log.when, isA<EntryAt>());
        expect(plan.view!.kcalDelta, 130);
        expect(
          _plan(
            const SavedMealLogRecord(
              savedMealId: savedMeal,
              when: RecordDayHint(),
              shared: true,
            ),
            _facts(meal: meal),
          ).issue,
          RecordIssue.unsupportedShare,
        );
        expect(
          _plan(
            const SavedMealLogRecord(
              savedMealId: savedMeal,
              when: RecordDayHint(),
            ),
            _facts(),
          ).issue,
          RecordIssue.notFound,
        );
      },
    );

    test('DY-032 save a meal from targets, a slot or a logged card', () {
      final a = entry();
      final fromTargets = _plan(
        SavedMealCreateRecord(name: '  My lunch ', targets: [a.id]),
        _facts(entries: [a]),
      );
      final save = fromTargets.ops.single as SaveMeal;
      expect(save.name, 'My lunch');
      expect(save.expected.entries.single, VersionedId(entryA, 1));
      expect(
        _plan(
          const SavedMealCreateRecord(name: 'Lunch', source: _lunch),
          _facts(day: [a]),
        ).ops.single,
        isA<SaveMeal>(),
      );
      expect(
        _plan(
          const SavedMealCreateRecord(name: 'x', activeProposal: copyB),
          _facts(),
        ).issue,
        RecordIssue.logFirst,
      );
      expect(
        _plan(
          const SavedMealCreateRecord(name: 'x', activeProposal: copyB),
          _facts(cardEntries: [a]),
        ).ops.single,
        isA<SaveMeal>(),
      );
      expect(
        _plan(const SavedMealCreateRecord(name: 'x'), _facts()).issue,
        RecordIssue.noSource,
      );
      expect(
        _plan(const SavedMealCreateRecord(name: ' '), _facts()).issue,
        RecordIssue.invalid,
      );
    });
  });

  group('batches (AI-100–AI-102, DY-040–DY-044)', () {
    final lines = [_line('Chicken', 1000, 1650), _line('Rice', 500, 650)];

    test('DY-041 a cooked weight sets per 100 g; a plate is 350 g; '
        'leftovers stay open', () {
      final plan = _plan(
        const BatchRecord(
          name: 'Chicken rice',
          cooked: RecordAmountInput(2, 'kg'),
          path: BatchPath.leftovers,
          eatenNow: RecordPortion(amount: RecordAmountInput(1, 'plate')),
          when: RecordDayHint(slotHint: 'dinner'),
        ),
        _facts(lines: lines),
      );
      final create = plan.ops.first as CreatePersonalFood;
      expect(create.draft.per100.kcal, closeTo(115, 0.01));
      expect(create.draft.createdFrom, BatchFacts.openCode);
      expect(create.draft.servings.single.amount, 2000);
      final log = plan.ops[1] as LogEntries;
      expect(log.entries.single.amount.amount, batchPlateGrams);
      expect(log.entries.single.food.ref.id, create.id);
      expect(log.entries.single.slotId, DefaultSlots.dinnerId);
      final batch = plan.view!.batch!;
      expect(batch.remainingGrams, 2000 - batchPlateGrams);
      expect(batch.eatenKcal, closeTo(402.5, 0.01));
      expect(
        plan.view!.notes,
        containsAll([RecordNote.plateAssumed, RecordNote.leftovers]),
      );
    });

    test('AI-100 the quick path logs the share and closes; without a weight '
        'the raw sum is used', () {
      final quick = _plan(
        const BatchRecord(
          eatenNow: RecordPortion(people: 6),
          when: RecordDayHint(),
        ),
        _facts(lines: lines),
        path: BatchPath.quick,
      );
      final create = quick.ops.first as CreatePersonalFood;
      expect(create.draft.createdFrom, BatchFacts.closedCode);
      expect(create.draft.names.en, 'Chicken, Rice');
      expect((quick.ops[1] as LogEntries).entries.single.amount.amount, 250);
      expect(quick.view!.notes, contains(RecordNote.rawWeight));
      // Quick without a portion: the whole batch.
      final whole = _plan(
        const BatchRecord(path: BatchPath.quick, when: RecordDayHint()),
        _facts(lines: lines),
      );
      expect((whole.ops[1] as LogEntries).entries.single.amount.amount, 1500);
      // No portion, no path: leftovers, nothing logged.
      expect(
        _plan(
          const BatchRecord(when: RecordDayHint()),
          _facts(lines: lines),
        ).ops,
        hasLength(1),
      );
      expect(
        _plan(const BatchRecord(when: RecordDayHint()), _facts()).issue,
        RecordIssue.invalid,
      );
      expect(
        _plan(
          const BatchRecord(
            cooked: RecordAmountInput(2, 'cup'),
            when: RecordDayHint(),
          ),
          _facts(lines: lines),
        ).issue,
        RecordIssue.unsupportedUnit,
      );
    });

    BatchFacts batchOf({
      double eaten = 500,
      String createdFrom = BatchFacts.openCode,
      DateTime? createdAt,
      bool whole = true,
    }) => BatchFacts(
      food: PersonalFood(
        id: '0199e3c2-5b1a-7000-8000-0000000000b0',
        version: 4,
        draft: PersonalFoodDraft(
          names: FoodNames('Chicken rice'),
          per100: Nutrients(kcal: 120, protein: 8, carbs: 12, fat: 4, fiber: 1),
          servings: [if (whole) PersonalFoodServing('serving', 2000)],
          createdFrom: createdFrom,
        ),
      ),
      eatenGrams: eaten,
      createdAt: createdAt ?? DateTime.utc(2026, 10, 12),
    );

    test('DY-043 a portion of an open batch; the rest closes it', () {
      final b = batchOf();
      final third = _plan(
        BatchPortionRecord(
          batchId: b.food.id,
          portion: const RecordPortion(fraction: 0.25),
          when: const RecordDayHint(),
        ),
        _facts(batch: b),
      );
      expect(third.ops.first, isA<RequirePersonalFood>());
      expect((third.ops[1] as LogEntries).entries.single.amount.amount, 500);
      expect(third.view!.batch!.remainingGrams, 1000);
      final rest = _plan(
        BatchPortionRecord(
          batchId: b.food.id,
          rest: true,
          when: const RecordDayHint(),
        ),
        _facts(batch: b),
      );
      expect(rest.ops.first, isA<RequirePersonalFood>());
      final close = rest.ops[1] as UpdatePersonalFood;
      expect(close.expectedVersion, 4);
      expect(close.draft.createdFrom, BatchFacts.closedCode);
      expect((rest.ops[2] as LogEntries).entries.single.amount.amount, 1500);
      expect(rest.view!.notes, contains(RecordNote.closesBatch));
    });

    test('DY-044 a closed, expired or unknown batch is refused; a share '
        'needs the whole weight', () {
      final b = batchOf();
      RecordIssue? issue(
        BatchFacts? facts, {
        RecordPortion? p,
        bool rest = false,
      }) => _plan(
        BatchPortionRecord(
          batchId: b.food.id,
          portion: p,
          rest: rest,
          when: const RecordDayHint(),
        ),
        _facts(batch: facts),
      ).issue;
      expect(issue(null, rest: true), RecordIssue.notFound);
      expect(
        issue(batchOf(createdFrom: BatchFacts.closedCode), rest: true),
        RecordIssue.notOpen,
      );
      expect(
        issue(batchOf(createdAt: DateTime.utc(2026, 9)), rest: true),
        RecordIssue.notOpen,
      );
      expect(issue(batchOf(eaten: 2000), rest: true), RecordIssue.notOpen);
      expect(
        issue(batchOf(whole: false), rest: true),
        RecordIssue.noTotalWeight,
      );
      expect(
        issue(batchOf(whole: false), p: const RecordPortion(people: 2)),
        RecordIssue.noTotalWeight,
      );
      expect(
        issue(b, p: const RecordPortion(amount: RecordAmountInput(1, 'cup'))),
        RecordIssue.unsupportedUnit,
      );
      expect(issue(b), RecordIssue.invalid);

      final close = _plan(BatchCloseRecord(b.food.id), _facts(batch: b));
      expect(
        (close.ops.single as UpdatePersonalFood).draft.createdFrom,
        BatchFacts.closedCode,
      );
      expect(
        _plan(
          BatchCloseRecord(b.food.id),
          _facts(batch: batchOf(createdFrom: BatchFacts.closedCode)),
        ).issue,
        RecordIssue.notOpen,
      );
      expect(
        _plan(BatchCloseRecord(b.food.id), _facts()).issue,
        RecordIssue.notFound,
      );
    });
  });

  group('personal foods, memory, weigh-ins', () {
    test('AI-054 components give per 100; stated figures go to the form', () {
      final fromLines = _plan(
        const PersonalFoodRecord(name: 'My shake', aliases: ['shake', ' ']),
        _facts(lines: [_line('Whey', 40, 160), _line('Milk', 300, 150)]),
      );
      expect(fromLines.ops, isEmpty);
      expect(fromLines.canConfirm, isFalse);
      final food = fromLines.view!.food!;
      expect(food.per100!.kcal, closeTo(91.2, 0.1));
      expect(food.aliases, ['shake']);
      final stated = _plan(
        const PersonalFoodRecord(
          name: 'Bar',
          stated: StatedFigures(basis: 'perServing', servingMl: 250, kcal: 90),
        ),
        _facts(),
      );
      expect(stated.view!.food!.basis, NutrientBasis.per100ml);
      expect(
        _plan(const PersonalFoodRecord(name: 'x'), _facts()).issue,
        RecordIssue.invalid,
      );
    });

    test('AI-054 a volume without a density is never counted as grams: the '
        'form asks for the weight; with one it converts', () {
      RecordFoodLine milk({double? density}) => RecordFoodLine(
        food: _line('Milk', 300, 150).food,
        amount: EntryAmount(
          input: Quantity(300, 'ml'),
          amount: 300,
          basis: NutrientBasis.per100ml,
        ),
        snapshot: Nutrients(kcal: 150, protein: 1, carbs: 1, fat: 1, fiber: 0),
        density: density,
      );
      final unknown = _plan(
        const PersonalFoodRecord(name: 'Shake'),
        _facts(lines: [_line('Whey', 40, 160), milk()]),
      ).view!.food!;
      expect(unknown.per100, isNull);
      expect(unknown.totals!.kcal, 310);
      expect(unknown.needsServingSize, isTrue);
      final known = _plan(
        const PersonalFoodRecord(name: 'Shake'),
        _facts(lines: [_line('Whey', 40, 160), milk(density: 1.03)]),
      ).view!.food!;
      expect(known.per100!.kcal, closeTo(310 / 349 * 100, 0.01));
      expect(known.needsServingSize, isFalse);
      expect(
        _plan(
          const BatchRecord(when: RecordDayHint()),
          _facts(lines: [_line('Rice', 500, 650), milk()]),
        ).issue,
        RecordIssue.noTotalWeight,
      );
      const noSize = FoodView(
        name: 'Bar',
        aliases: [],
        basis: NutrientBasis.per100g,
        stated: StatedFigures(basis: 'perServing', kcal: 250),
      );
      expect(noSize.needsServingSize, isTrue);
    });

    test("AI-055 remember writes the engine's question-kind key; forget "
        'deletes what matches', () {
      final plan = _plan(
        const MemoryRecord(
          forget: false,
          memoryKind: MemoryKinds.defaultValue,
          subject: 'Rice',
          dimension: 'state',
          value: 'raw',
          foodGroup: 'rice',
        ),
        _facts(),
      );
      final save = plan.ops.single as SaveMemoryItem;
      expect((save.key, save.value), ('state:rice', 'raw'));
      expect((save.checked, save.expectedVersion), (true, null));
      expect(plan.view!.memory!.subject, 'Rice');
      final portion = _plan(
        const MemoryRecord(
          forget: false,
          memoryKind: MemoryKinds.portion,
          subject: 'my bowl',
          amount: RecordAmountInput(350, 'g'),
        ),
        _facts(),
      );
      expect((portion.ops.single as SaveMemoryItem).value, '350 g');
      final fat = _plan(
        const MemoryRecord(
          forget: false,
          memoryKind: MemoryKinds.defaultValue,
          subject: 'eggs',
          dimension: 'fat',
          value: 'oil',
          amount: RecordAmountInput(1, 'tsp'),
        ),
        _facts(),
      );
      expect((fat.ops.single as SaveMemoryItem).value, 'oil:1.0:tsp');

      final item = MemoryItem(
        id: copyA,
        version: 2,
        kind: MemoryKinds.defaultValue,
        key: 'state:rice',
        value: 'raw',
        origin: MemoryOrigin.explicit,
        createdAt: DateTime.utc(2026, 10),
      );
      final forget = _plan(
        const MemoryRecord(
          forget: true,
          memoryKind: MemoryKinds.defaultValue,
          subject: 'rice',
        ),
        _facts(memory: [item]),
      );
      expect(forget.ops.single, DeleteMemoryItem(copyA, 2));
      expect(forget.view!.memory!.items, [item]);
      expect(
        _plan(
          const MemoryRecord(
            forget: true,
            memoryKind: MemoryKinds.alias,
            subject: 'shake',
          ),
          _facts(memory: [item]),
        ).issue,
        RecordIssue.nothingToForget,
      );
      expect(
        _plan(
          const MemoryRecord(forget: false, memoryKind: 'secret'),
          _facts(),
        ).issue,
        RecordIssue.invalid,
      );
      expect(
        _plan(
          const MemoryRecord(
            forget: false,
            memoryKind: MemoryKinds.alias,
            subject: 'shake',
          ),
          _facts(),
        ).issue,
        RecordIssue.invalid,
      );
    });

    test(
      'AI-052 a weigh-in on the hinted day with its change versus trend',
      () {
        final plan = _plan(
          const WeighInRecord(
            value: 97.3,
            unit: 'kg',
            when: RecordDayHint(dateHint: 'yesterday'),
          ),
          _facts(trendKg: 97.8),
        );
        final op = plan.ops.single as CreateWeighIn;
        expect(op.draft.localDate, _today.plusDays(-1));
        expect(plan.view!.weighIn!.trendDeltaKg, closeTo(-0.5, 0.001));
        expect(
          _plan(
            const WeighInRecord(
              value: 97,
              unit: 'stone',
              when: RecordDayHint(),
            ),
            _facts(),
          ).issue,
          RecordIssue.unsupportedUnit,
        );
        expect(
          _plan(
            const WeighInRecord(value: 5000, unit: 'kg', when: RecordDayHint()),
            _facts(),
          ).issue,
          RecordIssue.invalid,
        );
      },
    );

    test('record models describe themselves without user content', _describes);

    test('a slot hint matches by ID, default key or name only when active', () {
      expect(
        matchSlotHint(
          'Lunch',
          DefaultSlots.all,
          SlotMode.normal,
          (s) => s.toLowerCase(),
        ),
        DefaultSlots.lunchId,
      );
      expect(
        matchSlotHint(null, DefaultSlots.all, SlotMode.normal, (s) => s),
        isNull,
      );
      expect(
        matchSlotHint('lunch', DefaultSlots.all, SlotMode.ramadan, (s) => s),
        isNull,
      );
      expect(RecordKind.fromCode('batch'), RecordKind.batch);
      expect(RecordKind.fromCode('foodLog'), isNull);
    });
  });
}

void _describes() {
  // Nothing a record model prints holds user content.
  final rice = entry();
  final items = <Object>[
    const RecordDayHint(),
    _ref('rice'),
    const RecordAmountInput(1, 'g'),
    const RecordPortion(),
    RecordAmount(Quantity(1, 'g'), 1),
    RecordLine(names: FoodNames('Rice')),
    RecordChoice(rice),
    BatchView(name: 'Pot', wholeGrams: 1, per100: rice100),
    const FoodView(name: 'Pot', aliases: [], basis: NutrientBasis.per100g),
    const MemoryView(forget: false, kind: 'alias', subject: 'Pot'),
    const StatedFigures(basis: 'per100g'),
    _line('Pot', 1, 1),
    RecordFacts(now: _now, slots: const []),
    const RecordPlan.failed(RecordKind.batch, RecordIssue.invalid),
    const RecordView(kind: RecordKind.batch),
    BatchFacts(
      food: PersonalFood(
        id: copyA,
        version: 1,
        draft: PersonalFoodDraft(names: FoodNames('Pot'), per100: rice100),
      ),
      eatenGrams: 0,
      createdAt: DateTime.utc(2026),
    ),
  ];
  for (final i in items) {
    expect(i.toString(), isNot(contains('Rice')));
    expect(i.toString(), isNot(contains('Pot')));
  }
  expect(
    RecordLine(
      names: FoodNames('a'),
      after: RecordAmount(Quantity(1, 'g'), 1),
    ).added,
    isTrue,
  );
  expect(const RecordAmountInput(0, 'g').quantity, isNull);
  expect(
    BatchView(name: 'x', wholeGrams: 1, per100: rice100).eatenKcal,
    isNull,
  );
}

extension on DiaryEntry {
  DiaryEntry copyWithName(String name) => DiaryEntry(
    id: id,
    version: version,
    time: time,
    localDate: localDate,
    slotId: slotId,
    food: EntryFood(
      ref: food.ref,
      names: FoodNames(name),
      per100: food.per100,
      provenance: food.provenance,
    ),
    amount: amount,
    snapshot: snapshot,
  );
}
