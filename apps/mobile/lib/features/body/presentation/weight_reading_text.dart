import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/l10n/day_label.dart';
import 'package:fb_mobile/core/l10n/l10n.dart';
import 'package:fb_mobile/features/body/presentation/weight_text.dart';
import 'package:material_ui/material_ui.dart';

// The texts of the main weight number (WB-011, D-102): the latest weigh-in
// as entered while the user weighs in rarely, else the trend with the
// latest next to it. Today's line, Progress and Me › Profile share them.

/// The latest weigh-in of [reading] in [unit]: as typed when it was typed
/// in [unit] ("107.7 kg", TD-017), else converted.
String readingLastText(
  AppLocalizations l10n,
  WeightReading reading,
  MassUnit unit,
) => reading.lastInput.unit == unit
    ? weighInInputText(l10n, reading.lastInput)
    : weightText(l10n, reading.lastKg, unit);

/// The big number of [reading] in [unit]: the latest as entered or the
/// trend.
String readingMainText(
  AppLocalizations l10n,
  WeightReading reading,
  MassUnit unit,
) => switch (reading) {
  LatestWeightReading() => readingLastText(l10n, reading, unit),
  TrendWeightReading(:final trendKg) => weightText(l10n, trendKg, unit),
};

/// One line for a half-width tile or a row: "107.7 kg · Sat" (latest) or
/// "108.1 kg · −0.4 kg/week" (trend, with its rate once there is one).
String readingLineText(
  BuildContext context,
  WeightReading reading,
  MassUnit unit,
  LocalDate today,
) {
  final l10n = context.l10n;
  final main = readingMainText(l10n, reading, unit);
  return switch (reading) {
    LatestWeightReading(:final lastDate) => l10n.todayGlanceWeightLatest(
      main,
      dayLabelShort(context, lastDate, today),
    ),
    TrendWeightReading(:final weeklyRateKg?) => l10n.todayGlanceWeight(
      main,
      weightRateText(l10n, weeklyRateKg, unit),
    ),
    TrendWeightReading() => main,
  };
}

/// The supporting line of [reading] (WB-011): the change since the
/// weigh-in before ("−1.1 kg since last weigh-in (10 days)", "Your first
/// weigh-in"), or the latest weigh-in next to the trend ("last 107.7 kg ·
/// today · −0.4 kg/week").
String readingDetailText(
  BuildContext context,
  WeightReading reading,
  MassUnit unit,
  LocalDate today,
) {
  final l10n = context.l10n;
  final day = dayLabelShort(context, reading.lastDate, today);
  return switch (reading) {
    LatestWeightReading(:final changeKg?, :final daysSincePrevious?) =>
      l10n.weightReadingChange(
        weightDiffText(l10n, changeKg, unit),
        daysSincePrevious,
      ),
    LatestWeightReading() => l10n.weightReadingFirst,
    TrendWeightReading(:final weeklyRateKg?) => l10n.weightReadingLastRate(
      readingLastText(l10n, reading, unit),
      day,
      weightRateText(l10n, weeklyRateKg, unit),
    ),
    TrendWeightReading() => l10n.weightReadingLast(
      readingLastText(l10n, reading, unit),
      day,
    ),
  };
}

/// What a screen reader says for [reading]: the number, its day and the
/// change (latest), or the trend, its rate and the latest weigh-in.
String readingSemantics(
  BuildContext context,
  WeightReading reading,
  MassUnit unit,
  LocalDate today,
) {
  final l10n = context.l10n;
  final day = dayLabelInline(context, reading.lastDate, today);
  switch (reading) {
    case LatestWeightReading(:final changeKg):
      final spoken = _lastSpoken(l10n, reading, unit);
      return changeKg == null
          ? l10n.weightLatestSemantics(spoken, day)
          : l10n.weightLatestChangeSemantics(
              spoken,
              day,
              weightSpokenChange(l10n, changeKg, unit),
            );
    case TrendWeightReading(:final trendKg, :final weeklyRateKg):
      final spoken = weightSpoken(l10n, trendKg, unit);
      final summary = weeklyRateKg == null
          ? l10n.weightCardTrendSemantics(spoken)
          : l10n.weightCardTrendRateSemantics(
              spoken,
              weightSpokenChange(l10n, weeklyRateKg, unit),
            );
      return l10n.weightTrendLastSemantics(
        summary,
        _lastSpoken(l10n, reading, unit),
        day,
      );
  }
}

String _lastSpoken(
  AppLocalizations l10n,
  WeightReading reading,
  MassUnit unit,
) => reading.lastInput.unit == unit
    ? weightSpoken(l10n, reading.lastInput.kg, unit)
    : weightSpoken(l10n, reading.lastKg, unit);

/// The weight number of Progress's weight card (WB-011, D-102, design
/// board 3): a label ("Weight · Sat" or "Trend weight"), the big number and
/// one line (the change since the weigh-in before, or "last 107.7 kg ·
/// today · −0.4 kg/week"). One merged node for screen readers.
class WeightReadingHeader extends StatelessWidget {
  /// Shows [reading] in [unit] as of [today].
  const new({
    required this.reading,
    required this.unit,
    required this.today,
    super.key,
  });

  /// The reading.
  final WeightReading reading;

  /// The display unit.
  final MassUnit unit;

  /// Today, for the day words.
  final LocalDate today;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final muted = FbType.bodySmall.copyWith(color: scheme.onSurfaceVariant);
    final day = dayLabelShort(context, reading.lastDate, today);
    final title = switch (reading) {
      LatestWeightReading() => l10n.weightReadingLatestTitle(day),
      TrendWeightReading() => l10n.weightReadingTrendTitle,
    };
    final line = readingDetailText(context, reading, unit, today);
    return Semantics(
      key: const ValueKey('progress-weight-reading'),
      label: readingSemantics(context, reading, unit, today),
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: muted),
          Text(
            readingMainText(l10n, reading, unit),
            style: FbType.numeric(FbType.headline)
                .copyWith(color: scheme.onSurface),
          ),
          Text(line, style: muted),
        ],
      ),
    );
  }
}
