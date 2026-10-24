import 'dart:async';
import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_domain/testing.dart';
import 'package:fb_mobile/core/changes/apply_result.dart';
import 'package:fb_mobile/core/db/app_database.dart';
import 'package:fb_mobile/core/undo/undo_stack.dart';
import 'package:fb_mobile/features/diary/data/diary_repository.dart';
import 'package:fb_mobile/features/foods/data/food_catalog_repository.dart';
import 'package:fb_mobile/features/foods/foods.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../core/catalog/support/catalog_support.dart';
import '../data/personal_food_harness.dart';
import '../food_search_test.dart'
    show MetadataBlockingRepository, fixtureService, historyOf;

PersonalFood food({
  int n = 1,
  int version = 1,
  String name = 'Labneh',
  String? ar = 'لبنة',
  List<String> aliases = const ['labne', 'lab6a'],
  NutrientBasis basis = NutrientBasis.per100g,
  Nutrients? values,
  List<PersonalFoodServing> servings = const [],
  PersonalFoodServing? entryServing,
  FoodState state = FoodState.asSold,
}) => PersonalFood(
  id: fixtureId(n),
  version: version,
  draft: PersonalFoodDraft(
    names: FoodNames(name, ar: ar),
    aliases: aliases,
    basis: basis,
    per100:
        values ?? Nutrients(kcal: 100, protein: 5, carbs: 20, fat: 0, fiber: 0),
    servings: servings,
    entryServing: entryServing,
    state: state,
  ),
);

final clock = ManualClock(DateTime.utc(2026, 10, 23, 12));

UndoStack stack(PersonalHarness h) {
  final undo = UndoStack(revert: h.applier.revert, clock: clock);
  addTearDown(undo.dispose);
  return undo;
}

PersonalFoodActions actions(
  PersonalHarness h, {
  Future<ApplyResult> Function(ChangeSet)? apply,
}) => PersonalFoodActions(
  apply: apply ?? h.applier.apply,
  undoStack: stack(h),
  ids: SequenceIdGenerator(),
);

PersonalHarness harness() {
  final h = PersonalHarness();
  addTearDown(h.db.close);
  return h;
}

Future<PersonalFood> seed(PersonalHarness h, PersonalFood f) async {
  await h.apply([CreatePersonalFood(f.id, f.draft)]);
  return (await PersonalFoodRepository(h.db).byId(f.id))!;
}

Future<FoodSearchService> searchWith(
  PersonalFood f, {
  bool history = false,
}) async {
  final service = fixtureService();
  await service.updatePersonalFoods([f]);
  if (history) {
    await service.updateHistory([
      historyOf(f.id, name: f.names.en, kind: FoodRefKind.personal),
    ]);
  }
  await service.indexReady;
  return service;
}

Future<({ProviderContainer container, PersonalFoodFormController controller})>
form({
  PersonalFood? initial,
  String? prefill,
  PersonalFoodActions? commands,
  PersonalHarness? h,
  StreamController<PersonalFood?>? changes,
  List<PersonalFood> foods = const [],
}) async {
  final testHarness = h ?? harness();
  final id = initial?.id;
  final c = ProviderContainer(
    overrides: [
      personalFoodsProvider.overrideWith((ref) => Stream.value(foods)),
      if (id != null)
        personalFoodProvider(id).overrideWith(
          (ref) => changes == null
              ? Stream.value(initial)
              : Stream.multi((sink) {
                  sink.add(initial);
                  final sub = changes.stream.listen(sink.add);
                  sink.onCancel = sub.cancel;
                }),
        ),
      personalFoodActionsProvider.overrideWithValue(
        commands ?? actions(testHarness),
      ),
    ],
  );
  addTearDown(c.dispose);
  if (prefill != null) c.read(newFoodPrefillProvider.notifier).put(prefill);
  final key = _keys[c] = PersonalFoodFormKey(id);
  final sub = c.listen(personalFoodFormControllerProvider(key), (_, _) {});
  addTearDown(sub.close);
  await c.read(personalFoodFormControllerProvider(key).future);
  await c.read(personalFoodsProvider.future);
  return (
    container: c,
    controller: c.read(personalFoodFormControllerProvider(key).notifier),
  );
}

/// The form key of each test container (one form per container).
final Expando<PersonalFoodFormKey> _keys = Expando();

/// The form state in [c]; [id] only documents which food it edits.
PersonalFoodFormState value(ProviderContainer c, [String? id]) {
  final key = _keys[c]!;
  expect(key.id, id);
  return c.read(personalFoodFormControllerProvider(key)).requireValue;
}

void fill(PersonalFoodFormController controller) {
  for (final e in {
    PersonalFoodField.name: 'Test',
    PersonalFoodField.kcal: '100',
    PersonalFoodField.protein: '5',
    PersonalFoodField.carbs: '20',
    PersonalFoodField.fat: '0',
  }.entries) {
    controller.setField(e.key, e.value);
  }
}

void main() {
  test('FD-011 FD-021 a personal food ranks above a catalog food '
      'with a matching name and shows ⓨ', () async {
    final service = await searchWith(food(name: 'Rice', ar: null));
    final rows = (await service.search('rice')).rows;
    expect(rows.first.choice.ref.kind, FoodRefKind.personal);
    expect(rows.first.source, FoodSource.yours);
    expect(rows.any((r) => r.choice.ref.kind == FoodRefKind.catalog), isTrue);
  });
  test('FD-021 a personal food with the same name, state and brand'
      ' as a catalog food merges into one row represented by the '
      'personal food', () async {
    final service = await searchWith(
      food(name: 'Rice, white, cooked', ar: null, state: FoodState.cooked),
    );
    final rows = (await service.search('rice white cooked')).rows;
    expect(rows.where((r) => r.nameEn == 'Rice, white, cooked').length, 1);
    expect(rows.first.choice.ref.kind, FoodRefKind.personal);
  });
  test('FD-023 personal foods are found offline by English name, '
      'Arabic name and alias, and with a typo', () async {
    final service = await searchWith(food());
    for (final query in ['Labneh', 'لبنة', 'labne', 'labnhe']) {
      expect(
        (await service.search(query)).rows.first.choice.ref.kind,
        FoodRefKind.personal,
      );
    }
  });
  test(
    'FD-020 an Arabizi alias ("labne", "lab6a") finds the personal food',
    () async {
      final service = await searchWith(food());
      for (final query in ['labne', 'lab6a']) {
        expect(
          (await service.search(query)).rows.single.choice.ref.id,
          food().id,
        );
      }
    },
  );
  test('FD-010 a logged personal food shows ⓨ in the diary', () async {
    final h = harness();
    final f = await seed(h, food());
    final result = await LogFood(
      apply: h.applier.apply,
      undoStack: stack(h),
      clock: clock,
      ids: SequenceIdGenerator(),
    )(choice: personalChoice(f), input: Quantity(100, 'g'), date: today);
    expect(result, isA<FoodLogged>());
    final entries = await DiaryRepository(h.db)
        .watchEntries(today, today)
        .first;
    expect(entries.single.food.provenance.source, FoodSource.yours);
  });
  test('FD-073 a deleted personal food disappears from search and '
      'Recent; its diary entries stay', () async {
    final h = harness();
    final f = await seed(h, food());
    await h.apply([
      LogEntries([newEntry(10, ref: FoodRef.personal(f.id))]),
    ]);
    final service = await searchWith(f, history: true);
    expect((await service.recent()).rows, hasLength(1));
    await actions(h).delete(f);
    await service.updatePersonalFoods([]);
    expect((await service.recent()).rows, isEmpty);
    expect((await service.search('labneh')).rows, isEmpty);
    expect(
      await DiaryRepository(h.db).watchEntries(today, today).first,
      hasLength(1),
    );
  });
  test('FD-073 an edited personal food logs its new values next '
      'time; the earlier entry keeps the old', () async {
    final h = harness();
    final f = await seed(h, food());
    final log = LogFood(
      apply: h.applier.apply,
      undoStack: stack(h),
      clock: clock,
      ids: SequenceIdGenerator(),
    );
    await log(
      choice: personalChoice(f),
      input: Quantity(100, 'g'),
      date: today,
    );
    final changed = food(
      values: Nutrients(kcal: 200, protein: 10, carbs: 40, fat: 0, fiber: 0),
    );
    await actions(h).update(f, changed.draft);
    final live = (await PersonalFoodRepository(h.db).byId(f.id))!;
    await log(
      choice: personalChoice(live),
      input: Quantity(100, 'g'),
      date: today,
    );
    final entries = await DiaryRepository(h.db)
        .watchEntries(today, today)
        .first;
    expect(entries.map((e) => e.food.per100.kcal).toSet(), {100, 200});
  });
  test('FD-022 a never-logged personal food defaults to its entry '
      'serving, else its first serving, else 100 g or ml; a '
      'logged one to its last input', () {
    Quantity portion(PersonalFood f, {FoodHistoryItem? history}) =>
        FoodSearchRow(
          choice: personalChoice(f, history: history),
          tier: SourceTier.personal,
        ).defaultPortion;
    expect(
      portion(
        food(
          entryServing: PersonalFoodServing('cup', 80),
          servings: [PersonalFoodServing('plate', 150)],
        ),
      ).unitCode,
      'cup',
    );
    expect(
      portion(food(servings: [PersonalFoodServing('plate', 150)])).unitCode,
      'plate',
    );
    final conflicting = personalChoice(
      food(
        entryServing: PersonalFoodServing('cup', 30),
        servings: [PersonalFoodServing('cup', 100)],
      ),
    );
    expect(
      (conflicting.measures.resolve(Quantity(1, 'cup')) as Resolved).amount,
      100,
    );
    expect(conflicting.defaultPortion(), Quantity(30, 'g'));
    for (final basis in NutrientBasis.values) {
      expect(portion(food(basis: basis)), Quantity(100, basis.unitCode));
    }
    expect(
      portion(
        food(),
        history: historyOf(food().id, kind: FoodRefKind.personal, input: 42),
      ),
      Quantity(42, 'g'),
    );
  });
  test('FD-073 LogFood and ReplaceEntryFood put '
      'RequirePersonalFood(choice.guard) first for a personal '
      'choice and nothing for a catalog choice; a stale choice → '
      'Failed(changed)', () async {
    final h = harness();
    final f = await seed(h, food());
    await h.apply([
      LogEntries([newEntry(10)]),
    ]);
    final captured = <ChangeSet>[];
    Future<ApplyResult> apply(ChangeSet c) {
      captured.add(c);
      return h.applier.apply(c);
    }

    final log = LogFood(
      apply: apply,
      undoStack: stack(h),
      clock: clock,
      ids: SequenceIdGenerator(),
    );
    final replace = ReplaceEntryFood(apply: apply, undoStack: stack(h));
    await log(
      choice: personalChoice(f),
      input: Quantity(100, 'g'),
      date: today,
    );
    await replace(
      VersionedId(fixtureId(10), 1),
      personalChoice(f),
      Quantity(100, 'g'),
    );
    for (final c in captured) {
      expect(
        c.ops.first,
        isA<RequirePersonalFood>().having(
          (o) => o.food,
          'guard',
          VersionedId(f.id, f.version),
        ),
      );
    }
    await actions(h).update(f, food(name: 'Updated').draft);
    final before = await h.raw();
    expect(
      await log(
        choice: personalChoice(f),
        input: Quantity(100, 'g'),
        date: today,
      ),
      isA<FoodLogFailed>().having((r) => r.code, 'reason', 'changed'),
    );
    expect(await h.raw(), before);
    final catalog = historyChoice(historyOf('usda:retired'));
    await log(choice: catalog, input: Quantity(100, 'g'), date: today);
    expect(captured.last.ops, hasLength(1));
    await replace(VersionedId(fixtureId(10), 2), catalog, Quantity(100, 'g'));
    expect(captured.last.ops, hasLength(1));
  });
  test('FD-073 a personal choice without a guard is refused '
      '(removed) and nothing is applied', () async {
    final h = harness();
    var calls = 0;
    Future<ApplyResult> apply(ChangeSet c) async {
      calls++;
      throw StateError('unexpectedApply');
    }

    final choice = historyChoice(
      historyOf(food().id, kind: FoodRefKind.personal),
    );
    final result = await LogFood(
      apply: apply,
      undoStack: stack(h),
      clock: clock,
      ids: SequenceIdGenerator(),
    )(choice: choice, input: Quantity(100, 'g'), date: today);
    expect(
      result,
      isA<FoodLogFailed>().having((r) => r.code, 'reason', 'removed'),
    );
    expect(
      await ReplaceEntryFood(apply: apply, undoStack: stack(h))(
        VersionedId(fixtureId(10), 1),
        choice,
        Quantity(100, 'g'),
      ),
      isA<FoodLogFailed>(),
    );
    expect(calls, 0);
  });
  test('FD-073 the loader returns no choice for a deleted or '
      'merged-away personal food', () async {
    final (_, catalog) = fixtureCatalog();
    final h = harness();
    final a = await seed(h, food());
    final b = await seed(h, food(n: 2));
    final repo = PersonalFoodRepository(h.db);
    var live = await repo.watchAll().first;
    final loader = FoodChoiceLoader(
      FoodCatalogRepository(catalog),
      () => [historyOf(b.id, kind: FoodRefKind.personal)],
      personalFoods: () => live,
    );
    expect(
      (await loader.load(FoodChoiceRef(FoodRef.personal(b.id))))!.guard,
      VersionedId(b.id, 1),
    );
    await actions(h).merge(a, b);
    live = await repo.watchAll().first;
    expect(await loader.load(FoodChoiceRef(FoodRef.personal(b.id))), isNull);
    final survivor = (await repo.byId(a.id))!;
    await actions(h).delete(survivor);
    live = await repo.watchAll().first;
    expect(await loader.load(FoodChoiceRef(FoodRef.personal(a.id))), isNull);
  });
  test('FD-070 form: per-serving mode converts on save and reopens'
      ' with the same unit and size; switching modes keeps the '
      'typed values', () async {
    final h = harness();
    final f = await form(h: h);
    fill(f.controller);
    f.controller.setMode(PersonalFoodMode.perServing, unit: 'cup');
    f.controller.setField(PersonalFoodField.servingSize, '٥٠٫٠');
    expect(value(f.container).validation.draft!.per100.kcal, 200);
    f.controller.setMode(PersonalFoodMode.per100);
    expect(value(f.container).text(PersonalFoodField.kcal), '100');
    f.controller.setMode(PersonalFoodMode.perServing, unit: 'cup');
    final saved = await f.controller.submit() as PersonalFoodDone;
    final live = (await PersonalFoodRepository(h.db).byId(saved.foodId!))!;
    final reopened = await form(initial: live, h: h);
    final state = value(reopened.container, live.id);
    expect(state.mode, PersonalFoodMode.perServing);
    expect(state.servingUnit, 'cup');
    expect(
      parsePersonalFoodNumber(state.text(PersonalFoodField.servingSize)),
      50,
    );
    expect(parsePersonalFoodNumber(state.text(PersonalFoodField.kcal)), 100);
    expect(parsePersonalFoodNumber('12,5'), 12.5);
    expect(parsePersonalFoodNumber('0.${'0' * 400}1'), isNull);
  });
  test('FD-070 form: saving an untouched form writes nothing; an '
      'untouched field keeps its exact stored value when another '
      'changes', () async {
    final h = harness();
    final initial = await seed(
      h,
      food(
        values: Nutrients(
          kcal: 100.123456789,
          protein: 5.123456789,
          carbs: 20,
          fat: 0,
          fiber: 0,
        ),
        entryServing: PersonalFoodServing('cup', 33.333333333333),
      ),
    );
    final f = await form(initial: initial, h: h);
    final before = await h.raw();
    expect(await f.controller.submit(), isA<PersonalFoodUnchanged>());
    expect(await h.raw(), before);
    f.controller.setField(PersonalFoodField.name, 'Renamed');
    await f.controller.submit();
    expect(
      (await PersonalFoodRepository(h.db).byId(initial.id))!.per100,
      initial.per100,
    );
  });
  test('FD-070 form: an impossible value blocks Save with a field '
      'error (typed code)', () async {
    final f = await form();
    fill(f.controller);
    for (final text in ['-1', 'NaN', 'Infinity', '1e309', '921']) {
      f.controller.setField(PersonalFoodField.kcal, text);
      expect(value(f.container).canSave, isFalse);
      expect(
        value(f.container).validation.errors[PersonalFoodField.kcal],
        isA<PersonalFoodFieldError>(),
      );
      expect(await f.controller.submit(), isA<PersonalFoodFailed>());
    }
    f.controller.setField(PersonalFoodField.kcal, '100');
    f.controller.setField(PersonalFoodField.protein, '106');
    expect(
      value(f.container).validation.errors[PersonalFoodField.nutrients],
      PersonalFoodFieldError.impossible,
    );
  });
  test(
    'FD-012 form: a kcal mismatch sets the warning and Save stays enabled',
    () async {
      final f = await form();
      fill(f.controller);
      f.controller.setField(PersonalFoodField.kcal, '900');
      expect(value(f.container).sanity!.reason, SanityReason.kcalMismatch);
      expect(value(f.container).showSanityWarning, isTrue);
      expect(value(f.container).canSave, isTrue);
    },
  );
  test('FD-070 form: a live food with the same normalized name '
      'sets the duplicate note', () async {
    final duplicate = food();
    final f = await form(foods: [duplicate]);
    fill(f.controller);
    f.controller.setField(PersonalFoodField.name, ' LABNEH ');
    expect(value(f.container).duplicate, duplicate);
    expect(value(f.container).canSave, isTrue);
  });
  test('UX-052 form: a changed food offers Reload and keeps the '
      'typed values; a deleted food disables Save', () async {
    final changes = StreamController<PersonalFood?>();
    addTearDown(changes.close);
    final initial = food();
    final f = await form(initial: initial, changes: changes);
    f.controller.setField(PersonalFoodField.name, 'Typed');
    changes.add(food(version: 2, name: 'Remote'));
    await Future<void>.delayed(Duration.zero);
    expect(
      value(f.container, initial.id).staleness,
      PersonalFoodStaleness.changed,
    );
    expect(
      await f.controller.submit(),
      isA<PersonalFoodFailed>().having(
        (r) => r.reason,
        'reason',
        PersonalFoodFailure.changed,
      ),
    );
    f.controller.reload();
    expect(
      value(f.container, initial.id).text(PersonalFoodField.name),
      'Typed',
    );
    expect(value(f.container, initial.id).original!.version, 2);
    changes.add(null);
    await Future<void>.delayed(Duration.zero);
    expect(value(f.container, initial.id).canSave, isFalse);
    expect(
      await f.controller.submit(),
      isA<PersonalFoodFailed>().having(
        (r) => r.reason,
        'reason',
        PersonalFoodFailure.removed,
      ),
    );
  });
  test('UX-052 Reload keeps protein typed per 30 g when the stored serving '
      'changes to 60 g, and Save writes 20 g per 100', () async {
    final h = harness();
    final initial = await seed(
      h,
      food(entryServing: PersonalFoodServing('piece', 30)),
    );
    final changes = StreamController<PersonalFood?>();
    addTearDown(changes.close);
    final f = await form(initial: initial, h: h, changes: changes);
    f.controller.setField(PersonalFoodField.protein, '6');
    final remote = food(entryServing: PersonalFoodServing('piece', 60));
    await h.apply([UpdatePersonalFood(initial.id, 1, remote.draft)]);
    changes.add(
      food(version: 2, entryServing: PersonalFoodServing('piece', 60)),
    );
    await Future<void>.delayed(Duration.zero);
    f.controller.reload();
    final state = value(f.container, initial.id);
    expect(state.text(PersonalFoodField.protein), '6');
    expect(
      state.validation.draft!.entryServing,
      PersonalFoodServing('piece', 30),
    );
    expect(await f.controller.submit(), isA<PersonalFoodDone>());
    final stored = (await PersonalFoodRepository(h.db).byId(initial.id))!;
    expect(stored.per100.protein, 20);
    expect(stored.per100.carbs, remote.per100.carbs);
    expect(stored.entryServing, PersonalFoodServing('piece', 30));
  });

  test(
    'FD-070 too-small values have a distinct typed error from upper bounds',
    () async {
      final f = await form();
      fill(f.controller);
      f.controller.setField(
        PersonalFoodField.protein,
        '0.000000000000000000000000000001',
      );
      expect(
        value(f.container).validation.errors[PersonalFoodField.protein],
        PersonalFoodFieldError.tooSmall,
      );
      f.controller.setField(PersonalFoodField.protein, '1001');
      expect(
        value(f.container).validation.errors[PersonalFoodField.protein],
        PersonalFoodFieldError.bounds,
      );
    },
  );

  test('FD-070 a pending submit has its own outcome and keeps typed input '
      'after failure', () async {
    final h = harness();
    final pending = Completer<ApplyResult>();
    final f = await form(commands: actions(h, apply: (_) => pending.future));
    fill(f.controller);
    final first = f.controller.submit();
    expect(await f.controller.submit(), isA<PersonalFoodPending>());
    pending.complete(const Rejected(InvalidOp('synthetic')));
    expect(await first, isA<PersonalFoodFailed>());
    expect(value(f.container).submitting, isFalse);
    expect(value(f.container).text(PersonalFoodField.name), 'Test');
  });

  test('FD-070 create, update, delete and merge apply one direct '
      'change set each, record undo and return typed outcomes', () async {
    final h = harness();
    final undo = stack(h);
    final changes = <ChangeSet>[];
    final command = PersonalFoodActions(
      apply: (c) {
        changes.add(c);
        return h.applier.apply(c);
      },
      undoStack: undo,
      ids: SequenceIdGenerator(),
    );
    final create = await command.create(food().draft) as PersonalFoodDone;
    var live = (await PersonalFoodRepository(h.db).byId(create.foodId!))!;
    final update = await command.update(
      live,
      food(name: 'Changed').draft,
    ) as PersonalFoodDone;
    live = (await PersonalFoodRepository(h.db).byId(live.id))!;
    final deleted = await command.delete(live) as PersonalFoodDone;
    expect(await undo.undo(deleted.undoId), UndoOutcome.undone);
    live = (await PersonalFoodRepository(h.db).byId(live.id))!;
    final other = await seed(h, food(n: 100));
    final merged = await command.merge(live, other) as PersonalFoodDone;
    expect(changes, hasLength(4));
    expect(changes.every((c) => c.origin == Origin.direct), isTrue);
    expect(create.kind, PersonalFoodKind.personalFoodSaved);
    expect(update.kind, create.kind);
    expect(deleted.kind, PersonalFoodKind.personalFoodDeleted);
    expect(merged.kind, PersonalFoodKind.personalFoodsMerged);
    expect(await undo.undo(merged.undoId), UndoOutcome.undone);
  });
  test('FD-073 merge builds MergePersonalFoods and RelinkFoodRefs '
      'in one change set', () async {
    final h = harness();
    final a = await seed(h, food());
    final b = await seed(h, food(n: 2));
    ChangeSet? captured;
    final command = actions(
      h,
      apply: (c) {
        captured = c;
        return h.applier.apply(c);
      },
    );
    expect(
      await command.merge(a, a),
      isA<PersonalFoodFailed>().having(
        (r) => r.reason,
        'reason',
        PersonalFoodFailure.invalid,
      ),
    );
    expect(captured, isNull);
    expect(await command.merge(a, b), isA<PersonalFoodDone>());
    expect(captured!.ops, [isA<MergePersonalFoods>(), isA<RelinkFoodRefs>()]);
  });
  test(
    '#86 the prefill is taken once and never appears in a route location',
    () async {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      final prefill = c.read(newFoodPrefillProvider.notifier)
        ..put('  Private search  ');
      expect(prefill.take(), 'Private search');
      expect(prefill.take(), isNull);
      prefill.put('a' * 100);
      expect(prefill.take()!.length, 80);
      prefill.put('Private');
      expect(prefill.take(), 'Private');
      final handed = await form(
        prefill: 'Private form name',
        foods: [food(name: 'Private form name')],
      );
      expect(
        value(handed.container).text(PersonalFoodField.name),
        'Private form name',
      );
      expect(value(handed.container).duplicate?.names.en, 'Private form name');
      final key = _keys[handed.container]!;
      handed.container.invalidate(personalFoodFormControllerProvider(key));
      await handed.container.read(
        personalFoodFormControllerProvider(key).future,
      );
      expect(value(handed.container).text(PersonalFoodField.name), isEmpty);
      // Handoff names must not be serialized by the router.
      for (final file
          in Directory('lib/app/router')
              .listSync(recursive: true)
              .whereType<File>()
              .where((f) => f.path.endsWith('.dart'))) {
        expect(
          file.readAsStringSync(),
          isNot(contains('newFoodPrefillProvider')),
        );
      }
    },
  );
  test('FD-071 the foods feature imports no API client', () {
    for (final file
        in Directory('lib/features/foods')
            .listSync(recursive: true)
            .whereType<File>()
            .where((f) => f.path.endsWith('.dart'))) {
      expect(file.readAsStringSync(), isNot(contains('package:fb_api_client')));
    }
  });
  test('FD-073 snapshot fallback keeps the observed live guard '
      'across edit, delete and merge races', () async {
    for (final mutation in ['edit', 'delete', 'merge']) {
      final h = harness();
      final original = await seed(
        h,
        food(servings: [PersonalFoodServing('plate', 100)]),
      );
      await h.apply([
        LogEntries([newEntry(10)]),
      ]);
      await actions(h).update(original, food().draft);
      final live = (await PersonalFoodRepository(h.db).byId(original.id))!;
      final fallback = historyChoice(
        historyOf(
          original.id,
          kind: FoodRefKind.personal,
          input: 1,
          unit: 'plate',
        ),
        guard: VersionedId(live.id, live.version),
      );
      expect(fallback.measures.resolve(Quantity(1, 'plate')), isA<Resolved>());
      if (mutation == 'edit') {
        await actions(h).update(live, food(name: 'Changed').draft);
      } else if (mutation == 'delete') {
        await actions(h).delete(live);
      } else {
        final other = await seed(h, food(n: 2));
        await actions(h).merge(other, live);
      }
      final before = await h.raw();
      final result = await LogFood(
        apply: h.applier.apply,
        undoStack: stack(h),
        clock: clock,
        ids: SequenceIdGenerator(),
      )(choice: fallback, input: Quantity(1, 'plate'), date: today);
      expect(
        result,
        isA<FoodLogFailed>().having((r) => r.code, 'reason', 'changed'),
      );
      expect(await h.raw(), before);
      final replaced = await ReplaceEntryFood(
        apply: h.applier.apply,
        undoStack: stack(h),
      )(VersionedId(fixtureId(10), 1), fallback, Quantity(1, 'plate'));
      expect(
        replaced,
        isA<FoodLogFailed>().having((r) => r.code, 'reason', 'changed'),
      );
      expect(await h.raw(), before);
    }
  });
  test('FD-070 actions map typed rejections and clear pending on '
      'unexpected errors', () async {
    final h = harness();
    final undo = stack(h);
    var calls = 0;
    final command = PersonalFoodActions(
      apply: (c) async {
        calls++;
        if (calls == 1) throw StateError('syntheticFailure');
        if (calls == 2) throw const ChangeRejected(InvalidOp('tooMany'));
        return const Rejected(InvalidOp('basisMismatch'));
      },
      undoStack: undo,
      ids: SequenceIdGenerator(),
    );
    await expectLater(
      command.update(food(), food(name: 'Changed').draft),
      throwsStateError,
    );
    expect(
      await command.update(food(), food(name: 'Changed').draft),
      isA<PersonalFoodFailed>().having(
        (r) => r.reason,
        'reason',
        PersonalFoodFailure.tooMany,
      ),
    );
    expect(
      await command.update(food(), food(name: 'Changed').draft),
      isA<PersonalFoodFailed>().having(
        (r) => r.reason,
        'reason',
        PersonalFoodFailure.basisMismatch,
      ),
    );
    expect(calls, 3);
    final pending = Completer<ApplyResult>();
    var applies = 0;
    final slow = PersonalFoodActions(
      apply: (c) {
        applies++;
        return pending.future;
      },
      undoStack: undo,
      ids: SequenceIdGenerator(),
    );
    final first = slow.delete(food());
    expect(await slow.delete(food()), isA<PersonalFoodPending>());
    pending.complete(
      const Rejected(RowNotFound(entity: 'personalFood', id: 'synthetic')),
    );
    expect(
      await first,
      isA<PersonalFoodFailed>().having(
        (r) => r.reason,
        'reason',
        PersonalFoodFailure.removed,
      ),
    );
    expect(applies, 1);
  });
  test('FD-070 form clears submitting and preserves input after '
      'unexpected apply errors', () async {
    final command = PersonalFoodActions(
      apply: (_) => Future.error(StateError('syntheticFailure')),
      undoStack: stack(harness()),
      ids: SequenceIdGenerator(),
    );
    final f = await form(commands: command);
    fill(f.controller);
    await expectLater(f.controller.submit(), throwsStateError);
    expect(value(f.container).submitting, isFalse);
    expect(value(f.container).text(PersonalFoodField.name), 'Test');
  });
  test('FD-070 form validates optional nutrients, aliases, GTINs '
      'and serving rows without leaking input', () async {
    final f = await form();
    fill(f.controller);
    f.controller.setField(PersonalFoodField.aliases, 'labne, LABNE, lab6a');
    f.controller.setField(PersonalFoodField.fiber, '');
    f.controller.setField(PersonalFoodField.sodium, '12,5');
    var state = value(f.container);
    expect(state.dirty, isTrue);
    expect(state.validation.draft!.aliases, ['labne', 'lab6a']);
    expect(state.validation.draft!.per100.fiber, 0);
    expect(state.validation.draft!.per100.extra(NutrientKey.sodium), 12.5);
    expect(state.validation.draft!.per100.extra(NutrientKey.sugar), isNull);
    f.controller.setServings([
      const PersonalFoodServingInput('cup', '30'),
      const PersonalFoodServingInput('plate', '30'),
    ]);
    expect(value(f.container).canSave, isTrue);
    f.controller.setServings([const PersonalFoodServingInput('cup', '0.09')]);
    expect(
      value(f.container).validation.errors[PersonalFoodField.servings],
      PersonalFoodFieldError.invalidServing,
    );
    f.controller.setField(PersonalFoodField.barcodes, 'private-invalid');
    state = value(f.container);
    expect(
      state.validation.errors[PersonalFoodField.barcodes],
      PersonalFoodFieldError.invalidBarcode,
    );
    expect(state.validation.toString(), isNot(contains('private-invalid')));
    expect(
      state.validation.errors.toString(),
      isNot(contains('private-invalid')),
    );
  });
  test('FD-023 personal-food and history bursts publish only the '
      'latest coherent search input', () async {
    final (_, catalog) = fixtureCatalog();
    final repository = MetadataBlockingRepository(catalog);
    final service = FoodSearchService(repository);
    addTearDown(service.dispose);
    await service.updatePersonalFoods([food()]);
    repository.block = true;
    final first = service.updateHistory([
      historyOf('usda:rice_white_long_grain_cooked'),
    ]);
    await repository.started.future;
    final pending = <Future<void>>[];
    for (var i = 2; i <= 30; i++) {
      pending
        ..add(service.updatePersonalFoods([food(version: i, name: 'Newest')]))
        ..add(
          service.updateHistory([
            historyOf(
              food().id,
              name: 'Old snapshot',
              kind: FoodRefKind.personal,
            ),
          ]),
        );
    }
    repository.release.complete();
    await first;
    await Future.wait(pending);
    await service.indexReady;
    expect(service.personalFoods.single.version, 30);
    expect((await service.recent()).rows.single.nameEn, 'Newest');
    expect(
      (await service.search('Newest')).rows.single.choice.guard,
      VersionedId(food().id, 30),
    );
    expect((await service.search('Old snapshot')).rows, isEmpty);
  });
  test(
    'FD-073 LogFood refuses a guard for a different logged food ref',
    () async {
      final h = harness();
      final a = await seed(h, food());
      final b = await seed(h, food(n: 2));
      final valid = personalChoice(a);
      final mismatched = FoodChoice(
        food: valid.food,
        measures: valid.measures,
        guard: VersionedId(b.id, b.version),
      );
      var calls = 0;
      ChangeSet? captured;
      final log = LogFood(
        apply: (c) {
          calls++;
          captured = c;
          return h.applier.apply(c);
        },
        undoStack: stack(h),
        clock: clock,
        ids: SequenceIdGenerator(),
      );
      final before = await h.raw();
      expect(
        await log(choice: mismatched, input: Quantity(100, 'g'), date: today),
        isA<FoodLogFailed>().having((r) => r.code, 'reason', 'removed'),
      );
      expect(calls, 0);
      expect(await h.raw(), before);
      expect(
        await log(choice: valid, input: Quantity(100, 'g'), date: today),
        isA<FoodLogged>(),
      );
      expect(calls, 1);
      expect(
        (captured!.ops.first as RequirePersonalFood).food.id,
        (captured!.ops.last as LogEntries).entries.single.food.ref.id,
      );
    },
  );
  test(
    'FD-070 stored sanity failures allow metadata-only form saves and merges',
    () async {
      final h = harness();
      final a = await seed(h, food());
      final b = await seed(h, food(n: 2));
      await h.write([
        UpdateRow(
          h.db.personalFoods,
          a.id,
          const PersonalFoodsCompanion(
            per100Kcal: Value(424),
            per100ProteinG: Value(106),
            per100CarbsG: Value(0),
          ),
        ),
      ]);
      final stored = (await PersonalFoodRepository(h.db).byId(a.id))!;
      final f = await form(initial: stored, h: h);
      expect(
        value(f.container, a.id).sanity!.reason,
        SanityReason.macrosTooHeavy,
      );
      expect(await f.controller.submit(), isA<PersonalFoodUnchanged>());
      f.controller.setField(PersonalFoodField.name, 'Renamed');
      expect(value(f.container, a.id).canSave, isTrue);
      expect(await f.controller.submit(), isA<PersonalFoodDone>());
      final current = (await PersonalFoodRepository(h.db).byId(a.id))!;
      expect(await actions(h).merge(current, b), isA<PersonalFoodDone>());
      expect(
        (await PersonalFoodRepository(h.db).byId(a.id))!.per100,
        stored.per100,
      );
    },
  );
}
