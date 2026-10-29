import 'dart:math' as math;

import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/features/targets/application/setup_input.dart';

// What the shared profile and goal forms hold while the user types (A13b
// WP5): the text as typed, in the unit it was typed in (TD-017, D17), and
// how it reads against the A12 engine's input rules (`TargetRules.input`,
// D15). Pure and immutable: setup's draft notifier (WP6) and Me's edit
// sheets (A13c) keep these values and ask them whether a page is complete.
// Values never appear in a `toString` (body data is sensitive).

/// Why a typed field can't be used yet. Content-free.
enum TypedFieldError {
  /// Nothing typed.
  empty,

  /// Not a plain number ("." alone, a year with a decimal).
  notANumber,

  /// A number outside the field's accepted range.
  outOfRange,
}

/// A field read: its `value`, or the `error` that keeps it from one.
typedef TypedRead<T> = ({T? value, TypedFieldError? error});

TypedRead<T> _ok<T>(T value) => (value: value, error: null);

TypedRead<T> _fail<T>(TypedFieldError error) => (value: null, error: error);

/// Reads a typed nonnegative number: decimal comma or point, Western,
/// Arabic-Indic and Persian digits, the Arabic decimal mark. Grouping and
/// signs are refused rather than guessed (the personal-food rule, A09).
/// Null for anything else.
double? parseTypedNumber(String text) {
  var value = text.trim();
  for (var i = 0; i < 10; i++) {
    value = value
        .replaceAll(String.fromCharCode(0x660 + i), '$i')
        .replaceAll(String.fromCharCode(0x6f0 + i), '$i');
  }
  value = value.replaceAll(',', '.').replaceAll('٫', '.');
  if (!RegExp(r'^(?:[0-9]+(?:\.[0-9]*)?|\.[0-9]+)$').hasMatch(value)) {
    return null;
  }
  final number = double.tryParse(value);
  return number == null || !number.isFinite ? null : number;
}

TypedRead<double> _number(String text) {
  if (text.trim().isEmpty) return _fail(TypedFieldError.empty);
  final number = parseTypedNumber(text);
  return number == null ? _fail(TypedFieldError.notANumber) : _ok(number);
}

/// Reads a birth year: a whole year giving an age of 18–100 on [today]
/// (D15).
TypedRead<int> readBirthYear(String text, LocalDate today) {
  final read = _number(text);
  final number = read.value;
  if (number == null) return _fail(read.error!);
  if (number != number.truncateToDouble() || number > 9999) {
    return _fail(TypedFieldError.notANumber);
  }
  final year = number.toInt();
  return TargetRules.input.birthYear(year, today)
      ? _ok(year)
      : _fail(TypedFieldError.outOfRange);
}

/// A height as typed: centimetres, or feet and inches (TG-002, D17). The
/// texts of both units are kept, so switching back shows what was typed.
final class HeightDraft {
  /// A height typed in [unit].
  const new({
    this.unit = HeightInputUnit.centimeter,
    this.cm = '',
    this.feet = '',
    this.inches = '',
  });

  /// The unit the height is typed in.
  final HeightInputUnit unit;

  /// The centimetres text.
  final String cm;

  /// The feet text.
  final String feet;

  /// The inches text (empty reads as 0 when feet are typed).
  final String inches;

  /// This draft with [unit]; the texts stay as typed (no conversion).
  HeightDraft withUnit(HeightInputUnit unit) =>
      HeightDraft(unit: unit, cm: cm, feet: feet, inches: inches);

  /// This draft with new texts.
  HeightDraft copyWith({String? cm, String? feet, String? inches}) =>
      HeightDraft(
        unit: unit,
        cm: cm ?? this.cm,
        feet: feet ?? this.feet,
        inches: inches ?? this.inches,
      );

  /// The height, within 100–250 cm (D15). Inches must be under 12.
  TypedRead<Length> read() {
    final Length length;
    switch (unit) {
      case HeightInputUnit.centimeter:
        final read = _number(cm);
        if (read.value == null) return _fail(read.error!);
        length = Length.centimeters(read.value!);
      case HeightInputUnit.feetInches:
        final ft = _number(feet);
        if (ft.value == null) return _fail(ft.error!);
        final inch = inches.trim().isEmpty ? _ok<double>(0) : _number(inches);
        if (inch.value == null) return _fail(inch.error!);
        if (inch.value! >= 12) return _fail(TypedFieldError.outOfRange);
        length = Length.feetAndInches(ft.value!, inch.value!);
    }
    return TargetRules.input.height(length.centimeters)
        ? _ok(length)
        : _fail(TypedFieldError.outOfRange);
  }

  @override
  String toString() => 'HeightDraft(${unit.code})';
}

/// A body weight as typed in kg or lb (TD-017). A unit switch relabels the
/// number, as A14's weigh-in sheet does.
final class BodyWeightDraft {
  /// [text] in [unit].
  const new({this.unit = MassUnit.kilogram, this.text = ''});

  /// `kg` or `lb`.
  final MassUnit unit;

  /// The number as typed.
  final String text;

  /// This draft with [unit], the text unchanged.
  BodyWeightDraft withUnit(MassUnit unit) =>
      BodyWeightDraft(unit: unit, text: text);

  /// This draft with [text].
  BodyWeightDraft withText(String text) =>
      BodyWeightDraft(unit: unit, text: text);

  /// The weight in kg by A14's weigh-in rule (WB-003, A14 D6: 20–500 kg
  /// after conversion, kg rounded as stored), since it becomes the first
  /// weigh-in (TD-090).
  TypedRead<double> read() {
    final number = _number(text);
    if (number.value == null) return _fail(number.error!);
    final input = WeighInInput(number.value!, unit);
    return input.validate() == null
        ? _ok(input.kg)
        : _fail(TypedFieldError.outOfRange);
  }

  @override
  String toString() => 'BodyWeightDraft(${unit.code})';
}

/// Reads [text] in [unit] as kg, accepted by [inRange].
TypedRead<double> readMassKg(
  String text,
  MassUnit unit,
  bool Function(double kg) inRange,
) {
  final read = _number(text);
  if (read.value == null) return _fail(read.error!);
  final kg = Mass.of(read.value!, unit).kilograms;
  return inRange(kg) ? _ok(kg) : _fail(TypedFieldError.outOfRange);
}

/// The ranges the forms name in their messages, in the typed unit and
/// rounded inwards, so every number shown is accepted (D15).
abstract final class TypedRanges {
  /// Body and target weight in [unit], one decimal (the same 20–500 kg as
  /// A14's weigh-ins, `WeighInBounds`).
  static ({double min, double max}) weight(MassUnit unit) => (
    min: _ceil1(Mass.kilograms(TargetInputRules.minWeightKg).inUnit(unit)),
    max: _floor1(Mass.kilograms(TargetInputRules.maxWeightKg).inUnit(unit)),
  );

  /// Height in whole cm.
  static ({int min, int max}) heightCm() => (
    min: TargetInputRules.minHeightCm.ceil(),
    max: TargetInputRules.maxHeightCm.floor(),
  );

  /// Height in whole feet and inches.
  static ({({int feet, int inches}) min, ({int feet, int inches}) max})
  heightFeetInches() {
    final min = Length.centimeters(TargetInputRules.minHeightCm)
        .inUnit(LengthUnit.inch)
        .ceil();
    final max = Length.centimeters(TargetInputRules.maxHeightCm)
        .inUnit(LengthUnit.inch)
        .floor();
    return (
      min: (feet: min ~/ 12, inches: min % 12),
      max: (feet: max ~/ 12, inches: max % 12),
    );
  }

  /// The largest weekly rate in [unit], one decimal.
  static double maxRate(MassUnit unit) =>
      _floor1(Mass.kilograms(TargetInputRules.maxKgPerWeek).inUnit(unit));

  /// The largest monthly change in [unit], one decimal.
  static double maxMonth(MassUnit unit) =>
      _floor1(Mass.kilograms(TargetInputRules.maxMonthKg).inUnit(unit));

  // Cleaned to 6 decimals first, so 20 kg in kg stays 20.0, not 20.1.
  static double _ceil1(double value) =>
      roundHalfAwayFromZero(value * 10, 6).ceil() / 10;

  static double _floor1(double value) =>
      roundHalfAwayFromZero(value * 10, 6).floor() / 10;
}

/// A field of the goal form.
enum GoalField {
  /// Lose, maintain or gain.
  type,

  /// The weekly amount ("Per week").
  rate,

  /// The amount this month ("This month").
  month,

  /// The target weight (both target-weight expressions).
  targetWeight,

  /// The target date ("Target weight by a date").
  targetDate,

  /// The weekly pace ("Target weight at a pace").
  pace,
}

/// A goal as typed (TG-010/011, D9 page 3): the direction, how it is
/// expressed, and the texts of every expression (kept when the user
/// switches between them), in the goal's weight unit (TD-017, D17).
final class GoalDraft {
  /// A draft in [unit].
  const new({
    this.type,
    this.kind = GoalExpressionKind.weekly,
    this.unit = MassUnit.kilogram,
    this.rate = '',
    this.month = '',
    this.targetWeight = '',
    this.targetDate,
    this.pace = '',
  });

  /// The prefilled weekly loss, kg (D9).
  static const double defaultLossKgPerWeek = .5;

  /// The prefilled weekly gain, kg (D9).
  static const double defaultGainKgPerWeek = .25;

  /// The direction, or null before one is chosen.
  final GoalType? type;

  /// How a lose or gain goal is expressed.
  final GoalExpressionKind kind;

  /// `kg` or `lb`.
  final MassUnit unit;

  /// The weekly amount text (unsigned; the direction gives the sign).
  final String rate;

  /// The amount-this-month text (unsigned).
  final String month;

  /// The target weight text.
  final String targetWeight;

  /// The target date, or null before one is picked.
  final LocalDate? targetDate;

  /// The weekly pace text toward the target weight.
  final String pace;

  /// This draft for [type]: the weekly amount is prefilled with the
  /// default for the direction (0.5 kg lose, 0.25 kg gain, in [unit]) while
  /// it is empty or still another direction's default.
  GoalDraft withType(GoalType type) {
    final prefill = rate.trim().isEmpty || _isDefaultRate(rate, unit);
    return _copy(
      type: type,
      rate: prefill ? defaultRateText(type, unit) : rate,
    );
  }

  /// This draft expressed as [kind].
  GoalDraft withKind(GoalExpressionKind kind) => _copy(kind: kind);

  /// This draft in [unit]: the numbers are relabelled, except an untouched
  /// default amount, which is prefilled again in [unit].
  GoalDraft withUnit(MassUnit unit) {
    final type = this.type;
    final keepDefault =
        type != null && rate == defaultRateText(type, this.unit);
    return _copy(
      unit: unit,
      rate: keepDefault ? defaultRateText(type, unit) : rate,
    );
  }

  /// This draft with new texts or a new date.
  GoalDraft copyWith({
    String? rate,
    String? month,
    String? targetWeight,
    LocalDate? targetDate,
    String? pace,
  }) => _copy(
    rate: rate,
    month: month,
    targetWeight: targetWeight,
    targetDate: targetDate,
    pace: pace,
  );

  GoalDraft _copy({
    GoalType? type,
    GoalExpressionKind? kind,
    MassUnit? unit,
    String? rate,
    String? month,
    String? targetWeight,
    LocalDate? targetDate,
    String? pace,
  }) => GoalDraft(
    type: type ?? this.type,
    kind: kind ?? this.kind,
    unit: unit ?? this.unit,
    rate: rate ?? this.rate,
    month: month ?? this.month,
    targetWeight: targetWeight ?? this.targetWeight,
    targetDate: targetDate ?? this.targetDate,
    pace: pace ?? this.pace,
  );

  /// The prefilled weekly amount for [type] in [unit] (empty for
  /// maintain), two decimals at most: "0.5", "0.25", "1.1" (lb).
  static String defaultRateText(GoalType type, MassUnit unit) {
    final kg = switch (type) {
      GoalType.lose => defaultLossKgPerWeek,
      GoalType.gain => defaultGainKgPerWeek,
      GoalType.maintain => null,
    };
    if (kg == null) return '';
    final value = roundHalfAwayFromZero(Mass.kilograms(kg).inUnit(unit), 2);
    return value == value.truncateToDouble()
        ? value.toInt().toString()
        : value.toString();
  }

  static bool _isDefaultRate(String text, MassUnit unit) =>
      text == defaultRateText(GoalType.lose, unit) ||
      text == defaultRateText(GoalType.gain, unit);

  /// Reads the draft on [today]: the [GoalInput] (canonical kg, signed by
  /// the direction; "This month" is [today]'s calendar month), or the
  /// fields that keep it from one. Whether the goal can be resolved against
  /// the current weight is [GoalProblem.of]'s question.
  GoalDraftRead read(LocalDate today) {
    final type = this.type;
    if (type == null) {
      return GoalDraftRead._({GoalField.type: TypedFieldError.empty});
    }
    if (type == GoalType.maintain) {
      return GoalDraftRead._(
        const {},
        GoalInput.maintain(weightInputUnit: unit),
      );
    }
    final sign = type == GoalType.lose ? -1 : 1;
    const rules = TargetRules.input;
    final errors = <GoalField, TypedFieldError>{};
    double? field(
      GoalField name,
      String text,
      bool Function(double kg) inRange,
    ) {
      final read = readMassKg(text, unit, inRange);
      if (read.error != null) errors[name] = read.error!;
      return read.value;
    }

    bool positive(double kg, bool Function(double) rule) => kg > 0 && rule(kg);
    final GoalExpression? expression;
    switch (kind) {
      case GoalExpressionKind.weekly:
        final kg = field(
          GoalField.rate,
          rate,
          (kg) => positive(kg, rules.kgPerWeek),
        );
        expression = kg == null ? null : GoalExpression.weekly(sign * kg);
      case GoalExpressionKind.monthly:
        final kg = field(
          GoalField.month,
          month,
          (kg) => positive(kg, rules.monthKg),
        );
        expression = kg == null
            ? null
            : GoalExpression.monthly(
                sign * kg,
                LocalDate(today.year, today.month, 1),
              );
      case GoalExpressionKind.targetDate:
        final target = field(
          GoalField.targetWeight,
          targetWeight,
          rules.weight,
        );
        final date = targetDate;
        if (date == null) {
          errors[GoalField.targetDate] = TypedFieldError.empty;
        } else if (date.isAfter(rules.latestTargetDate(today))) {
          errors[GoalField.targetDate] = TypedFieldError.outOfRange;
        }
        // A date not after today is a goal problem, not a field error (PA3).
        expression = target == null || errors.isNotEmpty
            ? null
            : GoalExpression.targetDate(target, date!);
      case GoalExpressionKind.targetRate:
        final target = field(
          GoalField.targetWeight,
          targetWeight,
          rules.weight,
        );
        final speed = field(
          GoalField.pace,
          pace,
          (kg) => positive(kg, rules.kgPerWeek),
        );
        expression = target == null || speed == null
            ? null
            : GoalExpression.targetRate(target, speed);
    }
    if (expression == null) return GoalDraftRead._(errors);
    return GoalDraftRead._(
      errors,
      GoalInput(type: type, expression: expression, weightInputUnit: unit),
    );
  }

  @override
  String toString() => 'GoalDraft(${type?.name}, ${kind.name})';
}

/// A [GoalDraft] read: the [input], or the field [errors].
final class GoalDraftRead {
  new _(Map<GoalField, TypedFieldError> errors, [this.input])
    : errors = Map.unmodifiable(errors);

  /// The goal, or null while a field keeps it from one.
  final GoalInput? input;

  /// Why each field can't be used. Unmodifiable.
  final Map<GoalField, TypedFieldError> errors;

  @override
  String toString() => 'GoalDraftRead(${input == null ? 'incomplete' : 'ok'})';
}

/// Why a goal can't be resolved against the current weight (PA3). A typed
/// goal shows it instead of numbers and keeps Next disabled; a stored goal
/// (`TargetIssue.goalNeedsUpdate`) shows it as a neutral line in Me (A13c).
enum GoalProblem {
  /// The target date isn't after today (typed: pick a later date; stored:
  /// the goal date has passed).
  deadline,

  /// A lose goal whose target weight isn't below the current weight
  /// (stored: the target is reached).
  targetNotBelow,

  /// A gain goal whose target weight isn't above the current weight
  /// (stored: the target is reached).
  targetNotAbove;

  /// The problem of [goal] at [currentKg] on [today], or null when the A12
  /// engine resolves it.
  static GoalProblem? of(
    GoalInput goal, {
    required double currentKg,
    required LocalDate today,
  }) {
    try {
      ResolvedGoal.resolve(
        type: goal.type,
        expression: goal.expression,
        currentKg: math.max(currentKg, TargetLimits.minWeight),
        date: today,
      );
      return null;
    }
    // The engine's content-free signal for an unresolvable goal (PA3).
    // ignore: avoid_catching_errors
    on ArgumentError {
      if (goal.expression case TargetDateGoal(:final date)
          when !date.isAfter(today)) {
        return GoalProblem.deadline;
      }
      return goal.type == GoalType.gain
          ? GoalProblem.targetNotAbove
          : GoalProblem.targetNotBelow;
    }
  }
}
