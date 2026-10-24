// Benchmark and worked scores use synthetic fixtures only.
// ignore_for_file: avoid_print

import 'dart:math';

import 'package:fb_domain/fb_domain.dart';
import 'package:test/test.dart';

import '../helpers/diary.dart';

final today = LocalDate(2026, 10, 23); // Friday.
const String breakfast = DefaultSlots.breakfastId;
const String dinner = DefaultSlots.dinnerId;
String id(int n) =>
    '0199e3c2-5b1a-7000-8000-${n.toRadixString(16).padLeft(12, '0')}';
String nameKey(String name) => name.trim().toLowerCase();
const ranker = QuickAddRanker(nameKey: nameKey);
const matcher = SavedMealMatcher();
EntryFood food(String key, {FoodRefKind kind = FoodRefKind.catalog}) =>
    EntryFood(
      ref: kind == FoodRefKind.estimate
          ? FoodRef.estimate()
          : FoodRef(kind, id: key),
      names: FoodNames(key),
      per100: rice100,
      provenance: Provenance(
        source: kind == FoodRefKind.estimate
            ? FoodSource.estimate
            : FoodSource.database,
      ),
    );
DiaryEntry e(
  int n,
  String key, {
  int age = 1,
  int minute = 480,
  String slot = breakfast,
  FoodRefKind kind = FoodRefKind.catalog,
  int offset = 0,
}) {
  final date = today.plusDays(-age);
  return DiaryEntry(
    id: id(n),
    version: 1,
    time: EntryTime.local(LocalTime.ofMinuteOfDay(minute).on(date), offset),
    localDate: date,
    slotId: slot,
    food: food(key, kind: kind),
    amount: grams(n.toDouble()),
    snapshot: snapshotOf(100),
  );
}

SavedMeal meal(
  int n,
  List<String> keys, {
  FoodRefKind kind = FoodRefKind.catalog,
}) => SavedMeal(
  id: id(n),
  version: 2,
  name: 'private meal',
  items: [
    for (var i = 0; i < keys.length; i++)
      SavedMealItem(
        id: id(n + i + 10000),
        version: i + 1,
        sortOrder: i,
        food: food(keys[i], kind: kind),
        amount: grams(50),
        snapshot: snapshotOf(100),
      ),
  ],
);
QuickAddContext context({
  int minute = 480,
  String? slot = breakfast,
  LocalDate? target,
}) => QuickAddContext(
  now: LocalTime.ofMinuteOfDay(minute).on(today),
  weekday: today.weekday,
  slotId: slot,
  targetDate: target ?? today,
);
List<RankedChip> rank(
  List<DiaryEntry> entries, {
  List<SavedMeal> meals = const [],
  List<DiaryEntry> target = const [],
  QuickAddContext? ctx,
  Set<FoodKey> live = const {},
  int limit = 6,
}) => ranker.rank(
  windowEntries: entries,
  targetDayEntries: target,
  meals: meals,
  liveFoodKeys: live,
  context: ctx ?? context(),
  limit: limit,
);
SavedMealAttribution match(List<DiaryEntry> entries, List<SavedMeal> meals) =>
    matcher.attribute(entries, meals, nameKey: nameKey);
List<Object> signature(List<RankedChip> chips) => [
  for (final c in chips)
    (
      c.candidate.key,
      c.score,
      c.occurrences,
      c.latestUse,
      c.candidate is FoodCandidate
          ? (c.candidate as FoodCandidate).lastUsed.id
          : '',
    ),
];
List<Object> matches(SavedMealAttribution a) => [
  for (final o in a.mealOccurrences)
    (o.meal.id, o.entries.map((e) => e.id).toList().join(',')),
  a.unassignedEntries.map((e) => e.id).join(','),
];

void main() {
  test('DY-030 at 08:00 breakfast foods outrank dinner foods', () {
    final chips = rank([
      for (var i = 1; i <= 59; i++) ...[
        e(i, 'breakfast', age: i),
        e(i + 100, 'dinner', age: i, minute: 1170, slot: dinner),
      ],
    ]);
    expect(chips.first.candidate.key, 'catalog:breakfast');
    // Exact score for these explicit dates under the D13 formula.
    expect(chips[0].score, closeTo(19.20628354355883, 1e-10));
    expect(chips[1].score, closeTo(chips[0].score * .02, 1e-10));
    print('A09 worked morning: ${chips.map((c) => c.score).toList()}');
  });
  test('DY-030 at 19:30 dinner foods outrank breakfast foods, even a '
      'breakfast food eaten every day', () {
    final chips = rank([
      for (var i = 1; i <= 59; i++) e(i, 'breakfast', age: i),
      e(100, 'dinner', minute: 1170, slot: dinner),
    ], ctx: context(minute: 1170, slot: dinner));
    expect(chips.first.candidate.key, 'catalog:dinner');
    expect(chips.first.score, closeTo(.951695, 1e-6));
    expect(chips.last.score, closeTo(.3841256708711767, 1e-10));
    print('A09 worked evening: ${chips.map((c) => c.score).toList()}');
  });
  test('DY-030 a food eaten 8 times in 4 weeks outranks a one-off '
      'from yesterday in the same slot', () {
    final chips = rank([
      for (var i = 0; i < 8; i++)
        e(i + 1, 'frequent', age: 1 + (i ~/ 2) * 7 + (i % 2) * 2),
      e(100, 'once'),
    ]);
    expect(chips.first.candidate.key, 'catalog:frequent');
    expect(chips.first.score, closeTo(4.7, .1));
    expect(chips.last.score, closeTo(.951695, 1e-6));
    print('A09 worked frequent: ${chips.map((c) => c.score).toList()}');
  });
  test('DY-030 the same weekday counts more (Friday lunch on a Friday)', () {
    final lunchContext = context(minute: 780, slot: DefaultSlots.lunchId);
    final friday = e(
      1,
      'friday',
      age: 7,
      minute: 780,
      slot: DefaultSlots.lunchId,
    );
    final chips = rank([
      friday,
      e(2, 'thursday', age: 8, minute: 780, slot: DefaultSlots.lunchId),
    ], ctx: lunchContext);
    expect(chips.first.score, closeTo(pow(2, -.5) * 1.25, 1e-12));
    expect(chips.first.candidate.key, 'catalog:friday');
    final plain =
        const QuickAddRanker(
          nameKey: nameKey,
          weights: QuickAddWeights(weekdayMultiplier: 1),
        ).rank(
          windowEntries: [friday],
          targetDayEntries: [],
          meals: [],
          liveFoodKeys: {},
          context: lunchContext,
        );
    expect(chips.first.score, plain.first.score * 1.25);
  });
  test('DY-030 with equal counts the more recent wins (14-day half-life)', () {
    final chips = rank([e(1, 'new', age: 7), e(2, 'old', age: 21)]);
    expect(chips.first.candidate.key, 'catalog:new');
    expect(chips.first.score, chips.last.score * 2);
  });
  test("DY-030 entries older than 60 days don't count", () {
    final chips = rank([
      e(1, 'edge', age: 59),
      e(2, 'old', age: 60),
      e(3, 'future', age: -1),
    ]);
    expect(chips.single.candidate.key, 'catalog:edge');
  });
  test(
    'DY-031 a meal with two egg items matches only a slot with two egg entries',
    () {
      final m = meal(100, ['egg', 'egg']);
      expect(match([e(1, 'egg')], [m]).mealOccurrences, isEmpty);
      expect(
        match([e(1, 'egg'), e(2, 'egg')], [m]).mealOccurrences.single.entries,
        hasLength(2),
      );
      expect(
        match([e(1, 'egg'), e(2, 'egg', slot: dinner)], [m]).mealOccurrences,
        isEmpty,
      );
      expect(
        match([e(1, 'egg'), e(2, 'egg', age: 2)], [m]).mealOccurrences,
        isEmpty,
      );
    },
  );
  test('DY-031 overlapping meals: the larger meal is matched first '
      'and a smaller meal can match the leftover entries', () {
    final a = match(
      [e(1, 'egg'), e(2, 'bread'), e(3, 'milk'), e(4, 'egg'), e(5, 'bread')],
      [
        meal(100, ['egg', 'bread']),
        meal(101, ['egg', 'bread', 'milk']),
      ],
    );
    expect(a.mealOccurrences.map((o) => o.meal.id), [id(101), id(100)]);
    expect(a.unassignedEntries, isEmpty);
    // Equal size: distinct-key count first, then meal ID.
    final b = match(
      [e(1, 'egg'), e(2, 'egg'), e(3, 'bread')],
      [
        meal(100, ['egg', 'egg']),
        meal(101, ['egg', 'bread']),
        meal(102, ['egg', 'bread']),
      ],
    );
    expect(b.mealOccurrences.single.meal.id, id(101));
  });
  test(
    "DY-031 items more than 90 min apart in one slot don't form the meal",
    () {
      final m = meal(100, ['egg', 'bread']);
      expect(
        match([e(1, 'egg'), e(2, 'bread', minute: 571)], [m]).mealOccurrences,
        isEmpty,
      );
      expect(
        match([e(1, 'egg'), e(2, 'bread', minute: 570)], [m]).mealOccurrences,
        hasLength(1),
      );
    },
  );
  test('DY-031 a meal logged twice in one slot counts twice; the '
      'earliest entries of each key are selected', () {
    final a = match(
      [
        e(4, 'bread', minute: 500),
        e(2, 'bread', minute: 481),
        e(3, 'egg', minute: 490),
        e(1, 'egg'),
      ],
      [
        meal(100, ['egg', 'bread']),
      ],
    );
    expect(a.mealOccurrences.map((o) => o.entries.map((e) => e.id).toList()), [
      [id(1), id(2)],
      [id(3), id(4)],
    ]);
  });
  test('DY-031 the occurrence time is its earliest selected entry', () {
    final a = match(
      [e(1, 'unrelated'), e(2, 'egg', minute: 490), e(3, 'bread', minute: 500)],
      [
        meal(100, ['egg', 'bread']),
      ],
    );
    expect(a.mealOccurrences.single.first.time.localDateTime.minuteOfDay, 490);
    expect(a.unassignedEntries.single.id, id(1));
  });
  test("DY-030 DY-031 a matched meal's entries don't count for its foods", () {
    final chips = rank(
      [e(1, 'egg'), e(2, 'bread')],
      meals: [
        meal(100, ['egg', 'bread']),
      ],
    );
    expect(chips.single.candidate, isA<SavedMealCandidate>());
    expect(chips.single.occurrences, 1);
    expect(
      (chips.single.candidate as SavedMealCandidate).meal.versions!.items,
      hasLength(2),
    );
  });
  test('DY-030 estimates never become food chips; a saved meal of '
      'estimates still matches by name key', () {
    final entries = [
      e(1, ' Egg ', kind: FoodRefKind.estimate),
      e(2, 'egg', kind: FoodRefKind.estimate),
    ];
    expect(rank(entries), isEmpty);
    expect(
      rank(
        entries,
        meals: [
          meal(100, ['egg'], kind: FoodRefKind.estimate),
        ],
      ).single.occurrences,
      2,
    );
  });
  test(
    'property: matching and ranking give the same result for shuffled inputs',
    () {
      final random = Random(694);
      for (var run = 0; run < 1000; run++) {
        final entries = [
          for (var i = 0; i < 30; i++)
            e(
              i + 1,
              'f${random.nextInt(4)}',
              age: random.nextInt(4),
              minute: 450 + random.nextInt(100),
            ),
        ];
        final meals = [
          meal(100, ['f0', 'f0']),
          meal(101, ['f0', 'f1']),
          meal(102, ['f1', 'f2', 'f3']),
        ];
        final expected = signature(rank(entries, meals: meals));
        final attribution = matches(match(entries, meals));
        entries.shuffle(random);
        meals.shuffle(random);
        for (final m in meals) {
          // SavedMeal also canonicalizes item input order.
          final items = m.items.toList()..shuffle(random);
          expect(meal(999, []).versions, isNull);
          expect(
            SavedMeal(
              id: m.id,
              version: m.version,
              name: m.name,
              items: items,
            ).versions,
            m.versions,
          );
        }
        expect(signature(rank(entries, meals: meals)), expected);
        expect(matches(match(entries, meals)), attribution);
      }
    },
  );
  test('DY-030 logging a candidate on the target day in the context '
      'slot moves it below an unsuppressed one; removing that entry '
      'restores the order', () {
    final entries = [e(1, 'a'), e(2, 'b', age: 2)];
    expect(rank(entries).first.candidate.key, 'catalog:a');
    expect(
      rank(entries, target: [e(3, 'a', age: 0)]).first.candidate.key,
      'catalog:b',
    );
    expect(rank(entries).first.candidate.key, 'catalog:a');
    expect(
      rank(
        entries,
        target: [e(3, 'a', age: 0, slot: dinner)],
      ).first.candidate.key,
      'catalog:a',
    );
    final m = meal(100, ['a']);
    expect(
      rank(entries, meals: [m], target: [e(3, 'a', age: 0)]).last.score,
      closeTo(rank(entries, meals: [m]).first.score * .2, 1e-12),
    );
  });
  test("DY-030 suppression uses the target day's entries even when "
      'the target day is 90 days ago (outside the window)', () {
    final entries = [e(1, 'a'), e(2, 'b', age: 2)];
    final chips = rank(
      entries,
      ctx: context(target: today.plusDays(-90)),
      target: [e(3, 'a', age: 90), e(4, 'b', age: 0)],
    );
    expect(chips.first.candidate.key, 'catalog:b');
  });
  test('DY-030 FD-073 deleted personal foods, deleted saved meals '
      'and saved meals with no live items never become chips or match', () {
    final entries = [e(1, 'personal', kind: FoodRefKind.personal), e(2, 'egg')];
    expect(
      rank(
        entries,
        meals: [
          meal(100, []),
          meal(101, ['personal'], kind: FoodRefKind.personal),
        ],
      ).single.candidate.key,
      'catalog:egg',
    );
    expect(match(entries, [meal(100, [])]).mealOccurrences, isEmpty);
    expect(
      rank(entries, live: {const FoodKey(FoodRefKind.personal, 'personal')}),
      hasLength(2),
    );
    expect(
      rank([e(1, 'egg')], meals: []).single.candidate,
      isA<FoodCandidate>(),
    );
  });
  test('FD-022 the last-used amount is the latest in the context '
      'slot, else the latest overall', () {
    final chips = rank([
      e(1, 'a', age: 3),
      e(2, 'a', slot: dinner),
      e(3, 'b', slot: dinner),
    ]);
    final a =
        chips.firstWhere((c) => c.candidate.key == 'catalog:a').candidate
            as FoodCandidate;
    expect(a.latest.id, id(2));
    expect(a.lastUsed.id, id(1));
    expect(a.lastUsed.amount.input.amount, 1);
    final b =
        chips.firstWhere((c) => c.candidate.key == 'catalog:b').candidate
            as FoodCandidate;
    expect(b.latestInSlot, isNull);
    expect(b.lastUsed.id, id(3));
  });
  test('DY-030 at most 6 chips; order is deterministic (score, '
      'count, latest use, key)', () {
    final entries = [for (var i = 0; i < 9; i++) e(i + 1, 'f$i')];
    expect(rank(entries).map((c) => c.candidate.key), [
      for (var i = 0; i < 6; i++) 'catalog:f$i',
    ]);
    expect(rank(entries, limit: 20), hasLength(6));
    expect(rank(entries, limit: 2), hasLength(2));
    expect(rank(entries, limit: 0), isEmpty);
    expect(rank(entries, ctx: context(slot: null)), isEmpty);
    // Equal scores with different counts; then latest use; then key.
    const flat = QuickAddWeights(
      halfLifeDays: double.infinity,
      weekdayMultiplier: 1,
      slotWeight: 0,
      timeWeight: 0,
      baseline: 1,
    );
    final tied = const QuickAddRanker(nameKey: nameKey, weights: flat).rank(
      windowEntries: [
        e(1, 'a', age: 3),
        e(2, 'b'),
        e(3, 'c'),
        e(4, 'c', age: 2),
      ],
      targetDayEntries: [],
      meals: [],
      liveFoodKeys: {},
      context: context(),
    );
    expect(tied.map((c) => c.candidate.key), [
      'catalog:c',
      'catalog:b',
      'catalog:a',
    ]);
    final countTie =
        const QuickAddRanker(
          nameKey: nameKey,
          weights: QuickAddWeights(
            halfLifeDays: 1,
            weekdayMultiplier: 1,
            slotWeight: 0,
            timeWeight: 0,
            baseline: 1,
          ),
        ).rank(
          windowEntries: [
            e(1, 'once'),
            e(2, 'twice', age: 2),
            e(3, 'twice', age: 2),
          ],
          targetDayEntries: [],
          meals: [],
          liveFoodKeys: {},
          context: context(),
        );
    expect(countTie.first.candidate.key, 'catalog:twice');
  });
  test('property: with suppression fixed, scores are ≥ 0 and adding '
      "an occurrence never lowers a candidate's score", () {
    final random = Random(230);
    for (var run = 0; run < 1000; run++) {
      final entries = [
        for (var i = 0; i < random.nextInt(30) + 1; i++)
          e(i + 1, 'a', age: random.nextInt(60), minute: random.nextInt(1440)),
      ];
      final target = run.isEven ? [e(1000, 'a', age: 0)] : <DiaryEntry>[];
      final before = rank(entries, target: target).single.score;
      final after = rank([
        ...entries,
        e(100, 'a', age: random.nextInt(60)),
      ], target: target).single.score;
      expect(before, greaterThanOrEqualTo(0));
      expect(after, greaterThanOrEqualTo(before));
    }
  });
  test('DY-031 read models and diagnostics expose no private values', () {
    final m = meal(100, ['private ingredient']);
    expect(m.totals.kcal, 100);
    expect(m.versions!.meal, VersionedId(id(100), 2));
    expect(m.items.clear, throwsUnsupportedError);
    final k = FoodKey.of(food('private ingredient'), nameKey: nameKey);
    expect(k, FoodKey.of(food('private ingredient'), nameKey: nameKey));
    expect({
      k,
      const FoodKey(FoodRefKind.catalog, 'private ingredient'),
    }, hasLength(1));
    expect(k == Object(), isFalse);
    expect(k.compareTo(k), 0);
    final chip = rank([e(1, 'private ingredient')]).single;
    final saved = rank([e(1, 'private ingredient')], meals: [m]).single;
    for (final value in [
      m,
      m.items.single,
      k,
      chip,
      chip.candidate,
      saved.candidate,
    ]) {
      expect(value.toString(), isNot(contains('private')));
      expect(value.toString(), isNot(contains('100')));
    }
    final tied = SavedMeal(
      id: id(200),
      version: 1,
      name: 'private',
      items: [
        m.items.single,
        SavedMealItem(
          id: id(99),
          version: 1,
          sortOrder: 0,
          food: food('a'),
          amount: grams(1),
          snapshot: rice100,
        ),
      ],
    );
    expect(tied.items.first.id, id(99));
    final a = e(1, 'a');
    final b = e(2, 'a');
    expect(compareEntryTime(a, b), lessThan(0));
    final midnight = rank([e(1, 'a', minute: 1430)], ctx: context(minute: 10));
    expect(midnight.single.score, greaterThan(.9));
  });
  test('A09 perf quick-add rank over 1,500 entries and 40 saved '
      'meals p95 < 10 ms', () {
    final entries = [
      for (var i = 0; i < 1500; i++)
        e(i + 1, 'f${i % 25}', age: i ~/ 25, minute: 480 + i % 25),
    ];
    final meals = [
      for (var i = 0; i < 40; i++)
        meal(3000 + i, ['f${i * 2}', 'f${i * 2 + 1}']),
    ];
    for (var i = 0; i < 20; i++) {
      rank(entries, meals: meals);
    }
    final times = <double>[];
    for (var i = 0; i < 100; i++) {
      final timer = Stopwatch()..start();
      rank(entries, meals: meals);
      timer.stop();
      times.add(timer.elapsedMicroseconds / 1000);
    }
    times.sort();
    final p95 = times[94];
    print(
      'A09 rank 1500 entries / 40 meals: median ${times[49]} ms; p95 $p95 ms (100 runs)',
    );
    expect(p95, lessThan(10));
  });
}
