import 'dart:async';

import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/l10n/day_label.dart';
import 'package:fb_mobile/core/l10n/l10n.dart';
import 'package:fb_mobile/core/time/clock_provider.dart';
import 'package:fb_mobile/features/body/application/weight_card_state.dart';
import 'package:fb_mobile/features/body/application/weight_providers.dart';
import 'package:fb_mobile/features/body/presentation/weigh_in_sheet.dart';
import 'package:fb_mobile/features/body/presentation/weight_text.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// The weight half of Today's slim line (HM-005, D-093, A57 D3): the trend
/// as of the viewed day and its weekly rate ("72.4 kg · −0.3 kg/week"), or
/// the trend and the day of an older weigh-in, or "Weigh in" before the
/// first one. A tap opens the weigh-in sheet for the viewed day, so a
/// weigh-in is tap, type, Save (WB-001, UX-005). Loading and a read error
/// keep the same height ([FbGlanceTile]); the error's tap retries.
class WeightGlance extends ConsumerWidget {
  /// Creates the half for [date].
  const new({required this.date, required this.isToday, super.key});

  /// The viewed day.
  final LocalDate date;

  /// Whether [date] is today.
  final bool isToday;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final card = ref.watch(weightCardProvider(date, isToday: isToday));
    final state = card.value;
    if (state == null) {
      if (card.hasError) {
        return FbGlanceTile(
          key: const ValueKey('today-glance-weight'),
          icon: FbIcons.weight,
          text: l10n.todayGlanceUnavailable,
          muted: true,
          semanticLabel: l10n.todayGlanceWeightUnavailable,
          onTap: () => ref
            ..invalidate(weighInsProvider)
            ..invalidate(weightTrendProvider),
        );
      }
      return const FbGlanceTile.loading(key: ValueKey('today-glance-weight'));
    }
    void log() =>
        unawaited(showWeighInSheet(context, date: isToday ? null : date));
    final asOf = state.asOf;
    final unit = state.units.bodyMass;
    final trendKg = asOf.trendKg;
    final String text;
    final String summary;
    if (trendKg == null) {
      text = l10n.todayGlanceWeigh;
      summary = l10n.weightCardEmptySemantics(text);
      return FbGlanceTile(
        key: const ValueKey('today-glance-weight'),
        icon: FbIcons.add,
        text: text,
        semanticLabel: summary,
        onTap: log,
      );
    }
    final trend = weightText(l10n, trendKg, unit);
    final spoken = weightSpoken(l10n, trendKg, unit);
    if (asOf.isStale) {
      final today = EntryTime.now(ref.read(clockProvider)).localDate;
      final from = dayLabelInline(context, asOf.lastWeighIn!.localDate, today);
      text = l10n.todayGlanceWeightStale(trend, from);
      summary = l10n.weightCardTrendFromSemantics(spoken, from);
    } else if (asOf.weeklyRateKg case final perWeek?) {
      text = l10n.todayGlanceWeight(trend, weightRateText(l10n, perWeek, unit));
      summary = l10n.weightCardTrendRateSemantics(
        spoken,
        weightSpokenChange(l10n, perWeek, unit),
      );
    } else {
      text = trend;
      summary = l10n.weightCardTrendSemantics(spoken);
    }
    return FbGlanceTile(
      key: const ValueKey('today-glance-weight'),
      icon: FbIcons.weight,
      text: text,
      semanticLabel: l10n.weightCardLogSemantics(summary),
      onTap: log,
    );
  }
}
