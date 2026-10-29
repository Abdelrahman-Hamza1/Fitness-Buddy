import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/l10n/gen/app_localizations.dart';
import 'package:intl/intl.dart' show NumberFormat;

// The one place a body weight becomes text (A14 D13): one decimal, the
// locale's separators, kg or lb. Words only, never judgement: a change is a
// signed number, not "gained" or "lost".

/// The minus sign of a signed weight (U+2212), not a hyphen.
const String _minus = '\u2212';

/// [kg] in [unit] (no rounding).
double weightIn(double kg, MassUnit unit) => kg * 1000 / unit.grams;

/// The unit word: "kg" or "lb".
String weightUnitLabel(AppLocalizations l10n, MassUnit unit) =>
    unit == MassUnit.pound ? l10n.weightUnitLb : l10n.weightUnitKg;

/// [value] with one decimal and the locale's separators: "97.6", "1,102.3".
String weightNumber(AppLocalizations l10n, double value) =>
    NumberFormat.decimalPatternDigits(
      locale: l10n.localeName,
      decimalDigits: 1,
    ).format(value);

/// [kg] shown in [unit]: "97.6 kg", "215.2 lb".
String weightText(AppLocalizations l10n, double kg, MassUnit unit) =>
    l10n.weightValue(
      weightNumber(l10n, weightIn(kg, unit)),
      weightUnitLabel(l10n, unit),
    );

/// [value] in [unit] as a whole number: "20 kg", "1,102 lb" (the range
/// hint's bounds).
String weightWholeText(AppLocalizations l10n, int value, MassUnit unit) =>
    l10n.weightValue(
      NumberFormat.decimalPatternDigits(
        locale: l10n.localeName,
        decimalDigits: 0,
      ).format(value),
      weightUnitLabel(l10n, unit),
    );

/// [kg] in [unit] for a screen reader, the unit in full: "97.6 kilograms".
String weightSpoken(AppLocalizations l10n, double kg, MassUnit unit) =>
    _spoken(l10n, weightNumber(l10n, weightIn(kg, unit)), unit);

/// A signed change of [diffKg] in [unit] for a screen reader:
/// "−0.4 kilograms".
String weightSpokenChange(
  AppLocalizations l10n,
  double diffKg,
  MassUnit unit,
) => _spoken(l10n, signedWeightNumber(l10n, weightIn(diffKg, unit)), unit);

String _spoken(AppLocalizations l10n, String value, MassUnit unit) =>
    unit == MassUnit.pound
    ? l10n.weightSpokenLb(value)
    : l10n.weightSpokenKg(value);

/// A weigh-in as it was typed: "214.0 lb" (TG-002: the typed unit is kept).
String weighInInputText(AppLocalizations l10n, WeighInInput input) =>
    l10n.weightValue(
      weightNumber(l10n, input.value),
      weightUnitLabel(l10n, input.unit),
    );

/// [value] with a sign and one decimal: "+0.3", "−0.4", and "0.0" for
/// anything that rounds to zero (below 0.05 either way, A14 D2). A
/// non-finite [value] (never from readable rows) shows as "0.0" rather than
/// failing.
String signedWeightNumber(AppLocalizations l10n, double value) {
  if (!value.isFinite) return weightNumber(l10n, 0);
  final tenths = (value.abs() * 10).round();
  final number = weightNumber(l10n, tenths / 10);
  if (tenths == 0) return number;
  return value < 0 ? '$_minus$number' : '+$number';
}

/// A difference of [diffKg] in [unit]: "+3.0 kg", "−1.2 lb".
String weightDiffText(AppLocalizations l10n, double diffKg, MassUnit unit) =>
    l10n.weightValue(
      signedWeightNumber(l10n, weightIn(diffKg, unit)),
      weightUnitLabel(l10n, unit),
    );

/// The weekly rate of the trend in [unit]: "−0.4 kg/week" (WB-011).
String weightRateText(AppLocalizations l10n, double kgPerWeek, MassUnit unit) =>
    l10n.weightCardRate(
      signedWeightNumber(l10n, weightIn(kgPerWeek, unit)),
      weightUnitLabel(l10n, unit),
    );

/// The pad's [text] ("97.4", as typed with `.`) with the locale's decimal
/// separator; empty reads as "0".
String weightTyped(AppLocalizations l10n, String text) {
  if (text.isEmpty) return '0';
  final separator = NumberFormat.decimalPattern(l10n.localeName)
      .symbols
      .DECIMAL_SEP;
  return text.replaceFirst('.', separator);
}
