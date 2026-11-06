import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/l10n/gen/app_localizations.dart';
import 'package:intl/intl.dart' show NumberFormat;

// The one place "~" and "—" are added to a number (A62 D16, D-096): a value
// that includes an estimate or is only a lower bound shows "~" before it, a
// nutrient with nothing known shows "—", never 0. Only the symbols: tapping
// "~" explains nothing except on your own estimate (its popup).

/// [text] with "~" before it when [approximate].
String approxText(
  AppLocalizations l10n,
  String text, {
  required bool approximate,
}) => approximate ? l10n.approx(text) : text;

/// [field] of [intake] formatted by [format], "~" when approximate, "—"
/// when nothing is known.
String intakeText(
  AppLocalizations l10n,
  IntakeTotals intake,
  NutrientField field,
  String Function(double value) format,
) {
  final value = intake.valueOf(field);
  if (value == null) return l10n.unknownValue;
  return approxText(
    l10n,
    format(value),
    approximate: intake.isApproximate(field),
  );
}

/// [field] of [averages] formatted by [format], "~" when approximate, "—"
/// when unknown.
String averageText(
  AppLocalizations l10n,
  IntakeAverages averages,
  NutrientField field,
  String Function(double value) format,
) {
  final value = averages.valueOf(field);
  if (value == null) return l10n.unknownValue;
  return approxText(
    l10n,
    format(value),
    approximate: averages.isApproximate(field),
  );
}

/// [intake]'s calories as a summary shows them: display-rounded, grouped
/// in the locale, "~" when it holds an estimate ("~1,250").
String kcalSummaryText(AppLocalizations l10n, IntakeTotals intake) =>
    approxText(
      l10n,
      NumberFormat.decimalPattern(l10n.localeName)
          .format(DisplayRounding.kcal(intake.sum.kcal)),
      approximate: intake.estimated,
    );

/// Display-rounded grams in the locale ("30", "4.5").
String gramsText(AppLocalizations l10n, double grams) =>
    NumberFormat.decimalPattern(l10n.localeName)
        .format(DisplayRounding.nutrientGrams(grams));

/// [intakeText] for a screen reader: "about 30", "unknown".
String intakeSpoken(
  AppLocalizations l10n,
  IntakeTotals intake,
  NutrientField field,
  String Function(double value) format,
) {
  final value = intake.valueOf(field);
  if (value == null) return l10n.unknownValueSpoken;
  final text = format(value);
  return intake.isApproximate(field) ? l10n.approxSpoken(text) : text;
}
