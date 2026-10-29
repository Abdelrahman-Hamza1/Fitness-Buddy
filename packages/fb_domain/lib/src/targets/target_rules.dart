import 'package:fb_domain/src/targets/goals.dart';
import 'package:fb_domain/src/targets/target_profile.dart';
import 'package:fb_domain/src/targets/target_records.dart';
import 'package:fb_domain/src/targets/target_settings.dart';
import 'package:fb_domain/src/time/local_date.dart';

/// A rule a targets value breaks. Codes only: never the value (D15).
enum TargetRuleViolation {
  /// Wire: a field is missing or has the wrong JSON type.
  type,

  /// Wire: a closed-vocabulary field has an unknown value.
  vocabulary,

  /// Wire: a number is not finite or is outside its technical bounds.
  number,

  /// Wire: a date is not an ISO `YYYY-MM-DD` date.
  date,

  /// Wire: the domain revision is outside 1 … 2^53−1.
  revision,

  /// Wire: the phase name is longer than [TargetWireRules.maxNameLength].
  nameLength,

  /// Wire: the expression kind lacks one of its fields or has another's.
  expression,

  /// Wire: a maintain goal that isn't `weekly` 0 (PA4).
  maintain,

  /// Wire: a macro value without its `isPercent` flag, or the reverse.
  macroPair,

  /// Wire: `acknowledged` without `manual`.
  acknowledged,

  /// Wire: a phase ending before it starts.
  endBeforeStart,

  /// Input: age outside 18–100 on the evaluation date.
  age,

  /// Input: height outside 100–250 cm.
  height,

  /// Input: body weight outside 20–500 kg.
  weight,

  /// Input: target weight outside 20–500 kg.
  targetWeight,

  /// Input: weekly rate above 2 kg/week.
  rate,

  /// Input: monthly change above 8 kg.
  monthly,

  /// Input: target date not after today or more than 5 years ahead.
  targetDate,

  /// Input: manual target outside 500–10,000 kcal.
  manualKcal,

  /// Input: macro grams outside 0–1,000.
  macroGrams,

  /// Input: macro percent outside 0–100.
  macroPercent,

  /// Input: fiber outside 0–150 g.
  fiber,

  /// Input: shifting weight outside 1.0–2.0.
  shift,

  /// Input: phase name blank after trimming, too long or with controls.
  name,
}

/// The targets rules, split by PA6: [wire] is shared with server admission
/// (B19) and always applies; [input] is app-only plausibility, applied by
/// forms, commands and, on changed fields only, the op handler.
abstract final class TargetRules {
  /// Wire rules (contract bounds plus cross-field rules, D3/D15).
  static const TargetWireRules wire = TargetWireRules._();

  /// App-only plausibility rules (D15).
  static const TargetInputRules input = TargetInputRules._();
}

/// The wire rules over the camelCase content maps of [TargetWireFields].
/// Keys other than those fields (sync metadata) are ignored here.
final class TargetWireRules {
  const new _();

  /// Largest domain revision (2^53 − 1, a safe JSON integer).
  static const int maxRevision = 9007199254740991;

  /// Longest phase name on the wire.
  static const int maxNameLength = 120;

  /// Largest macro percent on the wire (`…IsPercent` true).
  static const double maxPercent = 100;

  /// Violations of a `profile` map.
  Set<TargetRuleViolation> profile(Map<String, Object?> wire) {
    final r = _Reader(wire)
      ..vocabulary('sex', FormulaSex.values)
      ..integer(
        'birthYear',
        min: 1,
        max: 9999,
        code: TargetRuleViolation.number,
      )
      ..number('heightCm', positive: true)
      ..code('heightInputUnit', HeightInputUnit.ofCode)
      ..vocabulary('activity', ActivityLevel.values);
    return r.violations;
  }

  /// Violations of a `goalPhase` map.
  Set<TargetRuleViolation> goalPhase(Map<String, Object?> wire) {
    final r = _Reader(wire)
      ..revision()
      ..text('name', maxNameLength);
    final start = r.date('startDate');
    final end = r.date('endDate', nullable: true);
    final type = r.vocabulary('goalType', GoalType.values);
    final kind = r.vocabulary('expressionKind', GoalExpressionKind.values);
    final targetKg = r.number('targetKg', positive: true, nullable: true);
    final targetDate = r.date('targetDate', nullable: true);
    final kgPerWeek = r.number('kgPerWeek', signed: true, nullable: true);
    final monthKg = r.number('monthKg', signed: true, nullable: true);
    final month = r.date('month', nullable: true);
    r.code('weightInputUnit', GoalWeightUnits.ofCode);
    if (start != null && end != null && end.isBefore(start)) {
      r.violations.add(TargetRuleViolation.endBeforeStart);
    }
    if (kind != null) {
      final present = [targetKg, targetDate, kgPerWeek, monthKg, month];
      final expected = switch (kind) {
        GoalExpressionKind.targetDate => [true, true, false, false, false],
        GoalExpressionKind.targetRate => [true, false, true, false, false],
        GoalExpressionKind.weekly => [false, false, true, false, false],
        GoalExpressionKind.monthly => [false, false, false, true, true],
      };
      for (var i = 0; i < present.length; i++) {
        if ((present[i] != null) != expected[i]) {
          r.violations.add(TargetRuleViolation.expression);
        }
      }
      // A target-rate speed is positive; the target sets the direction.
      if (kind == GoalExpressionKind.targetRate &&
          kgPerWeek != null &&
          kgPerWeek <= 0) {
        r.violations.add(TargetRuleViolation.number);
      }
    }
    if (type == GoalType.maintain &&
        (kind != GoalExpressionKind.weekly || kgPerWeek != 0)) {
      r.violations.add(TargetRuleViolation.maintain);
    }
    return r.violations;
  }

  /// Violations of a `targetSettings` map.
  Set<TargetRuleViolation> targetSettings(Map<String, Object?> wire) {
    final r = _Reader(wire)
      ..revision()
      ..date('effectiveFrom')
      ..vocabulary('mode', TargetMode.values)
      ..boolean('rebalancing')
      ..number('baseKcal', positive: true)
      ..number('basisWeightKg', positive: true);
    final manual = r.boolean('manual');
    final acknowledged = r.boolean('acknowledged');
    if (acknowledged == true && manual == false) {
      r.violations.add(TargetRuleViolation.acknowledged);
    }
    for (final field in TargetWireFields.shifts.values) {
      r.number(field, nullable: true);
    }
    for (final macro in TargetWireFields.macros) {
      final value = r.number('${macro}Value', nullable: true);
      final isPercent = r.boolean('${macro}IsPercent', nullable: true);
      if ((value == null) != (isPercent == null)) {
        r.violations.add(TargetRuleViolation.macroPair);
      } else if (isPercent == true && value! > maxPercent) {
        r.violations.add(TargetRuleViolation.number);
      }
    }
    r
      ..number('fiberG', nullable: true)
      ..boolean('caloriesProteinOnly');
    return r.violations;
  }
}

/// App-only plausibility (D15). Field checks serve forms; the record checks
/// serve commands and the handler, which passes the stored row as `before`
/// so only changed fields are checked (a synced outlier never blocks an
/// unrelated edit).
final class TargetInputRules {
  const new _();

  /// Youngest age the adult formula serves.
  static const int minAge = 18;

  /// Oldest supported age.
  static const int maxAge = 100;

  /// Shortest height, cm.
  static const double minHeightCm = 100;

  /// Tallest height, cm.
  static const double maxHeightCm = 250;

  /// Lightest weight, kg (aligned with the weigh-in rules, A14 D6).
  static const double minWeightKg = 20;

  /// Heaviest weight, kg.
  static const double maxWeightKg = 500;

  /// Largest weekly rate, kg/week (either direction).
  static const double maxKgPerWeek = 2;

  /// Largest monthly change, kg (either direction).
  static const double maxMonthKg = 8;

  /// Furthest target date, in years after today.
  static const int maxTargetYears = 5;

  /// Lowest manual target, kcal.
  static const double minManualKcal = 500;

  /// Highest manual target, kcal.
  static const double maxManualKcal = 10000;

  /// Largest macro override, g.
  static const double maxMacroGrams = 1000;

  /// Largest macro override, percent.
  static const double maxMacroPercent = 100;

  /// Largest fiber target, g.
  static const double maxFiberG = 150;

  /// Smallest shifting weight.
  static const double minShift = 1;

  /// Largest shifting weight.
  static const double maxShift = 2;

  /// Longest phase name after trimming.
  static const int maxNameLength = 40;

  static final _controls = RegExp(r'[\p{Cc}\p{Cf}]', unicode: true);

  /// The accepted birth years on [today] (for "between X and Y" messages).
  ({int min, int max}) birthYears(LocalDate today) =>
      (min: today.year - maxAge, max: today.year - minAge);

  /// The last accepted target date after [today].
  LocalDate latestTargetDate(LocalDate today) {
    final limit = DateTime.utc(
      today.year + maxTargetYears,
      today.month,
      today.day,
    );
    return LocalDate(limit.year, limit.month, limit.day);
  }

  /// Whether [year] gives an age of 18–100 on [today].
  bool birthYear(int year, LocalDate today) {
    final range = birthYears(today);
    return year >= range.min && year <= range.max;
  }

  /// Whether [cm] is a plausible height.
  bool height(double cm) => _within(cm, minHeightCm, maxHeightCm);

  /// Whether [kg] is a plausible body or target weight.
  bool weight(double kg) => _within(kg, minWeightKg, maxWeightKg);

  /// Whether [kgPerWeek] (either sign) is a plausible weekly rate.
  bool kgPerWeek(double kgPerWeek) => _within(kgPerWeek.abs(), 0, maxKgPerWeek);

  /// Whether [kg] (either sign) is a plausible monthly change.
  bool monthKg(double kg) => _within(kg.abs(), 0, maxMonthKg);

  /// Whether [date] is after [today] and at most 5 years ahead.
  bool targetDate(LocalDate date, LocalDate today) =>
      date.isAfter(today) && !date.isAfter(latestTargetDate(today));

  /// Whether [kcal] is a plausible manual daily target.
  bool manualKcal(double kcal) => _within(kcal, minManualKcal, maxManualKcal);

  /// Whether a macro override [value] is plausible in its unit.
  bool macro(double value, {required bool isPercent}) =>
      _within(value, 0, isPercent ? maxMacroPercent : maxMacroGrams);

  /// Whether [grams] is a plausible fiber target.
  bool fiber(double grams) => _within(grams, 0, maxFiberG);

  /// Whether [weight] is a supported shifting weight.
  bool shift(double weight) => _within(weight, minShift, maxShift);

  /// Whether [name] can be stored (null: the default label).
  bool name(String? name) {
    if (name == null) return true;
    final trimmed = name.trim();
    return trimmed.isNotEmpty &&
        trimmed.length <= maxNameLength &&
        !_controls.hasMatch(trimmed);
  }

  /// Violations of [record] on [today], checking only the fields that
  /// differ from [before] (all of them when [before] is null).
  Set<TargetRuleViolation> profile(
    ProfileRecord record, {
    required LocalDate today,
    ProfileRecord? before,
  }) => {
    if ((before == null || before.birthYear != record.birthYear) &&
        !birthYear(record.birthYear, today))
      TargetRuleViolation.age,
    if ((before == null || before.heightCm != record.heightCm) &&
        !height(record.heightCm))
      TargetRuleViolation.height,
  };

  /// Violations of [record] on [today], checking only changed fields.
  Set<TargetRuleViolation> goalPhase(
    GoalPhaseRecord record, {
    required LocalDate today,
    GoalPhaseRecord? before,
  }) {
    final now = record.toWire();
    final old = before?.toWire();
    T? changed<T>(String key) =>
        old == null || old[key] != now[key] ? now[key] as T? : null;
    final targetKg = changed<double>('targetKg');
    final rate = changed<double>('kgPerWeek');
    final month = changed<double>('monthKg');
    final date = changed<String>('targetDate');
    return {
      if ((old == null || old['name'] != now['name']) && !name(record.name))
        TargetRuleViolation.name,
      if (targetKg != null && !weight(targetKg))
        TargetRuleViolation.targetWeight,
      if (rate != null && !kgPerWeek(rate)) TargetRuleViolation.rate,
      if (month != null && !monthKg(month)) TargetRuleViolation.monthly,
      if (date != null && !targetDate(LocalDate.parse(date), today))
        TargetRuleViolation.targetDate,
    };
  }

  /// Violations of [record], checking only changed fields. A manual base is
  /// checked when it or the manual flag changed.
  Set<TargetRuleViolation> targetSettings(
    TargetSettingsRecord record, {
    TargetSettingsRecord? before,
  }) {
    final now = record.toWire();
    final old = before?.toWire();
    bool changed(String key) => old == null || old[key] != now[key];
    final violations = <TargetRuleViolation>{
      if (changed('basisWeightKg') && !weight(record.basisWeightKg))
        TargetRuleViolation.weight,
      if (record.manual &&
          (changed('baseKcal') || changed('manual')) &&
          !manualKcal(record.baseKcal))
        TargetRuleViolation.manualKcal,
      if (record.macros.fiberGrams case final fiber?
          when changed('fiberG') && !this.fiber(fiber))
        TargetRuleViolation.fiber,
    };
    for (final macro in TargetWireFields.macros) {
      final value = now['${macro}Value'] as double?;
      final isPercent = now['${macro}IsPercent'] as bool?;
      if (value != null &&
          (changed('${macro}Value') || changed('${macro}IsPercent')) &&
          !this.macro(value, isPercent: isPercent!)) {
        violations.add(
          isPercent
              ? TargetRuleViolation.macroPercent
              : TargetRuleViolation.macroGrams,
        );
      }
    }
    for (final MapEntry(key: day, value: field)
        in TargetWireFields.shifts.entries) {
      final weight = record.shifts[day];
      if (weight != null && changed(field) && !shift(weight)) {
        violations.add(TargetRuleViolation.shift);
      }
    }
    return violations;
  }

  static bool _within(double value, double min, double max) =>
      value.isFinite && value >= min && value <= max;
}

/// Reads typed wire fields, collecting violations; a bad field reads null.
final class _Reader {
  new(this.wire);

  final Map<String, Object?> wire;
  final Set<TargetRuleViolation> violations = {};

  Object? _field(String key, {required bool nullable}) {
    final value = wire[key];
    if (value == null && !nullable) violations.add(TargetRuleViolation.type);
    return value;
  }

  T? vocabulary<T extends Enum>(String key, List<T> values) {
    final value = _field(key, nullable: false);
    if (value == null) return null;
    if (value is! String) {
      violations.add(TargetRuleViolation.type);
      return null;
    }
    for (final v in values) {
      if (v.name == value) return v;
    }
    violations.add(TargetRuleViolation.vocabulary);
    return null;
  }

  /// A closed vocabulary by wire code ([ofCode] returns null for unknown).
  void code(String key, Object? Function(String) ofCode) {
    final value = _field(key, nullable: false);
    if (value == null) return;
    if (value is! String) {
      violations.add(TargetRuleViolation.type);
    } else if (ofCode(value) == null) {
      violations.add(TargetRuleViolation.vocabulary);
    }
  }

  int? integer(
    String key, {
    required int min,
    required int max,
    required TargetRuleViolation code,
  }) {
    final value = _field(key, nullable: false);
    if (value == null) return null;
    if (value is! int) {
      violations.add(TargetRuleViolation.type);
      return null;
    }
    if (value < min || value > max) {
      violations.add(code);
      return null;
    }
    return value;
  }

  void revision() => integer(
    'revision',
    min: 1,
    max: TargetWireRules.maxRevision,
    code: TargetRuleViolation.revision,
  );

  /// Technical bounds: 0 … [TargetLimits.maxNumber]; [signed] allows the
  /// negative range too; [positive] excludes zero (the engine needs it).
  double? number(
    String key, {
    bool nullable = false,
    bool signed = false,
    bool positive = false,
  }) {
    final value = _field(key, nullable: nullable);
    if (value == null) return null;
    if (value is! num) {
      violations.add(TargetRuleViolation.type);
      return null;
    }
    final number = value.toDouble();
    final magnitude = signed ? number.abs() : number;
    if (!number.isFinite ||
        magnitude > TargetLimits.maxNumber ||
        magnitude < 0 ||
        (positive && number == 0)) {
      violations.add(TargetRuleViolation.number);
      return null;
    }
    return number;
  }

  bool? boolean(String key, {bool nullable = false}) {
    final value = _field(key, nullable: nullable);
    if (value == null) return null;
    if (value is! bool) {
      violations.add(TargetRuleViolation.type);
      return null;
    }
    return value;
  }

  LocalDate? date(String key, {bool nullable = false}) {
    final value = _field(key, nullable: nullable);
    if (value == null) return null;
    if (value is! String) {
      violations.add(TargetRuleViolation.type);
      return null;
    }
    final date = LocalDate.tryParse(value);
    if (date == null) violations.add(TargetRuleViolation.date);
    return date;
  }

  void text(String key, int maxLength) {
    final value = _field(key, nullable: true);
    if (value == null) return;
    if (value is! String) {
      violations.add(TargetRuleViolation.type);
    } else if (value.length > maxLength) {
      violations.add(TargetRuleViolation.nameLength);
    }
  }
}
