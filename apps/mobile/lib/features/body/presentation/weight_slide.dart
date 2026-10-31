import 'dart:async';

import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/l10n/day_label.dart';
import 'package:fb_mobile/core/l10n/l10n.dart';
import 'package:fb_mobile/core/navigation/navigation.dart';
import 'package:fb_mobile/core/time/clock_provider.dart';
import 'package:fb_mobile/features/body/application/weight_card_state.dart';
import 'package:fb_mobile/features/body/application/weight_providers.dart';
import 'package:fb_mobile/features/body/application/weight_sparkline.dart';
import 'package:fb_mobile/features/body/application/weight_tip.dart';
import 'package:fb_mobile/features/body/presentation/weigh_in_sheet.dart';
import 'package:fb_mobile/features/body/presentation/weight_text.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// Weight as of the viewed date, with the existing log and edit entry points.
class WeightSlide extends ConsumerWidget {
  /// Creates the component with localized labels and session state.
  const new({
    required this.date,
    required this.isToday,
    this.selected = true,
    super.key,
  });

  /// The viewed day.
  final LocalDate date;

  /// Whether this is the current day.
  final bool isToday;

  /// Whether this slide is currently visible.
  final bool selected;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final card = ref.watch(weightCardProvider(date, isToday: isToday));
    final state = card.value;
    if (state != null) return _content(context, ref, state);
    if (card.hasError) {
      return FbInlineBanner(
        kind: FbInlineBannerKind.error,
        message: context.l10n.weightCardLoadFailed,
        actionLabel: context.l10n.weightCardTryAgain,
        onAction: () => ref.invalidate(weighInsProvider),
      );
    }
    return const FbSkeleton.card(height: 72);
  }

  Widget _content(BuildContext context, WidgetRef ref, WeightCardState state) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final muted = FbType.bodySmall.copyWith(color: scheme.onSurfaceVariant);
    final today = EntryTime.now(ref.read(clockProvider)).localDate;
    final asOf = state.asOf;
    final unit = state.units.bodyMass;

    // Row 1: the trend (title), the weekly rate on its own line, then at
    // most one quiet note; and what a screen reader says, units in full.
    final String main;
    String? rate;
    String? note;
    final String rowLabel;
    final trendKg = asOf.trendKg;
    if (trendKg == null) {
      main = state.hasHistory ? l10n.weightCardEmptyPast : l10n.weightCardEmpty;
      rowLabel = l10n.weightCardEmptySemantics(main);
    } else {
      final trend = weightText(l10n, trendKg, unit);
      final spoken = weightSpoken(l10n, trendKg, unit);
      final String summary;
      if (asOf.isStale) {
        final from = dayLabelInline(
          context,
          asOf.lastWeighIn!.localDate,
          today,
        );
        main = l10n.weightCardTrendFrom(trend, from);
        summary = l10n.weightCardTrendFromSemantics(spoken, from);
      } else if (asOf.weeklyRateKg case final perWeek?) {
        main = l10n.weightCardTrend(trend);
        rate = weightRateText(l10n, perWeek, unit);
        summary = l10n.weightCardTrendRateSemantics(
          spoken,
          weightSpokenChange(l10n, perWeek, unit),
        );
        if (state.cadence case final cadence?
            when cadence.kind == CadenceKind.sparse) {
          note = l10n.weightCardSparse(cadence.countLast28);
        }
      } else {
        main = l10n.weightCardTrend(trend);
        summary = l10n.weightCardTrendSemantics(spoken);
        note = l10n.weightCardRateLater;
      }
      rowLabel = note == null
          ? l10n.weightCardLogSemantics(summary)
          : l10n.weightCardLogNoteSemantics(summary, note);
    }

    if (state.showTip && selected) _markTipShown(context, ref);
    // Row 2: the latest weigh-in. When stale, the trend row already says
    // its day, so this one doesn't repeat it.
    final latest = state.latest;
    final String? last;
    final String? lastLabel;
    if (latest == null) {
      last = null;
      lastLabel = null;
    } else if (asOf.isStale) {
      last = l10n.weightCardLastValue(weightText(l10n, latest.kg, unit));
      lastLabel = l10n.weightCardLastValueSemantics(
        weightSpoken(l10n, latest.kg, unit),
      );
    } else {
      final when = dayLabel(context, latest.localDate, today);
      last = l10n.weightCardLast(weightText(l10n, latest.kg, unit), when);
      lastLabel = l10n.weightCardLastSemantics(
        weightSpoken(l10n, latest.kg, unit),
        when,
      );
    }

    final values = sparklineValues(
      ref.watch(weighInsProvider).value ?? [],
      date,
    );
    final large = MediaQuery.textScalerOf(context).scale(1) >= 1.4;
    final numbers = Semantics(
      label: l10n.weightGraphTitle,
      button: true,
      onTap: () =>
          ref.read(appNavigatorProvider).push(const TodayWeightGraphRoute()),
      excludeSemantics: true,
      child: InkWell(
        onTap: () =>
            ref.read(appNavigatorProvider).push(const TodayWeightGraphRoute()),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                main,
                style: state.isEmpty
                    ? FbType.body
                    : FbType.numeric(FbType.title),
              ),
              if (rate != null) Text(rate, style: FbType.bodySmall),
            ],
          ),
        ),
      ),
    );
    void log() =>
        unawaited(showWeighInSheet(context, date: isToday ? null : date));
    // The spoken action must match the route: numbers open the graph;
    // the log button retains the existing full-unit summary.
    final add = Semantics(
      label: rowLabel,
      button: true,
      excludeSemantics: true,
      onTap: log,
      child: FbButton.primary(
        key: const ValueKey('today-weigh-in'),
        label: l10n.weightSlideAdd,
        onPressed: log,
      ),
    );
    Widget lastValue() => Semantics(
      label: l10n.weightCardEditSemantics(lastLabel!),
      button: true,
      excludeSemantics: true,
      onTap: () => unawaited(showWeighInSheet(context, edit: latest)),
      child: InkWell(
        onTap: () => unawaited(showWeighInSheet(context, edit: latest)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: Text(last!, style: muted),
          ),
        ),
      ),
    );
    final tip = Semantics(
      button: true,
      label: l10n.weightCardTipDismiss,
      child: InkWell(
        onTap: () =>
            unawaited(ref.read(weightTipControllerProvider.notifier).dismiss()),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Text(
            l10n.weightCardTip,
            style: large ? muted : FbType.caption,
          ),
        ),
      ),
    );
    if (!large) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.weightTitle, style: FbType.label),
          Row(
            children: [
              Expanded(child: numbers),
              if (values.length >= 2)
                SizedBox(width: 160, child: FbSparkline(values: values)),
            ],
          ),
          Row(
            children: [
              if (last != null)
                Expanded(child: lastValue())
              else
                const Spacer(),
              add,
            ],
          ),
          if (selected && note != null) Text(note, style: FbType.caption),
          if (selected && state.showTip) tip,
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: FbSpace.s1,
      children: [
        Text(l10n.weightTitle, style: FbType.label),
        numbers,
        if (values.length >= 2) FbSparkline(values: values),
        if (latest != null && last != null) lastValue(),
        if (selected && note != null) Text(note, style: muted),
        if (selected && state.showTip) tip,
        Align(alignment: AlignmentDirectional.centerStart, child: add),
      ],
    );
  }

  void _markTipShown(BuildContext context, WidgetRef ref) {
    if (ref.read(weightTipControllerProvider).value?.shownOn == date) return;
    final controller = ref.read(weightTipControllerProvider.notifier);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) unawaited(controller.markShown(date));
    });
  }
}
