import 'package:fb_domain/fb_domain.dart';
import 'package:test/test.dart';

String _id(int value) =>
    '0199e3c2-5b1a-7000-8000-${value.toRadixString(16).padLeft(12, '0')}';
final _today = LocalDate(2026, 10, 28);

GoalPhaseRecord _phase(
  GoalExpression expression, {
  GoalType type = GoalType.lose,
  String? name,
  LocalDate? end,
}) => GoalPhaseRecord(
  weightInputUnit: MassUnit.kilogram,
  id: _id(1),
  revision: 3,
  name: name,
  start: _today,
  end: end,
  type: type,
  expression: expression,
);

TargetSettingsRecord _settings({
  LocalDate? from,
  Map<DayOfWeek, double> shifts = const {},
  MacroSettings? macros,
}) => TargetSettingsRecord(
  id: _id(2),
  revision: 2,
  effectiveFrom: from ?? _today.plusDays(-3),
  baseKcal: 2150.5,
  basisWeightKg: 82.4,
  shifts: shifts,
  macros: macros,
);

void main() {
  test('TG-011 GoalPhaseRecord maps each expression kind to the matching A12 '
      'GoalExpression; negative weekly and monthly goals round-trip', () {
    final cases = <(GoalExpression, GoalExpressionKind, Map<String, Object?>)>[
      (
        GoalExpression.targetDate(70, LocalDate(2027, 3, 1)),
        GoalExpressionKind.targetDate,
        {'targetKg': 70.0, 'targetDate': '2027-03-01'},
      ),
      (
        GoalExpression.targetRate(70, .5),
        GoalExpressionKind.targetRate,
        {'targetKg': 70.0, 'kgPerWeek': .5},
      ),
      (
        GoalExpression.weekly(-.75),
        GoalExpressionKind.weekly,
        {'kgPerWeek': -.75},
      ),
      (
        GoalExpression.monthly(-2, LocalDate(2026, 11, 17)),
        GoalExpressionKind.monthly,
        {'monthKg': -2.0, 'month': '2026-11-01'},
      ),
    ];
    for (final (expression, kind, fields) in cases) {
      expect(GoalExpressionKind.of(expression), kind);
      final record = _phase(expression, end: LocalDate(2027, 6, 30));
      final wire = record.toWire();
      expect(wire.keys, TargetWireFields.goalPhase);
      expect(wire['expressionKind'], kind.name);
      for (final key in ['targetKg', 'targetDate', 'kgPerWeek', 'monthKg']) {
        expect(wire[key], fields[key], reason: '$kind $key');
      }
      expect(wire['month'], fields['month']);
      final back = GoalPhaseRecord.fromWire(record.id, wire)!;
      expect(back, record);
      expect(back.hashCode, record.hashCode);
      expect(back.toWire(), wire);
      expect(GoalExpressionKind.of(back.expression), kind);
      final phase = back.toPhase();
      expect(phase.id, record.id);
      expect(phase.version, 3);
      expect(phase.start, _today);
      expect(phase.end, LocalDate(2027, 6, 30));
      expect(phase.type, GoalType.lose);
      expect(phase.expression, same(back.expression));
    }
    // A positive (gain) monthly goal and maintain = weekly 0 also map.
    final gain = GoalPhaseRecord.fromWire(
      _id(1),
      _phase(
        GoalExpression.monthly(1.5, LocalDate(2026, 2, 1)),
        type: GoalType.gain,
      ).toWire(),
    )!;
    expect((gain.expression as MonthlyGoal).kg, 1.5);
    expect((gain.expression as MonthlyGoal).days, 28);
    final maintain = _phase(GoalExpression.weekly(0), type: GoalType.maintain);
    expect(GoalPhaseRecord.fromWire(_id(1), maintain.toWire()), maintain);
    // Not a UUIDv7, or rejected by the wire rules: no record.
    expect(GoalPhaseRecord.fromWire('not-a-uuid', maintain.toWire()), isNull);
    expect(
      GoalPhaseRecord.fromWire(_id(1), {
        ...maintain.toWire(),
        'kgPerWeek': -.5,
      }),
      isNull,
    );
    // Equality covers every field.
    final base = _phase(GoalExpression.weekly(-.5), name: 'Cut');
    for (final other in [
      base.copyWith(id: _id(9)),
      base.copyWith(revision: 4),
      base.copyWith(start: _today.plusDays(1)),
      base.copyWith(type: GoalType.gain),
      base.copyWith(expression: GoalExpression.weekly(-.4)),
      base.withName(null),
      base.withEnd(_today),
      base.copyWith(weightInputUnit: MassUnit.pound),
    ]) {
      expect(other, isNot(base));
    }
    expect(base.copyWith(), base);
    expect(base.withEnd(_today).withEnd(null), base);
    expect(base, isNot(Object()));
  });

  test('TG-001 ProfileRecord round-trips its wire fields and builds the '
      'engine profile at a given weight', () {
    const record = ProfileRecord(
      heightInputUnit: HeightInputUnit.centimeter,
      sex: FormulaSex.male,
      birthYear: 1990,
      heightCm: 180.5,
      activity: ActivityLevel.moderate,
    );
    final wire = record.toWire();
    expect(wire, {
      'sex': 'male',
      'birthYear': 1990,
      'heightCm': 180.5,
      'heightInputUnit': 'cm',
      'activity': 'moderate',
    });
    expect(wire.keys, TargetWireFields.profile);
    expect(ProfileRecord.fromWire(wire), record);
    expect(ProfileRecord.fromWire({...wire, 'heightCm': 180}), isNotNull);
    expect(ProfileRecord.fromWire({...wire, 'sex': 'other'}), isNull);
    expect(ProfileRecord.fromWire(wire).hashCode, record.hashCode);
    final profile = record.toProfile(81);
    expect(profile.weightKg, 81);
    expect(profile.heightCm, 180.5);
    expect(profile.birthYear, 1990);
    expect(profile.sex, FormulaSex.male);
    expect(profile.activity, ActivityLevel.moderate);
    expect(record.copyWith(), record);
    for (final other in [
      record.copyWith(sex: FormulaSex.female),
      record.copyWith(birthYear: 1991),
      record.copyWith(heightCm: 181),
      record.copyWith(activity: ActivityLevel.high),
      record.copyWith(heightInputUnit: HeightInputUnit.feetInches),
    ]) {
      expect(other, isNot(record));
    }
  });

  test('TG-043 a NULL shift weight reads as 1.0; seven weights '
      'round-trip', () {
    final unshifted = _settings();
    final wire = unshifted.toWire();
    for (final field in TargetWireFields.shifts.values) {
      expect(wire.containsKey(field), isTrue);
      expect(wire[field], isNull);
    }
    expect(unshifted.shifts, isEmpty);
    expect(unshifted.weights, isEmpty);
    final plan = unshifted.toPlan(1500);
    expect(plan.weights, isEmpty);
    // NULL days are 1.0 to the engine: the same week as explicit 1.0s.
    final explicitOnes = _settings(
      shifts: {for (final d in DayOfWeek.values) d: 1.0},
    );
    final week = plan.day(date: _today, weightKg: 80).week!;
    final ones = explicitOnes.toPlan(1500).day(date: _today, weightKg: 80);
    expect(ones.week!.planned, week.planned);

    final seven = {
      for (final (i, day) in DayOfWeek.values.indexed) day: 1 + i / 10,
    };
    final shifted = _settings(shifts: seven);
    final shiftedWire = shifted.toWire();
    expect(shiftedWire['shiftMon'], 1.0);
    expect(shiftedWire['shiftSun'], closeTo(1.6, 1e-12));
    final back = TargetSettingsRecord.fromWire(shifted.id, shiftedWire)!;
    expect(back.shifts, seven);
    expect(back, shifted);
    expect(back.toPlan(1500).weights, seven);
    expect(back.shifts.clear, throwsUnsupportedError);
    // A synced weight the engine can't use reads as 1.0, but is kept.
    final odd = TargetSettingsRecord.fromWire(_id(2), {
      ...wire,
      'shiftFri': 0,
      'shiftSat': 5000,
      'shiftSun': 1.3,
    })!;
    expect(odd.shifts, {
      DayOfWeek.friday: 0.0,
      DayOfWeek.saturday: 5000.0,
      DayOfWeek.sunday: 1.3,
    });
    expect(odd.weights, {DayOfWeek.sunday: 1.3});
    expect(odd.toWire()['shiftSat'], 5000.0);
  });

  test('TG-054 TargetSettingsRecord round-trips every field incl. macro '
      'pairs, and toPlan raises a base below the floor unless acknowledged '
      'manual fixed', () {
    final record = TargetSettingsRecord(
      id: _id(3),
      revision: 4,
      effectiveFrom: _today,
      mode: TargetMode.fixed,
      rebalancing: false,
      baseKcal: 1300,
      manual: true,
      acknowledged: true,
      basisWeightKg: 70,
      shifts: {DayOfWeek.friday: 1.3},
      macros: MacroSettings(
        protein: MacroOverride.grams(140),
        fat: MacroOverride.percent(25),
        carbs: MacroOverride.grams(200),
        fiberGrams: 30,
        caloriesProteinOnly: true,
      ),
    );
    final wire = record.toWire();
    expect(wire.keys, TargetWireFields.targetSettings);
    expect(wire, containsPair('proteinValue', 140.0));
    expect(wire, containsPair('proteinIsPercent', false));
    expect(wire, containsPair('fatValue', 25.0));
    expect(wire, containsPair('fatIsPercent', true));
    expect(wire, containsPair('carbsIsPercent', false));
    expect(wire, containsPair('fiberG', 30.0));
    expect(wire, containsPair('caloriesProteinOnly', true));
    expect(TargetRules.wire.targetSettings(wire), isEmpty);
    final back = TargetSettingsRecord.fromWire(record.id, wire)!;
    expect(back, record);
    expect(back.hashCode, record.hashCode);
    expect(back.macros.fat!.isPercent, isTrue);
    expect(back.macros.carbs!.value, 200);
    expect(back.key, (id: _id(3), revision: 4, effectiveFrom: _today));
    expect(TargetSettingsRecord.fromWire('x', wire), isNull);
    expect(
      TargetSettingsRecord.fromWire(record.id, {...wire, 'manual': false}),
      isNull,
    );
    expect(_settings().toWire()['proteinValue'], isNull);
    expect(_settings().toWire()['proteinIsPercent'], isNull);

    // Acknowledged manual fixed: the base stands below the floor (SF-012).
    expect(record.mayStayBelowFloor, isTrue);
    final kept = record.toPlan(1600);
    expect(kept.baseKcal, 1300);
    expect(kept.floorKcal, 1600);
    expect(kept.manual, isTrue);
    expect(kept.acknowledged, isTrue);
    expect(kept.mode, TargetMode.fixed);
    expect(kept.rebalancing, isFalse);
    expect(kept.macros, same(record.macros));
    // Otherwise it is raised to the floor (SF-010, D6).
    for (final other in [
      record.copyWith(mode: TargetMode.weekly),
      record.copyWith(acknowledged: false),
      record.copyWith(manual: false, acknowledged: false),
    ]) {
      expect(other.mayStayBelowFloor, isFalse);
      expect(other.toPlan(1600).baseKcal, 1600);
    }
    expect(record.toPlan(1200).baseKcal, 1300);
    for (final other in [
      record.copyWith(id: _id(4)),
      record.copyWith(revision: 5),
      record.copyWith(effectiveFrom: _today.plusDays(1)),
      record.copyWith(rebalancing: true),
      record.copyWith(baseKcal: 1301),
      record.copyWith(basisWeightKg: 71),
      record.copyWith(shifts: {}),
      record.copyWith(macros: MacroSettings()),
    ]) {
      expect(other, isNot(record));
    }
    expect(record.copyWith(), record);
  });

  test("D5 TargetSettingsRevision.next updates today's row and otherwise "
      'copies the current row into a new one effective today', () {
    TargetSettingsRecord rebalanceOff(TargetSettingsRecord r) =>
        r.copyWith(rebalancing: false);
    // The current version started earlier: a new row effective today.
    final earlier = _settings(
      shifts: {DayOfWeek.friday: 1.3},
      macros: MacroSettings(fiberGrams: 30),
    );
    final inserted = TargetSettingsRevision.next(
      current: earlier,
      currentVersion: 7,
      today: _today,
      newId: _id(5),
      change: rebalanceOff,
    );
    expect(inserted.expectedVersion, isNull);
    expect(
      inserted.record,
      earlier.copyWith(
        id: _id(5),
        revision: 1,
        effectiveFrom: _today,
        rebalancing: false,
      ),
    );
    // The current version is today's: revise it in place.
    final todays = _settings(from: _today);
    final revised = TargetSettingsRevision.next(
      current: todays,
      currentVersion: 7,
      today: _today,
      newId: _id(5),
      change: (r) => r.copyWith(baseKcal: 1900, effectiveFrom: _today),
    );
    expect(revised.expectedVersion, 7);
    expect(
      revised.record,
      todays.copyWith(revision: todays.revision + 1, baseKcal: 1900),
    );
  });

  test('D17 the typed height and goal weight units round-trip by wire '
      'code; other codes are rejected', () {
    expect(HeightInputUnit.values.map((u) => u.code), ['cm', 'ft_in']);
    expect(HeightInputUnit.ofCode('ft_in'), HeightInputUnit.feetInches);
    expect(HeightInputUnit.ofCode('in'), isNull);
    expect(GoalWeightUnits.values.map((u) => u.code), ['kg', 'lb']);
    expect(GoalWeightUnits.ofCode('lb'), MassUnit.pound);
    expect(GoalWeightUnits.ofCode('g'), isNull);
    const imperial = ProfileRecord(
      sex: FormulaSex.female,
      birthYear: 1990,
      heightCm: 165.1,
      heightInputUnit: HeightInputUnit.feetInches,
      activity: ActivityLevel.light,
    );
    expect(imperial.toWire()['heightInputUnit'], 'ft_in');
    expect(ProfileRecord.fromWire(imperial.toWire()), imperial);
    final pounds = _phase(GoalExpression.weekly(-.45359237))
        .copyWith(weightInputUnit: MassUnit.pound);
    expect(pounds.toWire()['weightInputUnit'], 'lb');
    expect(GoalPhaseRecord.fromWire(pounds.id, pounds.toWire()), pounds);
    for (final (wire, field, bad) in [
      (imperial.toWire(), 'heightInputUnit', 'in'),
      (pounds.toWire(), 'weightInputUnit', 'g'),
    ]) {
      final rule = field == 'heightInputUnit'
          ? TargetRules.wire.profile
          : TargetRules.wire.goalPhase;
      expect(rule({...wire, field: bad}), {TargetRuleViolation.vocabulary});
      expect(rule({...wire, field: null}), {TargetRuleViolation.type});
      expect(rule({...wire, field: 2}), {TargetRuleViolation.type});
    }
  });
}
