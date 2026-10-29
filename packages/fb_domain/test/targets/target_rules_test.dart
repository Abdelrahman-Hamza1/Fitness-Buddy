import 'package:fb_domain/fb_domain.dart';
import 'package:test/test.dart';

String _id(int value) =>
    '0199e3c2-5b1a-7000-8000-${value.toRadixString(16).padLeft(12, '0')}';
final _today = LocalDate(2026, 10, 28);
const TargetWireRules _wire = TargetRules.wire;
const TargetInputRules _input = TargetRules.input;

const _profile = ProfileRecord(
  heightInputUnit: HeightInputUnit.centimeter,
  sex: FormulaSex.female,
  birthYear: 1990,
  heightCm: 165,
  activity: ActivityLevel.light,
);

GoalPhaseRecord _phase({
  GoalType type = GoalType.lose,
  GoalExpression? expression,
  String? name,
}) => GoalPhaseRecord(
  weightInputUnit: MassUnit.kilogram,
  id: _id(1),
  revision: 1,
  name: name,
  start: _today,
  type: type,
  expression: expression ?? GoalExpression.weekly(-.5),
);

TargetSettingsRecord _settings({
  double base = 2000,
  bool manual = false,
  double basis = 70,
  Map<DayOfWeek, double> shifts = const {},
  MacroSettings? macros,
}) => TargetSettingsRecord(
  id: _id(2),
  revision: 1,
  effectiveFrom: _today,
  baseKcal: base,
  basisWeightKg: basis,
  manual: manual,
  shifts: shifts,
  macros: macros,
);

Map<String, Object?> _with(
  Map<String, Object?> wire,
  Map<String, Object?> changes,
) => {...wire, ...changes};

void main() {
  test('TG-001 TargetRules.input: age 18–100 on the date, height 100–250 cm, '
      'weight 20–500 kg; each bound accepts its limit and rejects just past '
      'it', () {
    expect(_input.birthYears(_today), (min: 1926, max: 2008));
    Set<TargetRuleViolation> profile(int year, double cm) => _input.profile(
      _profile.copyWith(birthYear: year, heightCm: cm),
      today: _today,
    );
    expect(profile(1926, 100), isEmpty);
    expect(profile(2008, 250), isEmpty);
    expect(profile(1925, 165), {TargetRuleViolation.age});
    expect(profile(2009, 165), {TargetRuleViolation.age});
    expect(profile(1990, 99.99), {TargetRuleViolation.height});
    expect(profile(1990, 250.01), {TargetRuleViolation.height});
    // The age is evaluated on the given date.
    expect(
      _input.profile(
        _profile.copyWith(birthYear: 2009),
        today: LocalDate(2027, 1, 1),
      ),
      isEmpty,
    );
    for (final (kg, ok) in [
      (20.0, true),
      (500.0, true),
      (19.99, false),
      (500.01, false),
      (double.nan, false),
    ]) {
      expect(_input.weight(kg), ok);
      expect(
        _input.targetSettings(_settings(basis: kg)),
        ok ? isEmpty : {TargetRuleViolation.weight},
      );
      expect(
        _input.goalPhase(
          _phase(
            expression: GoalExpression.targetRate(kg.isFinite ? kg : 600, .5),
          ),
          today: _today,
        ),
        ok ? isEmpty : {TargetRuleViolation.targetWeight},
      );
    }
  });

  test('D15 TargetRules.input bounds for rates, months, dates, manual kcal, '
      'macros, fiber and shifting weights', () {
    expect(_input.kgPerWeek(-2), isTrue);
    expect(_input.kgPerWeek(2.01), isFalse);
    expect(_input.monthKg(-8), isTrue);
    expect(_input.monthKg(8.01), isFalse);
    expect(_input.latestTargetDate(_today), LocalDate(2031, 10, 28));
    // Feb 29 rolls to Mar 1 five years later.
    expect(
      _input.latestTargetDate(LocalDate(2028, 2, 29)),
      LocalDate(2033, 3, 1),
    );
    expect(_input.targetDate(_today, _today), isFalse);
    expect(_input.targetDate(_today.plusDays(1), _today), isTrue);
    expect(_input.targetDate(LocalDate(2031, 10, 28), _today), isTrue);
    expect(_input.targetDate(LocalDate(2031, 10, 29), _today), isFalse);
    expect(_input.manualKcal(500), isTrue);
    expect(_input.manualKcal(10000), isTrue);
    expect(_input.manualKcal(499.9), isFalse);
    expect(_input.manualKcal(10000.1), isFalse);
    expect(_input.macro(1000, isPercent: false), isTrue);
    expect(_input.macro(1000.1, isPercent: false), isFalse);
    expect(_input.macro(100, isPercent: true), isTrue);
    expect(_input.macro(100.1, isPercent: true), isFalse);
    expect(_input.fiber(150), isTrue);
    expect(_input.fiber(150.1), isFalse);
    expect(_input.shift(1), isTrue);
    expect(_input.shift(2), isTrue);
    expect(_input.shift(.99), isFalse);
    expect(_input.shift(2.01), isFalse);

    Set<TargetRuleViolation> goal(GoalExpression e) =>
        _input.goalPhase(_phase(expression: e), today: _today);
    expect(goal(GoalExpression.weekly(-2)), isEmpty);
    expect(goal(GoalExpression.weekly(-2.5)), {TargetRuleViolation.rate});
    expect(goal(GoalExpression.targetRate(60, 3)), {TargetRuleViolation.rate});
    expect(goal(GoalExpression.monthly(-8, _today)), isEmpty);
    expect(goal(GoalExpression.monthly(-9, _today)), {
      TargetRuleViolation.monthly,
    });
    expect(goal(GoalExpression.targetDate(60, LocalDate(2027, 3, 1))), isEmpty);
    expect(goal(GoalExpression.targetDate(60, _today)), {
      TargetRuleViolation.targetDate,
    });

    expect(_input.targetSettings(_settings(manual: true, base: 500)), isEmpty);
    expect(_input.targetSettings(_settings(manual: true, base: 400)), {
      TargetRuleViolation.manualKcal,
    });
    // A generated base has no plausibility range.
    expect(_input.targetSettings(_settings(base: 400)), isEmpty);
    expect(
      _input.targetSettings(
        _settings(
          shifts: {DayOfWeek.friday: 1.3, DayOfWeek.monday: 2.5},
          macros: MacroSettings(
            protein: MacroOverride.grams(1200),
            fat: MacroOverride.percent(25),
            carbs: MacroOverride.grams(200),
            fiberGrams: 200,
          ),
        ),
      ),
      {
        TargetRuleViolation.shift,
        TargetRuleViolation.macroGrams,
        TargetRuleViolation.fiber,
      },
    );
    expect(
      _input.targetSettings(
        _settings(
          macros: MacroSettings(fat: MacroOverride.grams(80), fiberGrams: 30),
        ),
      ),
      isEmpty,
    );
  });

  test('PA6 TargetRules.input checks only the fields that differ from the '
      'stored record', () {
    // A synced out-of-range height doesn't block an activity edit.
    final stored = _profile.copyWith(heightCm: 300, birthYear: 1900);
    expect(
      _input.profile(
        stored.copyWith(activity: ActivityLevel.high),
        today: _today,
        before: stored,
      ),
      isEmpty,
    );
    expect(
      _input.profile(
        stored.copyWith(heightCm: 260),
        today: _today,
        before: stored,
      ),
      {TargetRuleViolation.height},
    );
    // Goal: a passed deadline doesn't block a rename.
    final passed = _phase(
      expression: GoalExpression.targetDate(60, LocalDate(2026, 1, 1)),
    );
    expect(
      _input.goalPhase(passed.withName('Cut'), today: _today, before: passed),
      isEmpty,
    );
    expect(_input.goalPhase(passed, today: _today), {
      TargetRuleViolation.targetDate,
    });
    // Settings: an out-of-range synced shift or manual base stays put.
    final synced = _settings(
      manual: true,
      base: 300,
      shifts: {DayOfWeek.friday: 5},
      macros: MacroSettings(protein: MacroOverride.percent(90)),
    );
    expect(
      _input.targetSettings(
        synced.copyWith(rebalancing: false),
        before: synced,
      ),
      isEmpty,
    );
    // Turning a stored base manual checks it even if the number is the same.
    final generated = _settings(base: 300);
    expect(
      _input.targetSettings(
        generated.copyWith(manual: true),
        before: generated,
      ),
      {TargetRuleViolation.manualKcal},
    );
    // Switching a macro's unit re-checks its value in the new unit.
    final percent = _settings(
      macros: MacroSettings(protein: MacroOverride.percent(50)),
    );
    expect(
      _input.targetSettings(
        percent.copyWith(
          macros: MacroSettings(protein: MacroOverride.grams(1200)),
        ),
        before: percent,
      ),
      {TargetRuleViolation.macroGrams},
    );
    final outlier = _settings(
      macros: MacroSettings(protein: MacroOverride.grams(1200)),
    );
    expect(
      _input.targetSettings(
        outlier.copyWith(
          macros: MacroSettings(protein: MacroOverride.percent(50)),
        ),
        before: outlier,
      ),
      isEmpty,
    );
  });

  test('D15 TargetRules.wire: unknown enum, an expression kind with a '
      'missing or extra field, maintain not weekly 0, a value without '
      'isPercent, acknowledged without manual, end before start, revision 0, '
      'NaN/±infinity are each rejected; violations carry codes, never '
      'values', () {
    final phase = _phase().toWire();
    final settings = _settings().toWire();
    final profile = _profile.toWire();
    expect(_wire.profile(profile), isEmpty);
    expect(_wire.goalPhase(phase), isEmpty);
    expect(_wire.targetSettings(settings), isEmpty);

    void rejects(
      Set<TargetRuleViolation> Function(Map<String, Object?>) rule,
      Map<String, Object?> wire,
      Map<String, Object?> change,
      TargetRuleViolation code,
    ) {
      final violations = rule(_with(wire, change));
      expect(violations, contains(code), reason: '$change');
      for (final value in change.values) {
        if (value is String && code == TargetRuleViolation.vocabulary) {
          expect('$violations', isNot(contains(value)));
        }
      }
    }

    // Unknown enums.
    rejects(_wire.profile, profile, {
      'sex': 'bogusSex',
    }, TargetRuleViolation.vocabulary);
    rejects(_wire.profile, profile, {
      'activity': 'athleteX',
    }, TargetRuleViolation.vocabulary);
    rejects(_wire.goalPhase, phase, {
      'goalType': 'shred',
    }, TargetRuleViolation.vocabulary);
    rejects(_wire.goalPhase, phase, {
      'expressionKind': 'yearly',
    }, TargetRuleViolation.vocabulary);
    rejects(_wire.targetSettings, settings, {
      'mode': 'adaptive',
    }, TargetRuleViolation.vocabulary);
    // Expression kinds with a missing or an extra field.
    rejects(_wire.goalPhase, phase, {
      'kgPerWeek': null,
    }, TargetRuleViolation.expression);
    rejects(_wire.goalPhase, phase, {
      'targetKg': 60,
    }, TargetRuleViolation.expression);
    rejects(_wire.goalPhase, phase, {
      'expressionKind': 'targetDate',
    }, TargetRuleViolation.expression);
    rejects(_wire.goalPhase, phase, {
      'expressionKind': 'monthly',
      'kgPerWeek': null,
      'monthKg': -2,
    }, TargetRuleViolation.expression);
    rejects(_wire.goalPhase, phase, {
      'expressionKind': 'targetRate',
      'targetKg': 60,
      'kgPerWeek': -.5,
    }, TargetRuleViolation.number);
    // Maintain is weekly 0 only.
    rejects(_wire.goalPhase, phase, {
      'goalType': 'maintain',
    }, TargetRuleViolation.maintain);
    rejects(_wire.goalPhase, phase, {
      'goalType': 'maintain',
      'expressionKind': 'monthly',
      'kgPerWeek': null,
      'monthKg': 0,
      'month': '2026-11-01',
    }, TargetRuleViolation.maintain);
    expect(
      _wire.goalPhase(_with(phase, {'goalType': 'maintain', 'kgPerWeek': 0})),
      isEmpty,
    );
    // Macro pairs.
    rejects(_wire.targetSettings, settings, {
      'proteinValue': 120,
    }, TargetRuleViolation.macroPair);
    rejects(_wire.targetSettings, settings, {
      'carbsIsPercent': true,
    }, TargetRuleViolation.macroPair);
    rejects(_wire.targetSettings, settings, {
      'fatValue': 101,
      'fatIsPercent': true,
    }, TargetRuleViolation.number);
    expect(
      _wire.targetSettings(
        _with(settings, {'fatValue': 101, 'fatIsPercent': false}),
      ),
      isEmpty,
    );
    // Acknowledged only with manual.
    rejects(_wire.targetSettings, settings, {
      'acknowledged': true,
    }, TargetRuleViolation.acknowledged);
    expect(
      _wire.targetSettings(
        _with(settings, {'acknowledged': true, 'manual': true}),
      ),
      isEmpty,
    );
    // Dates and revisions.
    rejects(_wire.goalPhase, phase, {
      'endDate': '2026-10-27',
    }, TargetRuleViolation.endBeforeStart);
    expect(_wire.goalPhase(_with(phase, {'endDate': '2026-10-28'})), isEmpty);
    rejects(_wire.goalPhase, phase, {
      'startDate': '2026-02-30',
    }, TargetRuleViolation.date);
    rejects(_wire.goalPhase, phase, {
      'revision': 0,
    }, TargetRuleViolation.revision);
    rejects(_wire.targetSettings, settings, {
      'revision': TargetWireRules.maxRevision + 1,
    }, TargetRuleViolation.revision);
    expect(
      _wire.goalPhase(_with(phase, {'revision': TargetWireRules.maxRevision})),
      isEmpty,
    );
    // Non-finite and out-of-bound numbers.
    for (final bad in [double.nan, double.infinity, double.negativeInfinity]) {
      rejects(_wire.profile, profile, {
        'heightCm': bad,
      }, TargetRuleViolation.number);
      rejects(_wire.goalPhase, phase, {
        'kgPerWeek': bad,
      }, TargetRuleViolation.number);
      rejects(_wire.targetSettings, settings, {
        'baseKcal': bad,
      }, TargetRuleViolation.number);
      rejects(_wire.targetSettings, settings, {
        'shiftFri': bad,
      }, TargetRuleViolation.number);
    }
    rejects(_wire.profile, profile, {
      'heightCm': 0,
    }, TargetRuleViolation.number);
    rejects(_wire.targetSettings, settings, {
      'basisWeightKg': 1e6 + 1,
    }, TargetRuleViolation.number);
    rejects(_wire.targetSettings, settings, {
      'fiberG': -1,
    }, TargetRuleViolation.number);
    rejects(_wire.profile, profile, {
      'birthYear': 10000,
    }, TargetRuleViolation.number);
    rejects(_wire.goalPhase, phase, {
      'monthKg': -1e6 - 1,
      'expressionKind': 'monthly',
      'kgPerWeek': null,
      'month': '2026-11-01',
    }, TargetRuleViolation.number);
    // Negative weekly and monthly goals are wire-valid (PA4).
    expect(
      _wire.goalPhase(
        _with(phase, {
          'expressionKind': 'monthly',
          'kgPerWeek': null,
          'monthKg': -1e6,
          'month': '2026-11-01',
        }),
      ),
      isEmpty,
    );
    // Wrong JSON types and missing fields.
    rejects(_wire.profile, profile, {
      'birthYear': 1990.5,
    }, TargetRuleViolation.type);
    rejects(_wire.profile, profile, {'sex': 1}, TargetRuleViolation.type);
    rejects(_wire.profile, profile, {
      'heightCm': '165',
    }, TargetRuleViolation.type);
    rejects(_wire.targetSettings, settings, {
      'manual': 'no',
    }, TargetRuleViolation.type);
    rejects(_wire.goalPhase, phase, {
      'startDate': 20261028,
    }, TargetRuleViolation.type);
    rejects(_wire.goalPhase, phase, {'name': 7}, TargetRuleViolation.type);
    rejects(_wire.goalPhase, phase, {
      'name': 'x' * 121,
    }, TargetRuleViolation.nameLength);
    expect(_wire.goalPhase(_with(phase, {'name': 'x' * 120})), isEmpty);
    expect(_wire.profile({}), {TargetRuleViolation.type});
    // Other keys (sync metadata) are not the wire rules' concern.
    expect(_wire.profile(_with(profile, {'createdAtMs': 1})), isEmpty);
    // Integral JSON numbers are accepted for decimal fields.
    expect(_wire.profile(_with(profile, {'heightCm': 165})), isEmpty);
  });

  test('TG-012 a null phase name maps to a placeholder for GoalPhase and '
      'stays null in the record; a 41-character or control-character name '
      'fails TargetRules.input', () {
    final unnamed = _phase();
    expect(unnamed.name, isNull);
    expect(unnamed.toWire()['name'], isNull);
    expect(unnamed.toPhase().name, GoalPhaseRecord.placeholderName);
    expect(
      unnamed.withName('  ').toPhase().name,
      GoalPhaseRecord.placeholderName,
    );
    expect(
      GoalPhaseRecord.fromWire(unnamed.id, unnamed.toWire())!.name,
      isNull,
    );
    expect(_input.goalPhase(unnamed, today: _today), isEmpty);
    expect(_input.name(null), isTrue);
    final named = _phase(name: '  Summer cut  ');
    expect(named.toPhase().name, '  Summer cut  ');
    expect(_input.goalPhase(named, today: _today), isEmpty);
    expect(_input.name('x' * 40), isTrue);
    expect(_input.name(' ${'x' * 40} '), isTrue);
    for (final bad in ['x' * 41, 'Cut\u0007', 'Cut‎', '   ', '']) {
      expect(_input.name(bad), isFalse);
      expect(_input.goalPhase(_phase(name: bad), today: _today), {
        TargetRuleViolation.name,
      });
    }
  });
}
