import 'package:fb_domain/fb_domain.dart';
import 'package:glados/glados.dart';

import '../helpers/diary.dart';
import '../helpers/property.dart';

const List<String> _slots = [
  DefaultSlots.breakfastId,
  DefaultSlots.lunchId,
  DefaultSlots.snacksId,
];

/// One entry's snapshot in whole hundredths, as stored.
typedef _Row = ({
  int slot,
  int kcal,
  int protein,
  int carbs,
  int fat,
  int fiber,
});

String _id(int i) =>
    '0199e3c2-5b1a-7000-8000-${i.toRadixString(16).padLeft(12, '0')}';

List<DiaryEntry> _entries(List<_Row> rows) => [
  for (final (i, row) in rows.indexed)
    entry(
      id: _id(i),
      slotId: _slots[row.slot],
      snapshot: Nutrients(
        kcal: row.kcal / 100,
        protein: row.protein / 100,
        carbs: row.carbs / 100,
        fat: row.fat / 100,
        fiber: row.fiber / 100,
      ),
    ),
];

void main() {
  group('totals:', () {
    test('totals: day totals = Nutrients.sum of snapshots', () {
      final entries = [
        entry(snapshot: snapshotOf(195.1, protein: 4.05)),
        entry(
          id: entryB,
          slotId: DefaultSlots.dinnerId,
          snapshot: snapshotOf(0.2, protein: 0.1),
        ),
        entry(id: entryC, snapshot: snapshotOf(0.1, protein: 0.2)),
      ];
      final day = DiaryTotals.day(entries);
      expect(day.kcal, 195.4);
      expect(day.protein, 4.35);
      expect(day.carbs, 6);
      expect(day.fat, 9);
      expect(day.fiber, 1.5);
      expect(DiaryTotals.slot(entries, DefaultSlots.lunchId).kcal, 195.2);
      expect(DiaryTotals.slot(entries, DefaultSlots.dinnerId).kcal, 0.2);
      expect(DiaryTotals.slot(entries, DefaultSlots.snacksId), Nutrients.zero);
      expect(DiaryTotals.day(const []), Nutrients.zero);
      final bySlot = DiaryTotals.bySlot(entries);
      expect(bySlot.keys, {DefaultSlots.lunchId, DefaultSlots.dinnerId});
      expect(bySlot[DefaultSlots.lunchId]!.kcal, 195.2);
      expect(bySlot.clear, throwsUnsupportedError);
    });

    test('totals: an extra is totalled only when every entry has it', () {
      final withSodium = entry(
        snapshot: snapshotOf(
          100,
          extras: {NutrientKey.sodium: 120.5, NutrientKey.sugar: 3},
        ),
      );
      final alsoSodium = entry(
        id: entryB,
        snapshot: snapshotOf(50, extras: {NutrientKey.sodium: 30}),
      );
      final noExtras = entry(id: entryC, snapshot: snapshotOf(10));
      expect(DiaryTotals.day([withSodium, alsoSodium]).extras, {
        NutrientKey.sodium: 150.5,
      });
      expect(
        DiaryTotals.day([withSodium, alsoSodium, noExtras]).extras,
        isEmpty,
      );
      expect(DiaryTotals.day([withSodium]).extras, {
        NutrientKey.sodium: 120.5,
        NutrientKey.sugar: 3,
      });
    });
  });

  group('totals properties:', () {
    final row = any.combine6(
      any.intInRange(0, _slots.length),
      any.intInRange(0, 200001),
      any.intInRange(0, 15001),
      any.intInRange(0, 30001),
      any.intInRange(0, 15001),
      any.intInRange(0, 5001),
      (slot, kcal, protein, carbs, fat, fiber) => (
        slot: slot,
        kcal: kcal,
        protein: protein,
        carbs: carbs,
        fat: fat,
        fiber: fiber,
      ),
    );

    Glados2(
      any.listWithLengthInRange(0, 40, row),
      any.intInRange(0, 40),
      propertyRuns,
    ).test('property: day totals equal the sum of the stored snapshots and of '
        'the slot totals, and are order-independent (within 0.01)', (
      rows,
      rotateBy,
    ) {
      final entries = _entries(rows);
      final day = DiaryTotals.day(entries);

      // The exact sum, in whole hundredths.
      int sum(int Function(_Row) field) =>
          rows.fold(0, (total, row) => total + field(row));
      expect(day.kcal, sum((r) => r.kcal) / 100);
      expect(day.protein, sum((r) => r.protein) / 100);
      expect(day.carbs, sum((r) => r.carbs) / 100);
      expect(day.fat, sum((r) => r.fat) / 100);
      expect(day.fiber, sum((r) => r.fiber) / 100);

      // Order-independent.
      final shift = entries.isEmpty ? 0 : rotateBy % entries.length;
      final rotated = [...entries.skip(shift), ...entries.take(shift)];
      expect(DiaryTotals.day(rotated), day);
      expect(DiaryTotals.day(entries.reversed), day);

      // The day is the sum of its slots.
      final ofSlots = DiaryTotals.bySlot(entries).values;
      final slotSum = Nutrients.sum(ofSlots);
      expect((slotSum.kcal - day.kcal).abs(), lessThan(0.01));
      expect(slotSum.rounded(), day);
      expect(
        Nutrients.sum([
          for (final slot in _slots) DiaryTotals.slot(entries, slot),
        ]).rounded(),
        day,
      );
    });
  });
}
