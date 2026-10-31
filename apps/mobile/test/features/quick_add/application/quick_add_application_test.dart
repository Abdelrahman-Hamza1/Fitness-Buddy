import 'dart:async';

import 'package:drift/drift.dart' show Value;
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_domain/testing.dart';
import 'package:fb_mobile/core/api/api_providers.dart';
import 'package:fb_mobile/core/changes/apply_result.dart';
import 'package:fb_mobile/core/changes/change_providers.dart';
import 'package:fb_mobile/core/db/app_database.dart';
import 'package:fb_mobile/core/ids/id_generator.dart';
import 'package:fb_mobile/core/time/clock_provider.dart';
import 'package:fb_mobile/core/undo/undo_stack.dart';
import 'package:fb_mobile/features/diary/diary.dart';
import 'package:fb_mobile/features/foods/data/food_catalog_repository.dart';
import 'package:fb_mobile/features/foods/foods.dart';
import 'package:fb_mobile/features/quick_add/quick_add.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/ramadan_off.dart';
import '../../diary/support/diary_harness.dart' show foodOf;
import '../../foods/data/personal_food_harness.dart';
import '../../foods/food_search_test.dart' show fixtureService;

final day = LocalDate(2026, 10, 17);
const String lunch = DefaultSlots.lunchId;

final class Setup {
  new({
    this.apply,
    this.current,
    ManualClock? clock,
    bool failApi = false,
    FoodCatalogRepository? repository,
    LocalDate? viewedDate,
    Stream<DiaryDay>? viewedInput,
    Stream<List<DiaryEntry>> Function(LocalDate)? windowInput,
    Stream<List<MealSlot>>? slotsInput,
    Stream<List<SavedMeal>>? mealsInput,
    Stream<List<PersonalFood>>? personalInput,
    Map<LocalDate, Stream<DiaryDay>> extraDays = const {},
  }) : clock = clock ?? ManualClock(DateTime.utc(2026, 10, 17, 12)) {
    undo = UndoStack(revert: h.applier.revert, clock: this.clock);
    addTearDown(undo.dispose);
    c = ProviderContainer(
      overrides: [
        clockProvider.overrideWithValue(this.clock),
        idGeneratorProvider.overrideWithValue(
          SequenceIdGenerator(startMs: 0x0199e3c35b1a),
        ),
        undoStackProvider.overrideWithValue(undo),
        changeSetApplierProvider.overrideWithValue(h.applier),
        diaryApplyProvider.overrideWithValue(
          (change) => (apply ?? h.applier.apply)(change),
        ),
        diaryRepositoryProvider.overrideWithValue(DiaryRepository(h.db)),
        personalFoodRepositoryProvider.overrideWithValue(
          PersonalFoodRepository(h.db),
        ),
        if (repository == null)
          quickAddLogFoodProvider.overrideWith(
            (ref) => LogFood(
              apply: (change) => (apply ?? h.applier.apply)(change),
              undoStack: undo,
              clock: this.clock,
              ids: ref.read(idGeneratorProvider),
            ),
          ),
        if (repository == null)
          foodChoiceProvider.overrideWith((ref, key) async => current),
        if (repository != null)
          foodCatalogRepositoryProvider.overrideWithValue(repository),
        if (viewedInput != null)
          dayProvider(viewedDate!).overrideWith((_) => viewedInput),
        for (final MapEntry(:key, :value) in extraDays.entries)
          dayProvider(key).overrideWith((_) => value),
        if (windowInput != null)
          quickAddWindowProvider.overrideWith((_, today) => windowInput(today)),
        ramadanOff,
        if (slotsInput != null)
          foodSlotsProvider.overrideWith((_, _) => slotsInput),
        if (mealsInput != null)
          savedMealsProvider.overrideWith((_) => mealsInput),
        if (personalInput != null)
          personalFoodsProvider.overrideWith((_) => personalInput),
        if (failApi) ...[
          dioProvider.overrideWith((_) {
            apiCalls++;
            throw StateError('unexpected API');
          }),
          fbApiProvider.overrideWith((_) {
            apiCalls++;
            throw StateError('unexpected API');
          }),
          httpClientAdapterProvider.overrideWith((_) {
            apiCalls++;
            throw StateError('unexpected API');
          }),
        ],
      ],
    );
    addTearDown(() {
      if (!disposed) c.dispose();
    });
  }
  final PersonalHarness h = PersonalHarness();
  final ManualClock clock;
  Future<ApplyResult> Function(ChangeSet)? apply;
  FoodChoice? current;
  bool disposed = false;
  int apiCalls = 0;
  late final UndoStack undo;
  late final ProviderContainer c;

  /// Disposes the container now, so its timers are gone before the test ends.
  void disposeNow() {
    disposed = true;
    c.dispose();
  }

  SavedMealActions get actions => c.read(savedMealActionsProvider);
  QuickAddController get controller =>
      c.read(quickAddControllerProvider.notifier);
  Future<SavedMeal> saved() async =>
      (await DiaryRepository(h.db).watchSavedMeals().first).single;
  Future<List<DiaryEntry>> entries([LocalDate? date]) =>
      DiaryRepository(h.db).reads.entriesOn(date ?? day);
  Future<List<QuickAddChip>> chips({
    LocalDate? date,
    bool Function(List<QuickAddChip>)? until,
  }) async {
    final ready = Completer<List<QuickAddChip>>();
    c.listen(quickAddChipsProvider(date ?? day), (_, next) {
      if (next.hasError && !ready.isCompleted) {
        ready.completeError(next.error!, next.stackTrace);
      }
      if (next.value case final value?) {
        if (!ready.isCompleted && (until == null || until(value))) {
          ready.complete(value);
        }
      }
    }, fireImmediately: true);
    // The model starts only after the day's first data frame (D14): draw
    // frames until the chips are in.
    while (!ready.isCompleted) {
      await pumpEventQueue(times: 5);
      drawFrame();
    }
    return await ready.future;
  }

  Future<void> logHistory({
    int n = 20,
    FoodRef? ref,
    String unit = 'g',
    double input = 75,
    double amount = 75,
    LocalDate? date,
    String slot = lunch,
  }) async {
    await h.apply([
      LogEntries([
        NewDiaryEntry(
          id: fixtureId(n),
          when: EntryWhen.at(
            EntryTime.local(LocalTime(12).on(date ?? day.plusDays(-1)), 0),
          ),
          slotId: slot,
          food: foodOf(n, ref: ref),
          amount: EntryAmount(
            input: Quantity(input, unit),
            amount: amount,
            basis: NutrientBasis.per100g,
          ),
        ),
      ]),
    ]);
  }
}

/// A broadcast-like input that counts how often it is listened to and
/// cancelled, so a test can prove no listener is left behind.
final class CountedInput<T> {
  new(this.initial);
  final T initial;
  int starts = 0;
  int cancels = 0;
  late final Stream<T> stream = Stream<T>.multi((out) {
    starts++;
    out
      ..onCancel = (() => cancels++)
      ..add(initial);
  });
}

final class InputProbes {
  final window = CountedInput<List<DiaryEntry>>([]);
  final meals = CountedInput<List<SavedMeal>>([]);
  final personal = CountedInput<List<PersonalFood>>([]);
  final slots = CountedInput<List<MealSlot>>(DefaultSlots.all);
  List<CountedInput<Object?>> get all => [window, meals, personal, slots];
  List<int> starts() => [for (final p in all) p.starts];
  List<int> cancels() => [for (final p in all) p.cancels];
}

DiaryDay emptyDay(LocalDate date) =>
    DiaryDay(date: date, slots: DefaultSlots.all, groups: [], entries: []);

Future<void> settle() => pumpEventQueue(times: 50);

/// One frame in a plain `test`: runs the post-frame callbacks the quick-add
/// activation waits for.
void drawFrame() {
  TestWidgetsFlutterBinding.instance
    ..handleBeginFrame(Duration.zero)
    ..handleDrawFrame();
}

/// One real frame (its post-frame steps run), then the rebuilds it causes.
Future<void> frame(WidgetTester tester) async {
  await tester.pump();
  await tester.idle();
}

Future<void> flush(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 1));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('DY-031 logging a saved meal sends LogSavedMeal with '
      'the shown meal and item versions; one Undo removes '
      'every entry', () async {
    final s = Setup();
    await s.h.seed();
    final meal = await s.saved();
    final before = await s.h.state();
    ChangeSet? sent;
    s.apply = (change) {
      sent = change;
      return s.h.applier.apply(change);
    };
    final result = await s.actions.log(meal, day, lunch) as SavedMealDone;
    expect(sent!.origin, Origin.direct);
    final op = sent!.ops.single as LogSavedMeal;
    expect(op.expected, meal.versions);
    expect(op.entryIds.keys, meal.items.map((i) => i.id));
    expect(op.entryIds.values.toSet(), hasLength(meal.items.length));
    expect((await s.entries()).length, 4);
    expect(s.undo.latest!.label.key, 'savedMealLogged');
    expect(await s.undo.undo(result.undoEntryId), UndoOutcome.undone);
    expect(await s.h.state(), before);
  });
  test('DY-031 a saved meal changed after it was shown → '
      'Failed(changed), nothing logged', () async {
    for (final mutation in ['rename', 'delete', 'item', 'removed']) {
      final s = Setup();
      await s.h.seed();
      final shown = await s.saved();
      if (mutation == 'rename') {
        await s.h.apply([RenameSavedMeal(shown.id, shown.version, 'Other')]);
      }
      if (mutation == 'delete') {
        await s.h.apply([DeleteSavedMeal(shown.id, shown.version)]);
      }
      if (mutation == 'item') {
        await s.h.write([
          UpdateRow(
            s.h.db.savedMealItems,
            shown.items.first.id,
            const SavedMealItemsCompanion(sortOrder: Value(8)),
          ),
        ]);
      }
      if (mutation == 'removed') {
        await s.h.write([
          TombstoneRow(s.h.db.savedMealItems, shown.items.first.id),
        ]);
      }
      final before = await s.h.raw();
      final result = await s.actions.log(shown, day, lunch) as SavedMealFailed;
      expect(result.reason, SavedMealFailure.changed);
      expect(await s.h.raw(), before);
    }
  });
  test('DY-030 a food chip logs the last-used amount with '
      'the current food values', () async {
    final s = Setup(
      current: FoodChoice(
        food: foodOf(20, kcal: 300),
        measures: FoodMeasures(basis: NutrientBasis.per100g),
      ),
    );
    await s.logHistory();
    await s.logHistory(
      n: 21,
      ref: FoodRef.catalog('food-20', version: '1'),
      date: day,
      slot: DefaultSlots.dinnerId,
      input: 150,
      amount: 150,
    );
    final chip = (await s.chips()).single;
    final result = await s.controller.logChip(chip, day);
    expect(result, isA<QuickAddLogged>());
    final logged = (await s.entries()).singleWhere(
      (entry) => entry.slotId == lunch,
    );
    expect(logged.amount.input, Quantity(75, 'g'));
    expect(logged.food.per100.kcal, 300);
    expect(logged.snapshot.kcal, 225);
    expect(logged.slotId, lunch);
  });
  test('DY-030 a food chip whose unit no longer resolves '
      'logs the history snapshot', () async {
    final s = Setup(
      current: FoodChoice(
        food: foodOf(20, kcal: 300),
        measures: FoodMeasures(basis: NutrientBasis.per100g),
      ),
    );
    await s.logHistory(unit: 'piece', input: 2, amount: 80);
    final chip = (await s.chips()).single;
    expect(chip.choice!.food.per100.kcal, 200);
    expect(await s.controller.logChip(chip, day), isA<QuickAddLogged>());
    final logged = (await s.entries()).single;
    expect(logged.amount.input, Quantity(2, 'piece'));
    expect(logged.amount.amount, 80);
    expect(logged.food.per100.kcal, 200);
    expect(logged.snapshot.kcal, 160);
  });
  test('DY-030 FD-073 a personal-food chip whose serving '
      'was removed falls back to the snapshot with the '
      'observed version; an edit, delete or merge of the '
      'food before the apply → Failed(changed), nothing '
      'written', () async {
    for (final mutation in ['edit', 'delete', 'merge', 'none']) {
      final s = Setup();
      await s.h.apply([
        CreatePersonalFood(
          fixtureId(1),
          draft('Private', servings: [PersonalFoodServing('piece', 40)]),
        ),
        CreatePersonalFood(fixtureId(2), draft('Survivor')),
      ]);
      await s.logHistory(
        ref: FoodRef.personal(fixtureId(1)),
        unit: 'piece',
        input: 2,
        amount: 80,
      );
      await s.h.apply([UpdatePersonalFood(fixtureId(1), 1, draft('Private'))]);
      final chip = (await s.chips()).single;
      expect(chip.choice!.guard, VersionedId(fixtureId(1), 2));
      expect(chip.choice!.food.per100.kcal, 200);
      if (mutation == 'edit') {
        await s.h.apply([UpdatePersonalFood(fixtureId(1), 2, draft('Edited'))]);
      }
      if (mutation == 'delete') {
        await s.h.apply([DeletePersonalFood(VersionedId(fixtureId(1), 2))]);
      }
      if (mutation == 'merge') {
        await s.h.apply([
          MergePersonalFoods(
            survivor: VersionedId(fixtureId(2), 1),
            merged: VersionedId(fixtureId(1), 2),
          ),
          RelinkFoodRefs(
            from: FoodRef.personal(fixtureId(1)),
            to: FoodRef.personal(fixtureId(2)),
          ),
        ]);
      }
      final before = await s.h.raw();
      ChangeSet? sent;
      s.apply = (change) {
        sent = change;
        return s.h.applier.apply(change);
      };
      final result = await s.controller.logChip(chip, day);
      expect(sent!.ops.first, isA<RequirePersonalFood>());
      if (mutation == 'none') {
        expect(result, isA<QuickAddLogged>());
        expect((await s.entries()).single.amount.amount, 80);
      } else {
        expect((result as QuickAddFailed).reason, QuickAddFailure.changed);
        expect(await s.h.raw(), before);
      }
    }
  });
  test('DY-030 a personal-food chip for a food edited or '
      'merged meanwhile → Failed(changed), nothing logged', () async {
    for (final merge in [false, true]) {
      final s = Setup();
      await s.h.seed(entries: 1, items: 1);
      // Remove the saved parent so history is attributed to the food chip.
      await s.h.apply([DeleteSavedMeal(fixtureId(3), 1)]);
      final chip = (await s.chips()).single;
      if (merge) {
        await s.h.apply(s.h.merge());
      } else {
        await s.h.apply([UpdatePersonalFood(fixtureId(2), 1, draft('New'))]);
      }
      final before = await s.h.raw();
      final result = await s.controller.logChip(chip, day) as QuickAddFailed;
      expect(result.reason, QuickAddFailure.changed);
      expect(await s.h.raw(), before);
    }
  });
  test('DY-030 a chip on a past day logs into that day in '
      'the context slot at its default time, and that '
      'entry then suppresses the chip on that day', () async {
    final s = Setup();
    await s.logHistory();
    final past = day.plusDays(-90);
    final chip = (await s.chips(date: past)).single;
    final before = chip.ranked.score;
    final result = await s.controller.logChip(chip, past) as QuickAddLogged;
    expect(result.date, past);
    final logged = (await s.entries(past)).single;
    expect(logged.slotId, lunch);
    expect(logged.time.localDateTime.time, LocalTime(11));
    await settle();
    final after = s.c.read(quickAddChipsProvider(past)).requireValue.single;
    expect(after.ranked.score, closeTo(before * .2, 1e-12));
  });
  test('DY-030 a second tap while the first is pending is '
      'dropped (1 apply)', () async {
    final s = Setup();
    await s.logHistory();
    final chip = (await s.chips()).single;
    final gate = Completer<void>();
    var applies = 0;
    s.apply = (change) async {
      applies++;
      await gate.future;
      return await s.h.applier.apply(change);
    };
    final first = s.controller.logChip(chip, day);
    expect(s.c.read(quickAddControllerProvider), {chip.key});
    expect(await s.controller.logChip(chip, day), isA<QuickAddPending>());
    expect(applies, 1);
    gate.complete();
    await first;
    expect(s.c.read(quickAddControllerProvider), isEmpty);
  });
  testWidgets('DY-030 the chips recompute on a new entry in the '
      'window, a change to the viewed day, a slot change, '
      'the 30-min tick, midnight and resume', (tester) async {
    final clock = ManualClock(DateTime.utc(2026, 10, 17, 12));
    final window = StreamController<List<DiaryEntry>>();
    final viewed = StreamController<DiaryDay>();
    final slots = StreamController<List<MealSlot>>();
    addTearDown(window.close);
    addTearDown(viewed.close);
    addTearDown(slots.close);
    final past = day.plusDays(-90);
    final source = DiaryEntry(
      id: fixtureId(20),
      version: 1,
      time: EntryTime.local(LocalTime(12).on(day.plusDays(-1)), 0),
      localDate: day.plusDays(-1),
      slotId: lunch,
      food: foodOf(20),
      amount: EntryAmount(
        input: Quantity(75, 'g'),
        amount: 75,
        basis: NutrientBasis.per100g,
      ),
      snapshot: foodOf(20).per100.scale(.75),
    );
    final s = Setup(
      clock: clock,
      viewedDate: past,
      viewedInput: viewed.stream,
      windowInput: (today) => today == day ? window.stream : Stream.value([]),
      slotsInput: slots.stream,
      mealsInput: Stream.value([]),
      personalInput: Stream.value([]),
    );
    var emissions = 0;
    s.c.listen(quickAddChipsProvider(past), (_, next) {
      if (next.hasValue) emissions++;
    });
    viewed.add(
      DiaryDay(date: past, slots: DefaultSlots.all, groups: [], entries: []),
    );
    await flush(tester);
    slots.add(DefaultSlots.all);
    window.add([source]);
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 1));
    }
    expect(s.c.read(quickAddChipsProvider(past)).requireValue, hasLength(1));
    final initial = emissions;
    window.add([
      source,
      DiaryEntry(
        id: fixtureId(21),
        version: 1,
        time: source.time,
        localDate: source.localDate,
        slotId: lunch,
        food: source.food,
        amount: source.amount,
        snapshot: source.snapshot,
      ),
    ]);
    await flush(tester);
    expect(emissions, greaterThan(initial));
    final before = s.c
        .read(quickAddChipsProvider(past))
        .requireValue
        .single
        .ranked
        .score;
    viewed.add(
      DiaryDay(
        date: past,
        slots: DefaultSlots.all,
        groups: [],
        entries: [
          DiaryEntry(
            id: fixtureId(30),
            version: 1,
            time: EntryTime.local(LocalTime(11).on(past), 0),
            localDate: past,
            slotId: lunch,
            food: source.food,
            amount: source.amount,
            snapshot: source.snapshot,
          ),
        ],
      ),
    );
    await flush(tester);
    expect(
      s.c.read(quickAddChipsProvider(past)).requireValue.single.ranked.score,
      closeTo(before * .2, 1e-12),
    );
    slots.add([
      MealSlot(
        id: DefaultSlots.dinnerId,
        sortOrder: 0,
        defaultKey: 'dinner',
        window: TimeWindow(0, 1439),
      ),
    ]);
    await flush(tester);
    expect(s.c.read(quickAddContextProvider).slotId, DefaultSlots.dinnerId);
    final tick = s.c.read(quickAddContextProvider);
    clock.advance(const Duration(minutes: 30));
    await tester.pump(const Duration(minutes: 30));
    expect(
      s.c.read(quickAddContextProvider).now.minuteOfDay,
      tick.now.minuteOfDay + 30,
    );
    clock.utc = DateTime.utc(2026, 10, 17, 15, 50);
    slots.add(DefaultSlots.all);
    await flush(tester);
    expect(s.c.read(quickAddContextProvider).slotId, lunch);
    clock.advance(const Duration(minutes: 10));
    await tester.pump(const Duration(minutes: 10));
    await flush(tester);
    expect(s.c.read(quickAddContextProvider).slotId, DefaultSlots.dinnerId);
    clock.utc = DateTime.utc(2026, 10, 17, 23, 50);
    s.c.invalidate(quickAddContextProvider);
    await flush(tester);
    clock.advance(const Duration(minutes: 10));
    await tester.pump(const Duration(minutes: 10));
    expect(s.c.read(quickAddContextProvider).now.date, day.plusDays(1));
    clock.advance(const Duration(hours: 8));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await flush(tester);
    expect(s.c.read(quickAddContextProvider).now.hour, 8);
    s.disposed = true;
    // Dispose lifecycle listeners and timers before fake-time assertions.
    s.c.dispose();
  });
  testWidgets('HM-008 D14 leaving the viewed day (or disposing) before its '
      'frame leaves no input listener and never flips a disposed '
      'activation', (tester) async {
    final other = day.plusDays(-1);
    final last = day.plusDays(-2);
    final gate = StreamController<DiaryDay>();
    final otherGate = StreamController<DiaryDay>();
    final lastGate = StreamController<DiaryDay>();
    addTearDown(gate.close);
    addTearDown(otherGate.close);
    addTearDown(lastGate.close);
    final probes = InputProbes();
    final s = Setup(
      viewedDate: day,
      viewedInput: gate.stream,
      windowInput: (_) => probes.window.stream,
      mealsInput: probes.meals.stream,
      personalInput: probes.personal.stream,
      slotsInput: probes.slots.stream,
      extraDays: {other: otherGate.stream, last: lastGate.stream},
    );
    // Switching the viewed day: day A's chips are dropped before its frame.
    final first = s.c.listen(quickAddChipsProvider(day), (_, _) {});
    gate.add(emptyDay(day));
    await tester.idle();
    expect(s.c.exists(quickAddActivationProvider(day)), isTrue);
    first.close();
    final second = s.c.listen(quickAddChipsProvider(other), (_, _) {});
    otherGate.add(emptyDay(other));
    await tester.idle();
    expect(s.c.exists(quickAddActivationProvider(day)), isFalse);
    expect(probes.starts(), [0, 0, 0, 0]);
    await frame(tester);
    expect(tester.takeException(), isNull, reason: 'no flip once disposed');
    expect(s.c.exists(quickAddActivationProvider(day)), isFalse);
    // Only the day on screen started its inputs; the left day never did.
    expect(probes.starts(), [1, 1, 1, 1]);
    expect(probes.cancels(), [0, 0, 0, 0]);
    second.close();
    await tester.idle();
    expect(probes.cancels(), [1, 1, 1, 1]);
    // Disposing the whole container before a new day's frame.
    s.c.listen(quickAddChipsProvider(last), (_, _) {});
    lastGate.add(emptyDay(last));
    await tester.idle();
    expect(s.c.exists(quickAddActivationProvider(last)), isTrue);
    s.disposeNow();
    await frame(tester);
    expect(tester.takeException(), isNull, reason: 'no flip after dispose');
    expect(probes.starts(), [1, 1, 1, 1], reason: 'nothing subscribed late');
    expect(probes.cancels(), [1, 1, 1, 1], reason: 'no leaked listener');
  });
  testWidgets('HM-008 D14 an activated model cancels all four input '
      'listeners on dispose, and re-activates on the next view', (
    tester,
  ) async {
    final gate = StreamController<DiaryDay>.broadcast();
    addTearDown(gate.close);
    final probes = InputProbes();
    final s = Setup(
      viewedDate: day,
      viewedInput: gate.stream,
      windowInput: (_) => probes.window.stream,
      mealsInput: probes.meals.stream,
      personalInput: probes.personal.stream,
      slotsInput: probes.slots.stream,
    );
    final sub = s.c.listen(quickAddChipsProvider(day), (_, _) {});
    gate.add(emptyDay(day));
    await tester.idle();
    await frame(tester);
    expect(s.c.read(quickAddActivationProvider(day)), isTrue);
    expect(probes.starts(), [1, 1, 1, 1]);
    expect(probes.cancels(), [0, 0, 0, 0], reason: 'live while shown');
    sub.close();
    await tester.idle();
    expect(probes.cancels(), [1, 1, 1, 1], reason: 'all four cancelled');
    expect(probes.starts(), [1, 1, 1, 1]);
    // Viewing the day again waits for a new frame before it subscribes.
    final again = s.c.listen(quickAddChipsProvider(day), (_, _) {});
    gate.add(emptyDay(day));
    await tester.idle();
    expect(s.c.read(quickAddActivationProvider(day)), isFalse);
    expect(probes.starts(), [1, 1, 1, 1]);
    await frame(tester);
    expect(probes.starts(), [2, 2, 2, 2]);
    again.close();
    await tester.idle();
    expect(probes.cancels(), [2, 2, 2, 2]);
    // Disposing the container itself cancels them too.
    s.c.listen(quickAddChipsProvider(day), (_, _) {});
    gate.add(emptyDay(day));
    await tester.idle();
    await frame(tester);
    expect(probes.starts(), [3, 3, 3, 3]);
    s.disposeNow();
    expect(probes.cancels(), [3, 3, 3, 3]);
  });
  test('MN-021 quick-add and saved-meal logging make no API '
      'call (API providers overridden by failing fakes)', () async {
    final service = fixtureService();
    final s = Setup(failApi: true, repository: service.repository);
    await s.h.seed();
    final saved = await s.saved();
    expect(await s.actions.log(saved, day, lunch), isA<SavedMealDone>());
    await s.h.apply([DeleteSavedMeal(saved.id, saved.version)]);
    final chip = (await s.chips()).single;
    expect(await s.controller.logChip(chip, day), isA<QuickAddLogged>());
    await s.logHistory(
      n: 40,
      ref: FoodRef.catalog('usda:rice_white_long_grain_cooked', version: '1'),
    );
    final prepared =
        (await s.chips(
          until: (chips) => chips.any(
            (chip) =>
                chip.ranked.candidate is FoodCandidate &&
                (chip.ranked.candidate as FoodCandidate).foodKey.kind ==
                    FoodRefKind.catalog,
          ),
        )).firstWhere(
          (chip) =>
              chip.ranked.candidate is FoodCandidate &&
              (chip.ranked.candidate as FoodCandidate).foodKey.kind ==
                  FoodRefKind.catalog,
        );
    expect(prepared.choice!.catalogFood, isNotNull);
    expect(await s.controller.logChip(prepared, day), isA<QuickAddLogged>());
    expect(s.apiCalls, 0);
  });
  test('DY-031 rename and delete return typed outcomes; a '
      'stale version → Failed(changed)', () async {
    final s = Setup();
    await s.h.seed();
    final shown = await s.saved();
    expect(
      await s.actions.rename(shown, shown.name),
      isA<SavedMealUnchanged>(),
    );
    expect(await s.actions.rename(shown, ''), isA<SavedMealFailed>());
    final renamed = await s.actions.rename(shown, 'Updated') as SavedMealDone;
    expect(renamed.kind, SavedMealKind.savedMealRenamed);
    expect(
      (await s.actions.delete(shown) as SavedMealFailed).reason,
      SavedMealFailure.changed,
    );
    final latest = await s.saved();
    expect(
      (await s.actions.delete(latest) as SavedMealDone).kind,
      SavedMealKind.savedMealDeleted,
    );
    s.c.listen(savedMealProvider(latest.id), (_, next) {});
    expect(await s.c.read(savedMealProvider(latest.id).future), isNull);
    expect(
      (await s.actions.rename(latest, 'Again') as SavedMealFailed).reason,
      SavedMealFailure.changed,
    );
  });
  test('DY-030 unexpected errors rethrow after pending '
      'cleanup, and a retry works', () async {
    final s = Setup();
    await s.logHistory();
    final chip = (await s.chips()).single;
    s.apply = (_) async => throw StateError('unexpected apply');
    await expectLater(s.controller.logChip(chip, day), throwsStateError);
    expect(s.c.read(quickAddControllerProvider), isEmpty);
    s.apply = null;
    expect(await s.controller.logChip(chip, day), isA<QuickAddLogged>());
  });
}

final class BrokenClock implements Clock {
  @override
  DateTime nowUtc() => throw StateError('unexpected clock');
  @override
  int offsetMinutesAt(DateTime utc) => 0;
}
