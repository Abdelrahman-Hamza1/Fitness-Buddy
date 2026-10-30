import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/l10n/gen/app_localizations.dart';
import 'package:intl/intl.dart' show NumberFormat;

// The one place a body measurement becomes text (A15b D26): one decimal,
// the locale's separators, cm / in / %. Words only, never judgement: a
// change is a signed number.

/// The minus sign of a signed value (U+2212), not a hyphen.
const String _minus = '−';

/// The canonical [value] (cm, or %) in [unit].
double measurementIn(double value, MeasurementUnit unit) => value / unit.factor;

/// The unit word: "cm", "in" or "%".
String measurementUnitLabel(AppLocalizations l10n, MeasurementUnit unit) =>
    switch (unit) {
      MeasurementUnit.cm => l10n.measurementUnitCm,
      MeasurementUnit.inch => l10n.measurementUnitIn,
      MeasurementUnit.percent => l10n.measurementUnitPercent,
    };

/// [value] with one decimal and the locale's separators: "92.5".
String measurementNumber(AppLocalizations l10n, double value) =>
    NumberFormat.decimalPatternDigits(
      locale: l10n.localeName,
      decimalDigits: 1,
    ).format(value);

/// The canonical [value] shown in [unit]: "92.0 cm", "36.2 in", "18.4 %".
String measurementText(
  AppLocalizations l10n,
  double value,
  MeasurementUnit unit,
) => l10n.measurementValue(
  measurementNumber(l10n, measurementIn(value, unit)),
  measurementUnitLabel(l10n, unit),
);

/// A measurement as it was typed: "36.5 in" (TD-017).
String measurementInputText(AppLocalizations l10n, MeasurementInput input) =>
    l10n.measurementValue(
      measurementNumber(l10n, input.value),
      measurementUnitLabel(l10n, input.unit),
    );

/// A signed change of the canonical [diff] in [unit]: "+0.5 cm", "−3.5 cm",
/// "0.0 cm" when it rounds to zero.
String measurementDiffText(
  AppLocalizations l10n,
  double diff,
  MeasurementUnit unit,
) {
  final value = measurementIn(diff, unit);
  final tenths = value.isFinite ? (value.abs() * 10).round() : 0;
  final number = measurementNumber(l10n, tenths / 10);
  final signed = tenths == 0
      ? number
      : value < 0
      ? '$_minus$number'
      : '+$number';
  return l10n.measurementValue(signed, measurementUnitLabel(l10n, unit));
}

/// The display unit of [kind] for the length unit [lengthUnit] (the unit
/// setting): % for body fat.
MeasurementUnit measurementDisplayUnit(
  MeasurementKind kind,
  LengthUnit lengthUnit,
) => kind.isLength
    ? MeasurementUnit.ofLength(lengthUnit)
    : MeasurementUnit.percent;

/// The name of [type]: the built-in kind's word, or [customName] (the
/// custom type's own name; user content).
String measurementTypeName(
  AppLocalizations l10n,
  MeasurementTypeRef type, {
  String? customName,
}) => switch (type.kind) {
  MeasurementKind.waist => l10n.measurementKindWaist,
  MeasurementKind.chest => l10n.measurementKindChest,
  MeasurementKind.hips => l10n.measurementKindHips,
  MeasurementKind.arm => l10n.measurementKindArm,
  MeasurementKind.thigh => l10n.measurementKindThigh,
  MeasurementKind.neck => l10n.measurementKindNeck,
  MeasurementKind.bodyFat => l10n.measurementKindBodyFat,
  MeasurementKind.custom => customName ?? '',
};
