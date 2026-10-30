import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/features/body/application/weight_history_form.dart'
    show parseWeightHistoryNumber;

/// Why the measurement sheet can't save yet. Content-free.
enum MeasurementFormIssue {
  /// Nothing (or not a number) typed.
  empty,

  /// Outside the local range (10–300 cm, 2–75 %).
  outOfRange,

  /// Before 1970 or otherwise refused by the draft rules.
  invalid,
}

/// The measurement sheet's state (WB-040, A15b D18): the type, what was
/// typed, in which unit, and when. Immutable and pure: every edit returns
/// a new state; time comes in as a parameter.
///
/// **Edit ≠ create (PA3):** an edit opens with the entry's exact input,
/// unit, instant and stored offset. Until the user changes the value or
/// the unit, the stored input is kept as it is, so open + Save writes
/// nothing; a date-only change keeps the local time of day and the entry's
/// own offset ([EntryTime.onDate]). A new entry starts now, in the unit
/// setting, prefilled with the type's latest value.
final class MeasurementFormState {
  const new _({
    required this.type,
    required this.unit,
    required this.time,
    required this.lengthUnit,
    this.text = '',
    this.editing,
    this.touched = false,
  });

  /// A new entry of [type] at [now], in [lengthUnit] (body fat: %),
  /// prefilled with [latest] (the type's newest entry, if any).
  factory create({
    required MeasurementTypeRef type,
    required LengthUnit lengthUnit,
    required EntryTime now,
    Measurement? latest,
  }) {
    final unit = _unitFor(type.kind, lengthUnit);
    return MeasurementFormState._(
      type: type,
      unit: unit,
      time: now,
      lengthUnit: lengthUnit,
      text: latest == null ? '' : _prefill(latest, unit),
    );
  }

  /// An edit of [editing]: its exact value as typed, unit, time and offset.
  factory edit(Measurement editing, {required LengthUnit lengthUnit}) =>
      MeasurementFormState._(
        type: editing.type,
        unit: editing.input.unit,
        time: editing.time,
        lengthUnit: lengthUnit,
        text: numberText(editing.input.value),
        editing: editing,
      );

  /// The local time a new entry dated in the past gets (08:00).
  static final LocalTime pastTime = LocalTime(8);

  /// The series.
  final MeasurementTypeRef type;

  /// The unit the number means.
  final MeasurementUnit unit;

  /// When it was measured.
  final EntryTime time;

  /// The unit setting's length unit.
  final LengthUnit lengthUnit;

  /// The value as typed. User content.
  final String text;

  /// The entry being edited, at the version shown; `null` for a new one.
  final Measurement? editing;

  /// Whether the user changed the value or the unit.
  final bool touched;

  /// Whether this edits a stored entry.
  bool get isEdit => editing != null;

  /// The units this type can be typed in.
  List<MeasurementUnit> get units => type.kind.isLength
      ? const [MeasurementUnit.cm, MeasurementUnit.inch]
      : const [MeasurementUnit.percent];

  /// Another [type] for a new entry, in its unit, prefilled with [latest].
  /// An edit keeps its type (moving an entry is delete + create).
  MeasurementFormState withType(
    MeasurementTypeRef type, {
    Measurement? latest,
  }) {
    if (isEdit || type == this.type) return this;
    final unit = _unitFor(type.kind, lengthUnit);
    return _copy(
      type: type,
      unit: unit,
      text: latest == null ? '' : _prefill(latest, unit),
      touched: false,
    );
  }

  /// [text] typed.
  MeasurementFormState withText(String text) =>
      text == this.text ? this : _copy(text: text, touched: true);

  /// The number relabelled as [unit] (never converted, LC-011).
  MeasurementFormState withUnit(MeasurementUnit unit) =>
      unit == this.unit || !units.contains(unit)
      ? this
      : _copy(unit: unit, touched: true);

  /// Moved to [date]. An edit keeps its local time of day and offset; a new
  /// entry on [now]'s day is now, on a past day 08:00 local ([clock]'s
  /// zone at that date).
  MeasurementFormState withDate(
    LocalDate date, {
    required EntryTime now,
    required Clock clock,
  }) {
    if (date == time.localDate) return this;
    if (isEdit) return _copy(time: time.onDate(date));
    return _copy(
      time: date == now.localDate
          ? now
          : EntryTime.fromLocal(pastTime.on(date), clock),
    );
  }

  /// What Save would store, or `null` while nothing usable is typed. An
  /// untouched edit keeps the stored input exactly.
  MeasurementDraft? get draft {
    final MeasurementInput input;
    if (editing case final e? when !touched) {
      input = e.input;
    } else {
      final value = parseWeightHistoryNumber(text);
      if (value == null) return null;
      input = MeasurementInput(value, unit);
    }
    return MeasurementDraft(type: type, time: time, input: input);
  }

  /// Why Save is off, or `null`.
  MeasurementFormIssue? get issue {
    final draft = this.draft;
    if (draft == null) return MeasurementFormIssue.empty;
    return switch (draft.validate()) {
      null => null,
      MeasurementIssue.outOfRange => MeasurementFormIssue.outOfRange,
      _ => MeasurementFormIssue.invalid,
    };
  }

  /// [value] as field text: "92", "92.25" (at most two decimals, `.`).
  static String numberText(double value) {
    final hundredths = (value * 100).round();
    if (hundredths % 100 == 0) return '${hundredths ~/ 100}';
    final text = (hundredths / 100).toStringAsFixed(2);
    return text.endsWith('0') ? text.substring(0, text.length - 1) : text;
  }

  static MeasurementUnit _unitFor(MeasurementKind kind, LengthUnit length) =>
      kind.isLength
      ? MeasurementUnit.ofLength(length)
      : MeasurementUnit.percent;

  /// [latest] in [unit]: as typed when the units match, else converted to
  /// one decimal.
  static String _prefill(Measurement latest, MeasurementUnit unit) {
    if (latest.input.unit == unit) return numberText(latest.input.value);
    final converted = latest.value / unit.factor;
    return numberText((converted * 10).round() / 10);
  }

  MeasurementFormState _copy({
    MeasurementTypeRef? type,
    MeasurementUnit? unit,
    EntryTime? time,
    String? text,
    bool? touched,
  }) => MeasurementFormState._(
    type: type ?? this.type,
    unit: unit ?? this.unit,
    time: time ?? this.time,
    lengthUnit: lengthUnit,
    text: text ?? this.text,
    editing: editing,
    touched: touched ?? this.touched,
  );

  @override
  String toString() => 'MeasurementFormState(${type.key}, ${unit.code})';
}
