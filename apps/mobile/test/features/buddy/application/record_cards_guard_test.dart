import 'package:drift/drift.dart' show OrderingTerm;
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/changes/apply_result.dart';
import 'package:fb_mobile/core/undo/undo_stack.dart';
import 'package:fb_mobile/features/buddy/application/buddy_thread_controller.dart';
import 'package:fb_mobile/features/foods/foods.dart'
    show
        PersonalFoodDone,
        PersonalFoodField,
        PersonalFoodFormKey,
        PersonalFoodMode,
        personalFoodActionsProvider,
        personalFoodFormControllerProvider,
        preparedFoodPrefillProvider;
import 'package:flutter_test/flutter_test.dart';

import '../support/buddy_harness.dart';

/// The confirmation guard for every record card kind (TD-128, AQ-01,
/// A67 D15): a streamed `proposal` writes no user row; confirm writes
/// exactly the card's ops and its resolve in one change set; discard
/// writes only the resolve; Undo restores the rows.

const _lang = {'language': 'english', 'script': 'latin'};

Map<String, Object?> _ref(String mention) => {
  'mention': mention,
  'dateHint': null,
  'slotHint': null,
  'scope': 'one',
};

Map<String, Object?> _hint({String? slot}) => {
  'dateHint': null,
  'slotHint': slot,
  'timeHint': null,
};

/// The user rows a record card can change, as comparable text.
Future<String> _rows(BuddyHarness h) async {
  final db = h.db;
  // Live rows only: an undone insert is a tombstone (rows are never
  // deleted).
  final entries =
      await (db.select(db.diaryEntries)
            ..where((t) => t.deletedAt.isNull())
            ..orderBy([(t) => OrderingTerm(expression: t.id)]))
          .get();
  final meals = await (db.select(
    db.savedMeals,
  )..where((t) => t.deletedAt.isNull())).get();
  final weighIns = await (db.select(
    db.weighIns,
  )..where((t) => t.deletedAt.isNull())).get();
  final memory = await (db.select(
    db.memoryItems,
  )..where((t) => t.deletedAt.isNull())).get();
  final foods =
      await (db.select(db.personalFoods)
            ..where((t) => t.deletedAt.isNull())
            ..orderBy([(t) => OrderingTerm(expression: t.id)]))
          .get();
  return [
    for (final e in entries)
      '${e.id}:${e.amount}:${e.slotId}:${e.localDate}:${e.deletedAt != null}',
    for (final m in meals) 'meal:${m.id}:${m.deletedAt != null}',
    for (final w in weighIns) 'weigh:${w.kg}:${w.deletedAt != null}',
    for (final m in memory)
      'memory:${m.memoryKey}:${m.memoryValue}:${m.deletedAt != null}',
    for (final f in foods)
      'food:${f.id}:${f.createdFrom}:${f.deletedAt != null}',
  ].join('\n');
}

void main() {
  late BuddyHarness h;
  late String entryId;
  late String mealId;
  late String batchId;
  late String foodId;

  setUp(() async {
    h = BuddyHarness();
    final food = foodId = await h.personalFood();
    entryId = h.ids.next();
    mealId = h.ids.next();
    batchId = h.ids.next();
    final seeded = await h.applier.apply(
      ChangeSet([
        LogEntries([
          NewDiaryEntry(
            id: entryId,
            when: EntryWhen.at(EntryTime.now(h.clock)),
            slotId: DefaultSlots.lunchId,
            food: EntryFood(
              ref: FoodRef.personal(food),
              names: FoodNames('Rice'),
              per100: Nutrients(
                kcal: 130,
                protein: 3,
                carbs: 28,
                fat: 0,
                fiber: 0,
              ),
              provenance: Provenance(source: FoodSource.yours),
            ),
            amount: EntryAmount(
              input: Quantity(150, 'g'),
              amount: 150,
              basis: NutrientBasis.per100g,
            ),
          ),
        ]),
        CreatePersonalFood(
          batchId,
          PersonalFoodDraft(
            names: FoodNames('Chicken rice pot'),
            per100: Nutrients(
              kcal: 120,
              protein: 8,
              carbs: 12,
              fat: 4,
              fiber: 1,
            ),
            state: FoodState.cooked,
            servings: [PersonalFoodServing('serving', 2000)],
            createdFrom: BatchFacts.openCode,
          ),
        ),
      ], origin: Origin.direct),
    );
    expect(seeded, isA<Applied>());
    final saved = await h.applier.apply(
      ChangeSet([
        SaveMeal(
          savedMealId: mealId,
          name: 'Usual lunch',
          source: MealSource.entries([entryId]),
          expected: SourceVersions(entries: [VersionedId(entryId, 1)]),
        ),
      ], origin: Origin.direct),
    );
    expect(saved, isA<Applied>());
  });

  final cases = <String, Map<String, Object?> Function()>{
    'diaryEdit': () => {
      'kind': 'diaryEdit',
      ..._lang,
      'targets': [entryId],
      'reference': _ref('rice'),
      'patch': {
        'amount': {'value': 200, 'unit': 'g', 'explicit': true},
        'replacement': null,
        'move': _hint(slot: 'dinner'),
      },
    },
    'diaryDelete': () => {
      'kind': 'diaryDelete',
      ..._lang,
      'targets': [entryId],
      'reference': _ref('rice'),
    },
    'diaryCopy': () => {
      'kind': 'diaryCopy',
      ..._lang,
      'source': _hint(slot: 'lunch'),
      'target': _hint(slot: 'dinner'),
    },
    'savedMealLog': () => {
      'kind': 'savedMealLog',
      ..._lang,
      'savedMealId': mealId,
      'timeHint': null,
      'slotHint': 'breakfast',
      'dateHint': null,
      'share': null,
    },
    'savedMealCreate': () => {
      'kind': 'savedMealCreate',
      ..._lang,
      'name': 'My lunch',
      'activeProposal': null,
      'targets': [entryId],
      'source': null,
    },
    'batchPortion': () => {
      'kind': 'batchPortion',
      ..._lang,
      'batchId': batchId,
      'portion': {
        'amount': {'value': 300, 'unit': 'g', 'explicit': true},
        'share': null,
      },
      'rest': false,
      'timeHint': null,
      'slotHint': null,
      'dateHint': null,
    },
    'batchClose': () => {'kind': 'batchClose', ..._lang, 'batchId': batchId},
    'batch': () => {
      'kind': 'batch',
      ..._lang,
      'name': 'Pot',
      'ingredients': [
        item(
          match: food(key: foodId, source: 'personal'),
          amount: 500,
          unit: 'g',
        ),
      ],
      'cookedWeight': {'value': 1, 'unit': 'kg', 'explicit': true},
      'path': 'leftovers',
      'eatenNow': {
        'amount': null,
        'share': {'fraction': 0.25, 'people': null},
      },
      'timeHint': null,
      'slotHint': 'dinner',
      'dateHint': null,
    },
    'memoryChange': () => {
      'kind': 'memoryChange',
      ..._lang,
      'operation': 'remember',
      'memoryKind': 'alias',
      'subject': 'my shake',
      'dimension': null,
      'value': 'whey shake',
      'amount': null,
      'food': null,
    },
    'weighIn': () => {
      'kind': 'weighIn',
      ..._lang,
      'value': 97.3,
      'unit': 'kg',
      'timeHint': null,
      'dateHint': null,
    },
  };

  for (final MapEntry(key: kind, value: intent) in cases.entries) {
    test(
      'AQ-01 TD-128 $kind: streamed, it writes nothing; discard writes '
      'only its resolve; confirm writes exactly its ops; Undo restores',
      () async {
        final before = await _rows(h);
        h.answer({
          'intents': [intent()],
        });
        await h.thread.send('do it', texts);
        final turn = h.state.turns.single;
        final card = turn.records.single;
        expect(card.kind.code, kind);
        expect(card.resolution, CardResolution.open);
        expect(card.plan.canConfirm, isTrue);
        // Streamed: only the chat and a pending proposal row.
        expect(await _rows(h), before);
        expect(h.applied.where((s) => s.origin is OriginProposal), isEmpty);
        final row = await h.proposal(card.id);
        expect((row.kind, row.status), (kind, 'pending'));

        // Discard: the resolve alone, undoable.
        await h.thread.discardRecord(card.id);
        final discard = h.applied.last;
        expect(
          discard.ops.whereType<ResolveProposal>().single.to,
          ProposalStatus.discarded,
        );
        expect(
          discard.ops.every(
            (o) => o is ResolveProposal || o is ReleaseChatMessageAnswer,
          ),
          isTrue,
        );
        expect(await _rows(h), before);
        expect(await h.thread.undoRecord(card.id), UndoOutcome.undone);
        expect(
          h.state.turns.single.records.single.resolution,
          CardResolution.open,
        );

        // Confirm: the plan's ops and the resolve, one change set.
        final open = h.state.turns.single.records.single;
        await h.thread.confirmRecord(card.id);
        final confirm = h.applied.last;
        expect(confirm.origin, Origin.proposal(card.id));
        expect(
          confirm.ops,
          [
            ...open.plan.ops,
            isA<ResolveProposal>(),
            isA<ReleaseChatMessageAnswer>(),
          ].map((o) => o is Matcher ? o : equals(o)).toList(),
        );
        expect(
          (confirm.ops[open.plan.ops.length] as ResolveProposal).to,
          ProposalStatus.confirmed,
        );
        final logged = h.state.turns.single.records.single;
        expect(logged.resolution, CardResolution.logged);
        expect(await _rows(h), isNot(before));
        expect((await h.proposal(card.id)).status, 'confirmed');

        // Undo: every row as before, the card open again.
        expect(await h.thread.undoRecord(card.id), UndoOutcome.undone);
        expect(await _rows(h), before);
        expect((await h.proposal(card.id)).status, 'pending');
        expect(
          h.state.turns.single.records.single.resolution,
          CardResolution.open,
        );
      },
    );
  }

  test("AQ-01 AI-162 Log all confirms a reply's record cards in one change "
      'set with one Undo', () async {
    final before = await _rows(h);
    h.answer({
      'intents': [cases['weighIn']!(), cases['memoryChange']!()],
    });
    await h.thread.send('97.3 and remember my shake', texts);
    final turn = h.state.turns.single;
    expect(turn.applicableCount, 2);
    expect(await _rows(h), before);
    await h.thread.applyAll(turn.userMessageId);
    final records = h.state.turns.single.records;
    expect(
      records.map((r) => r.resolution),
      everyElement(CardResolution.logged),
    );
    expect(records.map((r) => r.undoEntryId).toSet(), hasLength(1));
    expect(h.applied.last.ops.whereType<ResolveProposal>(), hasLength(2));
    expect(await h.thread.undoRecord(records.first.id), UndoOutcome.undone);
    expect(await _rows(h), before);
    expect(
      h.state.turns.single.records.map((r) => r.resolution),
      everyElement(CardResolution.open),
    );
  });

  test(
    'AQ-01 a which-one card confirms nothing until an entry is picked',
    () async {
      final second = h.ids.next();
      final rice = (await h.entries()).single;
      await h.applier.apply(
        ChangeSet([
          CopyMeal(
            MealSource.entries([rice.id]),
            toDate: LocalDate.tryParse(rice.localDate)!,
            toSlotId: DefaultSlots.lunchId,
            expected: SourceVersions(
              entries: [VersionedId(rice.id, rice.version)],
            ),
            copyIds: {rice.id: second},
          ),
        ], origin: Origin.direct),
      );
      h.answer({
        'intents': [
          {
            'kind': 'ambiguousReference',
            ..._lang,
            'operation': 'delete',
            'candidates': [entryId, second],
            'reference': _ref('rice'),
            'patch': null,
          },
        ],
      });
      await h.thread.send('delete the rice', texts);
      final card = h.state.turns.single.records.single;
      expect(card.plan.view!.choices, hasLength(2));
      expect(card.plan.canConfirm, isFalse);
      await h.thread.confirmRecord(card.id);
      expect(h.applied.where((s) => s.origin is OriginProposal), isEmpty);
      await h.thread.pickRecord(card.id, second);
      await h.thread.confirmRecord(card.id);
      final del = h.applied.last.ops.whereType<DeleteEntries>().single;
      expect(del.entries.single.id, second);
    },
  );

  test("AQ-01 AI-054 a personal-food card is confirmed only by the form's "
      "save, in its change set; the form's Undo reopens it", () async {
    h.answer({
      'intents': [
        {
          'kind': 'personalFoodCreate',
          ..._lang,
          'name': 'My shake',
          'aliases': <String>[],
          'components': <Object?>[],
          'stated': {
            'basis': 'perServing',
            'servingG': null,
            'servingMl': 300,
            'kcal': 250,
            'proteinG': 30,
            'carbsG': null,
            'fatG': null,
            'fiberG': null,
          },
        },
      ],
    });
    await h.thread.send('my shake is 250 kcal 30 g protein per 300 ml', texts);
    final card = h.state.turns.single.records.single;
    expect(card.plan.ops, isEmpty);
    expect(h.applied.where((s) => s.origin is OriginProposal), isEmpty);
    expect(h.thread.prepareFoodForm(card.id), isTrue);
    final prefill = h.container
        .read(preparedFoodPrefillProvider.notifier)
        .take()!;
    expect(prefill.draft.names.en, 'My shake');
    expect(prefill.origin, Origin.proposal(card.id));
    final outcome = await h.container
        .read(personalFoodActionsProvider)
        .create(
          prefill.draft,
          also: prefill.also(adjusted: false),
          origin: prefill.origin,
        );
    expect(outcome, isA<PersonalFoodDone>());
    expect((await h.proposal(card.id)).status, 'confirmed');
    await pumpEventQueue();
    expect(
      h.state.turns.single.records.single.resolution,
      CardResolution.logged,
    );
    await h.undo.undo((outcome as PersonalFoodDone).undoId);
    await pumpEventQueue();
    expect((await h.proposal(card.id)).status, 'pending');
    expect(h.state.turns.single.records.single.resolution, CardResolution.open);
  });

  test('AQ-01 a row changed meanwhile re-plans the card, open again', () async {
    h.answer({
      'intents': [cases['diaryEdit']!()],
    });
    await h.thread.send('the rice was 200 g', texts);
    final card = h.state.turns.single.records.single;
    // The entry changes elsewhere before the tap.
    final rice = (await h.entries()).single;
    await h.applier.apply(
      ChangeSet([
        UpdateDiaryEntry(
          rice.id,
          rice.version,
          EntryPatch(
            amount: EntryAmount(
              input: Quantity(180, 'g'),
              amount: 180,
              basis: NutrientBasis.per100g,
            ),
          ),
        ),
      ], origin: Origin.direct),
    );
    await h.thread.confirmRecord(card.id);
    final now = h.state.turns.single.records.single;
    expect(now.resolution, CardResolution.open);
    expect(now.changedMeanwhile, isTrue);
    expect((await h.proposal(card.id)).status, 'pending');
    await h.thread.confirmRecord(card.id);
    expect(
      h.state.turns.single.records.single.resolution,
      CardResolution.logged,
    );
  });

  test('AQ-01 a batch portion pins the remainder: a portion logged meanwhile '
      're-plans the rest', () async {
    h.answer({
      'intents': [
        {
          'kind': 'batchPortion',
          ..._lang,
          'batchId': batchId,
          'portion': null,
          'rest': true,
          'timeHint': null,
          'slotHint': null,
          'dateHint': null,
        },
      ],
    });
    await h.thread.send('I ate the rest', texts);
    final card = h.state.turns.single.records.single;
    expect(card.plan.view!.batch!.eatenGrams, 2000);
    // Another 500 g of the pot is logged elsewhere first.
    final pot = await (h.db.select(
      h.db.personalFoods,
    )..where((t) => t.id.equals(batchId))).getSingle();
    await h.applier.apply(
      ChangeSet([
        LogEntries([
          NewDiaryEntry(
            id: h.ids.next(),
            when: EntryWhen.at(EntryTime.now(h.clock)),
            slotId: DefaultSlots.lunchId,
            food: EntryFood(
              ref: FoodRef.personal(batchId),
              names: FoodNames(pot.nameEn),
              per100: Nutrients(
                kcal: 120,
                protein: 8,
                carbs: 12,
                fat: 4,
                fiber: 1,
              ),
              provenance: Provenance(source: FoodSource.yours),
            ),
            amount: EntryAmount(
              input: Quantity(500, 'g'),
              amount: 500,
              basis: NutrientBasis.per100g,
            ),
          ),
        ]),
      ], origin: Origin.direct),
    );
    await h.thread.confirmRecord(card.id);
    final now = h.state.turns.single.records.single;
    expect(now.resolution, CardResolution.open);
    expect(now.changedMeanwhile, isTrue);
    expect(now.plan.view!.batch!.eatenGrams, 1500);
  });

  test('AI-054 TD-092 per-serving figures without a size open per serving '
      'with the size to fill in; never saved as per 100', () async {
    h.answer({
      'intents': [
        {
          'kind': 'personalFoodCreate',
          ..._lang,
          'name': 'Bar',
          'aliases': <String>[],
          'components': <Object?>[],
          'stated': {
            'basis': 'perServing',
            'servingG': null,
            'servingMl': null,
            'kcal': 250,
            'proteinG': 20,
            'carbsG': null,
            'fatG': null,
            'fiberG': null,
          },
        },
      ],
    });
    await h.thread.send('my bar is 250 kcal and 20 g protein', texts);
    final card = h.state.turns.single.records.single;
    expect(h.thread.prepareFoodForm(card.id), isTrue);
    final key = PersonalFoodFormKey.prepared();
    final sub = h.container.listen(
      personalFoodFormControllerProvider(key),
      (_, _) {},
    );
    addTearDown(sub.close);
    final form = await h.container.read(
      personalFoodFormControllerProvider(key).future,
    );
    expect(form.mode, PersonalFoodMode.perServing);
    expect(form.text(PersonalFoodField.servingSize), isEmpty);
    expect(form.validation.draft, isNull);
    final controller = h.container.read(
      personalFoodFormControllerProvider(key).notifier,
    )..setField(PersonalFoodField.servingSize, '50');
    final draft = controller.state.requireValue.validation.draft!;
    expect(draft.per100.kcal, 500);
    expect(draft.entryServing!.amount, 50);
  });

  test('AI-050 AI-091 a swap by a day/slot lookup (targets: []) builds the '
      'replacement for the entry it finds', () async {
    h.answer({
      'intents': [
        {
          'kind': 'diaryEdit',
          ..._lang,
          'targets': <String>[],
          'reference': {
            'mention': 'rice',
            'dateHint': 'today',
            'slotHint': 'lunch',
            'scope': 'one',
          },
          'patch': {
            'amount': null,
            'replacement': item(
              match: food(key: foodId, source: 'personal'),
              amount: null,
              unit: null,
              explicit: false,
            ),
            'move': null,
          },
        },
      ],
    });
    await h.thread.send('the rice was actually my private food', texts);
    final card = h.state.turns.single.records.single;
    expect(card.plan.canConfirm, isTrue);
    final op = card.plan.ops.single as UpdateDiaryEntry;
    expect(op.id, entryId);
    expect(op.patch.food!.ref.id, foodId);
    expect(op.patch.amount!.amount, 150);
  });

  test('a restart shows resolved record cards as they ended', () async {
    h.answer({
      'intents': [cases['weighIn']!(), cases['memoryChange']!()],
    });
    await h.thread.send('97.3 and remember my shake', texts);
    final cards = h.state.turns.single.records;
    await h.thread.confirmRecord(cards.first.id);
    await h.thread.discardRecord(cards.last.id);
    h.restart();
    await h.thread.ensureRestored(0);
    final restored = h.state.turns.single.records;
    expect(restored.map((r) => r.id), [for (final c in cards) c.id]);
    expect(restored.map((r) => r.resolution), [
      CardResolution.logged,
      CardResolution.discarded,
    ]);
  });
}
