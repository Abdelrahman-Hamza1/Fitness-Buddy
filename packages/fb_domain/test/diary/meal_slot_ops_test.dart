import 'package:fb_domain/fb_domain.dart';
import 'package:glados/glados.dart';

import '../helpers/property.dart';

const String a = DefaultSlots.lunchId;
const String b = DefaultSlots.snacksId;
void main() {
  test('DY-010 SlotContents constructor: no duplicates; toString shows '
      'counts only', () {
    final v = VersionedId(a, 1);
    expect(() => SlotContents(entries: [v, v]), throwsArgumentError);
    expect(() => SlotContents(groups: [v, v]), throwsArgumentError);
    final shown = SlotContents(
      entries: [v],
      groups: [VersionedId(b, 2)],
      dates: ['2026-10-24'],
    );
    expect(shown.toString(), 'SlotContents(1 entries, 1 groups, 1 days)');
    expect(
      shown ==
          SlotContents(
            entries: [v],
            groups: [VersionedId(b, 2)],
            dates: ['2026-10-24'],
          ),
      isTrue,
    );
    expect(
      shown.hashCode,
      SlotContents(
        entries: [v],
        groups: [VersionedId(b, 2)],
        dates: ['2026-10-24'],
      ).hashCode,
    );
    expect(shown == SlotContents.empty, isFalse);
    expect(
      shown == SlotContents(entries: [v], groups: [VersionedId(b, 2)]),
      isFalse,
    );
    expect(
      shown ==
          SlotContents(
            entries: [v],
            groups: [VersionedId(b, 2)],
            dates: ['2026-10-23'],
          ),
      isFalse,
    );
    expect(shown == SlotContents(entries: [v]), isFalse);
    expect(
      shown ==
          SlotContents(
            entries: [VersionedId(a, 2)],
            groups: [VersionedId(b, 2)],
            dates: ['2026-10-24'],
          ),
      isFalse,
    );
    expect(SlotContents.empty.isEmpty, isTrue);
    expect(SlotContents(groups: [v]).isEmpty, isFalse);
    expect(shown.isEmpty, isFalse);
    expect(shown.entries.clear, throwsUnsupportedError);
    expect(shown.groups.clear, throwsUnsupportedError);
    expect(shown.dates.clear, throwsUnsupportedError);
  });
  test('DY-010 toString of every MealSlotOp shows no names', () {
    final window = TimeWindow(1020, 1080);
    final patch = MealSlotPatch(
      name: 'Private name',
      setName: true,
      window: window,
      setWindow: true,
    );
    final pairs = <(MealSlotOp, MealSlotOp)>[
      (
        AddMealSlot(a, 'Private name', window: window),
        AddMealSlot(a, 'Private name', window: TimeWindow(1020, 1080)),
      ),
      (
        UpdateMealSlot(a, 1, patch),
        UpdateMealSlot(
          a,
          1,
          MealSlotPatch(
            name: 'Private name',
            setName: true,
            window: window,
            setWindow: true,
          ),
        ),
      ),
      (
        ReorderMealSlots([VersionedId(a, 1), VersionedId(b, 2)]),
        ReorderMealSlots([VersionedId(a, 1), VersionedId(b, 2)]),
      ),
      (
        RemoveMealSlot(
          a,
          1,
          expected: SlotContents.empty,
          moveTo: VersionedId(b, 2),
        ),
        RemoveMealSlot(
          a,
          1,
          expected: SlotContents.empty,
          moveTo: VersionedId(b, 2),
        ),
      ),
    ];
    for (final (op, equal) in pairs) {
      expect(op.family, 'mealSlot');
      expect(op, equal);
      expect(op.hashCode, equal.hashCode);
      expect(op == Object(), isFalse);
      expect(op.toString(), isNot(contains('Private name')));
    }
    expect(patch.toString(), 'MealSlotPatch');
    expect(patch.hashCode, (pairs[1].$2 as UpdateMealSlot).patch.hashCode);
    expect(patch == MealSlotPatch(setName: true), isFalse);
    expect(
      patch == MealSlotPatch(name: 'Private name', setName: true),
      isFalse,
    );
    expect(patch == MealSlotPatch(window: window, setWindow: true), isFalse);
    expect(
      MealSlotPatch(setName: true) == MealSlotPatch(setWindow: true),
      isFalse,
    );
    expect(
      pairs[0].$1 == AddMealSlot(b, 'Private name', window: window),
      isFalse,
    );
    expect(pairs[0].$1 == AddMealSlot(a, 'Other', window: window), isFalse);
    expect(pairs[0].$1 == AddMealSlot(a, 'Private name'), isFalse);
    expect(pairs[1].$1 == UpdateMealSlot(b, 1, patch), isFalse);
    expect(pairs[1].$1 == UpdateMealSlot(a, 2, patch), isFalse);
    expect(
      pairs[1].$1 == UpdateMealSlot(a, 1, MealSlotPatch(setName: true)),
      isFalse,
    );
    expect(
      pairs[2].$1 == ReorderMealSlots([VersionedId(b, 2), VersionedId(a, 1)]),
      isFalse,
    );
    expect(pairs[2].$1 == ReorderMealSlots([VersionedId(a, 1)]), isFalse);
    expect(
      pairs[3].$1 == RemoveMealSlot(b, 1, expected: SlotContents.empty),
      isFalse,
    );
    expect(
      pairs[3].$1 == RemoveMealSlot(a, 2, expected: SlotContents.empty),
      isFalse,
    );
    expect(
      pairs[3].$1 ==
          RemoveMealSlot(
            a,
            1,
            expected: SlotContents(entries: [VersionedId(b, 1)]),
          ),
      isFalse,
    );
    expect(
      pairs[3].$1 == RemoveMealSlot(a, 1, expected: SlotContents.empty),
      isFalse,
    );
    final e = MealSlotsChanged([a, b]);
    expect(e, MealSlotsChanged([b, a]));
    expect(e.hashCode, MealSlotsChanged([b, a]).hashCode);
    expect(e == Object(), isFalse);
    expect(e == MealSlotsChanged([a]), isFalse);
    expect(e == MealSlotsChanged([a, DefaultSlots.dinnerId]), isFalse);
    expect(e.toString(), 'MealSlotsChanged(2)');
    expect(e.slotIds.clear, throwsUnsupportedError);
  });
  test('DY-010 add and rename reject remaining Unicode controls '
      'after normalization', () {
    for (final code in [
      0,
      1,
      0x1f,
      0x7f,
      0x80,
      0x9f,
      0xad,
      0x600,
      0x61c,
      0x200b,
      0x200e,
      0x202a,
      0x202e,
      0x2066,
      0x2069,
      0xe0001,
    ]) {
      final name = 'Meal${String.fromCharCode(code)}name';
      expect(
        () => AddMealSlot(a, name),
        throwsArgumentError,
        reason: 'add U+${code.toRadixString(16)}',
      );
      expect(
        () => UpdateMealSlot(a, 1, MealSlotPatch(name: name, setName: true)),
        throwsArgumentError,
        reason: 'rename U+${code.toRadixString(16)}',
      );
    }
    expect(AddMealSlot(a, ' Meal\t\n name ').name, 'Meal name');
    expect(
      UpdateMealSlot(
        a,
        1,
        MealSlotPatch(name: ' Meal\t\n name ', setName: true),
      ).patch.name,
      'Meal name',
    );
  });
  test('DY-010 malformed slot commands fail before apply', () {
    expect(() => AddMealSlot('bad', 'Meal'), throwsArgumentError);
    for (final name in ['', ' ', 'a' * 31, 'a\u0000']) {
      expect(() => AddMealSlot(a, name), throwsArgumentError);
    }
    expect(MealSlotPatch.new, throwsArgumentError);
    expect(
      () => MealSlotPatch(name: 'Name', setWindow: true),
      throwsArgumentError,
    );
    expect(
      () => MealSlotPatch(window: TimeWindow(1, 2), setName: true),
      throwsArgumentError,
    );
    expect(
      () => MealSlotPatch(name: 'a' * 31, setName: true),
      throwsArgumentError,
    );
    expect(MealSlotPatch(name: '  ', setName: true).name, '');
    expect(
      () => UpdateMealSlot('bad', 1, MealSlotPatch(setName: true)),
      throwsArgumentError,
    );
    expect(
      () => UpdateMealSlot(a, 0, MealSlotPatch(setName: true)),
      throwsArgumentError,
    );
    expect(
      () => RemoveMealSlot('bad', 1, expected: SlotContents.empty),
      throwsArgumentError,
    );
    expect(
      () => RemoveMealSlot(a, 0, expected: SlotContents.empty),
      throwsArgumentError,
    );
    expect(() => ReorderMealSlots([]), throwsArgumentError);
    expect(
      () => ReorderMealSlots([VersionedId(a, 1), VersionedId(a, 2)]),
      throwsArgumentError,
    );
    expect(
      () => ReorderMealSlots([VersionedId(a, 1)]).order.clear(),
      throwsUnsupportedError,
    );
  });
  test(
    'DY-010 MealSlotRules normalize, insert, renumber and overnight lengths',
    () {
      expect(MealSlotRules.normalizeName('  Pre \n workout  '), 'Pre workout');
      expect(MealSlotRules.nameMax, 30);
      expect(MealSlotRules.maxActive, 8);
      expect(MealSlotRules.windowMinutes(TimeWindow(22 * 60, 2 * 60)), 240);
      expect(MealSlotRules.insertIndex(DefaultSlots.all, TimeWindow(0, 1)), 0);
      expect(
        MealSlotRules.insertIndex(
          DefaultSlots.all,
          TimeWindow(17 * 60, 18 * 60),
        ),
        3,
      );
      expect(MealSlotRules.insertIndex(DefaultSlots.all, null), 4);
      expect(
        MealSlotRules.insertIndex([
          DefaultSlots.breakfast,
        ], TimeWindow(17 * 60, 18 * 60)),
        1,
      );
      expect(MealSlotRules.renumber([b, a]), {b: 0, a: 1});
    },
  );
  test('DY-011 SlotAssigner D9: Pre-workout 17:00–18:00 catches 17:30 '
      'over Dinner 16:00–22:00; equal lengths fall back to sortOrder '
      'then id', () {
    final narrow = MealSlot(
      id: a,
      name: 'Pre workout',
      sortOrder: 9,
      window: TimeWindow(17 * 60, 18 * 60),
    );
    const assigner = SlotAssigner();
    expect(
      assigner.assign(17 * 60 + 30, [
        DefaultSlots.dinner,
        narrow,
      ], SlotMode.normal),
      a,
    );
    final tie = MealSlot(
      id: b,
      name: 'Tie',
      sortOrder: 9,
      window: TimeWindow(17 * 60, 18 * 60),
    );
    expect(
      assigner.assign(17 * 60 + 30, [tie, narrow], SlotMode.normal),
      ([a, b]..sort()).first,
    );
  });
  Glados2(any.intInRange(0, 1440), any.intInRange(0, 1440), propertyRuns).test(
    "property: with non-overlapping windows the D9 rule equals A06's rule",
    (offset, minute) {
      final slots = [
        for (var i = 0; i < 4; i++)
          MealSlot(
            id: DefaultSlots.all[i].id,
            name: 'Meal',
            sortOrder: 3 - i,
            window: TimeWindow(
              (offset + i * 360) % 1440,
              (offset + (i + 1) * 360) % 1440,
            ),
          ),
      ];
      final expected = slots.singleWhere((s) => s.window!.contains(minute)).id;
      expect(
        const SlotAssigner().assign(minute, slots, SlotMode.normal),
        expected,
      );
    },
  );
}
