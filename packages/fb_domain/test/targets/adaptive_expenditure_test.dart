import 'dart:math' as math;

import 'package:fb_domain/fb_domain.dart';
import 'package:test/test.dart';

import '../helpers/body.dart';

/// The window's last day in every scenario (day 27 after [day0]).
final LocalDate _end = dayN(27);

/// A deterministic synthetic history (A38 D1 test scenarios): days of
/// intake around [intake] (± [intakeNoise], a fixed pseudo-random pattern)
/// and a weight that follows energy balance against [expenditure]
/// (7,700 kcal/kg), weighed on [weighDays] with ± [weightNoise] kg.
final class _History {
  new({
    this.expenditure = 2500,
    this.intake = 2000,
    this.intakeNoise = 300,
    this.weightNoise = .4,
    Iterable<int>? logDays,
    Iterable<int>? weighDays,
  }) : logDays = (logDays ?? List.generate(28, (i) => i)).toList(),
       weighDays = (weighDays ?? List.generate(28, (i) => i)).toList();

  final double expenditure;
  final double intake;
  final double intakeNoise;
  final double weightNoise;
  final double startKg = 90;
  final List<int> logDays;
  final List<int> weighDays;
  final int seed = 7;

  List<IntakeDay> get intakeDays {
    final random = math.Random(seed);
    return [
      for (final d in logDays)
        IntakeDay(
          date: dayN(d),
          kcal: intake + (random.nextDouble() * 2 - 1) * intakeNoise,
          entryCount: 4,
          mealCount: 3,
        ),
    ];
  }

  List<WeighIn> get weighIns {
    final random = math.Random(seed + 1);
    final perDay = (intake - expenditure) / 7700;
    return [
      for (final (i, d) in weighDays.indexed)
        storedOn(
          dayN(d),
          ((startKg +
                          perDay * d +
                          (random.nextDouble() * 2 - 1) * weightNoise) *
                      10)
                  .roundToDouble() /
              10,
          id: weighInId(i + 1),
        ),
    ];
  }

  AdaptiveResult estimate({
    double prior = 2300,
    List<IntakeDay>? days,
    List<WeighIn>? weighIns,
    bool Function(LocalDate)? isRamadan,
  }) => AdaptiveExpenditure.estimate(
    end: _end,
    days: days ?? intakeDays,
    weighIns: weighIns ?? this.weighIns,
    priorKcal: prior,
    isRamadan: isRamadan,
  );
}

void main() {
  group('TG-030 TG-033 expenditure from synthetic histories', () {
    test('S1 daily weigh-ins and full logging: the truth within 50 kcal, '
        'high confidence, the blend leans on the data', () {
      final result = _History().estimate();
      final e = result.estimate!;
      expect(result.readiness.isReady, isTrue);
      expect(e.dataKcal, closeTo(2500, 50));
      expect(e.confidence, ExpenditureConfidence.high);
      expect(e.weightKgPerWeek, closeTo(-500 * 7 / 7700, .1));
      // Between the prior and the data, much closer to the data.
      expect(e.kcal, greaterThan(2300));
      expect((e.kcal - e.dataKcal).abs(), lessThan((e.kcal - 2300).abs()));
      expect(e.sigmaKcal, lessThan(e.dataSigmaKcal));
      expect(e.windowStart, day0);
      expect(e.windowEnd, _end);
      expect(e.completeDays, 28);
      expect(e.weighIns, 28);
    });

    test('S1b a gain is read as well as a loss', () {
      final e = _History(expenditure: 2200, intake: 2700).estimate().estimate!;
      expect(e.dataKcal, closeTo(2200, 75));
      expect(e.weightKgPerWeek, greaterThan(0));
    });

    test('S2 weekly weigh-ins: within 200 kcal, medium confidence', () {
      final e = _History(weighDays: [0, 7, 14, 21, 27]).estimate().estimate!;
      expect(e.dataKcal, closeTo(2500, 200));
      expect(e.confidence, ExpenditureConfidence.medium);
    });

    test('S3 three weigh-ins over ten days: low confidence, the blend stays '
        'near the formula', () {
      final e = _History(weighDays: [17, 22, 27]).estimate().estimate!;
      expect(e.confidence, ExpenditureConfidence.low);
      final dataShare = (e.kcal - 2300) / (e.dataKcal - 2300);
      expect(dataShare, inInclusiveRange(0, .35));
    });

    test('S9 noisier weigh-ins mean lower confidence', () {
      final calm = _History(weightNoise: .2).estimate().estimate!;
      final noisy = _History(weightNoise: 1.2).estimate().estimate!;
      expect(noisy.dataSigmaKcal, greaterThan(calm.dataSigmaKcal));
      expect(noisy.confidence.index, lessThan(calm.confidence.index));
    });
  });

  group('TG-031 readiness thresholds', () {
    AdaptiveReadiness readiness({
      required List<int> logDays,
      required List<int> weighDays,
      List<int> incomplete = const [],
    }) {
      final h = _History(logDays: logDays, weighDays: weighDays);
      final days = [
        for (final d in h.intakeDays)
          IntakeDay(
            date: d.date,
            kcal: d.kcal,
            entryCount: d.entryCount,
            mealCount: d.mealCount,
            incomplete: incomplete.contains(d.date.epochDay - day0.epochDay),
          ),
      ];
      return h.estimate(days: days).readiness;
    }

    final fourteen = List.generate(14, (i) => 27 - i);
    test('14 logged days ready, 13 not', () {
      final ready = readiness(logDays: fourteen, weighDays: [17, 22, 27]);
      expect(ready.isReady, isTrue);
      final short = readiness(
        logDays: fourteen.sublist(1),
        weighDays: [17, 22, 27],
      );
      expect(short.isReady, isFalse);
      expect(short.daysToLog, 1);
    });

    test('10 complete days ready, 9 not', () {
      final ten = readiness(
        logDays: fourteen,
        incomplete: fourteen.sublist(0, 4),
        weighDays: [17, 22, 27],
      );
      expect(ten.loggedDays, 14);
      expect(ten.completeDays, 10);
      expect(ten.isReady, isTrue);
      final nine = readiness(
        logDays: fourteen,
        incomplete: fourteen.sublist(0, 5),
        weighDays: [17, 22, 27],
      );
      expect(nine.isReady, isFalse);
      expect(nine.completeDaysToLog, 1);
      expect(nine.daysToLog, 0);
    });

    test('3 weigh-ins ready, 2 not ("1 more weigh-in")', () {
      final two = readiness(logDays: fourteen, weighDays: [17, 27]);
      expect(two.isReady, isFalse);
      expect(two.weighInsToLog, 1);
      expect(two.spanDaysToGo, 0);
    });

    test('weigh-ins over 10 days ready, over 9 not', () {
      final nine = readiness(logDays: fourteen, weighDays: [18, 22, 27]);
      expect(nine.isReady, isFalse);
      expect(nine.weighInSpanDays, 9);
      expect(nine.spanDaysToGo, 1);
      expect(nine.weighInsToLog, 0);
      expect(
        readiness(logDays: fourteen, weighDays: [17, 22, 27]).isReady,
        isTrue,
      );
    });

    test('only the window counts: older days and weigh-ins are ignored', () {
      final h = _History();
      final result = AdaptiveExpenditure.estimate(
        end: dayN(60),
        days: h.intakeDays,
        weighIns: h.weighIns,
        priorKcal: 2300,
      );
      expect(result.estimate, isNull);
      expect(result.readiness.loggedDays, 0);
      expect(result.readiness.weighIns, 0);
    });

    test('several weigh-ins on one day count once (the day choice)', () {
      final ws = [
        storedOn(dayN(17), 90, id: weighInId(1)),
        storedOn(dayN(17), 90.4, id: weighInId(2), hour: 9),
        storedOn(dayN(27), 89.6, id: weighInId(3)),
      ];
      final r = _History(logDays: fourteen).estimate(weighIns: ws).readiness;
      expect(r.weighIns, 2);
    });
  });

  group('TG-032 missing and incomplete days', () {
    test('S5 missing days are unknown, not zero: the same intake with gaps '
        'gives the same expenditure', () {
      final full = _History(intakeNoise: 0).estimate().estimate!;
      final gaps = _History(
        intakeNoise: 0,
        logDays: [
          for (var d = 0; d < 28; d++)
            if (d % 3 != 0) d,
        ],
      ).estimate().estimate!;
      expect(gaps.intakeKcal, closeTo(full.intakeKcal, 1e-9));
      expect(gaps.dataKcal, closeTo(full.dataKcal, 1e-9));
      expect(gaps.completeDays, lessThan(full.completeDays));
    });

    test('S6 incomplete days are left out of the average', () {
      final h = _History(intakeNoise: 0);
      final days = [
        ...h.intakeDays.where((d) => d.date != dayN(5)),
        IntakeDay(date: dayN(5), kcal: 600, entryCount: 5, incomplete: true),
      ];
      final e = h.estimate(days: days).estimate!;
      expect(e.intakeKcal, closeTo(2000, 1e-9));
      expect(e.completeDays, 27);
    });

    test('S6b TG-031 an unmarked day that only looks incomplete still '
        'counts: the estimate never leaves days out on its own', () {
      final h = _History(intakeNoise: 0);
      final days = [
        ...h.intakeDays.where((d) => d.date != dayN(5)),
        IntakeDay(date: dayN(5), kcal: 700, entryCount: 1, mealCount: 1),
      ];
      final e = h.estimate(days: days).estimate!;
      expect(e.completeDays, 28);
      expect(e.intakeKcal, closeTo((27 * 2000 + 700) / 28, 1e-9));
      // Readiness: 14 logged, unmarked days are 14 complete ones, however
      // light (TG-031), so 9 normal + 5 light days are ready.
      final mixed = [
        for (var d = 14; d < 28; d++)
          IntakeDay(
            date: dayN(d),
            kcal: d < 19 ? 600 : 2000,
            entryCount: 1,
            mealCount: 1,
          ),
      ];
      final r = h.estimate(days: mixed).readiness;
      expect(r.completeDays, 14);
      expect(r.isReady, isTrue);
    });
  });

  group('intake consistency', () {
    List<WeighIn> flatWeighIns(Iterable<int> days) => [
      for (final d in days) storedOn(dayN(d), 80, id: weighInId(d + 1)),
    ];

    for (final (label, logDays) in [
      ('full', [for (var d = 0; d < 28; d++) d]),
      (
        'partial',
        [
          for (var d = 0; d < 28; d++)
            if (d % 4 != 1) d,
        ],
      ),
    ]) {
      test('S10 $label logging, one mistyped 20,000 kcal day: counted as '
          'logged, flagged, never high confidence', () {
        final h = _History(intakeNoise: 0, logDays: logDays);
        final days = [
          ...h.intakeDays.where((d) => d.date != dayN(8)),
          IntakeDay(date: dayN(8), kcal: 20000, entryCount: 2, mealCount: 2),
        ];
        final n = days.length;
        final e = h
            .estimate(days: days, weighIns: flatWeighIns(logDays), prior: 2000)
            .estimate!;
        expect(e.anomalyDates, [dayN(8)]);
        expect(e.intakeKcal, closeTo((2000 * (n - 1) + 20000) / n, 1e-6));
        expect(e.confidence, isNot(ExpenditureConfidence.high));
        expect(e.dataSigmaKcal, greaterThan(200));
        // Confirmed by the user: no longer an anomaly.
        final confirmed = [
          ...h.intakeDays.where((d) => d.date != dayN(8)),
          IntakeDay(
            date: dayN(8),
            kcal: 20000,
            entryCount: 2,
            mealCount: 2,
            confirmed: true,
          ),
        ];
        expect(
          h
              .estimate(
                days: confirmed,
                weighIns: flatWeighIns(logDays),
                prior: 2000,
              )
              .estimate!
              .anomalyDates,
          isEmpty,
        );
      });

      test('S13 $label logging, genuine weekly 4,000 kcal days: the real '
          'average, nothing flagged', () {
        final h = _History(intakeNoise: 0, logDays: logDays);
        final days = [
          for (final d in h.intakeDays)
            IntakeDay(
              date: d.date,
              kcal: (d.date.epochDay - day0.epochDay) % 7 == 3 ? 4000 : 2000,
              entryCount: 4,
              mealCount: 3,
            ),
        ];
        final mean = days.fold<double>(0, (s, d) => s + d.kcal) / days.length;
        final e = h
            .estimate(days: days, weighIns: flatWeighIns(logDays))
            .estimate!;
        expect(e.anomalyDates, isEmpty);
        expect(e.intakeKcal, closeTo(mean, 1e-6));
        // Flat weight: expenditure ≈ the real average intake (≈ 2,286).
        expect(e.dataKcal, closeTo(mean, 1e-6));
        expect(e.kcal, closeTo(2290, 25));
        expect(
          AdaptiveCheckIn.propose(
            current: 2300,
            recommended: e.kcal,
            floor: 1500,
          ),
          isNull,
        );
      });
    }

    test('S11 full logging keeps an intake term: noisier logging means a '
        'wider uncertainty', () {
      final calm = _History(intakeNoise: 50).estimate().estimate!;
      final noisy = _History(intakeNoise: 900).estimate().estimate!;
      expect(noisy.dataSigmaKcal, greaterThan(calm.dataSigmaKcal));
    });

    test('S12 partial logging (two days in three) widens the uncertainty '
        'and stays within tolerance', () {
      final full = _History().estimate().estimate!;
      final partial = _History(
        logDays: [
          for (var d = 0; d < 28; d++)
            if (d % 3 != 0) d,
        ],
      ).estimate().estimate!;
      expect(partial.dataSigmaKcal, greaterThan(full.dataSigmaKcal));
      expect(partial.dataKcal, closeTo(2500, 120));
      expect(partial.anomalyDates, isEmpty);
    });
  });

  group('outliers and Ramadan', () {
    test('S7 one wild weigh-in is dropped and barely moves the estimate', () {
      final h = _History();
      final clean = h.estimate().estimate!;
      final ws = [...h.weighIns];
      final wild = ws[14];
      ws[14] = storedOn(wild.localDate, wild.kg + 4, id: wild.id);
      final e = h.estimate(weighIns: ws).estimate!;
      expect(e.droppedWeighIns, 1);
      expect(e.weighIns, 27);
      expect(e.dataKcal, closeTo(clean.dataKcal, 60));
      expect(clean.droppedWeighIns, 0);
    });

    test('S7b with three weigh-ins nothing is dropped', () {
      final ws = [
        storedOn(dayN(17), 90, id: weighInId(1)),
        storedOn(dayN(22), 95, id: weighInId(2)),
        storedOn(dayN(27), 89.5, id: weighInId(3)),
      ];
      final e = _History().estimate(weighIns: ws).estimate!;
      expect(e.droppedWeighIns, 0);
      expect(e.weighIns, 3);
    });

    test('S8 TG-037 Ramadan weigh-ins count less: wider uncertainty', () {
      final h = _History(weighDays: [0, 7, 14, 21, 27]);
      final normal = h.estimate().estimate!;
      final ramadan = h.estimate(isRamadan: (d) => true).estimate!;
      expect(ramadan.dataSigmaKcal, greaterThan(normal.dataSigmaKcal));
    });

    test('a non-positive prior is refused', () {
      expect(() => _History().estimate(prior: 0), throwsArgumentError);
    });
  });

  group('DY-004 incomplete-day rule', () {
    test('under half of the reference in fewer than two meals, only', () {
      bool matches(
        double kcal,
        int entries,
        int meals, {
        bool marked = false,
      }) => IncompleteDayRule.matches(
        kcal: kcal,
        entryCount: entries,
        mealCount: meals,
        referenceKcal: 2000,
        incomplete: marked,
      );
      expect(matches(999, 2, 1), isTrue);
      expect(matches(1000, 2, 1), isFalse, reason: 'exactly half');
      expect(matches(500, 3, 2), isFalse, reason: 'two meals');
      expect(matches(0, 0, 0), isFalse, reason: 'nothing logged: unknown');
      expect(matches(500, 1, 1, marked: true), isFalse, reason: 'answered');
      expect(
        IncompleteDayRule.matches(
          kcal: 100,
          entryCount: 1,
          mealCount: 1,
          referenceKcal: 0,
        ),
        isFalse,
      );
    });
  });
}
