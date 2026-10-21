import 'package:fb_domain/fb_domain.dart';
import 'package:test/test.dart';

String _id(int value) =>
    '0199e3c2-5b1a-7000-8000-${value.toRadixString(16).padLeft(12, '0')}';

final saturday = LocalDate(2026, 10, 17);
TargetPlan plan(double kcal, {TargetMode mode = TargetMode.weekly}) =>
    TargetPlan(baseKcal: kcal, floorKcal: 1500, mode: mode);

void main() {
  test(
    'TG-060 G10 date revisions recompute historical days including midweek',
    () {
      final first = TargetSettings(
        id: _id(1),
        version: 1,
        effectiveFrom: saturday,
        standard: plan(2000),
      );
      final second = TargetSettings(
        id: _id(2),
        version: 2,
        effectiveFrom: saturday.plusDays(3),
        standard: plan(2200),
      );
      final history = TargetSettingsHistory([second, first]);
      expect(history.versions, [first, second]);
      expect(history.at(saturday.plusDays(-1)), isNull);
      for (var i = 0; i < 7; i++) {
        final date = saturday.plusDays(i);
        final revision = history.at(date)!;
        final day = revision.plan().day(date: date, weightKg: 70);
        expect(revision.version, i < 3 ? 1 : 2);
        expect(day.kcal, closeTo(i < 3 ? 2000 : 2200, 1e-7));
        expect(day.macros.kcal, day.kcal);
        expect(day.week, isNotNull);
        expect(day.manual, isFalse);
        expect(day.acknowledged, isFalse);
      }
      expect(history.versions.clear, throwsUnsupportedError);
      expect(TargetSettingsHistory([]).at(saturday), isNull);
      expect(
        () => TargetSettings(
          id: _id(0),
          version: 0,
          effectiveFrom: saturday,
          standard: plan(2000),
        ),
        throwsArgumentError,
      );
      expect(
        () => TargetSettingsHistory.validateForWrite([
          first,
          TargetSettings(
            id: _id(2),
            version: 2,
            effectiveFrom: saturday,
            standard: plan(2200),
          ),
        ]),
        throwsArgumentError,
      );
      expect(
        () => TargetSettingsHistory.validateForWrite([
          first,
          TargetSettings(
            id: _id(1),
            version: 1,
            effectiveFrom: saturday.plusDays(2),
            standard: plan(2200),
          ),
        ]),
        throwsArgumentError,
      );
    },
  );

  test('TG-060 Ramadan variant selects without modifying normal history', () {
    final standard = plan(2000);
    final ramadan = plan(2200, mode: TargetMode.fixed);
    final settings = TargetSettings(
      id: _id(1),
      version: 1,
      effectiveFrom: saturday,
      standard: standard,
      ramadan: ramadan,
    );
    expect(settings.ramadan, ramadan);
    expect(settings.plan(ramadanActive: true), ramadan);
    expect(settings.plan(), standard);
    final absent = TargetSettings(
      id: _id(1),
      version: 1,
      effectiveFrom: saturday,
      standard: standard,
    );
    expect(absent.plan(ramadanActive: true), standard);
  });

  test(
    'SF-012 acknowledged manual fixed target is separate from generators',
    () {
      final manual = TargetPlan(
        baseKcal: 1000,
        floorKcal: 1600,
        mode: TargetMode.fixed,
        manual: true,
        acknowledged: true,
      );
      final day = manual.day(date: saturday, weightKg: 70);
      expect(day.kcal, 1000);
      expect(day.week, isNull);
      expect(day.manual, isTrue);
      expect(day.acknowledged, isTrue);
      expect(manual.mode, TargetMode.fixed);
      expect(manual.rebalancing, isTrue);
      expect(manual.floorKcal, 1600);
      expect(manual.macros.caloriesProteinOnly, isFalse);
      expect(manual.weights, isEmpty);
      for (final bad in [
        () => TargetPlan(baseKcal: 1000, floorKcal: 1600),
        () =>
            TargetPlan(baseKcal: 1000, floorKcal: 1600, mode: TargetMode.fixed),
        () => TargetPlan(
          baseKcal: 1000,
          floorKcal: 1600,
          mode: TargetMode.fixed,
          manual: true,
        ),
        () => TargetPlan(
          baseKcal: 1000,
          floorKcal: 1600,
          manual: true,
          acknowledged: true,
        ),
      ]) {
        expect(bad, throwsArgumentError);
      }
    },
  );

  test(
    'TG-040 TG-043 settings copy weights and pass intake/calendar to engine',
    () {
      final weights = {DayOfWeek.friday: 2.0};
      final macros = MacroSettings(protein: MacroOverride.grams(150));
      final settings = TargetPlan(
        baseKcal: 2000,
        floorKcal: 1500,
        weights: weights,
        macros: macros,
        rebalancing: false,
      );
      weights.clear();
      expect(settings.weights[DayOfWeek.friday], 2);
      expect(settings.weights.clear, throwsUnsupportedError);
      final date = saturday.plusDays(6);
      final day = settings.day(
        date: date,
        weightKg: 70,
        earlierIntake: [WeekIntake(date: saturday, kcal: 3000)],
      );
      expect(day.kcal, closeTo(2500, 1e-7));
      expect(day.macros.proteinGrams, 150);
      expect(day.week!.accountedPastKcal, greaterThan(3000));
      final updated = settings.day(
        date: saturday.plusDays(4),
        weightKg: 70,
        remainingWeights: {DayOfWeek.wednesday: 2},
      );
      expect(updated.week!.planned[saturday], day.week!.planned[saturday]);
      expect(
        updated.kcal,
        greaterThan(updated.week!.planned[saturday.plusDays(4)]!),
      );
      final monday = settings.day(
        date: date,
        weightKg: 70,
        calendar: const WeekCalendar(weekStart: DayOfWeek.monday),
      );
      expect(monday.week!.weekStart.weekday, DayOfWeek.monday);
      for (final value in [0.0, double.nan, double.infinity, .0001, 1001.0]) {
        expect(
          () => TargetPlan(
            baseKcal: 2000,
            floorKcal: 1500,
            weights: {DayOfWeek.friday: value},
          ),
          throwsArgumentError,
        );
      }
    },
  );

  test('TG-020 defaults summary is centralized for future adaptation', () {
    const d = TargetDefaults();
    expect(d.kcalPerKg, 7700);
    expect(d.maxLossFraction, .01);
    expect(d.dailyFlex, .25);
    expect(d.proteinPerKg, 1.8);
    expect(d.fatFraction, .3);
    expect(d.fatPerKgFloor, .6);
    expect(d.fiberPer1000Kcal, 14);
    expect(d.adaptiveDays, 14);
    expect(d.adaptiveCompleteDays, 10);
    expect(d.adaptiveWeighIns, 3);
    expect(d.adaptiveWeighInSpanDays, 10);
    expect(d.checkInThresholdKcal, 50);
    expect(d.checkInMaxChangeKcal, 150);
    expect(d.minimumKcal(FormulaSex.male), 1500);
    expect(d.minimumKcal(FormulaSex.female), 1200);
  });
}
