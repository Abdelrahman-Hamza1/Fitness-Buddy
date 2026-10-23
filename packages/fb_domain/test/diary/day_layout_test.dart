import 'package:fb_domain/fb_domain.dart';
import 'package:glados/glados.dart';

import '../helpers/diary.dart';
import '../helpers/property.dart';

List<DiaryEntry> flatten(DayLayout layout) => [
  for (final section in layout.sections)
    for (final item in section.items)
      ...switch (item) {
        EntryItem(:final entry) => [entry],
        GroupItem(:final members) => members,
      },
];

void main() {
  test(
    'DY-020 active slots, history, Other, stored totals and immutable models',
    () {
      final inactive = MealSlot(
        id: copyA,
        sortOrder: -1,
        name: 'Historical',
        active: false,
      );
      final otherMode = MealSlot(
        id: copyB,
        sortOrder: -2,
        name: 'Iftar',
        mode: SlotMode.ramadan,
      );
      final tie = MealSlot(id: copyG, sortOrder: 1, name: 'Tie');
      final unused = MealSlot(
        id: savedMeal,
        sortOrder: 9,
        name: 'Unused',
        active: false,
      );
      final rows = [
        entry(snapshot: snapshotOf(0.49)),
        entry(id: entryB, slotId: copyA, snapshot: snapshotOf(0.49)),
        entry(id: entryC, slotId: groupG),
        entry(id: groupG, slotId: copyB),
      ];
      final layout = DayLayout.build(
        [...DefaultSlots.all, inactive, otherMode, tie, unused],
        [],
        rows,
      );
      expect(layout.sections.map((s) => s.key), [
        DefaultSlots.breakfastId,
        copyG,
        DefaultSlots.lunchId,
        ...DefaultSlots.all.skip(2).map((s) => s.id),
        copyB,
        copyA,
        'other',
      ]);
      expect(layout.entryCount, 4);
      expect(layout.isEmpty, isFalse);
      expect(layout.totals, DiaryTotals.day(rows));
      final lunch = layout.sections.firstWhere(
        (s) => s.key == DefaultSlots.lunchId,
      );
      expect(lunch.summaryNames, ['Rice, cooked']);
      expect(lunch.items.single.key, entryA);
      expect(lunch.totals.kcal.round(), 0);
      expect(
        DayLayout.build(DefaultSlots.all, [], rows.take(2)).totals.kcal.round(),
        1,
      );
      expect(layout.sections.clear, throwsUnsupportedError);
      expect(lunch.items.clear, throwsUnsupportedError);
      expect(lunch.summaryNames.clear, throwsUnsupportedError);
      expect(DayLayout.build(DefaultSlots.all, [], []).isEmpty, isTrue);
      expect(
        DayLayout.build(
          DefaultSlots.all.reversed,
          [],
          [],
        ).sections.map((s) => s.key),
        DefaultSlots.all.map((s) => s.id),
      );
      expect(
        DayLayout.build(
          [tie, DefaultSlots.lunch],
          [],
          [],
        ).sections.map((s) => s.key),
        [copyG, DefaultSlots.lunchId],
      );
    },
  );

  test('DY-024 groups sort by first member, split by slot, missing '
      'group falls back', () {
    final group = DishGroup(
      id: groupG,
      version: 1,
      name: 'Dish',
      localDate: LocalDate(2026, 10, 13),
      slotId: DefaultSlots.lunchId,
    );
    final rows = [
      entry(id: entryB, dishGroupId: groupG),
      entry(dishGroupId: groupG),
      entry(id: entryC, slotId: DefaultSlots.dinnerId, dishGroupId: groupG),
      entry(id: copyA, dishGroupId: copyG),
    ];
    final layout = DayLayout.build(DefaultSlots.all, [group], rows);
    final lunch = layout.sections.firstWhere(
      (s) => s.key == DefaultSlots.lunchId,
    );
    final dish = lunch.items.first as GroupItem;
    expect(dish.key, groupG);
    expect(dish.firstEntry.id, entryA);
    expect(dish.members.map((e) => e.id), [entryA, entryB]);
    expect(dish.totals, DiaryTotals.day(rows.take(2)));
    expect(lunch.summaryNames, ['Dish', 'Rice, cooked']);
    expect(layout.sections[2].items.single, isA<GroupItem>());
    expect(flatten(layout).length, rows.length);
    expect(dish.members.clear, throwsUnsupportedError);
  });

  test('DY-020 DY-024 chronological members and item time/id ordering', () {
    DiaryEntry timed(String id, int hour, {String? group}) {
      final base = entry(id: id, dishGroupId: group);
      final time = EntryTime.local(LocalTime(hour).on(base.localDate), 180);
      return DiaryEntry(
        id: base.id,
        version: 1,
        time: time,
        localDate: base.localDate,
        slotId: base.slotId,
        food: base.food,
        amount: base.amount,
        snapshot: base.snapshot,
        dishGroupId: group,
      );
    }

    final group = DishGroup(
      id: groupG,
      version: 1,
      name: 'Dish',
      localDate: LocalDate(2026, 10, 13),
      slotId: DefaultSlots.lunchId,
    );
    final rows = [
      timed(entryA, 14, group: groupG),
      timed(entryB, 10, group: groupG),
      timed(entryC, 9),
      timed(copyA, 10),
    ];
    final layout = DayLayout.build(DefaultSlots.all, [group], rows);
    final items = layout.sections[1].items;
    expect(items.map((e) => e.key), [entryC, groupG, copyA]);
    expect((items[1] as GroupItem).members.map((e) => e.id), [entryB, entryA]);
    final two = DayLayout.build(DefaultSlots.all, [], [
      entry(snapshot: snapshotOf(0.49)),
      entry(
        id: entryB,
        slotId: DefaultSlots.dinnerId,
        snapshot: snapshotOf(0.49),
      ),
    ]);
    expect(two.totals.kcal.round(), 1);
    expect(
      two.sections.fold<int>(0, (sum, s) => sum + s.totals.kcal.round()),
      0,
    );
  });

  Glados(
    any.listWithLengthInRange(0, 60, any.intInRange(0, 100000)),
    propertyRuns,
  ).test('DY-020 DY-024 every entry once, totals agree, '
      'independent of input order (1000)', (values) {
    final rows = [
      for (final (i, v) in values.indexed)
        entry(
          id:
              '0199e3c2-5b1a-7000-8000-'
              '${i.toRadixString(16).padLeft(12, '0')}',
          slotId: DefaultSlots.all[v % 4].id,
          snapshot: snapshotOf(v / 100),
          dishGroupId: v.isEven ? groupG : null,
        ),
    ];
    final group = DishGroup(
      id: groupG,
      version: 1,
      name: 'Dish',
      localDate: LocalDate(2026, 10, 13),
      slotId: DefaultSlots.lunchId,
    );
    final a = DayLayout.build(DefaultSlots.all, [group], rows);
    final b = DayLayout.build(DefaultSlots.all.reversed, [
      group,
    ], rows.reversed);
    expect(flatten(a).map((e) => e.id).toSet(), rows.map((e) => e.id).toSet());
    expect(flatten(a).length, rows.length);
    expect(flatten(a), flatten(b));
    expect(a.totals, DiaryTotals.day(rows));
    for (final section in a.sections) {
      expect(section.totals, DiaryTotals.slot(rows, section.key));
    }
  });
}
