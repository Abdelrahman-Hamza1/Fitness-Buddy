import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/features/body/application/weight_providers.dart';
import 'package:fb_mobile/features/body/application/weight_tip.dart';
import 'package:fb_mobile/features/settings/settings.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'weight_card_state.g.dart';

/// What the weight card of one day page shows (HM-005, HM-009, WB-011,
/// WB-012, A14 D9/D10): everything "as of" that day.
final class WeightCardState {
  /// See [weightCard].
  const new({
    required this.asOf,
    required this.units,
    this.latest,
    this.cadence,
    this.showTip = false,
    this.hasHistory = false,
  });

  /// The trend, weekly rate (or none: too little history, or stale) and
  /// last weigh-in day on or before the day.
  final WeightAsOf asOf;

  /// The latest weigh-in measured on or before the day (any of the day's
  /// weigh-ins, not only the trend's choice), or `null`.
  final WeighIn? latest;

  /// The weigh-in cadence of the last 4 weeks, on today's page only, and
  /// only once there is a weekly rate (the "rate after 2 weeks" line says
  /// enough until then; A14 UX review M2).
  final WeighInCadence? cadence;

  /// Whether the "weigh in 2–3 times a week" suggestion shows (today only,
  /// at most once in 30 days).
  final bool showTip;

  /// The unit setting (LC-010).
  final UnitSystem units;

  /// Whether there are weigh-ins at all (later than the day when [isEmpty]:
  /// a past page invites one for that day rather than the "first" one).
  final bool hasHistory;

  /// No weigh-in on or before the day.
  bool get isEmpty => asOf.trendKg == null;

  /// Never the values.
  @override
  String toString() => 'WeightCardState(empty: $isEmpty, tip: $showTip)';
}

/// The weight card's state for [date] (A14 D9). [isToday] adds the
/// cadence and the suggestion (D10, PA3: today's page only).
///
/// Synchronous over the shared weigh-in and trend streams: once they have
/// loaded (for any page), a newly shown day page has its card in the same
/// frame, with no skeleton. The unit setting is read only when there is a
/// weight to show, and the suggestion's preference only when it could show
/// (until it has loaded the suggestion stays hidden).
@riverpod
AsyncValue<WeightCardState> weightCard(
  Ref ref,
  LocalDate date, {
  required bool isToday,
}) {
  final weighInsValue = ref.watch(weighInsProvider);
  final trendValue = ref.watch(weightTrendProvider);
  if (weighInsValue.value == null || trendValue.value == null) {
    if (weighInsValue case AsyncError(:final error, :final stackTrace)) {
      return AsyncError(error, stackTrace);
    }
    if (trendValue case AsyncError(:final error, :final stackTrace)) {
      return AsyncError(error, stackTrace);
    }
    return const AsyncLoading();
  }
  final weighIns = weighInsValue.requireValue;
  final trend = trendValue.requireValue;
  final asOf = trend.asOf(date);
  if (asOf.trendKg == null) {
    return AsyncData(
      WeightCardState(
        asOf: asOf,
        units: UnitSystem.defaultSystem,
        hasHistory: trend.points.isNotEmpty,
      ),
    );
  }
  final unitsValue = ref.watch(unitSystemProvider);
  if (unitsValue.isLoading && !unitsValue.hasValue) return const AsyncLoading();
  final units = unitsValue.value ?? UnitSystem.defaultSystem;
  WeighIn? latest;
  for (final weighIn in weighIns) {
    if (weighIn.localDate.isAfter(date) || !weighIn.isReadable) continue;
    if (latest == null || _isLater(weighIn, latest)) latest = weighIn;
  }
  WeighInCadence? cadence;
  var showTip = false;
  // While the rate is not available yet (under 2 weeks of history) the card
  // says so, and the cadence line and the suggestion wait (M2). Stale has no
  // rate either, and no line: the trend row already says "from {date}".
  if (isToday && asOf.weeklyRateKg != null) {
    cadence = WeighInCadence.of([
      for (final p in trend.points) p.localDate,
    ], date);
    if (cadence.kind == CadenceKind.sparse) {
      final tip = ref.watch(weightTipControllerProvider).value;
      showTip = tip != null && CadenceTipRule.shouldShow(tip, date, cadence);
    }
  }
  return AsyncData(
    WeightCardState(
      asOf: asOf,
      units: units,
      latest: latest,
      cadence: cadence,
      showTip: showTip,
      hasHistory: true,
    ),
  );
}

bool _isLater(WeighIn a, WeighIn b) {
  final byTime = a.time.occurredAtUtc.compareTo(b.time.occurredAtUtc);
  return byTime != 0 ? byTime > 0 : a.id.compareTo(b.id) > 0;
}
