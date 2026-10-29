import 'package:fb_domain/fb_domain.dart';
import 'package:glados/glados.dart';

import '../helpers/property.dart';

extension on Any {
  Generator<LiftedSet> get liftedSet => combine2(
    intInRange(0, 4001).map((quarter) => quarter / 4),
    intInRange(1, 31),
    (kg, reps) => (kg: kg, reps: reps),
  );
}

void main() {
  test('WO-042 Epley e1RM: a single is its weight, reps scale by 1/30', () {
    expect(epleyE1rm(100, 1), 100);
    expect(epleyE1rm(100, 10), closeTo(133.333, 0.001));
    expect(epleyE1rm(80, 8), closeTo(101.333, 0.001));
    expect(epleyE1rm(0, 12), 0);
  });

  test('WO-042 e1RM rejects zero reps and non-finite weights', () {
    expect(() => epleyE1rm(80, 0), throwsArgumentError);
    expect(() => epleyE1rm(double.nan, 5), throwsArgumentError);
    expect(() => epleyE1rm(-1, 5), throwsArgumentError);
  });

  test('WO-042 records: heaviest, best e1RM, most reps at a weight', () {
    final records = PersonalRecords.of([
      (kg: 80, reps: 8),
      (kg: 85, reps: 5),
      (kg: 80, reps: 10),
      (kg: 90, reps: 1),
    ]);
    expect(records.heaviestKg, 90);
    expect(records.bestE1rm, closeTo(106.667, 0.001)); // 80 × 10
    expect(records.mostRepsByKg, {80.0: 10, 85.0: 5, 90.0: 1});
  });

  test('WO-042 the first set beats every record; ties beat none', () {
    expect(PersonalRecords.none.newRecords((kg: 60, reps: 5)), {
      PrKind.heaviest,
      PrKind.e1rm,
      PrKind.repsAtWeight,
    });
    final records = PersonalRecords.of([(kg: 60, reps: 5)]);
    expect(records.newRecords((kg: 60, reps: 5)), isEmpty);
    expect(records.newRecords((kg: 60, reps: 6)), {
      PrKind.e1rm,
      PrKind.repsAtWeight,
    });
    expect(records.newRecords((kg: 40, reps: 6)), {PrKind.repsAtWeight});
  });

  test('WO-042 lb and kg sets meet on the 0.25 kg grid', () {
    expect(PersonalRecords.keyOf(176.37 * 0.45359237), 80);
    expect(PersonalRecords.keyOf(82.4), 82.5);
  });

  test('WO-042 bodyweight sets with no added load count for reps only', () {
    final records = PersonalRecords.of([(kg: 0, reps: 12)]);
    expect(records.heaviestKg, isNull);
    expect(records.bestE1rm, isNull);
    expect(records.mostRepsByKg, {0.0: 12});
  });

  Glados2(any.list(any.liftedSet), any.list(any.liftedSet), propertyRuns).test(
    'WO-042 PRs never decrease when sessions are added',
    (before, added) {
      final old = PersonalRecords.of(before);
      final now = PersonalRecords.of([...before, ...added]);
      if (old.heaviestKg != null) {
        expect(now.heaviestKg, greaterThanOrEqualTo(old.heaviestKg!));
      }
      if (old.bestE1rm != null) {
        expect(now.bestE1rm, greaterThanOrEqualTo(old.bestE1rm!));
      }
      for (final MapEntry(:key, :value) in old.mostRepsByKg.entries) {
        expect(now.mostRepsByKg[key], greaterThanOrEqualTo(value));
      }
    },
  );

  Glados(any.list(any.liftedSet), propertyRuns).test(
    'WO-042 records are the maxima over all sets, in any order',
    (sets) {
      final records = PersonalRecords.of(sets);
      final reversed = PersonalRecords.of(sets.reversed);
      expect(reversed.heaviestKg, records.heaviestKg);
      expect(reversed.bestE1rm, records.bestE1rm);
      expect(reversed.mostRepsByKg, records.mostRepsByKg);
    },
  );
}
